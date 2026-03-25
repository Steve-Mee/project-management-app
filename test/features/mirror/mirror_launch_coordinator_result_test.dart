import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/providers.dart' as core_providers;
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/core/services/analytics_events.dart';
import 'package:pma_core/core/services/analytics_service.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:project_management_app/core/providers/mirror_hydration_inputs_provider.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';
import 'package:project_management_app/core/providers/mirror_premium_provider.dart';
import 'package:project_management_app/core/providers/mirror_state_resolver.dart';
import 'package:project_management_app/features/mirror/models/mirror_launch_result.dart';
import 'package:project_management_app/features/mirror/services/mirror_launch_coordinator.dart';

class _FakeAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    events.add(<String, dynamic>{
      'name': name,
      'parameters': parameters ?? <String, dynamic>{},
    });
  }
}

class _StubFlagNotifier extends FeatureFlagNotifier {
  _StubFlagNotifier(this._flags);

  final Map<String, dynamic> _flags;

  @override
  Future<Map<String, dynamic>> build() async => _flags;
}

class _StubMirrorModeController extends MirrorModeController {
  _StubMirrorModeController({
    required this.resolvedMode,
    this.teamModeVariant = 'solo',
  });

  final String resolvedMode;
  final String teamModeVariant;

  @override
  MirrorState build() {
    return MirrorState(
      mode: resolvedMode,
      isPremium: false,
      teamModeVariant: teamModeVariant,
      runnerModeVariant: 'cloud',
      offlineWarning: null,
      hydrationPhase: MirrorHydrationPhase.resolved,
    );
  }

  @override
  Future<void> setMode(String mode) async {
    state = state.copyWith(
      mode: resolvedMode,
      teamModeVariant: teamModeVariant,
      hydrationPhase: MirrorHydrationPhase.resolved,
    );
  }
}

Override _flagOverride(Map<String, dynamic> flags) =>
    featureFlagProvider.overrideWith(() => _StubFlagNotifier(flags));

Override _permissionOverride(bool granted) =>
    hasPermissionProvider(AppPermissions.useMirror)
        .overrideWith((ref) => granted);

Override _modeOverride({
  required String resolvedMode,
  String teamModeVariant = 'solo',
}) =>
    mirrorModeControllerProvider.overrideWith(
      () => _StubMirrorModeController(
        resolvedMode: resolvedMode,
        teamModeVariant: teamModeVariant,
      ),
    );

Future<MirrorLaunchResult> _openMirror({
  required Map<String, dynamic> flags,
  required bool canUseMirror,
  required String resolvedMode,
  String preferredMode = 'private',
  bool isPremium = true,
  String runnerModeVariant = 'cloud',
  _FakeAnalyticsService? analytics,
}) async {
  final analyticsService = analytics ?? _FakeAnalyticsService();
  final container = ProviderContainer(
    overrides: <Override>[
      _flagOverride(flags),
      _permissionOverride(canUseMirror),
      _modeOverride(resolvedMode: resolvedMode),
      mirrorPremiumProvider.overrideWith((ref) async => isPremium),
      mirrorRunnerModeVariantProvider.overrideWith(
        (ref) async => runnerModeVariant,
      ),
      core_providers.analyticsServiceProvider.overrideWithValue(
        analyticsService,
      ),
    ],
  );
  addTearDown(container.dispose);

  return container.read(mirrorLaunchCoordinatorProvider).openMirrorFromTask(
        projectId: '11111111-1111-4111-8111-111111111111',
        taskId: '22222222-2222-4222-8222-222222222222',
        preferredMode: preferredMode,
      );
}

void main() {
  group('MirrorLaunchCoordinator result contract', () {
    test('returns featureDisabled when feature flag is off', () async {
      final result = await _openMirror(
        flags: {'mirror_enabled': false},
        canUseMirror: true,
        resolvedMode: 'private',
      );

      expect(result.status, MirrorLaunchStatus.featureDisabled);
      expect(result.payload, isNull);
    });

    test('returns permissionDenied when permission is missing', () async {
      final result = await _openMirror(
        flags: {'mirror_enabled': true},
        canUseMirror: false,
        resolvedMode: 'private',
      );

      expect(result.status, MirrorLaunchStatus.permissionDenied);
      expect(result.payload, isNull);
    });

    test('returns launched when requested and resolved mode match', () async {
      final result = await _openMirror(
        flags: {'mirror_enabled': true},
        canUseMirror: true,
        resolvedMode: 'private',
      );

      expect(result.status, MirrorLaunchStatus.launched);
      expect(result.payload, isNotNull);
      expect(result.payload!.mode, 'private');
    });

    test('returns launchedWithDowngrade when requested cloud resolves private', () async {
      final result = await _openMirror(
        flags: {'mirror_enabled': true},
        canUseMirror: true,
        resolvedMode: 'private',
        preferredMode: 'cloud',
      );

      expect(result.status, MirrorLaunchStatus.launchedWithDowngrade);
      expect(result.payload, isNotNull);
      expect(result.requestedMode, 'cloud');
      expect(result.resolvedMode, 'private');
    });

    test('returns entitlementDenied when cloud mode requires premium', () async {
      final result = await _openMirror(
        flags: {'mirror_enabled': true, 'mirror_cloud_mode_enabled': true},
        canUseMirror: true,
        resolvedMode: 'private',
        preferredMode: 'cloud',
        isPremium: false,
        runnerModeVariant: 'cloud',
      );

      expect(result.status, MirrorLaunchStatus.entitlementDenied);
      expect(result.payload, isNull);
    });

    test('records canonical launch analytics event with status payload', () async {
      final analytics = _FakeAnalyticsService();

      final result = await _openMirror(
        flags: {'mirror_enabled': true},
        canUseMirror: true,
        resolvedMode: 'private',
        preferredMode: 'private',
        analytics: analytics,
      );

      expect(result.status, MirrorLaunchStatus.launched);
      expect(analytics.events, isNotEmpty);
      final event = analytics.events.single;
      expect(event['name'], AnalyticsEventName.mirrorLaunchResolved);
      final params = event['parameters'] as Map<String, dynamic>;
      expect(params['status'], MirrorLaunchStatus.launched.name);
      expect(params['requested_mode'], 'private');
      expect(params['is_success'], true);
    });
  });
}
