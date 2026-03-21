import '../mirror_signed_inputs_backend.dart';
import 'mirror_backend_workflows.dart';
import 'mirror_preview_metadata_service.dart';

class MirrorCompilePatchPlan {
  const MirrorCompilePatchPlan({
    required this.compileContextForPreviewAndApply,
    required this.compileContextFingerprint,
    required this.runPrompt,
  });

  final ProjectContext compileContextForPreviewAndApply;
  final String compileContextFingerprint;
  final String runPrompt;
}

class MirrorApplyPatchPlan {
  const MirrorApplyPatchPlan({
    required this.patches,
    required this.previewPatch,
  });

  final List<MirrorFilePatch> patches;
  final MirrorFilePatch? previewPatch;
}

/// Canonical patch pipeline contract for interactive Mirror run flows.
///
/// This service owns preview/apply patch derivation and session patch planning
/// so UI orchestration classes remain focused on user interaction.
class MirrorPatchPipelineService {
  const MirrorPatchPipelineService();

  static const MirrorBackendWorkflows _workflows = MirrorBackendWorkflows();
  static const MirrorPreviewMetadataService _previewMetadataService =
      MirrorPreviewMetadataService();

  MirrorCompilePatchPlan prepareCompilePlan({
    required ProjectContext executionContext,
    required String selectedFile,
    required String selectedContent,
    String? generatedCode,
  }) {
    final originalCompileContext = ProjectContext(
      projectId: executionContext.projectId,
      taskId: executionContext.taskId,
      files: Map<String, String>.from(executionContext.files),
      metadata: executionContext.metadata,
    );

    final generatedPatches = _workflows.buildPreviewPatches(
      context: executionContext,
      selectedFile: selectedFile,
      compileOutput: generatedCode,
      generatedCode: generatedCode,
    );

    final compileContext = generatedPatches.isEmpty
        ? originalCompileContext
        : originalCompileContext.copyWith(
            files: _workflows.applyPatchesToFiles(
              files: originalCompileContext.files,
              patches: generatedPatches,
            ),
          );

    final compileContextFingerprint =
        _previewMetadataService.computeContextFingerprint(compileContext.files);

    final compileContextForPreviewAndApply = compileContext.copyWith(
      files: Map<String, String>.from(compileContext.files),
      metadata: compileContext.metadata.copyWith(
        previewContextFingerprint: compileContextFingerprint,
      ),
    );

    return MirrorCompilePatchPlan(
      compileContextForPreviewAndApply: compileContextForPreviewAndApply,
      compileContextFingerprint: compileContextFingerprint,
      runPrompt:
          _firstNonEmpty(generatedCode, selectedContent) ?? selectedContent,
    );
  }

  MirrorApplyPatchPlan prepareApplyPlan({
    required ProjectContext compileContextForPreviewAndApply,
    required String selectedFile,
    required String compileOutput,
    String? generatedCode,
  }) {
    final patches = _workflows.buildPreviewPatches(
      context: compileContextForPreviewAndApply,
      selectedFile: selectedFile,
      compileOutput: compileOutput,
      generatedCode: generatedCode,
    );

    if (patches.isEmpty) {
      return const MirrorApplyPatchPlan(
        patches: <MirrorFilePatch>[],
        previewPatch: null,
      );
    }

    final previewPatch = patches.firstWhere(
      (MirrorFilePatch patch) => patch.path == selectedFile,
      orElse: () => patches.first,
    );

    return MirrorApplyPatchPlan(
      patches: patches,
      previewPatch: previewPatch,
    );
  }

  MirrorSessionPatchPlan buildSessionPersistPlan({
    required Map<String, String> currentFiles,
    required String previousSelected,
    required String fallbackSelectedFile,
    required List<MirrorFilePatch> patches,
  }) {
    return _workflows.buildSessionPatchPlan(
      currentFiles: currentFiles,
      previousSelected: previousSelected,
      fallbackSelectedFile: fallbackSelectedFile,
      patches: patches,
    );
  }

  String? _firstNonEmpty(String? first, String? second) {
    final firstValue = first?.trim();
    if (firstValue != null && firstValue.isNotEmpty) {
      return firstValue;
    }

    final secondValue = second?.trim();
    if (secondValue != null && secondValue.isNotEmpty) {
      return secondValue;
    }

    return null;
  }
}
