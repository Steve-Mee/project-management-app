// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import 'mirror_signed_inputs_backend.dart';
import 'services/mirror_backend_workflows.dart';
import 'services/mirror_context_budget_service.dart';
import 'services/mirror_observability_service.dart';
import 'services/mirror_retry_policy.dart';

const Uuid _uuid = Uuid();
const MirrorBackendWorkflows _mirrorWorkflows = MirrorBackendWorkflows();

class MirrorGatewayBackend implements MirrorComputeBackend {
  MirrorGatewayBackend({
    SupabaseClient? client,
    http.Client? httpClient,
    this.httpEndpoint,
    this.applyHttpEndpoint,
    this.useSecureApply = true,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 300),
    MirrorContextBudgetService? budgetService,
    MirrorObservabilityService? observabilityService,
    MirrorRetryPolicy? retryPolicy,
    this.onCompileValidated,
  })  : _client = _resolveClient(client),
        _httpClient = httpClient ?? http.Client(),
        _budgetService = budgetService,
        _observabilityService = observabilityService,
        _retryPolicy = retryPolicy ??
            MirrorRetryPolicy(
              timeout: timeout,
              maxRetries: maxRetries,
              initialBackoff: initialBackoff,
            );

  final SupabaseClient? _client;
  final http.Client _httpClient;
  final MirrorContextBudgetService? _budgetService;
  final MirrorObservabilityService? _observabilityService;
  final MirrorRetryPolicy _retryPolicy;
  final String? httpEndpoint;
  final String? applyHttpEndpoint;
  final bool useSecureApply;
  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff;
  final void Function({
    required String projectId,
    required String taskId,
    required String compileFingerprint,
    String? serverVersionToken,
  })? onCompileValidated;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    late final CompileResult compileResult;
    try {
      final endpoint = _resolveCompileEndpoint();
      compileResult = await _postCompile(
        endpoint: endpoint,
        prompt: prompt,
        context: context,
        mode: mode,
      );
    } catch (error) {
      _observabilityService?.recordFallbackEvent(
        reason: 'config_error',
        mode: mode,
        fromBackend: 'mirror_gateway',
        toBackend: 'offline_queue',
      );
      compileResult = CompileResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.config,
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
    }

    if (!compileResult.success) {
      return GenerateResult(
        success: false,
        message: compileResult.errors.join(' | '),
        diagnostics: compileResult.errors,
      );
    }

    return GenerateResult(
      success: true,
      code: compileResult.output,
      diagnostics: compileResult.warnings,
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    try {
      final endpoint = _resolveCompileEndpoint();
      return _postCompile(
        endpoint: endpoint,
        prompt: prompt,
        context: context,
        mode: mode,
      );
    } catch (error) {
      _observabilityService?.recordFallbackEvent(
        reason: 'config_error',
        mode: mode,
        fromBackend: 'mirror_gateway',
        toBackend: 'offline_queue',
      );
      return CompileResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.config,
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
    }
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    late final String endpoint;
    try {
      endpoint = _resolveApplyEndpoint();
    } catch (error) {
      _observabilityService?.recordFallbackEvent(
        reason: 'config_error',
        mode: mode,
        fromBackend: 'mirror_gateway',
        toBackend: 'offline_queue',
      );
      return ApplyResult(
        success: false,
        message: _formatStructuredError(
          family: _MirrorGatewayErrorFamily.config,
          message: error.toString(),
          retryable: false,
        ),
      );
    }

    final normalizedCompileFingerprint = compileFingerprint?.trim() ?? '';
    if (useSecureApply && normalizedCompileFingerprint.isEmpty) {
      return ApplyResult(
        success: false,
        message: _formatStructuredError(
          family: _MirrorGatewayErrorFamily.validation,
          message:
              'Apply blocked: preview fingerprint missing. Re-run preview before applying.',
          retryable: false,
        ),
      );
    }

    if (!useSecureApply && normalizedCompileFingerprint.isEmpty) {
      return _applyWithoutSecurity(
        endpoint: endpoint,
        prompt: prompt,
        context: context,
        mode: mode,
      );
    }

    if (!useSecureApply) {
      final preflight = await compile(
        prompt: prompt,
        context: context,
        mode: mode,
      );
      if (!preflight.success || preflight.output == null) {
        return ApplyResult(
          success: false,
          message: preflight.errors.isEmpty
              ? _formatStructuredError(
                  family: _MirrorGatewayErrorFamily.validation,
                  message: 'Apply failed: compile output is empty.',
                  retryable: false,
                )
              : preflight.errors.join(' | '),
        );
      }

      final consistencyError = _validatePreviewApplyConsistency(
        prompt: prompt,
        context: context,
        mode: mode,
        expectedCompileFingerprint: normalizedCompileFingerprint,
        preflightOutput: preflight.output!,
      );
      if (consistencyError != null) {
        return ApplyResult(success: false, message: consistencyError);
      }

      return _applyWithoutSecurity(
        endpoint: endpoint,
        prompt: prompt,
        context: context,
        mode: mode,
      );
    }

    return _mirrorWorkflows.secureApply(
      prompt: prompt,
      context: context,
      mode: mode,
      onApply: (ApplySecurityArtifacts artifacts) async {
        final preflight = await compile(
          prompt: prompt,
          context: context,
          mode: mode,
        );
        if (!preflight.success || preflight.output == null) {
          return ApplyResult(
            success: false,
            message: preflight.errors.isEmpty
                ? _formatStructuredError(
                    family: _MirrorGatewayErrorFamily.validation,
                    message: 'Apply failed: compile output is empty.',
                    retryable: false,
                  )
                : preflight.errors.join(' | '),
          );
        }

        final consistencyError = _validatePreviewApplyConsistency(
          prompt: prompt,
          context: context,
          mode: mode,
          expectedCompileFingerprint: normalizedCompileFingerprint,
          preflightOutput: preflight.output!,
        );
        if (consistencyError != null) {
          return ApplyResult(success: false, message: consistencyError);
        }

        return _executeApplyRequest(
          endpoint: endpoint,
          prompt: prompt,
          context: context,
          mode: mode,
          artifacts: artifacts,
        );
      },
    );
  }

  String? _validatePreviewApplyConsistency({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required String expectedCompileFingerprint,
    required String preflightOutput,
  }) {
    final actualFingerprint = computeCompileResultFingerprint(
      prompt: prompt,
      context: context,
      mode: mode,
      output: preflightOutput,
    );
    if (actualFingerprint != expectedCompileFingerprint) {
      return _formatStructuredError(
        family: _MirrorGatewayErrorFamily.consistency,
        message:
            'Apply blocked: preview fingerprint mismatch. Re-run preview before applying.',
        retryable: false,
      );
    }

    // Contract: context.metadata['previewContextFingerprint'] is validated
    final expectedContextFingerprint =
        context.metadata.previewContextFingerprint ?? '';
    if (expectedContextFingerprint.isNotEmpty) {
      final actualContextFingerprint = _fingerprintFileMap(context.files);
      if (actualContextFingerprint != expectedContextFingerprint) {
        return _formatStructuredError(
          family: _MirrorGatewayErrorFamily.consistency,
          message:
              'Apply blocked: preview context mismatch. Re-run preview before applying.',
          retryable: false,
        );
      }
    }

    return null;
  }

  Future<ApplyResult> _applyWithoutSecurity({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return _executeApplyRequest(
      endpoint: endpoint,
      prompt: prompt,
      context: context,
      mode: mode,
      artifacts: null,
    );
  }

  Future<ApplyResult> _executeApplyRequest({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
    required ApplySecurityArtifacts? artifacts,
  }) async {
    final raw = await _postRaw(
      endpoint: endpoint,
      prompt: prompt,
      context: context,
      mode: mode,
      extra: artifacts == null
          ? const <String, dynamic>{}
          : <String, dynamic>{
              'backupId': artifacts.backupId,
              'fileSetFingerprint': _fingerprintFileMap(context.files),
              'actorUserId': _client?.auth.currentUser?.id,
              'signedInputUrls': artifacts.signedInputUrls,
            },
    );

    if (!raw.success || raw.body == null) {
      return ApplyResult(
        success: false,
        message: raw.errors.join(' | '),
      );
    }

    final normalizedOutput = _normalizeGatewayOutput(raw.body!);

    final patches = _mirrorWorkflows.buildPatchesFromApplyPayload(
      context: context,
      output: normalizedOutput,
    );

    if (patches.isEmpty) {
      return ApplyResult(
        success: false,
        message: _formatStructuredError(
          family: _MirrorGatewayErrorFamily.validation,
          message: 'Apply failed: no patchable changes returned.',
          retryable: false,
        ),
      );
    }

    if (artifacts != null) {
      final updatedFiles = _mirrorWorkflows.applyPatchesToFiles(
        files: context.files,
        patches: patches,
      );

      await _mirrorWorkflows.persistApplyToHive(
        context: context,
        mode: mode,
        prompt: prompt,
        patches: patches,
        artifacts: artifacts,
        backend: 'mirror_gateway',
        updatedFiles: updatedFiles,
      );
    }

    return ApplyResult(
      success: true,
      appliedFiles: patches.map((patch) => patch.path).toSet().toList(),
      message: artifacts == null
          ? 'Applied ${patches.length} patch(es).'
          : 'Applied ${patches.length} patch(es) with backup ${artifacts.backupId}.',
    );
  }

  String _resolveCompileEndpoint() {
    return resolveCompileEndpoint(httpEndpoint: httpEndpoint);
  }

  String _resolveApplyEndpoint() {
    return resolveApplyEndpoint(
      compileHttpEndpoint: httpEndpoint,
      applyHttpEndpoint: applyHttpEndpoint,
    );
  }

  Future<CompileResult> _postCompile({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final requestTrace = _buildRequestTrace(context: context, mode: mode);
    final request = _buildGatewayRequest(
      prompt: prompt,
      context: context,
      mode: mode,
      requestTrace: requestTrace,
    );
    _observabilityService?.recordRequestLinkEvent(
      operation: 'compile',
      mode: mode,
      requestId: requestTrace.requestId,
      traceId: requestTrace.traceId,
      idempotencyKey: requestTrace.idempotencyKey,
      endpoint: endpoint,
      stage: 'client_gateway_dispatch',
    );

    final result = await _retryPolicy.execute<CompileResult, http.Response>(
      attemptOperation: () => _httpClient.post(
        Uri.parse(endpoint),
        headers: request.headers,
        body: request.body,
      ),
      isSuccess: (response) => _isSuccessfulStatus(response.statusCode),
      isRetriable: (response) => _isRetriableStatus(response.statusCode),
      retryReasonForResult: (response) =>
          response.statusCode == 429 ? 'rate_limited' : 'server_error',
      onSuccess: (response) {
        _recordGatewayResponseLink(
          operation: 'compile',
          mode: mode,
          endpoint: endpoint,
          requestTrace: requestTrace,
          response: response,
        );
        return _compileResultFromRaw(response.body);
      },
      onFailure: (response) => CompileResult(
        success: false,
        errors: <String>[
          '${_httpErrorCodeForStatus(response.statusCode).family.value}: HTTP ${response.statusCode}',
          if (response.body.trim().isNotEmpty) response.body,
        ],
      ),
      onTimeoutFailure: () => CompileResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.timeout,
            message: 'Mirror Gateway HTTP /compile request timed out.',
          ),
        ],
      ),
      onErrorFailure: (error) => CompileResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.network,
            message: error.toString(),
          ),
        ],
      ),
      onAttemptComplete: ({
        required int durationMs,
        required bool success,
        required int attempt,
      }) {
        _observabilityService?.recordCompileLatency(
          durationMs: durationMs,
          mode: mode,
          operation: 'compile',
          success: success,
          attempt: attempt,
          requestId: requestTrace.requestId,
          traceId: requestTrace.traceId,
          idempotencyKey: requestTrace.idempotencyKey,
        );
      },
      onRetry: ({required String reason, required int attempt}) {
        _observabilityService?.recordRetry(
          operation: 'compile',
          reason: reason,
          attempt: attempt,
          mode: mode,
          requestId: requestTrace.requestId,
          traceId: requestTrace.traceId,
          idempotencyKey: requestTrace.idempotencyKey,
        );
      },
    );

    _persistCompileValidationArtifacts(
      prompt: prompt,
      context: context,
      mode: mode,
      compileResult: result,
    );

    return result;
  }

  void _persistCompileValidationArtifacts({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required CompileResult compileResult,
  }) {
    final callback = onCompileValidated;
    if (callback == null || !compileResult.success) {
      return;
    }

    final output = compileResult.output;
    if (output == null || output.trim().isEmpty) {
      return;
    }

    final projectId = context.projectId.trim();
    final taskId = context.taskId.trim();
    if (projectId.isEmpty || taskId.isEmpty) {
      return;
    }

    final compileFingerprint = computeCompileResultFingerprint(
      prompt: prompt,
      context: context,
      mode: mode,
      output: output,
    );

    callback(
      projectId: projectId,
      taskId: taskId,
      compileFingerprint: compileFingerprint,
      serverVersionToken: compileResult.serverVersionToken,
    );
  }

  Future<_RawGatewayResult> _postRaw({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final requestTrace = _buildRequestTrace(context: context, mode: mode);
    final request = _buildGatewayRequest(
      prompt: prompt,
      context: context,
      mode: mode,
      extra: extra,
      requestTrace: requestTrace,
    );
    _observabilityService?.recordRequestLinkEvent(
      operation: 'apply',
      mode: mode,
      requestId: requestTrace.requestId,
      traceId: requestTrace.traceId,
      idempotencyKey: requestTrace.idempotencyKey,
      endpoint: endpoint,
      stage: 'client_gateway_dispatch',
    );

    return _retryPolicy.execute<_RawGatewayResult, http.Response>(
      attemptOperation: () => _httpClient.post(
        Uri.parse(endpoint),
        headers: request.headers,
        body: request.body,
      ),
      isSuccess: (response) => _isSuccessfulStatus(response.statusCode),
      isRetriable: (response) => _isRetriableStatus(response.statusCode),
      retryReasonForResult: (response) =>
          response.statusCode == 429 ? 'rate_limited' : 'server_error',
      onSuccess: (response) {
        _recordGatewayResponseLink(
          operation: 'apply',
          mode: mode,
          endpoint: endpoint,
          requestTrace: requestTrace,
          response: response,
        );
        return _RawGatewayResult(success: true, body: response.body);
      },
      onFailure: (response) => _RawGatewayResult(
        success: false,
        errors: <String>[
          '${_httpErrorCodeForStatus(response.statusCode).family.value}: HTTP ${response.statusCode}',
          if (response.body.trim().isNotEmpty) response.body,
        ],
      ),
      onTimeoutFailure: () => _RawGatewayResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.timeout,
            message: 'Mirror Gateway HTTP /apply request timed out.',
          ),
        ],
      ),
      onErrorFailure: (error) => _RawGatewayResult(
        success: false,
        errors: <String>[
          _formatStructuredError(
            family: _MirrorGatewayErrorFamily.network,
            message: error.toString(),
          ),
        ],
      ),
      onAttemptComplete: ({
        required int durationMs,
        required bool success,
        required int attempt,
      }) {
        _observabilityService?.recordCompileLatency(
          durationMs: durationMs,
          mode: mode,
          operation: 'apply',
          success: success,
          attempt: attempt,
          requestId: requestTrace.requestId,
          traceId: requestTrace.traceId,
          idempotencyKey: requestTrace.idempotencyKey,
        );
      },
      onRetry: ({required String reason, required int attempt}) {
        _observabilityService?.recordRetry(
          operation: 'apply',
          reason: reason,
          attempt: attempt,
          mode: mode,
          requestId: requestTrace.requestId,
          traceId: requestTrace.traceId,
          idempotencyKey: requestTrace.idempotencyKey,
        );
      },
    );
  }

  _MirrorGatewayRequest _buildGatewayRequest({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required _MirrorRequestTrace requestTrace,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final effectiveContext =
        _budgetService?.enforce(context).context ?? context;
    final token = _client?.auth.currentSession?.accessToken;
    final idempotencyKey = requestTrace.idempotencyKey;
    final metadata = <String, dynamic>{
      ...effectiveContext.metadata.toJson(),
      'requestId': requestTrace.requestId,
      'traceId': requestTrace.traceId,
    };
    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': effectiveContext.projectId,
      'taskId': effectiveContext.taskId,
      'mode': mode,
      'files': effectiveContext.files,
      'metadata': metadata,
      ...extra,
    };

    final encodedPayload = _budgetService?.encodePayload(payload);
    final body = encodedPayload?.bytes ?? jsonEncode(payload);
    return _MirrorGatewayRequest(
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (encodedPayload?.isGzip ?? false) 'Content-Encoding': 'gzip',
        'x-request-id': requestTrace.requestId,
        'x-trace-id': requestTrace.traceId,
        if (idempotencyKey != null) 'x-idempotency-key': idempotencyKey,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

  _MirrorRequestTrace _buildRequestTrace({
    required ProjectContext context,
    required String mode,
  }) {
    final metadataJson = context.metadata.toJson();
    final requestId = _resolveRequestId(metadataJson);
    final traceId = _resolveTraceId(metadataJson, requestId: requestId);
    final idempotencyKey = _resolveIdempotencyKey(context.metadata);
    return _MirrorRequestTrace(
      requestId: requestId,
      traceId: traceId,
      idempotencyKey: idempotencyKey,
      mode: mode,
    );
  }

  void _recordGatewayResponseLink({
    required String operation,
    required String mode,
    required String endpoint,
    required _MirrorRequestTrace requestTrace,
    required http.Response response,
  }) {
    final gatewayRequestId =
        _firstNonBlank(<String?>[response.headers['x-request-id']]) ??
            requestTrace.requestId;
    final gatewayTraceId =
        _firstNonBlank(<String?>[response.headers['x-trace-id']]) ??
            requestTrace.traceId;

    _observabilityService?.recordRequestLinkEvent(
      operation: operation,
      mode: mode,
      requestId: requestTrace.requestId,
      traceId: requestTrace.traceId,
      linkedRequestId: gatewayRequestId,
      linkedTraceId: gatewayTraceId,
      idempotencyKey: requestTrace.idempotencyKey,
      endpoint: endpoint,
      stage: 'gateway_response',
    );
  }

  bool _isSuccessfulStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  bool _isRetriableStatus(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  _MirrorGatewayHttpErrorCode _httpErrorCodeForStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return _MirrorGatewayHttpErrorCode.unauthorized;
    }
    if (statusCode == 429) {
      return _MirrorGatewayHttpErrorCode.rateLimited;
    }
    if (statusCode >= 500) {
      return _MirrorGatewayHttpErrorCode.server;
    }
    return _MirrorGatewayHttpErrorCode.badRequest;
  }

  CompileResult _compileResultFromRaw(String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = <String, dynamic>{'success': true, 'output': raw};
    }

    if (decoded is Map) {
      final normalized = Map<String, dynamic>.from(decoded);
      final errorsRaw = normalized['errors'];
      final warningsRaw = normalized['warnings'];

      return CompileResult(
        success: (normalized['success'] as bool?) ?? true,
        output: _normalizeDecodedOutput(normalized),
        serverVersionToken:
            _normalizeServerVersionToken(normalized['artifactPath']),
        errors: errorsRaw is List
            ? errorsRaw.map((e) => e.toString()).toList()
            : const <String>[],
        warnings: warningsRaw is List
            ? warningsRaw.map((e) => e.toString()).toList()
            : const <String>[],
      );
    }

    return CompileResult(success: true, output: raw);
  }

  String? _normalizeServerVersionToken(Object? rawToken) {
    final token = rawToken?.toString().trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  String _normalizeGatewayOutput(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final normalizedOutput = _normalizeDecodedOutput(
          Map<String, dynamic>.from(decoded),
        );
        if (normalizedOutput != null && normalizedOutput.trim().isNotEmpty) {
          return normalizedOutput;
        }
      }
    } catch (_) {
      // Keep original raw payload when response is not JSON.
    }

    return raw;
  }

  String? _normalizeDecodedOutput(Map<String, dynamic> decoded) {
    return _normalizeOutputField(decoded['output']);
  }

  String? _normalizeOutputField(Object? output) {
    if (output == null) {
      return null;
    }
    if (output is String) {
      return output;
    }
    if (output is Map) {
      return jsonEncode(Map<String, dynamic>.from(output));
    }
    if (output is List) {
      return jsonEncode(output);
    }
    return output.toString();
  }

  static String resolveCompileEndpoint({String? httpEndpoint}) {
    final explicit = httpEndpoint?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final base = _requireSupabaseBaseUrl();
    return '$base/functions/v1/mirror-gateway/compile';
  }

  static String resolveApplyEndpoint({
    String? compileHttpEndpoint,
    String? applyHttpEndpoint,
  }) {
    final explicitApply = applyHttpEndpoint?.trim();
    if (explicitApply != null && explicitApply.isNotEmpty) {
      return explicitApply;
    }

    final explicitCompile = compileHttpEndpoint?.trim();
    if (explicitCompile == null || explicitCompile.isEmpty) {
      return _defaultApplyEndpoint();
    }

    final compileEndpoint =
        resolveCompileEndpoint(httpEndpoint: explicitCompile);
    if (compileEndpoint.endsWith('/compile')) {
      return '${compileEndpoint.substring(0, compileEndpoint.length - '/compile'.length)}/apply';
    }
    if (compileEndpoint.endsWith('/')) {
      return '${compileEndpoint}apply';
    }
    return '$compileEndpoint/apply';
  }

  static String _defaultApplyEndpoint() {
    final base = _requireSupabaseBaseUrl();
    return '$base/functions/v1/mirror-gateway/apply';
  }

  static String _requireSupabaseBaseUrl() {
    final configured = AppConfig.supabaseUrl?.trim();
    if (configured == null || configured.isEmpty) {
      throw StateError(
        'supabase_url_missing: Set AppConfig.supabaseUrl or provide explicit MirrorGatewayBackend endpoints.',
      );
    }
    return configured;
  }

  static SupabaseClient? _resolveClient(SupabaseClient? client) {
    if (client != null) {
      return client;
    }

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

enum _MirrorGatewayHttpErrorCode {
  unauthorized(_MirrorGatewayErrorFamily.unauthorized),
  rateLimited(_MirrorGatewayErrorFamily.rateLimited),
  badRequest(_MirrorGatewayErrorFamily.badRequest),
  server(_MirrorGatewayErrorFamily.serverError);

  const _MirrorGatewayHttpErrorCode(this.family);

  final _MirrorGatewayErrorFamily family;
}

enum _MirrorGatewayErrorFamily {
  config('config_error', false),
  validation('validation_error', false),
  consistency('consistency_error', false),
  timeout('timeout', true),
  network('network', true),
  unauthorized('unauthorized', false),
  rateLimited('rate_limited', true),
  badRequest('bad_request', false),
  serverError('server_error', true);

  const _MirrorGatewayErrorFamily(this.value, this.defaultRetryable);

  final String value;
  final bool defaultRetryable;
}

String _formatStructuredError({
  required _MirrorGatewayErrorFamily family,
  required String message,
  bool? retryable,
  int? statusCode,
}) {
  return jsonEncode(<String, dynamic>{
    'error_family': family.value,
    'retryable': retryable ?? family.defaultRetryable,
    'message': message,
    if (statusCode != null) 'status_code': statusCode,
  });
}

class _RawGatewayResult {
  const _RawGatewayResult({
    required this.success,
    this.body,
    this.errors = const <String>[],
  });

  final bool success;
  final String? body;
  final List<String> errors;
}

class _MirrorGatewayRequest {
  const _MirrorGatewayRequest({
    required this.headers,
    required this.body,
  });

  final Map<String, String> headers;
  final Object body;
}

String _fingerprintFileMap(Map<String, String> files) {
  final paths = files.keys.toList()..sort();
  final buffer = StringBuffer();
  for (final path in paths) {
    buffer
      ..write(path)
      ..write(':')
      ..write(files[path] ?? '')
      ..write('\n');
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

String? _resolveIdempotencyKey(ProjectContextMetadata metadata) {
  final idempotencyKey = metadata.idempotencyKey;
  if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
    return idempotencyKey;
  }
  return null;
}

String _resolveRequestId(Map<String, dynamic> metadata) {
  const candidates = <String>[
    'requestId',
    'request_id',
    'x-request-id',
  ];
  for (final key in candidates) {
    final value = metadata[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return 'mirror-${_uuid.v4()}';
}

String _resolveTraceId(
  Map<String, dynamic> metadata, {
  required String requestId,
}) {
  const candidates = <String>[
    'traceId',
    'trace_id',
    'x-trace-id',
  ];
  for (final key in candidates) {
    final value = metadata[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return 'trace-$requestId-${_uuid.v4()}';
}

String? _firstNonBlank(List<String?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

class _MirrorRequestTrace {
  const _MirrorRequestTrace({
    required this.requestId,
    required this.traceId,
    required this.mode,
    this.idempotencyKey,
  });

  final String requestId;
  final String traceId;
  final String mode;
  final String? idempotencyKey;
}
