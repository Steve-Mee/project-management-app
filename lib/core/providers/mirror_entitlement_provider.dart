library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/services/mirror_access_policy.dart';

import '../../features/mirror/mirror_signed_inputs_backend.dart';
import '../../features/mirror/mirror_gateway_backend.dart';
import '../../features/mirror/private_grpc_backend.dart';
import '../../features/mirror/services/mirror_context_budget_service.dart';
import 'mirror_feature_flag_provider.dart';
import 'mirror_provider.dart';
import 'mirror_session_provider.dart';
import 'supabase_client_provider.dart';

final mirrorContextBudgetServiceProvider =
    Provider<MirrorContextBudgetService>((ref) {
  return const MirrorContextBudgetService();
});

final mirrorGatewayBackendProvider = Provider<MirrorGatewayBackend>((ref) {
  final budgetService = ref.read(mirrorContextBudgetServiceProvider);
  return MirrorGatewayBackend(
    client: ref.read(supabaseClientProvider),
    budgetService: budgetService,
    onCompileValidated: ({
      required String projectId,
      required String taskId,
      required String compileFingerprint,
      String? serverVersionToken,
    }) {
      final normalizedProjectId = projectId.trim();
      final normalizedTaskId = taskId.trim();
      if (normalizedProjectId.isEmpty || normalizedTaskId.isEmpty) {
        return;
      }

      final sessionKey = '$normalizedProjectId::$normalizedTaskId';
      ref
          .read(mirrorSessionProvider(sessionKey).notifier)
          .setCompileValidationArtifacts(
            compileFingerprint: compileFingerprint,
            serverVersionToken: serverVersionToken,
          );
    },
  );
});

final mirrorBackendProvider = FutureProvider<MirrorComputeBackend>((ref) async {
  final isMirrorEnabled =
      await resolveMirrorFeatureEnabled(ref, useWatch: true);
  if (!isMirrorEnabled) {
    return const _MirrorDisabledBackend();
  }

  final mode = ref.watch(mirrorModeProvider);
  final isPremium = await ref.watch(mirrorPremiumProvider.future);
  final runnerModeVariant =
      await ref.watch(mirrorRunnerModeVariantProvider.future);
  final canUsePrivateMode = await resolveMirrorPrivateModeEnabled(
    ref,
    useWatch: true,
  );
  final canUseCloudMode = await resolveMirrorCloudModeEnabled(
    ref,
    useWatch: true,
  );
  final allowAdminBypass = await resolveMirrorAdminBypassEnabled(
    ref,
    useWatch: true,
  );
  const policy = MirrorAccessPolicy();
  final decision = policy.resolveRequestedMode(
    requestedMode: mode,
    isPremium: isPremium,
    runnerModeVariant: runnerModeVariant,
    allowPrivateMode: canUsePrivateMode,
    allowCloudMode: canUseCloudMode,
    allowAdminBypass: allowAdminBypass,
  );

  if (decision.effectiveMode == 'cloud') {
    return ref.watch(mirrorGatewayBackendProvider);
  }

  return PrivateGrpcBackend(client: ref.read(supabaseClientProvider));
});

class _MirrorDisabledBackend implements MirrorComputeBackend {
  const _MirrorDisabledBackend();

  static const String _message =
      'Mirror is disabled by feature flag: mirror_enabled';

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: _message,
      diagnostics: <String>[_message],
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: false,
      errors: <String>[_message],
    );
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    return const ApplyResult(
      success: false,
      message: _message,
    );
  }
}
