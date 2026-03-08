import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mirror_compute_backend.dart';

typedef PremiumAccessResolver = FutureOr<bool> Function(User? user);

class CloudFlyBackend implements MirrorComputeBackend {
  CloudFlyBackend({
    SupabaseClient? client,
    this.httpEndpoint = 'https://mirror-compute.fly.dev/compile',
    this.timeout = const Duration(seconds: 45),
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 350),
    PremiumAccessResolver? premiumResolver,
  }) : _client = client ?? Supabase.instance.client,
       _premiumResolver = premiumResolver ?? _defaultPremiumResolver;

  final SupabaseClient _client;
  final String httpEndpoint;
  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff;
  final PremiumAccessResolver _premiumResolver;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: 'Generate is not implemented in CloudFlyBackend.',
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final user = _client.auth.currentUser;
    final hasPremium = await _premiumResolver(user);
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

    return _compileViaHttp(payload, _client.auth.currentSession?.accessToken);
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const ApplyResult(
      success: false,
      message: 'Apply is not implemented in CloudFlyBackend.',
    );
  }

  Future<CompileResult> _compileViaHttp(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final uri = Uri.parse(httpEndpoint);
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

  static bool _defaultPremiumResolver(User? user) {
    if (user == null) {
      return false;
    }

    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata;

    final planValue =
        appMetadata['plan'] ??
        appMetadata['subscription'] ??
        userMetadata?['plan'] ??
        userMetadata?['subscription'];

    final normalized = planValue?.toString().toLowerCase().trim() ?? '';
    return normalized == 'premium' || normalized == 'pro' || normalized == 'enterprise';
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
