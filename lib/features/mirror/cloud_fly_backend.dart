import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/services/mirror_premium_service.dart';

import 'edge_function_backend.dart';
import 'mirror_compute_backend.dart';

class CloudFlyBackend implements MirrorComputeBackend {
  CloudFlyBackend({
    required MirrorPremiumService premiumService,
    this.accessTokenProvider,
    this.httpEndpoint,
    this.timeout = const Duration(seconds: 45),
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 350),
  }) : _premiumService = premiumService;

  final MirrorPremiumService _premiumService;
  final String? Function()? accessTokenProvider;
  final String? httpEndpoint;
  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff;

  String? get _accessToken {
    final token = accessTokenProvider?.call();
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  bool get supportsApply {
    try {
      EdgeFunctionBackend.resolveApplyEndpoint(
        compileHttpEndpoint: httpEndpoint,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final compileResult = await compile(
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
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      return const CompileResult(
        success: false,
        errors: <String>['Cloud compile is available for premium users only.'],
      );
    }

    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': context.projectId,
      'taskId': context.taskId,
      'mode': mode,
      'files': context.files,
      'metadata': context.metadata,
    };

    return _compileViaHttp(payload, _accessToken);
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      return const ApplyResult(
        success: false,
        message: 'Cloud apply is available for premium users only.',
      );
    }

    return secureApply(
      prompt: prompt,
      context: context,
      mode: mode,
      onApply: (ApplySecurityArtifacts artifacts) async {
        late final String endpoint;
        try {
          endpoint = _requireApplyEndpoint();
        } on UnsupportedError catch (error) {
          return ApplyResult(success: false, message: error.message);
        } on StateError catch (error) {
          return ApplyResult(success: false, message: 'config_error: ${error.message}');
        }

        final payload = <String, dynamic>{
          'prompt': prompt,
          'projectId': context.projectId,
          'taskId': context.taskId,
          'mode': mode,
          'files': context.files,
          'metadata': context.metadata,
          'backupId': artifacts.backupId,
          'signedInputUrls': artifacts.signedInputUrls,
        };

        final raw = await _postRawWithRetries(
          endpoint: endpoint,
          payload: payload,
          accessToken: _accessToken,
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
          backend: 'cloud_fly',
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

  Future<CompileResult> _compileViaHttp(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final endpoint = _requireCompileEndpoint();
    final uri = Uri.parse(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    var backoff = initialBackoff;
    var attempt = 0;

    while (true) {
      attempt += 1;
      try {
        final response = await http
            .post(
              uri,
              headers: headers,
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

        final errorCode = response.statusCode == 401 || response.statusCode == 403
            ? _MirrorHttpErrorCode.unauthorized
            : response.statusCode == 429
                ? _MirrorHttpErrorCode.rateLimited
                : response.statusCode >= 500
                    ? _MirrorHttpErrorCode.server
                    : _MirrorHttpErrorCode.badRequest;

        return CompileResult(
          success: false,
          errors: <String>[
            '${errorCode.value}: HTTP ${response.statusCode}',
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
          errors: <String>['timeout: Fly HTTP /compile request timed out.'],
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

  String _requireApplyEndpoint() {
    if (!supportsApply) {
      throw UnsupportedError(
        'contract_error: CloudFlyBackend does not support apply because no valid apply endpoint can be resolved.',
      );
    }

    return EdgeFunctionBackend.resolveApplyEndpoint(
      compileHttpEndpoint: httpEndpoint,
    );
  }

  String _requireCompileEndpoint() {
    return EdgeFunctionBackend.resolveCompileEndpoint(
      httpEndpoint: httpEndpoint,
    );
  }

  Future<_RawHttpResult> _postRawWithRetries({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String? accessToken,
  }) async {
    final uri = Uri.parse(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    var backoff = initialBackoff;
    var attempt = 0;

    while (true) {
      attempt += 1;
      try {
        final response = await http
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(timeout);

        final bodyText = response.body;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _RawHttpResult(success: true, body: bodyText);
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
            ? _MirrorHttpErrorCode.unauthorized
            : response.statusCode == 429
                ? _MirrorHttpErrorCode.rateLimited
                : response.statusCode >= 500
                    ? _MirrorHttpErrorCode.server
                    : _MirrorHttpErrorCode.badRequest;

        return _RawHttpResult(
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
        return const _RawHttpResult(
          success: false,
          errors: <String>['timeout: Fly HTTP /apply request timed out.'],
        );
      } catch (error) {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }
        return _RawHttpResult(
          success: false,
          errors: <String>['network: ${error.toString()}'],
        );
      }
    }
  }

}

enum _MirrorHttpErrorCode {
  unauthorized('unauthorized'),
  rateLimited('rate_limited'),
  badRequest('bad_request'),
  server('server_error');

  const _MirrorHttpErrorCode(this.value);

  final String value;
}

class _RawHttpResult {
  const _RawHttpResult({
    required this.success,
    this.body,
    this.errors = const <String>[],
  });

  final bool success;
  final String? body;
  final List<String> errors;
}
