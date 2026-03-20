import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/features/mirror/grpc_generated/mirror.pbgrpc.dart';
import 'compile_runner.dart';

typedef RunnerLog = void Function(
  String level,
  String message, {
  Map<String, Object?> context,
});

typedef RunnerAuthVerifier = RunnerAuthVerdict Function(
  Map<String, String> metadata,
);

typedef RunnerCompileMeasured = void Function({
  required Duration latency,
  required bool success,
});

typedef RunnerGatewayStarter = Future<void> Function();
typedef RunnerGatewayStopper = Future<void> Function();

class RunnerBootstrapConfig {
  const RunnerBootstrapConfig({
    required this.runnerName,
    required this.grpcPort,
    required this.services,
    required this.startGateway,
    required this.stopGateway,
    required this.log,
    this.bindAddress = '0.0.0.0',
    this.startupContext = const <String, Object?>{},
  });

  final String runnerName;
  final int grpcPort;
  final List<Service> services;
  final RunnerGatewayStarter startGateway;
  final RunnerGatewayStopper stopGateway;
  final RunnerLog log;
  final String bindAddress;
  final Map<String, Object?> startupContext;
}

class RunnerRuntime {
  RunnerRuntime({
    required Server server,
    required RunnerGatewayStopper stopGateway,
  })  : _server = server,
        _stopGateway = stopGateway;

  final Server _server;
  final RunnerGatewayStopper _stopGateway;

  Future<void> shutdown() async {
    await _stopGateway();
    await _server.shutdown();
  }
}

Future<RunnerRuntime> bootstrapRunner(RunnerBootstrapConfig config) async {
  final server = Server.create(
    services: config.services,
    codecRegistry:
        CodecRegistry(codecs: const <Codec>[GzipCodec(), IdentityCodec()]),
  );

  await server.serve(address: config.bindAddress, port: config.grpcPort);
  await config.startGateway();

  config.log(
    'info',
    '${config.runnerName} started',
    context: <String, Object?>{
      'grpcPort': config.grpcPort,
      ...config.startupContext,
    },
  );

  final runtime = RunnerRuntime(
    server: server,
    stopGateway: config.stopGateway,
  );

  ProcessSignal.sigint.watch().listen((_) async {
    config.log('info', 'shutdown signal received');
    await runtime.shutdown();
    exit(0);
  });

  return runtime;
}

Future<int> cleanupOldWorkspaces(
  String rootPath, {
  required Duration maxAge,
  required RunnerLog log,
}) async {
  final root = Directory(rootPath);
  if (!await root.exists()) {
    await root.create(recursive: true);
    log(
      'info',
      'workspace root created',
      context: <String, Object?>{'rootPath': rootPath},
    );
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

  log(
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

Timer startWorkspaceCleanupScheduler(
  String rootPath, {
  required Duration maxAge,
  required Duration interval,
  required RunnerLog log,
}) {
  return Timer.periodic(
    interval,
    (_) => unawaited(
      cleanupOldWorkspaces(rootPath, maxAge: maxAge, log: log),
    ),
  );
}

class RunnerAuthVerdict {
  const RunnerAuthVerdict._({
    required this.authorized,
    required this.reasonCode,
  });

  const RunnerAuthVerdict.authorized()
      : this._(
          authorized: true,
          reasonCode: '',
        );

  const RunnerAuthVerdict.denied({required String reasonCode})
      : this._(
          authorized: false,
          reasonCode: reasonCode,
        );

  final bool authorized;
  final String reasonCode;
}

class MirrorRunnerService extends MirrorComputeServiceBase {
  MirrorRunnerService({
    required this.workspaceRoot,
    required String artifactBaseUrl,
    required String signedUrlSecret,
    required this.log,
    this.verifyAuth,
    this.onAuthDenied,
    this.onCompileMeasured,
    this.metricsSnapshot,
  }) : _artifactSigner = ArtifactSigner(
          baseUrl: artifactBaseUrl,
          secret: signedUrlSecret,
        );

  final String workspaceRoot;
  final RunnerLog log;
  final RunnerAuthVerifier? verifyAuth;
  final void Function(String reasonCode)? onAuthDenied;
  final RunnerCompileMeasured? onCompileMeasured;
  final Map<String, Object?> Function()? metricsSnapshot;
  final ArtifactSigner _artifactSigner;

  @override
  Future<CompileResponse> compile(ServiceCall call, CompileRequest request) async {
    final response = await _executeRequest(
      call: call,
      action: 'compile',
      projectId: request.projectId,
      taskId: request.taskId,
      mode: request.mode,
      files: request.files,
      metadataJson: request.metadataJson,
    );
    return CompileResponse(
      success: response.success,
      output: response.output,
      errors: response.errors,
      warnings: response.warnings,
      logs: response.logs,
      signedUrl: response.signedUrl,
      artifactPath: response.artifactPath,
      errorJson: response.errorJson,
    );
  }

  @override
  Future<ApplyResponse> apply(ServiceCall call, ApplyRequest request) async {
    final response = await _executeRequest(
      call: call,
      action: 'apply',
      projectId: request.projectId,
      taskId: request.taskId,
      mode: request.mode,
      files: request.files,
      metadataJson: request.metadataJson,
    );
    return ApplyResponse(
      success: response.success,
      output: response.output,
      errors: response.errors,
      warnings: response.warnings,
      logs: response.logs,
      signedUrl: response.signedUrl,
      artifactPath: response.artifactPath,
      errorJson: response.errorJson,
    );
  }

  Future<_RunnerRpcResponse> _executeRequest({
    required ServiceCall call,
    required String action,
    required String projectId,
    required String taskId,
    required String mode,
    required Map<String, String> files,
    required String metadataJson,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestId = resolveRequestId(call.clientMetadata);
    final traceId = resolveTraceId(call.clientMetadata, requestId: requestId);

    final verifier = verifyAuth;
    if (verifier != null) {
      final verdict = verifier(call.clientMetadata ?? const <String, String>{});
      if (!verdict.authorized) {
        onAuthDenied?.call(verdict.reasonCode);
        log(
          'warn',
          'unauthorized compile request blocked',
          context: <String, Object?>{
            'requestId': requestId,
            'traceId': traceId,
            'reasonCode': verdict.reasonCode,
            ...?metricsSnapshot?.call(),
          },
        );
        throw GrpcError.unauthenticated('auth_denied:${verdict.reasonCode}');
      }
    }

    final metadata = metadataJson.trim().isEmpty
        ? const <String, dynamic>{}
        : tryParseJson(metadataJson);
    log(
      'info',
      '$action request received',
      context: <String, Object?>{
        'requestId': requestId,
        'traceId': traceId,
        'projectId': projectId,
        'taskId': taskId,
        'mode': mode,
      },
    );

    final runner = CompileRunner(workspaceRoot: workspaceRoot);
    final compileResult = await runner.run(
      CompileRunnerInput(
        projectId: projectId,
        taskId: taskId,
        files: files,
        metadata: metadata,
      ),
    );

    final artifactPath = compileResult.artifactPath;
    final signedUrl = artifactPath == null
        ? null
        : _artifactSigner.sign(
            artifactPath,
            validFor: const Duration(minutes: 30),
          );

    final response = _RunnerRpcResponse(
      success: compileResult.success,
      output: jsonEncode(<String, dynamic>{
        'files': Map<String, String>.from(compileResult.outputFiles),
      }),
      errors: compileResult.errors,
      warnings: compileResult.warnings,
      logs: compileResult.logs,
      signedUrl: signedUrl ?? '',
      artifactPath: artifactPath ?? '',
      errorJson: compileResult.contractError == null
          ? ''
          : jsonEncode(compileResult.contractError!.toJson()),
    );

    stopwatch.stop();
    onCompileMeasured?.call(
      latency: stopwatch.elapsed,
      success: compileResult.success,
    );

    log(
      compileResult.success ? 'info' : 'error',
      '$action request completed',
      context: <String, Object?>{
        'requestId': requestId,
        'traceId': traceId,
        'projectId': projectId,
        'taskId': taskId,
        'success': compileResult.success,
        'errorCount': compileResult.errors.length,
        ...?metricsSnapshot?.call(),
      },
    );

    return response;
  }
}

Map<String, dynamic> tryParseJson(String value) {
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

String resolveRequestId(Map<String, String>? metadata) {
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

String resolveTraceId(
  Map<String, String>? metadata, {
  required String requestId,
}) {
  final headers = metadata ?? const <String, String>{};
  final direct = headers['x-trace-id'] ?? headers['trace-id'];
  if (direct != null && direct.trim().isNotEmpty) {
    return direct.trim();
  }

  for (final entry in headers.entries) {
    final key = entry.key.toLowerCase();
    if ((key == 'x-trace-id' || key == 'trace-id') &&
        entry.value.trim().isNotEmpty) {
      return entry.value.trim();
    }
  }

  return 'trace-$requestId';
}

class _RunnerRpcResponse {
  const _RunnerRpcResponse({
    required this.success,
    required this.output,
    required this.errors,
    required this.warnings,
    required this.logs,
    required this.signedUrl,
    required this.artifactPath,
    required this.errorJson,
  });

  final bool success;
  final String output;
  final List<String> errors;
  final List<String> warnings;
  final List<String> logs;
  final String signedUrl;
  final String artifactPath;
  final String errorJson;
}

class ArtifactSigner {
  const ArtifactSigner({required this.baseUrl, required this.secret});

  final String baseUrl;
  final String secret;

  String sign(String artifactPath, {required Duration validFor}) {
    final expiresAt =
        DateTime.now().toUtc().add(validFor).millisecondsSinceEpoch;
    final payload = '$artifactPath:$expiresAt';
    final signature =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    final encodedPath = Uri.encodeComponent(artifactPath);
    return '$baseUrl/$encodedPath?exp=$expiresAt&sig=${signature.toString()}';
  }
}
