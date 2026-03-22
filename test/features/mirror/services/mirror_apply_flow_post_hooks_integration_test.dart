import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_apply_flow_coordinator.dart';
import 'package:project_management_app/features/mirror/services/mirror_draft_cache_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_service_boundaries.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingDraftCacheService extends MirrorDraftCacheService {
  final List<Map<String, String>> writes = <Map<String, String>>[];

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
    writes.add(Map<String, String>.from(files));
  }
}

class _FakeTaskNotifier extends TaskNotifier {
  @override
  Future<List<Task>> build() async => const [];

  @override
  Future<void> loadTasks(String projectId) async {
    state = const AsyncValue.data([]);
  }
}

class _FakeOrchestrator implements MirrorExecutionOrchestrator {
  _FakeOrchestrator({required this.applyResult});

  final ApplyResult applyResult;

  @override
  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(success: true, code: 'gen_code');
  }

  @override
  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: true,
      output: 'compiled_output',
      serverVersionToken: 'v1',
    );
  }

  @override
  Future<ApplyResult> apply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    return applyResult;
  }
}

Future<WidgetRef> _captureRef(
  WidgetTester tester, {
  required MirrorDraftCacheService draftCacheService,
}) async {
  WidgetRef? ref;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tasksProvider.overrideWith(_FakeTaskNotifier.new),
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
      child: Consumer(
        builder: (_, widgetRef, __) {
          ref = widgetRef;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return ref!;
}

ProjectContext _makeContext() {
  return const ProjectContext(
    projectId: 'project-1',
    taskId: 'task-1',
    files: <String, String>{'lib/main.dart': 'void main() {}'},
    metadata: ProjectContextMetadata(selectedFile: 'lib/main.dart'),
  );
}

void main() {
  group('MirrorApplyFlowCoordinator post-hooks integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets(
      'successful apply triggers compile-start and apply-complete persistence',
      (tester) async {
        final drafts = _RecordingDraftCacheService();
        final ref = await _captureRef(
          tester,
          draftCacheService: drafts,
        );

        final sessionNotifier =
            ref.read(mirrorSessionProvider('project-1::task-1').notifier);
        sessionNotifier.updateSelectedFileContent('post-hooks-success-content');

        final coordinator = MirrorApplyFlowCoordinator();
        final result = await coordinator.executeApplyFlow(
          orchestrator: _FakeOrchestrator(
            applyResult:
                const ApplyResult(success: true, appliedFiles: ['lib/main.dart']),
          ),
          ref: ref,
          sessionKey: 'project-1::task-1',
          prompt: 'post-hooks-success-content',
          context: _makeContext(),
          mode: 'private',
          sessionNotifier: sessionNotifier,
          onStateChange: (_) {},
          onApprovalRequired: (_) async => true,
        );

        expect(result.success, isTrue);
        expect(drafts.writes.length, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'failed apply does not run apply-complete persistence hook',
      (tester) async {
        final drafts = _RecordingDraftCacheService();
        final ref = await _captureRef(
          tester,
          draftCacheService: drafts,
        );

        final sessionNotifier =
            ref.read(mirrorSessionProvider('project-1::task-1').notifier);
        sessionNotifier.updateSelectedFileContent('post-hooks-fail-content');

        final coordinator = MirrorApplyFlowCoordinator();
        final result = await coordinator.executeApplyFlow(
          orchestrator: _FakeOrchestrator(
            applyResult: const ApplyResult(success: false, message: 'apply failed'),
          ),
          ref: ref,
          sessionKey: 'project-1::task-1',
          prompt: 'post-hooks-fail-content',
          context: _makeContext(),
          mode: 'private',
          sessionNotifier: sessionNotifier,
          onStateChange: (_) {},
          onApprovalRequired: (_) async => true,
        );

        expect(result.success, isFalse);
        expect(drafts.writes, hasLength(1));
      },
    );
  });
}
