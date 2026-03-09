import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';

import 'http_gateway.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/compile_runner.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-cloud-runner/lib/auth_guard.dart';

Future<void> main() async {
  final grpcPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? 50051;
  final httpPort = int.tryParse(Platform.environment['HTTP_PORT'] ?? '') ?? 8080;
  final workspaceRoot =
      Platform.environment['MIRROR_WORKSPACE_ROOT'] ?? '/tmp/mirror-local-workspaces';
  final signedUrlSecret = _requireEnv('SIGNED_URL_SECRET');
  final artifactBaseUrl = _requireEnv('ARTIFACT_BASE_URL');
  final authGuardEnabled =
      _isTrue(Platform.environment['MIRROR_AUTH_GUARD_ENABLED']);
  final authGuard = authGuardEnabled
      ? AuthGuard(
          serviceToken: _requireEnv('MIRROR_SERVICE_TOKEN'),
          jwtSecret: _requireEnv('MIRROR_JWT_SECRET'),
          jwtSecretsByKid: AuthGuard.parseKidSecretMapping(
            Platform.environment['MIRROR_JWT_KEYS_BY_KID'],
          ),
          requiredAudience: _optionalEnv('MIRROR_JWT_AUDIENCE'),
          requiredIssuer: _optionalEnv('MIRROR_JWT_ISSUER'),
        )
      : null;

  await _cleanupOldWorkspaces(workspaceRoot, maxAge: const Duration(hours: 24));
  Timer.periodic(
    const Duration(hours: 1),
    (_) => unawaited(
      _cleanupOldWorkspaces(workspaceRoot, maxAge: const Duration(hours: 24)),
    ),
  );

  final server = Server.create(
    services: <Service>[
      MirrorCompileService(
        workspaceRoot: workspaceRoot,
        artifactBaseUrl: artifactBaseUrl,
        signedUrlSecret: signedUrlSecret,
        authGuard: authGuard,
      ),
    ],
    codecRegistry: CodecRegistry(codecs: const <Codec>[GzipCodec(), IdentityCodec()]),
  );

  await server.serve(address: '0.0.0.0', port: grpcPort);

  final gateway = MirrorHttpGateway(
    bindAddress: '0.0.0.0',
    httpPort: httpPort,
    grpcHost: '127.0.0.1',
    grpcPort: grpcPort,
  );
  await gateway.start();

  _log(
    'info',
    'mirror-local-runner started',
    context: <String, Object?>{
      'grpcPort': grpcPort,
      'httpPort': httpPort,
      'workspaceRoot': workspaceRoot,
      'authGuardEnabled': authGuardEnabled,
    },
  );

  ProcessSignal.sigint.watch().listen((_) async {
    _log('info', 'shutdown signal received');
    await gateway.stop();
    await server.shutdown();
    exit(0);
  });
}

class MirrorCompileService extends Service {
  @override
  String get $name => 'mirror.compute.v1.MirrorComputeService';

  MirrorCompileService({
    required this.workspaceRoot,
    required this.artifactBaseUrl,
    required this.signedUrlSecret,
    required this.authGuard,
  })
    : _artifactSigner = ArtifactSigner(
        baseUrl: artifactBaseUrl,
        secret: signedUrlSecret,
      ) {
    $addMethod(ServiceMethod<List<int>, List<int>>(
      'Compile',
      compile,
      false,
      false,
      (List<int> value) => value,
      (List<int> value) => value,
    ));

    $addMethod(ServiceMethod<List<int>, List<int>>(
      'Apply',
      apply,
      false,
      false,
      (List<int> value) => value,
      (List<int> value) => value,
    ));
  }

  final String workspaceRoot;
  final String artifactBaseUrl;
  final String signedUrlSecret;
  final AuthGuard? authGuard;
  final ArtifactSigner _artifactSigner;

  Future<List<int>> compile(ServiceCall call, List<int> requestBytes) async {
    final requestId = _resolveRequestId(call.clientMetadata);
    final verifier = authGuard;
    if (verifier != null) {
      final verdict = verifier.verify(
        call.clientMetadata ?? const <String, String>{},
      );
      if (!verdict.authorized) {
        _log(
          'warn',
          'unauthorized compile request blocked',
          context: <String, Object?>{
            'requestId': requestId,
            'reasonCode': verdict.reasonCode,
          },
        );
        throw GrpcError.unauthenticated('auth_denied:${verdict.reasonCode}');
      }
    }

    final requestRaw = utf8.decode(requestBytes);
    final request = CompileRequestPayload.fromJson(_tryParseJson(requestRaw));
    _log(
      'info',
      'compile request received',
      context: <String, Object?>{
        'requestId': requestId,
        'projectId': request.projectId,
        'taskId': request.taskId,
        'mode': request.mode,
      },
    );
    final runner = CompileRunner(workspaceRoot: workspaceRoot);

    final compileResult = await runner.run(
      CompileRunnerInput(
        projectId: request.projectId,
        taskId: request.taskId,
        files: request.files,
        metadata: request.metadata,
      ),
    );
    final artifactPath = compileResult.artifactPath;

    final signedUrl = artifactPath == null
        ? null
        : _artifactSigner.sign(
            artifactPath,
            validFor: const Duration(minutes: 30),
          );

    final response = CompileResponsePayload(
      success: compileResult.success,
      output: <String, dynamic>{
        'files': Map<String, String>.from(compileResult.outputFiles),
      },
      errors: compileResult.errors,
      warnings: compileResult.warnings,
      logs: compileResult.logs,
      signedUrl: signedUrl,
      artifactPath: artifactPath,
    );

    _log(
      compileResult.success ? 'info' : 'error',
      'compile request completed',
      context: <String, Object?>{
        'requestId': requestId,
        'projectId': request.projectId,
        'taskId': request.taskId,
        'success': compileResult.success,
        'errorCount': compileResult.errors.length,
      },
    );

    return utf8.encode(jsonEncode(response.toJson()));
  }

  // Keep Apply byte-level signature identical to Compile for compatibility.
  Future<List<int>> apply(ServiceCall call, List<int> requestBytes) {
    return compile(call, requestBytes);
  }

  Map<String, dynamic> _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'raw': value};
    } catch (_) {
      return <String, dynamic>{'raw': value};
    }
  }
}

String _resolveRequestId(Map<String, String>? metadata) {
  final headers = metadata ?? const <String, String>{};
  final direct = headers['x-request-id'] ?? headers['request-id'];
  if (direct != null && direct.trim().isNotEmpty) {
    return direct.trim();
  }

  for (final entry in headers.entries) {
    final key = entry.key.toLowerCase();
    if ((key == 'x-request-id' || key == 'request-id') &&
        entry.value.trim().isNotEmpty) {
      return entry.value.trim();
    }
  }

  return 'grpc-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

String? _optionalEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

bool _isTrue(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

String _requireEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    _log('fatal', 'missing required environment variable', context: <String, Object?>{'key': key});
    throw StateError('Missing required environment variable: $key');
  }
  return value;
}

Future<int> _cleanupOldWorkspaces(String rootPath, {required Duration maxAge}) async {
  final root = Directory(rootPath);
  if (!await root.exists()) {
    await root.create(recursive: true);
    _log('info', 'workspace root created', context: <String, Object?>{'rootPath': rootPath});
    return 0;
  }

  final cutoff = DateTime.now().toUtc().subtract(maxAge);
  final toDelete = <Directory>[];

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! Directory) {
      continue;
    }
    try {
      final modified = (await entity.stat()).modified.toUtc();
      if (modified.isBefore(cutoff)) {
        toDelete.add(entity);
      }
    } catch (_) {
      // Ignore inaccessible workspace paths during cleanup.
    }
  }

  toDelete.sort((a, b) => b.path.length.compareTo(a.path.length));
  var removed = 0;
  for (final dir in toDelete) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        removed += 1;
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  _log(
    'info',
    'workspace cleanup finished',
    context: <String, Object?>{
      'rootPath': rootPath,
      'removedDirectories': removed,
      'maxAgeHours': maxAge.inHours,
    },
  );
  return removed;
}

void _log(String level, String message, {Map<String, Object?> context = const <String, Object?>{}}) {
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'message': message,
      ...context,
    }),
  );
}

class CompileRequestPayload {
  const CompileRequestPayload({
    required this.prompt,
    required this.projectId,
    required this.taskId,
    required this.mode,
    required this.files,
    required this.metadata,
  });

  final String prompt;
  final String projectId;
  final String taskId;
  final String mode;
  final Map<String, String> files;
  final Map<String, dynamic> metadata;

  factory CompileRequestPayload.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final metadataRaw = json['metadata'];

    return CompileRequestPayload(
      prompt: (json['prompt'] ?? '').toString(),
      projectId: (json['projectId'] ?? json['project_id'] ?? '').toString(),
      taskId: (json['taskId'] ?? json['task_id'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      files: filesRaw is Map
          ? filesRaw.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      metadata: metadataRaw is Map
          ? metadataRaw.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{},
    );
  }
}

class CompileResponsePayload {
  const CompileResponsePayload({
    required this.success,
    required this.output,
    required this.errors,
    required this.warnings,
    required this.logs,
    required this.signedUrl,
    required this.artifactPath,
  });

  final bool success;
  final Map<String, dynamic>? output;
  final List<String> errors;
  final List<String> warnings;
  final List<String> logs;
  final String? signedUrl;
  final String? artifactPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'output': output,
      'errors': errors,
      'warnings': warnings,
      'logs': logs,
      'signedUrl': signedUrl,
      'artifactPath': artifactPath,
    };
  }
}

class ArtifactSigner {
  const ArtifactSigner({required this.baseUrl, required this.secret});

  final String baseUrl;
  final String secret;

  String sign(String artifactPath, {required Duration validFor}) {
    final expiresAt = DateTime.now().toUtc().add(validFor).millisecondsSinceEpoch;
    final payload = '$artifactPath:$expiresAt';
    final signature = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    final encodedPath = Uri.encodeComponent(artifactPath);
    return '$baseUrl/$encodedPath?exp=$expiresAt&sig=${signature.toString()}';
  }
}
