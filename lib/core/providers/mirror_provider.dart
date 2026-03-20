// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/services/mirror_access_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ab_testing_service.dart';
import 'mirror_entitlement_provider.dart';
import 'mirror_feature_flag_provider.dart';
import 'mirror_offline_cache_provider.dart';
import '../../features/mirror/mirror_compute_backend.dart';
import '../../features/mirror/mirror_gateway_backend.dart';
import '../../features/mirror/private_grpc_backend.dart';
import '../../features/mirror/services/mirror_context_budget_service.dart';

export '../../features/mirror/mirror_compute_backend.dart';
export '../../features/mirror/mirror_gateway_backend.dart';
export '../../features/mirror/private_grpc_backend.dart';
export '../../features/mirror/services/mirror_context_budget_service.dart';
export 'mirror_entitlement_provider.dart';
export 'mirror_feature_flag_provider.dart';
export 'mirror_offline_cache_provider.dart';

class MirrorOfflineWarningKeys {
  const MirrorOfflineWarningKeys._();

  static const String teamVariantLoadedFromCache =
    'mirrorOfflineTeamVariantLoadedFromCacheWarning';
  static const String teamVariantFallbackSolo =
    'mirrorOfflineTeamVariantFallbackSoloWarning';
  static const String runnerVariantLoadedFromCache =
    'mirrorOfflineRunnerVariantLoadedFromCacheWarning';
  static const String runnerVariantFallbackCloud =
    'mirrorOfflineRunnerVariantFallbackCloudWarning';
  static const String cloudModeRequiresPremium =
    'mirrorCloudModeRequiresPremiumWarning';
}

class MirrorState {
  const MirrorState({
    required this.mode,
    required this.isPremium,
    required this.teamModeVariant,
    this.runnerModeVariant = 'cloud',
    required this.offlineWarning,
  });

  final String mode;
  final bool isPremium;
  final String teamModeVariant;
  final String runnerModeVariant;
  final String? offlineWarning;

  bool get isTeamMode => teamModeVariant == 'team';
  bool get hasOfflineWarning =>
      offlineWarning != null && offlineWarning!.isNotEmpty;

  MirrorState copyWith({
    String? mode,
    bool? isPremium,
    String? teamModeVariant,
    String? runnerModeVariant,
    String? offlineWarning,
    bool clearOfflineWarning = false,
  }) {
    return MirrorState(
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
      teamModeVariant: teamModeVariant ?? this.teamModeVariant,
      runnerModeVariant: runnerModeVariant ?? this.runnerModeVariant,
      offlineWarning:
          clearOfflineWarning ? null : (offlineWarning ?? this.offlineWarning),
    );
  }
}

final mirrorModeProvider = StateProvider<String>((ref) => 'private');

final mirrorOfflineWarningProvider = StateProvider<String?>((ref) => null);

final mirrorContextBudgetServiceProvider =
    Provider<MirrorContextBudgetService>((ref) {
  return const MirrorContextBudgetService();
});


final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  final user = _currentSupabaseUserOrNull();
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_team_mode',
      userId: userId,
      variants: const <String>['solo', 'team'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      warningNotifier.state = MirrorOfflineWarningKeys.teamVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.teamVariantFallbackSolo;
    return 'solo';
  }
});

final mirrorRunnerModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  final user = _currentSupabaseUserOrNull();
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_runner_mode',
      userId: userId,
      variants: const <String>['local', 'cloud'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveRunnerModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cached != null) {
      warningNotifier.state =
          MirrorOfflineWarningKeys.runnerVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.runnerVariantFallbackCloud;
    return 'cloud';
  }
});

final mirrorGatewayBackendProvider = Provider<MirrorGatewayBackend>((ref) {
  final budgetService = ref.read(mirrorContextBudgetServiceProvider);
  return MirrorGatewayBackend(
    client: Supabase.instance.client,
    budgetService: budgetService,
  );
});

final mirrorBackendProvider = FutureProvider<MirrorComputeBackend>((ref) async {
  final isMirrorEnabled = await resolveMirrorFeatureEnabled(ref, useWatch: true);
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

  return PrivateGrpcBackend();
});

class MirrorNotifier extends Notifier<MirrorState> {
  bool _cacheHydrated = false;

  @override
  MirrorState build() {
    if (!_cacheHydrated) {
      _cacheHydrated = true;
      unawaited(_hydrateFromCache());
    }

    final mode = ref.watch(mirrorModeProvider);
    final isPremium = ref.watch(mirrorPremiumProvider).valueOrNull ?? false;
    final teamModeVariant =
        ref.watch(mirrorTeamModeVariantProvider).valueOrNull ?? 'solo';
    final runnerModeVariant =
        ref.watch(mirrorRunnerModeVariantProvider).valueOrNull ?? 'cloud';
    final offlineWarning = ref.watch(mirrorOfflineWarningProvider);
    return MirrorState(
      mode: mode,
      isPremium: isPremium,
      teamModeVariant: teamModeVariant,
      runnerModeVariant: runnerModeVariant,
      offlineWarning: offlineWarning,
    );
  }

  Future<void> setMode(String mode) async {
    final isMirrorEnabled = await resolveMirrorFeatureEnabled(ref);
    if (!isMirrorEnabled) {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      ref.read(mirrorOfflineWarningProvider.notifier).state = null;
      state = state.copyWith(
        mode: 'private',
        offlineWarning: null,
      );
      unawaited(MirrorOfflineCache.saveMode('private'));
      return;
    }

    final hasPremium = await ref.read(mirrorPremiumProvider.future);
    final runnerModeVariant =
        await ref.read(mirrorRunnerModeVariantProvider.future);
    final canUsePrivateMode = await resolveMirrorPrivateModeEnabled(ref);
    final canUseCloudMode = await resolveMirrorCloudModeEnabled(ref);
    final allowAdminBypass = await resolveMirrorAdminBypassEnabled(ref);
    const policy = MirrorAccessPolicy();
    final decision = policy.resolveRequestedMode(
      requestedMode: mode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
      allowPrivateMode: canUsePrivateMode,
      allowCloudMode: canUseCloudMode,
      allowAdminBypass: allowAdminBypass,
    );

    ref.read(mirrorModeProvider.notifier).state = decision.effectiveMode;
    ref.read(mirrorOfflineWarningProvider.notifier).state = decision.warning;
    state = state.copyWith(
      mode: decision.effectiveMode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
      offlineWarning: decision.warning,
    );
    unawaited(MirrorOfflineCache.saveMode(decision.effectiveMode));
  }

  Future<void> refreshPremiumFromMetadata() async {
    final previousPremium = state.isPremium;
    ref.invalidate(mirrorPremiumProvider);
    final isPremium = await ref.read(mirrorPremiumProvider.future);
    state = state.copyWith(isPremium: isPremium);

    await MirrorOfflineCache.invalidateOnPremiumChange(
      previousPremium: previousPremium,
      currentPremium: isPremium,
    );

    if (!isPremium && state.mode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      state = state.copyWith(
        mode: 'private',
        offlineWarning: MirrorOfflineWarningKeys.cloudModeRequiresPremium,
      );
      unawaited(MirrorOfflineCache.saveMode('private'));
    }
  }

  Future<void> refreshTeamModeVariant() async {
    ref.invalidate(mirrorTeamModeVariantProvider);
    final teamModeVariant =
        await ref.read(mirrorTeamModeVariantProvider.future);
    state = state.copyWith(teamModeVariant: teamModeVariant);
  }

  Future<void> refreshRunnerModeVariant() async {
    ref.invalidate(mirrorRunnerModeVariantProvider);
    final runnerModeVariant =
        await ref.read(mirrorRunnerModeVariantProvider.future);
    state = state.copyWith(runnerModeVariant: runnerModeVariant);
  }

  void clearOfflineWarning() {
    ref.read(mirrorOfflineWarningProvider.notifier).state = null;
    state = state.copyWith(clearOfflineWarning: true);
  }

  Future<void> _hydrateFromCache() async {
    final user = _currentSupabaseUserOrNull();
    final userId = user?.id ?? 'anonymous';

    await MirrorOfflineCache.invalidateOnAuthChange(currentUserId: userId);

    final cachedMode = await MirrorOfflineCache.getMode();
    if (cachedMode == 'private' || cachedMode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = cachedMode!;
    }

    final cachedVariant = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cachedVariant != null) {
      state = state.copyWith(teamModeVariant: cachedVariant);
    }

    final cachedRunnerVariant =
      await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cachedRunnerVariant != null) {
      state = state.copyWith(runnerModeVariant: cachedRunnerVariant);
    }

    await refreshPremiumFromMetadata();
  }
}

User? _currentSupabaseUserOrNull() {
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
}

final mirrorProvider =
    NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

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
