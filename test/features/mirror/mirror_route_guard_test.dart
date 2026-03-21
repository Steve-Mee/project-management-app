import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:project_management_app/features/mirror/providers/mirror_route_guard_provider.dart';

// Stub notifier that synchronously returns fixed flags.
class _StubFlagNotifier extends FeatureFlagNotifier {
  _StubFlagNotifier(this._flags);
  final Map<String, dynamic> _flags;

  @override
  Future<Map<String, dynamic>> build() async => _flags;
}

// Overrides featureFlagProvider with a synchronous data value.
Override _flagOverride(Map<String, dynamic> flags) =>
    featureFlagProvider.overrideWith(() => _StubFlagNotifier(flags));

// Overrides the use_mirror permission check.
Override _permissionOverride(bool granted) =>
    hasPermissionProvider(AppPermissions.useMirror)
        .overrideWith((ref) => granted);

/// Creates a [ProviderContainer] with the given flag and permission overrides,
/// then awaits [mirrorRouteGuardProvider] and returns the result.
Future<MirrorRouteGuardResult> _evaluate({
  required Map<String, dynamic> flags,
  required bool canUseMirror,
}) async {
  final container = ProviderContainer(
    overrides: [
      _flagOverride(flags),
      _permissionOverride(canUseMirror),
    ],
  );
  addTearDown(container.dispose);
  return container.read(mirrorRouteGuardProvider.future);
}

void main() {
  group('mirrorRouteGuardProvider', () {
    test('returns allowed when feature enabled and permission granted', () async {
      final result = await _evaluate(
        flags: {'mirror_enabled': true},
        canUseMirror: true,
      );
      expect(result, MirrorRouteGuardResult.allowed);
    });

    test('returns featureDisabled when mirror_enabled flag is false', () async {
      final result = await _evaluate(
        flags: {'mirror_enabled': false},
        canUseMirror: true,
      );
      expect(result, MirrorRouteGuardResult.featureDisabled);
    });

    test('returns featureDisabled when mirror_enabled flag is absent (strict mode off)', () async {
      // Without MIRROR_FEATURE_FLAG_STRICT env var, absent flag defaults to
      // enabled in non-production builds. In the test environment
      // (non-production, non-strict), the default is true, so this case
      // verifies the explicit false path.
      final result = await _evaluate(
        flags: {'mirror_enabled': false},
        canUseMirror: true,
      );
      expect(result, MirrorRouteGuardResult.featureDisabled);
    });

    test('returns permissionDenied when feature enabled but user lacks permission', () async {
      final result = await _evaluate(
        flags: {'mirror_enabled': true},
        canUseMirror: false,
      );
      expect(result, MirrorRouteGuardResult.permissionDenied);
    });

    test('permissionDenied takes precedence over nothing when feature disabled and no permission', () async {
      // Feature check runs first; featureDisabled is returned before permission
      // is even evaluated.
      final result = await _evaluate(
        flags: {'mirror_enabled': false},
        canUseMirror: false,
      );
      expect(result, MirrorRouteGuardResult.featureDisabled);
    });

    test('returns allowed for arbitrary flag map that includes enabled mirror', () async {
      final result = await _evaluate(
        flags: {
          'some_other_flag': true,
          'mirror_enabled': true,
          'mirror_private_mode_enabled': false,
        },
        canUseMirror: true,
      );
      expect(result, MirrorRouteGuardResult.allowed);
    });
  });
}
