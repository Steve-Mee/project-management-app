import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/http_gateway.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-cloud-runner/lib/auth_guard.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/runner_service.dart';

Future<void> main() async {
  final grpcPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? 50051;
  final httpPort = int.tryParse(Platform.environment['HTTP_PORT'] ?? '') ?? 8080;
  final bindAddress = _optionalEnv('MIRROR_BIND_ADDRESS') ?? '127.0.0.1';
  final workspaceRoot =
      Platform.environment['MIRROR_WORKSPACE_ROOT'] ?? '/tmp/mirror-local-workspaces';
  final signedUrlSecret = _requireEnv('SIGNED_URL_SECRET');
  final artifactBaseUrl = _requireEnv('ARTIFACT_BASE_URL');
  final authGuardEnabled = _isTrue(
    Platform.environment['MIRROR_AUTH_GUARD_ENABLED'] ?? 'true',
  );
  if (!authGuardEnabled) {
    _log(
      'fatal',
      'auth guard cannot be disabled',
      context: <String, Object?>{'envKey': 'MIRROR_AUTH_GUARD_ENABLED'},
    );
    throw StateError(
      'MIRROR_AUTH_GUARD_ENABLED=false is not allowed for mirror-local-runner',
    );
  }
  final authGuard = AuthGuard(
    serviceToken: _requireEnv('MIRROR_SERVICE_TOKEN'),
    jwtSecret: _requireEnv('MIRROR_JWT_SECRET'),
    jwtSecretsByKid: AuthGuard.parseKidSecretMapping(
      Platform.environment['MIRROR_JWT_KEYS_BY_KID'],
    ),
    requiredAudience: _optionalEnv('MIRROR_JWT_AUDIENCE'),
    requiredIssuer: _optionalEnv('MIRROR_JWT_ISSUER'),
  );

  await cleanupOldWorkspaces(
    workspaceRoot,
    maxAge: const Duration(hours: 24),
    log: _log,
  );
  startWorkspaceCleanupScheduler(
    workspaceRoot,
    maxAge: const Duration(hours: 24),
    interval: const Duration(hours: 1),
    log: _log,
  );

  final gateway = MirrorHttpGateway(
    bindAddress: bindAddress,
    httpPort: httpPort,
    grpcHost: '127.0.0.1',
    grpcPort: grpcPort,
  );

  await bootstrapRunner(
    RunnerBootstrapConfig(
      runnerName: 'mirror-local-runner',
      grpcPort: grpcPort,
      services: <MirrorRunnerService>[
        MirrorRunnerService(
          workspaceRoot: workspaceRoot,
          artifactBaseUrl: artifactBaseUrl,
          signedUrlSecret: signedUrlSecret,
          verifyAuth: (Map<String, String> metadata) {
            final verdict = authGuard.verify(metadata);
            if (verdict.authorized) {
              return const RunnerAuthVerdict.authorized();
            }
            return RunnerAuthVerdict.denied(
              reasonCode: verdict.reasonCode,
            );
          },
          log: _log,
        ),
      ],
      bindAddress: bindAddress,
      startGateway: gateway.start,
      stopGateway: gateway.stop,
      log: _log,
      startupContext: <String, Object?>{
        'httpPort': httpPort,
        'bindAddress': bindAddress,
        'workspaceRoot': workspaceRoot,
        'authGuardEnabled': authGuardEnabled,
      },
    ),
  );
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
