import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/services/mirror_apply_post_hooks_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_draft_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PersistedDraftRecord {
  const _PersistedDraftRecord({
    required this.sessionKey,
    required this.files,
    required this.selectedFile,
  });

  final String sessionKey;
  final Map<String, String> files;
  final String selectedFile;
}

class _RecordingDraftCacheService extends MirrorDraftCacheService {
  final List<_PersistedDraftRecord> writes = <_PersistedDraftRecord>[];

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
    writes.add(
      _PersistedDraftRecord(
        sessionKey: sessionKey,
        files: Map<String, String>.from(files),
        selectedFile: selectedFile,
      ),
    );
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
}) {
  return ProviderContainer(
    overrides: [
      mirrorDraftCacheServiceProvider.overrideWith((ref) => draftCacheService),
      mirrorResolvedModeProvider.overrideWith((ref) => 'private'),
      mirrorResolvedOfflineWarningProvider.overrideWith((ref) => null),
      mirrorSessionDraftBootstrapProvider.overrideWith(
        (ref, sessionKey) async => null,
      ),
      mirrorSessionRepositoryBootstrapProvider.overrideWith(
        (ref, sessionKey) async => null,
      ),
    ],
  );
}

void main() {
  group('MirrorApplyPostHooksService lifecycle persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('persistOnCompileStart persists current draft snapshot', () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );
      notifier.updateSelectedFileContent('compile-start-content');

      const service = MirrorApplyPostHooksService();
      final result = await service.persistOnCompileStart(
        sessionNotifier: notifier,
      );

      expect(result.success, isTrue);
      expect(drafts.writes.length, greaterThanOrEqualTo(1));
      expect(
        drafts.writes.last.files['lib/main.dart'],
        'compile-start-content',
      );
    });

    test('persistOnApplyComplete persists draft and records apply timestamp',
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

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );
      notifier.updateSelectedFileContent('apply-complete-content');

      const service = MirrorApplyPostHooksService();
      final result = await service.persistOnApplyComplete(
        sessionNotifier: notifier,
        projectId: 'project-1',
        taskId: 'task-1',
      );

      expect(result.success, isTrue);
      expect(drafts.writes.length, greaterThanOrEqualTo(1));
      expect(
        drafts.writes.last.files['lib/main.dart'],
        'apply-complete-content',
      );

      final timestamp =
          await service.getLastApplyTimestamp('project-1', 'task-1');
      expect(timestamp, isNotNull);
    });

    test('persistOnRouteExit persists latest selected file state', () async {
      final drafts = _RecordingDraftCacheService();
      final container = _buildContainer(draftCacheService: drafts);
      addTearDown(container.dispose);

      final sub = container.listen<MirrorSessionState>(
        mirrorSessionProvider('project-1::task-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final notifier =
          container.read(mirrorSessionProvider('project-1::task-1').notifier);
      await _waitUntil(
        () =>
            container.read(mirrorSessionProvider('project-1::task-1'))
                .bootstrapPhase ==
            MirrorSessionBootstrapPhase.ready,
      );

      notifier.upsertFileContent(path: 'README.md', content: 'route-exit-content');
      notifier.selectFile('README.md');

      const service = MirrorApplyPostHooksService();
      final result = await service.persistOnRouteExit(
        sessionNotifier: notifier,
      );

      expect(result.success, isTrue);
      expect(drafts.writes.length, greaterThanOrEqualTo(1));
      expect(drafts.writes.last.selectedFile, 'README.md');
      expect(
        drafts.writes.last.files['README.md'],
        'route-exit-content',
      );
    });
  });
}
