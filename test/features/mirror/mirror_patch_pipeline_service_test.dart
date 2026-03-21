import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_patch_pipeline_service.dart';

void main() {
  group('MirrorPatchPipelineService', () {
    const service = MirrorPatchPipelineService();

    test('prepareCompilePlan patches compile context and emits run prompt', () {
      const executionContext = ProjectContext(
        projectId: 'project-1',
        taskId: 'task-1',
        files: const <String, String>{
          'lib/main.dart': 'void main() {}',
        },
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
      );

      final plan = service.prepareCompilePlan(
        executionContext: executionContext,
        selectedFile: 'lib/main.dart',
        selectedContent: 'original prompt',
        generatedCode: 'void main() { print("hi"); }',
      );

      expect(plan.runPrompt, equals('void main() { print("hi"); }'));
      expect(
        plan.compileContextForPreviewAndApply.files['lib/main.dart'],
        equals('void main() { print("hi"); }'),
      );
      expect(plan.compileContextFingerprint, isNotEmpty);
      expect(
        plan.compileContextForPreviewAndApply.metadata
            .previewContextFingerprint,
        equals(plan.compileContextFingerprint),
      );
    });

    test('prepareApplyPlan returns no preview when compile output is empty',
        () {
      const context = ProjectContext(
        projectId: 'project-2',
        taskId: 'task-2',
        files: const <String, String>{'lib/main.dart': 'base'},
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
      );

      final plan = service.prepareApplyPlan(
        compileContextForPreviewAndApply: context,
        selectedFile: 'lib/main.dart',
        compileOutput: '   ',
        generatedCode: null,
      );

      expect(plan.patches, isEmpty);
      expect(plan.previewPatch, isNull);
    });

    test('buildSessionPersistPlan marks unknown files as upsert', () {
      final plan = service.buildSessionPersistPlan(
        currentFiles: const <String, String>{'lib/main.dart': 'old'},
        previousSelected: 'lib/main.dart',
        fallbackSelectedFile: 'lib/main.dart',
        patches: const <MirrorFilePatch>[
          MirrorFilePatch(
            path: 'lib/new.dart',
            originalContent: '',
            updatedContent: 'new content',
            diff: '+new content',
          ),
        ],
      );

      expect(plan.mutations, hasLength(1));
      expect(plan.mutations.first.path, equals('lib/new.dart'));
      expect(plan.mutations.first.requiresUpsert, isTrue);
      expect(plan.restoreTarget, equals('lib/main.dart'));
    });
  });
}
