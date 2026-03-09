import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

import 'http_gateway.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-cloud-runner/lib/auth_guard.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/runner_service.dart';

Future<void> main() async {
  final grpcPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? 50051;
  final httpPort = int.tryParse(Platform.environment['HTTP_PORT'] ?? '') ?? 8080;
  final workspaceRoot =
      Platform.environment['MIRROR_WORKSPACE_ROOT'] ?? '/tmp/mirror-local-workspaces';
  final signedUrlSecret = _requireEnv('SIGNED_URL_SECRET');
  final artifactBaseUrl = _requireEnv('ARTIFACT_BASE_URL');
  final authGuardEnabled = _isTrue(
    Platform.environment['MIRROR_AUTH_GUARD_ENABLED'] ?? 'true',
  );
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
      MirrorRunnerService(
        workspaceRoot: workspaceRoot,
        artifactBaseUrl: artifactBaseUrl,
        signedUrlSecret: signedUrlSecret,
        verifyAuth: authGuard == null
            ? null
            : (Map<String, String> metadata) {
                final verdict = authGuard.verify(metadata);
                if (verdict.authorized) {
                  return const RunnerAuthVerdict.authorized();
                }
                return RunnerAuthVerdict.denied(reasonCode: verdict.reasonCode);
              },
        log: _log,
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
