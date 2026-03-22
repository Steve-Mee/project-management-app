library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ab_testing_service.dart';
import 'mirror_feature_flag_provider.dart';
import 'mirror_offline_cache_provider.dart';
import 'mirror_premium_provider.dart';
import 'mirror_state_resolver.dart';
import 'supabase_client_provider.dart';

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

final currentMirrorUserIdProvider = Provider<String>((ref) {
  try {
    return ref.read(supabaseClientProvider).auth.currentUser?.id ?? 'anonymous';
  } catch (_) {
    return 'anonymous';
  }
});

final mirrorPremiumSnapshotProvider = FutureProvider<bool>((ref) async {
  return ref.read(mirrorPremiumProvider.future);
});

final mirrorFeatureGateSnapshotProvider =
    FutureProvider<MirrorFeatureGateSnapshot>((ref) async {
  return MirrorFeatureGateSnapshot(
    mirrorEnabled: await resolveMirrorFeatureEnabled(ref),
    allowPrivateMode: await resolveMirrorPrivateModeEnabled(ref),
    allowCloudMode: await resolveMirrorCloudModeEnabled(ref),
    allowAdminBypass: await resolveMirrorAdminBypassEnabled(ref),
  );
});

final mirrorTeamModeVariantSnapshotProvider =
    FutureProvider<MirrorVariantSnapshot>((ref) async {
  final userId = _resolveCurrentMirrorUserId(ref);

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_team_mode',
      userId: userId,
      variants: const <String>['solo', 'team'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    return MirrorVariantSnapshot(
      value: variant,
      source: MirrorValueSource.remote,
    );
  } catch (_) {
    final cached = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      return MirrorVariantSnapshot(
        value: cached,
        source: MirrorValueSource.cache,
        warningKey: MirrorOfflineWarningKeys.teamVariantLoadedFromCache,
      );
    }

    return const MirrorVariantSnapshot(
      value: 'solo',
      source: MirrorValueSource.fallback,
      warningKey: MirrorOfflineWarningKeys.teamVariantFallbackSolo,
    );
  }
});

final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final snapshot = await ref.watch(mirrorTeamModeVariantSnapshotProvider.future);
  return snapshot.value;
});

final mirrorRunnerModeVariantSnapshotProvider =
    FutureProvider<MirrorVariantSnapshot>((ref) async {
  final userId = _resolveCurrentMirrorUserId(ref);

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_runner_mode',
      userId: userId,
      variants: const <String>['local', 'cloud'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveRunnerModeVariant(userId, variant);
    return MirrorVariantSnapshot(
      value: variant,
      source: MirrorValueSource.remote,
    );
  } catch (_) {
    final cached = await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cached != null) {
      return MirrorVariantSnapshot(
        value: cached,
        source: MirrorValueSource.cache,
        warningKey: MirrorOfflineWarningKeys.runnerVariantLoadedFromCache,
      );
    }

    return const MirrorVariantSnapshot(
      value: 'cloud',
      source: MirrorValueSource.fallback,
      warningKey: MirrorOfflineWarningKeys.runnerVariantFallbackCloud,
    );
  }
});

final mirrorRunnerModeVariantProvider = FutureProvider<String>((ref) async {
  final snapshot = await ref.watch(mirrorRunnerModeVariantSnapshotProvider.future);
  return snapshot.value;
});

String _resolveCurrentMirrorUserId(Ref ref) {
  return ref.read(currentMirrorUserIdProvider);
}
