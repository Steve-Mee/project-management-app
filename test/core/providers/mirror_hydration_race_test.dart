import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_management_app/features/mirror/services/mirror_draft_cache_service.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/core/providers/mirror_state_resolver.dart';

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
      final initialPremium = _completed(true);
      final initialTeam = _completed(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      final staleTeam = Completer<MirrorVariantSnapshot>();
      final currentTeam = Completer<MirrorVariantSnapshot>();
      final initialRunner = _completed(const MirrorVariantSnapshot(
        value: 'cloud',
        source: MirrorValueSource.remote,
      ));
      final premiumResponses = _QueuedAsync<bool>(
        ListQueue<Completer<bool>>.of([initialPremium]),
      );
      final teamResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([
          initialTeam,
          staleTeam,
          currentTeam,
        ]),
      );
      final runnerResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([initialRunner]),
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
          mirrorPremiumSnapshotProvider.overrideWith(
            (ref) => premiumResponses.next(),
          ),
          mirrorTeamModeVariantSnapshotProvider.overrideWith(
            (ref) => teamResponses.next(),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) => runnerResponses.next(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () => container.read(mirrorProvider).hydrationPhase != MirrorHydrationPhase.hydrating,
      );
      expect(container.read(mirrorProvider).teamModeVariant, 'solo');

      final staleRefresh = container.read(mirrorProvider.notifier).refreshTeamModeVariant();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      container.read(userIdProvider.notifier).state = 'user-b';
      final currentRefresh =
          container.read(mirrorProvider.notifier).refreshTeamModeVariant();

      currentTeam.complete(const MirrorVariantSnapshot(
        value: 'team',
        source: MirrorValueSource.remote,
      ));
      await currentRefresh;

      expect(container.read(mirrorProvider).teamModeVariant, 'team');

      staleTeam.complete(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      await staleRefresh;

      final state = container.read(mirrorProvider);
      expect(state.teamModeVariant, 'team');
      expect(state.hydrationPhase, MirrorHydrationPhase.resolved);
    });

    test('premium refresh ignores stale completion and preserves cloud mode', () async {
      final initialPremium = _completed(true);
      final stalePremium = Completer<bool>();
      final currentPremium = Completer<bool>();
      final initialTeam = _completed(const MirrorVariantSnapshot(
        value: 'solo',
        source: MirrorValueSource.remote,
      ));
      final initialRunner = _completed(const MirrorVariantSnapshot(
        value: 'cloud',
        source: MirrorValueSource.remote,
      ));
      final premiumResponses = _QueuedAsync<bool>(
        ListQueue<Completer<bool>>.of([
          initialPremium,
          stalePremium,
          currentPremium,
        ]),
      );
      final teamResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([initialTeam]),
      );
      final runnerResponses = _QueuedAsync<MirrorVariantSnapshot>(
        ListQueue<Completer<MirrorVariantSnapshot>>.of([initialRunner]),
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
            (ref) => teamResponses.next(),
          ),
          mirrorRunnerModeVariantSnapshotProvider.overrideWith(
            (ref) => runnerResponses.next(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(mirrorProvider);
      await _waitUntil(
        () => container.read(mirrorProvider).hydrationPhase != MirrorHydrationPhase.hydrating,
      );

      await container.read(mirrorProvider.notifier).setMode('cloud');
      expect(container.read(mirrorProvider).mode, 'cloud');

      final staleRefresh = container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final currentRefresh =
          container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();

        currentPremium.complete(true);
      await currentRefresh;

      expect(container.read(mirrorProvider).mode, 'cloud');
      expect(container.read(mirrorProvider).isPremium, isTrue);

      stalePremium.complete(false);
      await staleRefresh;

      final state = container.read(mirrorProvider);
      expect(state.mode, 'cloud');
      expect(state.isPremium, isTrue);
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
        () => container
                .read(mirrorSessionProvider('project-b::task-b'))
                .bootstrapPhase !=
            MirrorSessionBootstrapPhase.initial,
      );

      final sessionB = container.read(mirrorSessionProvider('project-b::task-b'));
      expect(sessionB.files['README.md'], 'repo-b');
      expect(sessionB.bootstrapSource, 'repository');

      repoA.complete(const MirrorSessionBootstrapRepository(
        files: <String, String>{
          'README.md': 'repo-a',
          'lib/main.dart': 'void main() => print("a");',
        },
        preferredSelectedFile: 'README.md',
        infoMessage: 'repo-a-loaded',
      ));

      await _waitUntil(
        () => container
                .read(mirrorSessionProvider('project-a::task-a'))
                .bootstrapPhase !=
            MirrorSessionBootstrapPhase.initial,
      );

      final sessionBAfter = container.read(mirrorSessionProvider('project-b::task-b'));
      expect(sessionBAfter.files['README.md'], 'repo-b');
      expect(sessionBAfter.bootstrapSource, 'repository');
    });
  });
}
