import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mirror_compute_backend.dart';

class EdgeFunctionBackend implements MirrorComputeBackend {
  EdgeFunctionBackend({
    SupabaseClient? client,
    this.httpEndpoint,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 300),
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String? httpEndpoint;
  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final compileResult = await _postCompile(
      prompt: prompt,
      context: context,
      mode: mode,
    );

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
    return _postCompile(
      prompt: prompt,
      context: context,
      mode: mode,
    );
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const ApplyResult(
      success: false,
      message: 'Apply is not implemented in EdgeFunctionBackend.',
    );
  }

  Future<CompileResult> _postCompile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final endpoint = httpEndpoint ?? _defaultCompileEndpoint();
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
    final base = _client.supabaseUrl;
    return '$base/functions/v1/mirror_compute/compile';
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
