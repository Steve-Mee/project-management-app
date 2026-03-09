import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'auth_guard.dart';
import 'auth_metrics.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/http_gateway.dart';
// ignore: avoid_relative_lib_imports
import '../../mirror-shared/lib/runner_service.dart';

Future<void> main() async {
  final httpPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final grpcPort = int.tryParse(Platform.environment['GRPC_PORT'] ?? '') ?? 50051;
  final workspaceRoot =
      Platform.environment['MIRROR_WORKSPACE_ROOT'] ?? '/tmp/mirror-workspaces';
  final signedUrlSecret = _requireEnv('SIGNED_URL_SECRET');
  final serviceToken = _requireEnv('MIRROR_SERVICE_TOKEN');
  final jwtSecret = _requireEnv('MIRROR_JWT_SECRET');
  final jwtSecretsByKid = AuthGuard.parseKidSecretMapping(
    Platform.environment['MIRROR_JWT_KEYS_BY_KID'],
  );
  final artifactBaseUrl = _requireEnv('ARTIFACT_BASE_URL');
  final requiredAudience = Platform.environment['MIRROR_JWT_AUDIENCE'];
  final requiredIssuer = Platform.environment['MIRROR_JWT_ISSUER'];
  final metrics = RunnerMetrics();
  final gatewayQuota = MirrorGatewayQuotaConfig(
    maxFiles: _intEnv('MIRROR_MAX_FILES', fallback: 500),
    maxWorkspaceBytes:
        _intEnv('MIRROR_MAX_WORKSPACE_BYTES', fallback: 50 * 1024 * 1024),
    maxExecutionWindow: Duration(
      seconds: _intEnv('MIRROR_MAX_EXECUTION_WINDOW_SECONDS', fallback: 300),
    ),
  );

  final authGuard = AuthGuard(
    serviceToken: serviceToken,
    jwtSecret: jwtSecret,
    jwtSecretsByKid: jwtSecretsByKid,
    requiredAudience: requiredAudience,
    requiredIssuer: requiredIssuer,
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
    bindAddress: '0.0.0.0',
    httpPort: httpPort,
    grpcHost: '127.0.0.1',
    grpcPort: grpcPort,
    quota: gatewayQuota,
  );

  await bootstrapRunner(
    RunnerBootstrapConfig(
      runnerName: 'mirror-cloud-runner',
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
            return RunnerAuthVerdict.denied(reasonCode: verdict.reasonCode);
          },
          onAuthDenied: metrics.recordAuthDenied,
          onCompileMeasured:
              ({required Duration latency, required bool success}) {
            metrics.recordCompile(latency: latency, success: success);
          },
          metricsSnapshot: metrics.snapshot,
          log: _log,
        ),
      ],
      startGateway: gateway.start,
      stopGateway: gateway.stop,
      log: _log,
      startupContext: <String, Object?>{
        'httpPort': httpPort,
        'workspaceRoot': workspaceRoot,
        'maxFiles': gatewayQuota.maxFiles,
        'maxWorkspaceBytes': gatewayQuota.maxWorkspaceBytes,
        'maxExecutionWindowSeconds': gatewayQuota.maxExecutionWindow.inSeconds,
      },
    ),
  );
}

int _intEnv(String key, {required int fallback}) {
  final raw = Platform.environment[key]?.trim();
  final parsed = raw == null ? null : int.tryParse(raw);
  if (parsed == null || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

String _requireEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    _log('fatal', 'missing required environment variable',
        context: <String, Object?>{'key': key});
    throw StateError('Missing required environment variable: $key');
  }
  return value;
}

void _log(String level, String message,
    {Map<String, Object?> context = const <String, Object?>{}}) {
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'message': message,
      ...context,
    }),
  );
}
