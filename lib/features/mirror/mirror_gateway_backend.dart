// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'mirror_compute_backend.dart';
import 'services/mirror_context_budget_service.dart';
import 'services/mirror_observability_service.dart';
import 'services/mirror_retry_policy.dart';

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
  })  : _client = _resolveClient(client),
        _httpClient = httpClient ?? http.Client(),
        _budgetService = budgetService,
        _observabilityService = observabilityService,
        _retryPolicy = retryPolicy ?? MirrorRetryPolicy(
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
        errors: <String>['config_error: ${error.toString()}'],
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
        errors: <String>['config_error: ${error.toString()}'],
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
        message: 'config_error: ${error.toString()}',
      );
    }

    final normalizedCompileFingerprint = compileFingerprint?.trim() ?? '';
    if (useSecureApply && normalizedCompileFingerprint.isEmpty) {
      return const ApplyResult(
        success: false,
        message:
            'Apply blocked: preview fingerprint missing. Re-run preview before applying.',
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
              ? 'Apply failed: compile output is empty.'
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

    return secureApply(
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
                ? 'Apply failed: compile output is empty.'
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
      return 'Apply blocked: preview fingerprint mismatch. Re-run preview before applying.';
    }

    final expectedContextFingerprint =
        context.metadata['previewContextFingerprint']?.toString().trim() ?? '';
    if (expectedContextFingerprint.isNotEmpty) {
      final actualContextFingerprint = _fingerprintFileMap(context.files);
      if (actualContextFingerprint != expectedContextFingerprint) {
        return 'Apply blocked: preview context mismatch. Re-run preview before applying.';
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

    final patches = buildPatchesFromApplyPayload(
      context: context,
      output: normalizedOutput,
    );

    if (patches.isEmpty) {
      return const ApplyResult(
        success: false,
        message: 'Apply failed: no patchable changes returned.',
      );
    }

    if (artifacts != null) {
      final updatedFiles = applyPatchesToFiles(
        files: context.files,
        patches: patches,
      );

      await persistApplyToHive(
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
    final request = _buildGatewayRequest(
      prompt: prompt,
      context: context,
      mode: mode,
    );

    return _retryPolicy.execute<CompileResult, http.Response>(
      attemptOperation: () => _httpClient.post(
        Uri.parse(endpoint),
        headers: request.headers,
        body: request.body,
      ),
      isSuccess: (response) => _isSuccessfulStatus(response.statusCode),
      isRetriable: (response) => _isRetriableStatus(response.statusCode),
      retryReasonForResult: (response) =>
          response.statusCode == 429 ? 'rate_limited' : 'server_error',
      onSuccess: (response) => _compileResultFromRaw(response.body),
      onFailure: (response) => CompileResult(
        success: false,
        errors: <String>[
          '${_httpErrorCodeForStatus(response.statusCode).value}: HTTP ${response.statusCode}',
          if (response.body.trim().isNotEmpty) response.body,
        ],
      ),
      onTimeoutFailure: () => const CompileResult(
        success: false,
        errors: <String>['timeout: Mirror Gateway HTTP /compile request timed out.'],
      ),
      onErrorFailure: (error) => CompileResult(
        success: false,
        errors: <String>['network: ${error.toString()}'],
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
        );
      },
      onRetry: ({required String reason, required int attempt}) {
        _observabilityService?.recordRetry(
          operation: 'compile',
          reason: reason,
          attempt: attempt,
          mode: mode,
        );
      },
    );
  }

  Future<_RawGatewayResult> _postRaw({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final request = _buildGatewayRequest(
      prompt: prompt,
      context: context,
      mode: mode,
      extra: extra,
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
      onSuccess: (response) => _RawGatewayResult(success: true, body: response.body),
      onFailure: (response) => _RawGatewayResult(
        success: false,
        errors: <String>[
          '${_httpErrorCodeForStatus(response.statusCode).value}: HTTP ${response.statusCode}',
          if (response.body.trim().isNotEmpty) response.body,
        ],
      ),
      onTimeoutFailure: () => const _RawGatewayResult(
        success: false,
        errors: <String>['timeout: Mirror Gateway HTTP /apply request timed out.'],
      ),
      onErrorFailure: (error) => _RawGatewayResult(
        success: false,
        errors: <String>['network: ${error.toString()}'],
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
        );
      },
      onRetry: ({required String reason, required int attempt}) {
        _observabilityService?.recordRetry(
          operation: 'apply',
          reason: reason,
          attempt: attempt,
          mode: mode,
        );
      },
    );
  }

  _MirrorGatewayRequest _buildGatewayRequest({
    required String prompt,
    required ProjectContext context,
    required String mode,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final effectiveContext = _budgetService?.enforce(context).context ?? context;
    final token = _client?.auth.currentSession?.accessToken;
    final idempotencyKey = _resolveIdempotencyKey(context.metadata);
    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': effectiveContext.projectId,
      'taskId': effectiveContext.taskId,
      'mode': mode,
      'files': effectiveContext.files,
      'metadata': effectiveContext.metadata,
      ...extra,
    };

    final encodedPayload = _budgetService?.encodePayload(payload);
    final body = encodedPayload?.bytes ?? jsonEncode(payload);
    return _MirrorGatewayRequest(
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (encodedPayload?.isGzip ?? false) 'Content-Encoding': 'gzip',
        if (idempotencyKey != null) 'x-idempotency-key': idempotencyKey,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body,
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

    final compileEndpoint = resolveCompileEndpoint(httpEndpoint: explicitCompile);
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
  unauthorized('unauthorized'),
  rateLimited('rate_limited'),
  badRequest('bad_request'),
  server('server_error');

  const _MirrorGatewayHttpErrorCode(this.value);

  final String value;
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

String? _resolveIdempotencyKey(Map<String, dynamic> metadata) {
  final fromCanonical = metadata['idempotencyKey']?.toString().trim();
  if (fromCanonical != null && fromCanonical.isNotEmpty) {
    return fromCanonical;
  }

  final fromHeaderStyle = metadata['x-idempotency-key']?.toString().trim();
  if (fromHeaderStyle != null && fromHeaderStyle.isNotEmpty) {
    return fromHeaderStyle;
  }

  return null;
}


