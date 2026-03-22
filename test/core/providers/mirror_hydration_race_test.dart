import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/core/providers/mirror_state_resolver.dart';
import 'package:project_management_app/features/mirror/services/mirror_draft_cache_service.dart';

class _NoopDraftCacheService extends MirrorDraftCacheService {
  const _NoopDraftCacheService();

  @override
  Future<MirrorDraftCacheSnapshot?> readDraft(String sessionKey) async => null;

  @override
  Future<void> writeDraft({
    required String sessionKey,
    required Map<String, String> files,
    required String selectedFile,
    metadata,
    String? mode,
    String? offlineWarningKey,
    String? contextFingerprint,
    int? contextVersion,
  }) async {}
}

Completer<T> _completed<T>(T value) {
  final completer = Completer<T>();
  completer.complete(value);
  return completer;
}

class _QueuedAsync<T> {
  _QueuedAsync(this._values);

  final ListQueue<Completer<T>> _values;
  int _index = 0;

  Future<T> next() {
    if (_values.isEmpty) {
      throw StateError('No async values configured.');
    }
    final effectiveIndex = _index >= _values.length ? _values.length - 1 : _index;
    _index += 1;
    return _values.elementAt(effectiveIndex).future;
  }
}

Future<void> _waitUntil(bool Function() predicate) async {
  final started = DateTime.now();
  while (!predicate()) {
    if (DateTime.now().difference(started) > const Duration(seconds: 2)) {
      throw TimeoutException('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('mirror_hydration_race_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('mirror_offline_cache')) {
      final box = Hive.box<dynamic>('mirror_offline_cache');
      await box.clear();
      await box.close();
    }
    await Hive.deleteBoxFromDisk('mirror_offline_cache');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('Mirror hydration race handling', () {
    test('auth switch ignores stale team-variant completion', () async {
      final userIdProvider = StateProvider<String>((ref) => 'user-a');
      final initialTeam = _completed(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      final staleTeam = Completer<MirrorVariantSnapshot>();
      final currentTeam = Completer<MirrorVariantSnapshot>();
      final teamResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([
          initialTeam,
          staleTeam,
          currentTeam,
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          currentMirrorUserIdProvider.overrideWith(
            (ref) => ref.watch(userIdProvider),
          ),
          mirrorFeatureGateSnapshotProvider.overrideWith(
            (ref) async => const MirrorFeatureGateSnapshot(
              mirrorEnabled: true,
              allowPrivateMode: true,
              allowCloudMode: true,
              allowAdminBypass: false,
            ),
          ),
          mirrorPremiumSnapshotProvider.overrideWith((ref) async => true),
          mirrorTeamModeVariantSnapshotProvider.overrideWith(
            (ref) => teamResponses.next(),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'cloud',
              source: MirrorValueSource.remote,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () =>
            container.read(mirrorProvider).hydrationPhase !=
            MirrorHydrationPhase.hydrating,
      );
      expect(container.read(mirrorProvider).teamModeVariant, 'solo');

      final staleRefresh =
          container.read(mirrorProvider.notifier).refreshTeamModeVariant();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      container.read(userIdProvider.notifier).state = 'user-b';
        final currentRefresh =
          container.read(mirrorProvider.notifier).refreshTeamModeVariant();

      staleTeam.complete(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      currentTeam.complete(const MirrorVariantSnapshot(
        value: 'team',
        source: MirrorValueSource.remote,
      ));
      await Future.wait([staleRefresh, currentRefresh]);

      await _waitUntil(() => container.read(mirrorProvider).teamModeVariant == 'team');
      expect(container.read(mirrorProvider).teamModeVariant, 'team');
    });

    test('session bootstrap completions stay isolated per session key', () async {
      final repoA = Completer<MirrorSessionBootstrapRepository?>();
      final repoB = Completer<MirrorSessionBootstrapRepository?>();

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          mirrorModeProvider.overrideWith((ref) => 'private'),
          mirrorOfflineWarningProvider.overrideWith((ref) => null),
          mirrorSessionDraftBootstrapProvider.overrideWith(
            (ref, sessionKey) async => null,
          ),
          mirrorSessionRepositoryBootstrapProvider.overrideWith(
            (ref, sessionKey) {
              if (sessionKey == 'project-a::task-a') {
                return repoA.future;
              }
              if (sessionKey == 'project-b::task-b') {
                return repoB.future;
              }
              return Future<MirrorSessionBootstrapRepository?>.value(null);
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      final subA = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-a::task-a'),
        (_, __) {},
        fireImmediately: true,
      );
      final subB = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-b::task-b'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subA.close);
      addTearDown(subB.close);

      repoB.complete(const MirrorSessionBootstrapRepository(
        files: <String, String>{
          'README.md': 'repo-b',
          'lib/main.dart': 'void main() => print("b");',
        },
        preferredSelectedFile: 'README.md',
        infoMessage: 'repo-b-loaded',
      ));

      await _waitUntil(
        () =>
            container
                .read(mirrorSessionProvider('project-b::task-b'))
                .bootstrapPhase !=
            MirrorSessionBootstrapPhase.initial,
      );

      expect(
        container.read(mirrorSessionProvider('project-b::task-b')).files['README.md'],
        'repo-b',
      );

      repoA.complete(const MirrorSessionBootstrapRepository(
        files: <String, String>{
          'README.md': 'repo-a',
          'lib/main.dart': 'void main() => print("a");',
        },
        preferredSelectedFile: 'README.md',
        infoMessage: 'repo-a-loaded',
      ));

      await _waitUntil(
        () =>
            container
                .read(mirrorSessionProvider('project-a::task-a'))
                .bootstrapPhase !=
            MirrorSessionBootstrapPhase.initial,
      );

      final sessionBAfter = container.read(mirrorSessionProvider('project-b::task-b'));
      expect(sessionBAfter.files['README.md'], 'repo-b');
      expect(sessionBAfter.bootstrapSource, 'repository');
    });

    test('session bootstrap degrades after repository timeout', () async {
      final repositoryNeverCompletes = Completer<MirrorSessionBootstrapRepository?>();

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          mirrorModeProvider.overrideWith((ref) => 'private'),
          mirrorOfflineWarningProvider.overrideWith((ref) => null),
          mirrorSessionRepositoryBootstrapTimeoutProvider.overrideWith(
            (ref) => const Duration(milliseconds: 40),
          ),
          mirrorSessionDraftBootstrapProvider.overrideWith(
            (ref, sessionKey) async => null,
          ),
          mirrorSessionRepositoryBootstrapProvider.overrideWith(
            (ref, sessionKey) => repositoryNeverCompletes.future,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-timeout::task-timeout'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container
                .read(mirrorSessionProvider('project-timeout::task-timeout'))
                .bootstrapPhase !=
            MirrorSessionBootstrapPhase.initial,
      );

      final session =
          container.read(mirrorSessionProvider('project-timeout::task-timeout'));
      expect(session.bootstrapPhase, MirrorSessionBootstrapPhase.degraded);
      expect(session.bootstrapSource, 'baseline');
      expect(
        session.bootstrapReasonCode,
        MirrorSessionBootstrapReasonCodes.repositoryTimeout,
      );
      expect(
        session.terminalLog,
        contains(MirrorSessionBootstrapMessages.repositoryTimeout),
      );
    });

    test('coalesces overlapping premium refresh runs to latest-wins replay', () async {
      var premiumReads = 0;

      final initialPremium = _completed(true);
      final inFlightPremium = Completer<bool>();
      final replayPremium = Completer<bool>();
      final premiumResponses = _QueuedAsync<bool>(
        ListQueue<Completer<bool>>.of([
          initialPremium,
          inFlightPremium,
          replayPremium,
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          mirrorFeatureGateSnapshotProvider.overrideWith(
            (ref) async => const MirrorFeatureGateSnapshot(
              mirrorEnabled: true,
              allowPrivateMode: true,
              allowCloudMode: true,
              allowAdminBypass: false,
            ),
          ),
          mirrorPremiumSnapshotProvider.overrideWith((ref) {
            premiumReads += 1;
            return premiumResponses.next();
          }),
          mirrorTeamModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'solo',
              source: MirrorValueSource.remote,
            ),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'cloud',
              source: MirrorValueSource.remote,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () =>
            container.read(mirrorProvider).hydrationPhase !=
            MirrorHydrationPhase.hydrating,
      );
      expect(premiumReads, 1);

      final refreshA =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final refreshB =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();
      final refreshC =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();

      expect(premiumReads, 2);

      inFlightPremium.complete(true);
      replayPremium.complete(true);
      await Future.wait([refreshA, refreshB, refreshC]);

      expect(premiumReads, 3);
      expect(container.read(mirrorProvider).isPremium, isTrue);
    });

    test('await setMode waits for in-flight refresh completion', () async {
      final initialTeam = _completed(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      final blockedTeam = Completer<MirrorVariantSnapshot>();
      final teamResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([
          initialTeam,
          blockedTeam,
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          mirrorFeatureGateSnapshotProvider.overrideWith(
            (ref) async => const MirrorFeatureGateSnapshot(
              mirrorEnabled: true,
              allowPrivateMode: true,
              allowCloudMode: true,
              allowAdminBypass: false,
            ),
          ),
          mirrorPremiumSnapshotProvider.overrideWith((ref) async => true),
          mirrorTeamModeVariantSnapshotProvider.overrideWith(
            (ref) => teamResponses.next(),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'cloud',
              source: MirrorValueSource.remote,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () =>
            container.read(mirrorProvider).hydrationPhase !=
            MirrorHydrationPhase.hydrating,
      );

      final inFlight =
          container.read(mirrorProvider.notifier).refreshTeamModeVariant();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var setModeCompleted = false;
      final setModeFuture =
          container.read(mirrorProvider.notifier).setMode('cloud');
      setModeFuture.then((_) {
        setModeCompleted = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(setModeCompleted, isFalse);

      blockedTeam.complete(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));

      await Future.wait([inFlight, setModeFuture]);
      expect(setModeCompleted, isTrue);
      expect(container.read(mirrorProvider).mode, 'cloud');
    });

    test('premium stale overlap recovers to latest premium state', () async {
      final initialPremium = _completed(true);
      final stalePremium = Completer<bool>();
      final replayPremium = Completer<bool>();
      final premiumResponses = _QueuedAsync<bool>(
        ListQueue<Completer<bool>>.of([
          initialPremium,
          stalePremium,
          replayPremium,
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          mirrorDraftCacheServiceProvider.overrideWith(
            (ref) => const _NoopDraftCacheService(),
          ),
          mirrorFeatureGateSnapshotProvider.overrideWith(
            (ref) async => const MirrorFeatureGateSnapshot(
              mirrorEnabled: true,
              allowPrivateMode: true,
              allowCloudMode: true,
              allowAdminBypass: false,
            ),
          ),
          mirrorPremiumSnapshotProvider.overrideWith(
            (ref) => premiumResponses.next(),
          ),
          mirrorTeamModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'solo',
              source: MirrorValueSource.remote,
            ),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) async => const MirrorVariantSnapshot(
              value: 'cloud',
              source: MirrorValueSource.remote,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () =>
            container.read(mirrorProvider).hydrationPhase !=
            MirrorHydrationPhase.hydrating,
      );

      await container.read(mirrorProvider.notifier).setMode('cloud');
      expect(container.read(mirrorProvider).mode, 'cloud');

      final refreshA =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final refreshB =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();

      stalePremium.complete(false);
      replayPremium.complete(true);

      await Future.wait([refreshA, refreshB]);
      final state = container.read(mirrorProvider);
      expect(state.isPremium, isTrue);
      expect(state.mode, 'cloud');
    });
  });
}
