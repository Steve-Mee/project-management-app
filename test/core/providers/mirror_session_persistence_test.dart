import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/services/mirror_draft_cache_service.dart';

class _PersistedDraftRecord {
  const _PersistedDraftRecord({
    required this.sessionKey,
    required this.files,
    required this.selectedFile,
    required this.mode,
    required this.offlineWarningKey,
    required this.contextFingerprint,
    required this.contextVersion,
  });

  final String sessionKey;
  final Map<String, String> files;
  final String selectedFile;
  final String? mode;
  final String? offlineWarningKey;
  final String? contextFingerprint;
  final int? contextVersion;
}

class _RecordingDraftCacheService extends MirrorDraftCacheService {
  _RecordingDraftCacheService({this.firstWriteBlocker});

  final Completer<void>? firstWriteBlocker;
  final List<_PersistedDraftRecord> writes = <_PersistedDraftRecord>[];
  int _writeCount = 0;

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
  }) async {
    _writeCount += 1;
    writes.add(
      _PersistedDraftRecord(
        sessionKey: sessionKey,
        files: Map<String, String>.from(files),
        selectedFile: selectedFile,
        mode: mode,
        offlineWarningKey: offlineWarningKey,
        contextFingerprint: contextFingerprint,
        contextVersion: contextVersion,
      ),
    );

    if (_writeCount == 1 && firstWriteBlocker != null) {
      await firstWriteBlocker!.future;
    }
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

ProviderContainer _buildContainer({
  required MirrorDraftCacheService draftCacheService,
  Future<MirrorSessionBootstrapDraft?> Function(String sessionKey)? draftLoader,
  Future<MirrorSessionBootstrapRepository?> Function(String sessionKey)?
      repositoryLoader,
}) {
  return ProviderContainer(
    overrides: [
      mirrorDraftCacheServiceProvider.overrideWith((ref) => draftCacheService),
      mirrorResolvedModeProvider.overrideWith((ref) => 'private'),
      mirrorResolvedOfflineWarningProvider.overrideWith((ref) => null),
      mirrorSessionDraftBootstrapProvider.overrideWith(
        (ref, sessionKey) async =>
            draftLoader == null ? null : await draftLoader(sessionKey),
      ),
      mirrorSessionRepositoryBootstrapProvider.overrideWith(
        (ref, sessionKey) async => repositoryLoader == null
            ? null
            : await repositoryLoader(sessionKey),
      ),
    ],
  );
}

void main() {
  group('MirrorSessionNotifier bootstrap phases', () {
    test('publishes repositoryLoading, merging, and ready in order',
        () async {
      final repository = Completer<MirrorSessionBootstrapRepository?>();
      final phases = <MirrorSessionBootstrapPhase>[];
      final container = _buildContainer(
        draftCacheService: _RecordingDraftCacheService(),
        repositoryLoader: (_) => repository.future,
      );
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, next) => phases.add(next.bootstrapPhase),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () => phases.contains(MirrorSessionBootstrapPhase.repositoryLoading),
      );

      repository.complete(const MirrorSessionBootstrapRepository(
        files: <String, String>{
          'README.md': 'repo',
          'lib/main.dart': 'void main() => print("repo");',
        },
        preferredSelectedFile: 'README.md',
      ));

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      expect(
        phases,
        containsAllInOrder(<MirrorSessionBootstrapPhase>[
          MirrorSessionBootstrapPhase.initial,
          MirrorSessionBootstrapPhase.repositoryLoading,
          MirrorSessionBootstrapPhase.merging,
          MirrorSessionBootstrapPhase.ready,
        ]),
      );
    });
  });

  group('MirrorSessionNotifier lifecycle persistence', () {
    test('persistOnRunStart writes the current session snapshot immediately',
        () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      notifier.updateSelectedFileContent('void main() => print("run");');

      await notifier.persistOnRunStart();

      expect(drafts.writes, hasLength(1));
      expect(
        drafts.writes.single.files['lib/main.dart'],
        'void main() => print("run");',
      );
    });

    test('persistOnApply writes the current session snapshot immediately',
        () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      notifier.upsertFileContent(
        path: 'lib/new_file.dart',
        content: 'class Added {}',
      );

      await notifier.persistOnApply();

      expect(drafts.writes, hasLength(1));
      expect(drafts.writes.single.files['lib/new_file.dart'], 'class Added {}');
    });

    test('persistOnRouteExit writes the latest selected file state',
        () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      notifier.selectFile('README.md');
      notifier.updateSelectedFileContent('route-exit-state');

      await notifier.persistOnRouteExit();

      expect(drafts.writes, hasLength(1));
      expect(drafts.writes.single.selectedFile, 'README.md');
      expect(drafts.writes.single.files['README.md'], 'route-exit-state');
    });

    test('stale in-flight persist is followed by a fresh persist for newer state',
        () async {
      final firstWriteBlocker = Completer<void>();
      final drafts =
          _RecordingDraftCacheService(firstWriteBlocker: firstWriteBlocker);
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      notifier.updateSelectedFileContent('version-1');

      final firstPersist = notifier.persistOnRunStart();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      notifier.updateSelectedFileContent('version-2');
      firstWriteBlocker.complete();

      await firstPersist;
      await _waitUntil(() => drafts.writes.length >= 2);

      expect(drafts.writes.first.files['lib/main.dart'], 'version-1');
      expect(drafts.writes.last.files['lib/main.dart'], 'version-2');
    });

    test('debounced persist still writes after local edit', () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      notifier.updateSelectedFileContent('debounced-change');

      await _waitUntil(() => drafts.writes.isNotEmpty);

      expect(drafts.writes.last.files['lib/main.dart'], 'debounced-change');
    });
  });
}