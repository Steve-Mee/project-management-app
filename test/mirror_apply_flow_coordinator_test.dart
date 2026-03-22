// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_apply_flow_coordinator.dart';
import 'package:project_management_app/features/mirror/services/mirror_service_boundaries.dart';

class _FakeOrchestrator implements MirrorExecutionOrchestrator {
  _FakeOrchestrator({
    this.generateResult = const GenerateResult(success: true, code: 'gen_code'),
    CompileResult? compileResult,
    this.applyResult = const ApplyResult(
      success: true,
      appliedFiles: ['lib/main.dart'],
    ),
  }) : compileResult = compileResult ??
            const CompileResult(
              success: true,
              output: 'compiled_output',
              serverVersionToken: 'v1',
              warnings: [],
            );

  final GenerateResult generateResult;
  final CompileResult compileResult;
  final ApplyResult applyResult;

  int generateCallCount = 0;
  int compileCallCount = 0;
  int applyCallCount = 0;
  ProjectContext? lastApplyContext;
  String? lastApplyFingerprint;

  @override
  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    generateCallCount++;
    return generateResult;
  }

  @override
  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    compileCallCount++;
    return compileResult;
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
    applyCallCount++;
    lastApplyContext = context;
    lastApplyFingerprint = compileFingerprint;
    return applyResult;
  }
}

class _FakeTaskNotifier extends TaskNotifier {
  int loadTasksCallCount = 0;
  String? lastLoadedProjectId;

  @override
  Future<List<Task>> build() async => const [];

  @override
  Future<void> loadTasks(String projectId) async {
    loadTasksCallCount++;
    lastLoadedProjectId = projectId;
    state = const AsyncValue.data([]);
  }
}

ProjectContext _makeContext({
  String projectId = 'project-1',
  String taskId = 'task-1',
}) {
  return ProjectContext(
    projectId: projectId,
    taskId: taskId,
    files: const {'lib/main.dart': 'void main() {}'},
    metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
  );
}

Future<WidgetRef> _captureRef(
  WidgetTester tester,
) async {
  WidgetRef? ref;
  await tester.pumpWidget(
    ProviderScope(
      // Always fake the task notifier to avoid Hive initialization in tests.
      overrides: [tasksProvider.overrideWith(_FakeTaskNotifier.new)],
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

/// Like [_captureRef] but also exposes the [_FakeTaskNotifier] instance so
/// cache-refresh tests can inspect call counts.
Future<({WidgetRef ref, _FakeTaskNotifier tasks})> _captureRefWithTasks(
  WidgetTester tester,
) async {
  final fakeNotifier = _FakeTaskNotifier();
  WidgetRef? ref;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tasksProvider.overrideWith(() => fakeNotifier)],
      child: Consumer(
        builder: (_, widgetRef, __) {
          ref = widgetRef;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (ref: ref!, tasks: fakeNotifier);
}

final _coordinator = MirrorApplyFlowCoordinator();

void main() {
  group('MirrorApplyFlowCoordinator - state machine transitions', () {
    testWidgets('emits generating stage as first state', (tester) async {
      final ref = await _captureRef(tester);
      final stages = <MirrorApplyFlowStage>[];

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) => stages.add(s.stage),
        onApprovalRequired: (_) async => true,
      );

      expect(stages.first, MirrorApplyFlowStage.generating);
    });

    testWidgets('emits compiling stage after successful generate',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        generateResult: const GenerateResult(
          success: true,
          code: 'gen_code',
          diagnostics: ['warn1'],
        ),
      );
      final states = <MirrorApplyFlowState>[];

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: states.add,
        onApprovalRequired: (_) async => true,
      );

      final compiling = states.firstWhere(
        (s) => s.stage == MirrorApplyFlowStage.compiling,
      );
      expect(compiling.generateDiagnostics, ['warn1']);
    });

    testWidgets('emits previewing stage after successful compile',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        compileResult: const CompileResult(
          success: true,
          output: 'compiled_output',
          serverVersionToken: 'v2',
          warnings: ['compat warning'],
        ),
      );
      final states = <MirrorApplyFlowState>[];

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: states.add,
        onApprovalRequired: (_) async => true,
      );

      final previewing = states.firstWhere(
        (s) => s.stage == MirrorApplyFlowStage.previewing,
      );
      expect(previewing.patches.isNotEmpty, isTrue);
      expect(previewing.compileWarnings, ['compat warning']);
      expect(previewing.compileFingerprint, isNotEmpty);
      expect(previewing.previewPatchPath, isNotNull);
    });

    testWidgets('emits validating stage after approval', (tester) async {
      final ref = await _captureRef(tester);
      final stages = <MirrorApplyFlowStage>[];

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) => stages.add(s.stage),
        onApprovalRequired: (_) async => true,
      );

      expect(stages, contains(MirrorApplyFlowStage.validating));
    });

    testWidgets('emits applying stage before apply call', (tester) async {
      final ref = await _captureRef(tester);
      final stages = <MirrorApplyFlowStage>[];

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) => stages.add(s.stage),
        onApprovalRequired: (_) async => true,
      );

      expect(stages, contains(MirrorApplyFlowStage.applying));
    });

    testWidgets('emits done stage as final state on success', (tester) async {
      final ref = await _captureRef(tester);
      final stages = <MirrorApplyFlowStage>[];

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) => stages.add(s.stage),
        onApprovalRequired: (_) async => true,
      );

      expect(stages.last, MirrorApplyFlowStage.done);
    });

    testWidgets('full happy path emits all 6 stages in correct order',
        (tester) async {
      final ref = await _captureRef(tester);
      final stages = <MirrorApplyFlowStage>[];

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) => stages.add(s.stage),
        onApprovalRequired: (_) async => true,
      );

      expect(stages, [
        MirrorApplyFlowStage.generating,
        MirrorApplyFlowStage.compiling,
        MirrorApplyFlowStage.previewing,
        MirrorApplyFlowStage.validating,
        MirrorApplyFlowStage.applying,
        MirrorApplyFlowStage.done,
      ]);
    });
  });

  group('MirrorApplyFlowCoordinator - success result', () {
    testWidgets('returns success true with appliedFiles and patches',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        applyResult: const ApplyResult(
          success: true,
          appliedFiles: ['lib/main.dart', 'lib/app.dart'],
        ),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(result.success, isTrue);
      expect(result.stage, MirrorApplyFlowStage.done);
      expect(result.appliedFiles, ['lib/main.dart', 'lib/app.dart']);
      expect(result.patches, isNotNull);
      expect(result.patches!.isNotEmpty, isTrue);
      expect(result.error, isNull);
    });

    testWidgets('approval callback receives correct preview data',
        (tester) async {
      final ref = await _captureRef(tester);
      MirrorApplyFlowPreviewData? capturedPreview;

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (preview) async {
          capturedPreview = preview;
          return true;
        },
      );

      expect(capturedPreview, isNotNull);
      expect(capturedPreview!.patches.isNotEmpty, isTrue);
      expect(capturedPreview!.compileFingerprint, isNotEmpty);
      expect(capturedPreview!.compileOutput, 'compiled_output');
      expect(capturedPreview!.previewServerVersionToken, 'v1');
      expect(capturedPreview!.previewPatch, isNotNull);
    });
  });

  group('MirrorApplyFlowCoordinator - early exit paths', () {
    testWidgets('fails at generating stage when generate returns failure',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        generateResult: const GenerateResult(
          success: false,
          message: 'generate_error',
        ),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => fail('should not be called'),
      );

      expect(result.success, isFalse);
      expect(result.stage, MirrorApplyFlowStage.generating);
      expect(result.error, 'generate_error');
      expect(orchestrator.compileCallCount, 0);
      expect(orchestrator.applyCallCount, 0);
    });

    testWidgets('fails at compiling stage when compile returns failure',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        compileResult: const CompileResult(
          success: false,
          errors: ['syntax error at line 42'],
        ),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => fail('should not be called'),
      );

      expect(result.success, isFalse);
      expect(result.stage, MirrorApplyFlowStage.compiling);
      expect(result.error, contains('syntax error at line 42'));
      expect(orchestrator.applyCallCount, 0);
    });

    testWidgets('fails at compiling stage when compile output is empty',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        compileResult: const CompileResult(success: true, output: '   '),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => fail('should not be called'),
      );

      expect(result.success, isFalse);
      expect(result.stage, MirrorApplyFlowStage.compiling);
      expect(orchestrator.applyCallCount, 0);
    });

    testWidgets('fails with no_patches error when compile produces no diff',
        (tester) async {
      final ref = await _captureRef(tester);
      // When compile output is identical to the existing file content,
      // no changed patches are produced and the coordinator short-circuits.
      const existingContent = 'void main() { print(42); }';
      final orchestrator = _FakeOrchestrator(
        generateResult: const GenerateResult(success: true, code: null),
        compileResult: const CompileResult(
          success: true,
          output: existingContent,
          serverVersionToken: 'v1',
        ),
      );
      final unchangedCtx = ProjectContext(
        projectId: 'p',
        taskId: 't',
        files: const {'lib/main.dart': existingContent},
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: existingContent,
        context: unchangedCtx,
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => fail('should not be called'),
      );

      expect(result.success, isFalse);
      expect(result.error, 'no_patches');
      expect(orchestrator.applyCallCount, 0);
    });

    testWidgets('fails with cancelled error when approval callback returns false',
        (tester) async {
      final ref = await _captureRef(tester);
      var approvalCalled = false;

      final result = await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (preview) async {
          approvalCalled = true;
          return false;
        },
      );

      expect(result.success, isFalse);
      expect(result.stage, MirrorApplyFlowStage.previewing);
      expect(result.error, 'cancelled');
      expect(approvalCalled, isTrue);
      expect(result.patches, isNotNull);
    });

    testWidgets('fails at done stage when apply returns failure',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        applyResult: const ApplyResult(
          success: false,
          message: 'consistency check failed',
        ),
      );

      final result = await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(result.success, isFalse);
      expect(result.stage, MirrorApplyFlowStage.done);
      expect(result.error, 'consistency check failed');
    });
  });

  group('MirrorApplyFlowCoordinator - data integrity', () {
    testWidgets('compileFingerprint is non-empty in previewing state',
        (tester) async {
      final ref = await _captureRef(tester);
      MirrorApplyFlowState? previewingState;

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) {
          if (s.stage == MirrorApplyFlowStage.previewing) {
            previewingState = s;
          }
        },
        onApprovalRequired: (_) async => true,
      );

      expect(previewingState, isNotNull);
      expect(previewingState!.compileFingerprint, isNotEmpty);
    });

    testWidgets('compileFingerprint is propagated to applying state',
        (tester) async {
      final ref = await _captureRef(tester);
      String? previewFingerprint;
      String? applyingFingerprint;

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) {
          if (s.stage == MirrorApplyFlowStage.previewing) {
            previewFingerprint = s.compileFingerprint;
          }
          if (s.stage == MirrorApplyFlowStage.applying) {
            applyingFingerprint = s.compileFingerprint;
          }
        },
        onApprovalRequired: (_) async => true,
      );

      expect(previewFingerprint, isNotNull);
      expect(applyingFingerprint, previewFingerprint);
    });

    testWidgets('compileFingerprint is embedded in applyContext metadata',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator();

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      final applyCtx = orchestrator.lastApplyContext;
      expect(applyCtx, isNotNull);
      expect(applyCtx!.metadata.compileFingerprint, isNotNull);
      expect(applyCtx.metadata.compileFingerprint, isNotEmpty);
    });

    testWidgets('compileFingerprint passed to apply matches context metadata',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator();

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(orchestrator.lastApplyFingerprint, isNotNull);
      expect(
        orchestrator.lastApplyContext!.metadata.compileFingerprint,
        orchestrator.lastApplyFingerprint,
      );
    });

    testWidgets('compileWarnings appear in previewing state', (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        compileResult: const CompileResult(
          success: true,
          output: 'compiled_output',
          warnings: ['deprecated api', 'unused import'],
        ),
      );
      MirrorApplyFlowState? previewState;

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) {
          if (s.stage == MirrorApplyFlowStage.previewing) previewState = s;
        },
        onApprovalRequired: (_) async => true,
      );

      expect(previewState!.compileWarnings, ['deprecated api', 'unused import']);
    });

    testWidgets('generateDiagnostics appear in compiling state',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        generateResult: const GenerateResult(
          success: true,
          code: 'gen_code',
          diagnostics: ['hint: use const', 'info: unused var'],
        ),
      );
      MirrorApplyFlowState? compilingState;

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) {
          if (s.stage == MirrorApplyFlowStage.compiling) compilingState = s;
        },
        onApprovalRequired: (_) async => true,
      );

      expect(
        compilingState!.generateDiagnostics,
        ['hint: use const', 'info: unused var'],
      );
    });

    testWidgets('previewPatchPath is set in previewing state', (tester) async {
      final ref = await _captureRef(tester);
      MirrorApplyFlowState? previewState;

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (s) {
          if (s.stage == MirrorApplyFlowStage.previewing) previewState = s;
        },
        onApprovalRequired: (_) async => true,
      );

      expect(previewState!.previewPatchPath, isNotNull);
      expect(previewState!.previewPatchPath, isNotEmpty);
    });
  });

  group('MirrorApplyFlowCoordinator - cache refresh', () {
    testWidgets('calls loadTasks on successful apply', (tester) async {
      final (:ref, :tasks) = await _captureRefWithTasks(tester);

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: 'project-1::task-1',
        prompt: 'run',
        context: _makeContext(projectId: 'project-1', taskId: 'task-1'),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(tasks.loadTasksCallCount, 1);
      expect(tasks.lastLoadedProjectId, 'project-1');
    });

    testWidgets('does NOT call loadTasks when apply fails', (tester) async {
      final (:ref, :tasks) = await _captureRefWithTasks(tester);

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(
          applyResult: const ApplyResult(success: false, message: 'fail'),
        ),
        ref: ref,
        sessionKey: 'project-1::task-1',
        prompt: 'run',
        context: _makeContext(projectId: 'project-1', taskId: 'task-1'),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(tasks.loadTasksCallCount, 0);
    });

    testWidgets('skips cache refresh when projectId is empty', (tester) async {
      final (:ref, :tasks) = await _captureRefWithTasks(tester);

      final emptyProjCtx = ProjectContext(
        projectId: '',
        taskId: 'task-1',
        files: const {'lib/main.dart': 'void main() {}'},
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
      );

      await _coordinator.executeApplyFlow(
        orchestrator: _FakeOrchestrator(),
        ref: ref,
        sessionKey: '::task-1',
        prompt: 'run',
        context: emptyProjCtx,
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(tasks.loadTasksCallCount, 0);
    });
  });

  group('MirrorApplyFlowCoordinator - orchestrator call counts', () {
    testWidgets('calls generate compile and apply exactly once on happy path',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator();

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => true,
      );

      expect(orchestrator.generateCallCount, 1);
      expect(orchestrator.compileCallCount, 1);
      expect(orchestrator.applyCallCount, 1);
    });

    testWidgets('does not call compile or apply when generate fails',
        (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator(
        generateResult: const GenerateResult(success: false, message: 'err'),
      );

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => false,
      );

      expect(orchestrator.compileCallCount, 0);
      expect(orchestrator.applyCallCount, 0);
    });

    testWidgets('does not call apply when user cancels', (tester) async {
      final ref = await _captureRef(tester);
      final orchestrator = _FakeOrchestrator();

      await _coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: 'p::t',
        prompt: 'run',
        context: _makeContext(),
        mode: 'standard',
        onStateChange: (_) {},
        onApprovalRequired: (_) async => false,
      );

      expect(orchestrator.applyCallCount, 0);
    });
  });
}
