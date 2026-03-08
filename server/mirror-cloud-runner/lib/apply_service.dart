import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

import 'auth_guard.dart';
import 'auth_metrics.dart';

typedef ApplyExecutor = Future<ApplyExecutionResult> Function(
  ApplyRequestPayload request,
);

class MirrorApplyService extends Service {
  MirrorApplyService({
    required this.authGuard,
    required this.metrics,
    required this.executor,
  }) {
    $addMethod(ServiceMethod<List<int>, List<int>>(
      'Apply',
      apply,
      false,
      false,
      (List<int> value) => value,
      (List<int> value) => value,
    ));
  }

  @override
  String get $name => 'mirror.compute.v1.MirrorComputeService';

  final AuthGuard authGuard;
  final RunnerMetrics metrics;
  final ApplyExecutor executor;

  // gRPC endpoint signature mirrors Compile.
  Future<List<int>> apply(ServiceCall call, List<int> requestBytes) async {
    final requestId = _resolveRequestId(call.clientMetadata);
    final headers = call.clientMetadata ?? const <String, String>{};
    final stopwatch = Stopwatch()..start();

    final verdict = authGuard.verify(headers);
    if (!verdict.authorized) {
      metrics.recordAuthDenied(verdict.reasonCode);
      _log(
        'warn',
        'unauthorized apply request blocked',
        context: <String, Object?>{
          'requestId': requestId,
          'reasonCode': verdict.reasonCode,
          ...metrics.snapshot(),
        },
      );
      throw GrpcError.unauthenticated('auth_denied:${verdict.reasonCode}');
    }

    return _executeRequest(
      requestId: requestId,
      requestBytes: requestBytes,
      stopwatch: stopwatch,
      transport: 'grpc',
    );
  }

  // HTTP endpoint keeps the same payload/response signature as Compile.
  Future<List<int>> applyHttp(HttpRequest request, List<int> requestBytes) async {
    final headers = <String, String>{};
    request.headers.forEach((String name, List<String> values) {
      if (values.isEmpty) {
        return;
      }
      headers[name.toLowerCase()] = values.first;
    });

    final requestId = _resolveRequestId(headers);
    final stopwatch = Stopwatch()..start();

    final verdict = authGuard.verify(headers);
    if (!verdict.authorized) {
      metrics.recordAuthDenied(verdict.reasonCode);
      _log(
        'warn',
        'unauthorized apply request blocked',
        context: <String, Object?>{
          'requestId': requestId,
          'reasonCode': verdict.reasonCode,
          'transport': 'http',
          ...metrics.snapshot(),
        },
      );

      final unauthorized = ApplyResponsePayload(
        success: false,
        output: null,
        errors: <String>['auth_denied:${verdict.reasonCode}'],
        warnings: const <String>[],
        logs: const <String>[],
      );
      return utf8.encode(jsonEncode(unauthorized.toJson()));
    }

    return _executeRequest(
      requestId: requestId,
      requestBytes: requestBytes,
      stopwatch: stopwatch,
      transport: 'http',
    );
  }

  Future<List<int>> _executeRequest({
    required String requestId,
    required List<int> requestBytes,
    required Stopwatch stopwatch,
    required String transport,
  }) async {
    final requestRaw = utf8.decode(requestBytes);
    final request = ApplyRequestPayload.fromJson(_tryParseJson(requestRaw));

    _log(
      'info',
      'apply request received',
      context: <String, Object?>{
        'requestId': requestId,
        'projectId': request.projectId,
        'taskId': request.taskId,
        'mode': request.mode,
        'transport': transport,
      },
    );

    final result = await executor(request);

    final response = ApplyResponsePayload(
      success: result.success,
      output: result.output,
      errors: result.errors,
      warnings: result.warnings,
      logs: result.logs,
    );

    stopwatch.stop();
    metrics.recordCompile(latency: stopwatch.elapsed, success: result.success);

    _log(
      result.success ? 'info' : 'error',
      'apply request completed',
      context: <String, Object?>{
        'requestId': requestId,
        'projectId': request.projectId,
        'taskId': request.taskId,
        'success': result.success,
        'errorCount': result.errors.length,
        'transport': transport,
        ...metrics.snapshot(),
      },
    );

    return utf8.encode(jsonEncode(response.toJson()));
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

class ApplyRequestPayload {
  const ApplyRequestPayload({
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

  factory ApplyRequestPayload.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final metadataRaw = json['metadata'];

    return ApplyRequestPayload(
      prompt: (json['prompt'] ?? '').toString(),
      projectId: (json['projectId'] ?? json['project_id'] ?? '').toString(),
      taskId: (json['taskId'] ?? json['task_id'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      files: filesRaw is Map
          ? filesRaw
              .map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      metadata: metadataRaw is Map
          ? metadataRaw.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{},
    );
  }
}

class ApplyExecutionResult {
  const ApplyExecutionResult({
    required this.success,
    required this.output,
    required this.errors,
    required this.warnings,
    required this.logs,
  });

  final bool success;
  final String? output;
  final List<String> errors;
  final List<String> warnings;
  final List<String> logs;
}

class ApplyResponsePayload {
  const ApplyResponsePayload({
    required this.success,
    required this.output,
    required this.errors,
    required this.warnings,
    required this.logs,
  });

  final bool success;
  final String? output;
  final List<String> errors;
  final List<String> warnings;
  final List<String> logs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'output': output,
      'errors': errors,
      'warnings': warnings,
      'logs': logs,
    };
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

  return 'apply-${DateTime.now().toUtc().microsecondsSinceEpoch}';
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
