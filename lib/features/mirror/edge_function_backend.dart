import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'mirror_compute_backend.dart';

class EdgeFunctionBackend implements MirrorComputeBackend {
  EdgeFunctionBackend({
    SupabaseClient? client,
    this.httpEndpoint,
    this.applyHttpEndpoint,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 300),
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String? httpEndpoint;
  final String? applyHttpEndpoint;
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
      final endpoint = httpEndpoint ?? _defaultCompileEndpoint();
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
      final endpoint = httpEndpoint ?? _defaultCompileEndpoint();
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
  }) async {
    final endpoint =
        applyHttpEndpoint ?? httpEndpoint ?? _safeDefaultApplyEndpoint();
    if (endpoint == null) {
      return const ApplyResult(
        success: false,
        message:
            'config_error: Missing Supabase edge endpoint configuration for apply.',
      );
    }

    return secureApply(
      prompt: prompt,
      context: context,
      mode: mode,
      onApply: (ApplySecurityArtifacts artifacts) async {
        final raw = await _postRaw(
          endpoint: endpoint,
          prompt: prompt,
          context: context,
          mode: mode,
          extra: <String, dynamic>{
            'backupId': artifacts.backupId,
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
          backend: 'edge_function',
          updatedFiles: updatedFiles,
        );

        return ApplyResult(
          success: true,
          appliedFiles: patches.map((patch) => patch.path).toSet().toList(),
          message:
              'Applied ${patches.length} patch(es) with backup ${artifacts.backupId}.',
        );
      },
    );
  }

  String? _safeDefaultApplyEndpoint() {
    try {
      return _defaultApplyEndpoint();
    } catch (_) {
      return null;
    }
  }

  Future<CompileResult> _postCompile({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
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
        final response = await http
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

        final retriable =
            response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;

        if (retriable && attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        final code = response.statusCode == 401 || response.statusCode == 403
            ? _MirrorEdgeHttpErrorCode.unauthorized
            : response.statusCode == 429
                ? _MirrorEdgeHttpErrorCode.rateLimited
                : response.statusCode >= 500
                    ? _MirrorEdgeHttpErrorCode.server
                    : _MirrorEdgeHttpErrorCode.badRequest;

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
          errors: <String>['timeout: Edge HTTP /compile request timed out.'],
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

  Future<_RawEdgeResult> _postRaw({
    required String endpoint,
    required String prompt,
    required ProjectContext context,
    required String mode,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final token = _client.auth.currentSession?.accessToken;
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
        final response = await http
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
          return _RawEdgeResult(success: true, body: bodyText);
        }

        final retriable =
            response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;
        if (retriable && attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        final code = response.statusCode == 401 || response.statusCode == 403
            ? _MirrorEdgeHttpErrorCode.unauthorized
            : response.statusCode == 429
                ? _MirrorEdgeHttpErrorCode.rateLimited
                : response.statusCode >= 500
                    ? _MirrorEdgeHttpErrorCode.server
                    : _MirrorEdgeHttpErrorCode.badRequest;

        return _RawEdgeResult(
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
        return const _RawEdgeResult(
          success: false,
          errors: <String>['timeout: Edge HTTP /apply request timed out.'],
        );
      } catch (error) {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }
        return _RawEdgeResult(
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

  String _defaultCompileEndpoint() {
    final base = _requireSupabaseBaseUrl();
    return '$base/functions/v1/mirror_compute/compile';
  }

  String _defaultApplyEndpoint() {
    final base = _requireSupabaseBaseUrl();
    return '$base/functions/v1/mirror_compute/apply';
  }

  String _requireSupabaseBaseUrl() {
    final configured = AppConfig.supabaseUrl?.trim();
    if (configured == null || configured.isEmpty) {
      throw StateError(
        'supabase_url_missing: Set AppConfig.supabaseUrl or provide explicit EdgeFunctionBackend endpoints.',
      );
    }
    return configured;
  }
}

enum _MirrorEdgeHttpErrorCode {
  unauthorized('unauthorized'),
  rateLimited('rate_limited'),
  badRequest('bad_request'),
  server('server_error');

  const _MirrorEdgeHttpErrorCode(this.value);

  final String value;
}

class _RawEdgeResult {
  const _RawEdgeResult({
    required this.success,
    this.body,
    this.errors = const <String>[],
  });

  final bool success;
  final String? body;
  final List<String> errors;
}
