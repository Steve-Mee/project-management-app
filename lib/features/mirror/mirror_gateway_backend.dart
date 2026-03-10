// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'mirror_compute_backend.dart';

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
  })  : _client = _resolveClient(client),
        _httpClient = httpClient ?? http.Client();

  final SupabaseClient? _client;
  final http.Client _httpClient;
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
      return ApplyResult(
        success: false,
        message: 'config_error: ${error.toString()}',
      );
    }

    final normalizedCompileFingerprint = compileFingerprint?.trim() ?? '';
    if (normalizedCompileFingerprint.isEmpty) {
      return const ApplyResult(
        success: false,
        message:
            'Apply blocked: preview fingerprint missing. Re-run preview before applying.',
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

    final patches = buildPatchesFromApplyPayload(
      context: context,
      output: raw.body!,
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
    final token = _client?.auth.currentSession?.accessToken;
    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': context.projectId,
      'taskId': context.taskId,
      'mode': mode,
      'files': context.files,
      'metadata': context.metadata,
    };

    var attempt = 0;
    var backoff = initialBackoff;

    while (true) {
      attempt += 1;
      try {
        final response = await _httpClient
            .post(
              Uri.parse(endpoint),
              headers: <String, String>{
                'Content-Type': 'application/json',
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
            .timeout(timeout);

        final bodyText = response.body;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _compileResultFromRaw(bodyText);
        }

        final retriable = response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;

        if (retriable && attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        final code = response.statusCode == 401 || response.statusCode == 403
          ? _MirrorGatewayHttpErrorCode.unauthorized
          : response.statusCode == 429
            ? _MirrorGatewayHttpErrorCode.rateLimited
            : response.statusCode >= 500
              ? _MirrorGatewayHttpErrorCode.server
              : _MirrorGatewayHttpErrorCode.badRequest;

        return CompileResult(
          success: false,
          errors: <String>[
            '${code.value}: HTTP ${response.statusCode}',
            if (bodyText.trim().isNotEmpty) bodyText,
          ],
        );
      } on TimeoutException {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        return const CompileResult(
          success: false,
          errors: <String>['timeout: Mirror Gateway HTTP /compile request timed out.'],
        );
      } catch (error) {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        return CompileResult(
          success: false,
          errors: <String>['network: ${error.toString()}'],
        );
      }
    }
  }

  Future<_RawGatewayResult> _postRaw({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final token = _client?.auth.currentSession?.accessToken;
    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': context.projectId,
      'taskId': context.taskId,
      'mode': mode,
      'files': context.files,
      'metadata': context.metadata,
      ...extra,
    };

    var attempt = 0;
    var backoff = initialBackoff;

    while (true) {
      attempt += 1;
      try {
        final response = await _httpClient
            .post(
              Uri.parse(endpoint),
              headers: <String, String>{
                'Content-Type': 'application/json',
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
            .timeout(timeout);

        final bodyText = response.body;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _RawGatewayResult(success: true, body: bodyText);
        }

        final retriable = response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;
        if (retriable && attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        final code = response.statusCode == 401 || response.statusCode == 403
          ? _MirrorGatewayHttpErrorCode.unauthorized
          : response.statusCode == 429
            ? _MirrorGatewayHttpErrorCode.rateLimited
            : response.statusCode >= 500
              ? _MirrorGatewayHttpErrorCode.server
              : _MirrorGatewayHttpErrorCode.badRequest;

        return _RawGatewayResult(
          success: false,
          errors: <String>[
            '${code.value}: HTTP ${response.statusCode}',
            if (bodyText.trim().isNotEmpty) bodyText,
          ],
        );
      } on TimeoutException {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }
        return const _RawGatewayResult(
          success: false,
          errors: <String>['timeout: Mirror Gateway HTTP /apply request timed out.'],
        );
      } catch (error) {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }
        return _RawGatewayResult(
          success: false,
          errors: <String>['network: ${error.toString()}'],
        );
      }
    }
  }

  CompileResult _compileResultFromRaw(String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = <String, dynamic>{'success': true, 'output': raw};
    }

    if (decoded is Map<String, dynamic>) {
      final errorsRaw = decoded['errors'];
      final warningsRaw = decoded['warnings'];

      return CompileResult(
        success: (decoded['success'] as bool?) ?? true,
        output: decoded['output']?.toString(),
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


