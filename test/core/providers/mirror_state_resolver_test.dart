import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_hydration_inputs_provider.dart';
import 'package:project_management_app/core/providers/mirror_state_resolver.dart';

void main() {
  group('resolveMirrorHydration', () {
    test('forces private mode when mirror feature is disabled', () {
      final resolved = resolveMirrorHydration(
        const MirrorHydrationSnapshot(
          requestedMode: 'cloud',
          cachedMode: 'cloud',
          isPremium: true,
          teamModeVariant: MirrorVariantSnapshot(
            value: 'team',
            source: MirrorValueSource.remote,
          ),
          runnerModeVariant: MirrorVariantSnapshot(
            value: 'cloud',
            source: MirrorValueSource.remote,
          ),
          featureGates: MirrorFeatureGateSnapshot(
            mirrorEnabled: false,
            allowPrivateMode: true,
            allowCloudMode: true,
            allowAdminBypass: false,
          ),
        ),
      );

      expect(resolved.mode, 'private');
      expect(resolved.offlineWarning, isNull);
      expect(resolved.teamModeVariant, 'team');
      expect(resolved.provenance.reasonCode, isNull);
    });

    test('uses cached requested mode when no explicit mode was requested', () {
      final resolved = resolveMirrorHydration(
        const MirrorHydrationSnapshot(
          requestedMode: null,
          cachedMode: 'cloud',
          isPremium: true,
          teamModeVariant: MirrorVariantSnapshot(
            value: 'solo',
            source: MirrorValueSource.remote,
          ),
          runnerModeVariant: MirrorVariantSnapshot(
            value: 'cloud',
            source: MirrorValueSource.remote,
          ),
          featureGates: MirrorFeatureGateSnapshot(
            mirrorEnabled: true,
            allowPrivateMode: true,
            allowCloudMode: true,
            allowAdminBypass: false,
          ),
        ),
      );

      expect(resolved.mode, 'cloud');
      expect(resolved.offlineWarning, isNull);
    });

    test('prefers policy warning over variant fallback warning', () {
      final resolved = resolveMirrorHydration(
        const MirrorHydrationSnapshot(
          requestedMode: 'cloud',
          cachedMode: 'private',
          isPremium: false,
          teamModeVariant: MirrorVariantSnapshot(
            value: 'solo',
            source: MirrorValueSource.fallback,
            warningKey: MirrorOfflineWarningKeys.teamVariantFallbackSolo,
          ),
          runnerModeVariant: MirrorVariantSnapshot(
            value: 'cloud',
            source: MirrorValueSource.cache,
            warningKey: MirrorOfflineWarningKeys.runnerVariantLoadedFromCache,
          ),
          featureGates: MirrorFeatureGateSnapshot(
            mirrorEnabled: true,
            allowPrivateMode: true,
            allowCloudMode: true,
            allowAdminBypass: false,
          ),
        ),
      );

      expect(resolved.mode, 'private');
      expect(
        resolved.offlineWarning,
        'Cloud mode requires an active Stripe premium subscription.',
      );
      expect(
        resolved.provenance.reasonCode,
        MirrorHydrationReasonCodes.policyWarning,
      );
    });

    test('surfaces runner fallback warning when policy permits mode', () {
      final resolved = resolveMirrorHydration(
        const MirrorHydrationSnapshot(
          requestedMode: 'private',
          cachedMode: 'private',
          isPremium: true,
          teamModeVariant: MirrorVariantSnapshot(
            value: 'solo',
            source: MirrorValueSource.remote,
          ),
          runnerModeVariant: MirrorVariantSnapshot(
            value: 'cloud',
            source: MirrorValueSource.fallback,
            warningKey: MirrorOfflineWarningKeys.runnerVariantFallbackCloud,
          ),
          featureGates: MirrorFeatureGateSnapshot(
            mirrorEnabled: true,
            allowPrivateMode: true,
            allowCloudMode: true,
            allowAdminBypass: false,
          ),
        ),
      );

      expect(resolved.mode, 'private');
      expect(
        resolved.offlineWarning,
        MirrorOfflineWarningKeys.runnerVariantFallbackCloud,
      );
      expect(
        resolved.provenance.reasonCode,
        MirrorHydrationReasonCodes.runnerVariantFallback,
      );
    });
  });
}
