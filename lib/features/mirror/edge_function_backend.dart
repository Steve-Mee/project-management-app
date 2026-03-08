import 'package:supabase_flutter/supabase_flutter.dart';

import 'mirror_compute_backend.dart';

class EdgeFunctionBackend implements MirrorComputeBackend {
  EdgeFunctionBackend({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'mirror_compute',
        body: {
          'prompt': prompt,
          'projectId': context.projectId,
          'taskId': context.taskId,
          'mode': mode,
        },
      );

      final dynamic payload = response.data;
      if (payload is Map<String, dynamic>) {
        final diagnosticsRaw = payload['diagnostics'];
        final diagnostics = diagnosticsRaw is List
            ? diagnosticsRaw.map((e) => e.toString()).toList()
            : const <String>[];

        return GenerateResult(
          success: (payload['success'] as bool?) ?? true,
          code: payload['code']?.toString(),
          message: payload['message']?.toString(),
          diagnostics: diagnostics,
        );
      }

      if (payload is String) {
        return GenerateResult(success: true, code: payload);
      }

      return const GenerateResult(
        success: false,
        message: 'Unexpected response from mirror_compute',
      );
    } catch (error) {
      return GenerateResult(
        success: false,
        message: error.toString(),
      );
    }
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: false,
      errors: <String>['Compile is not implemented in EdgeFunctionBackend.'],
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
}
