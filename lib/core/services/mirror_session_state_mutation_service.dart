import '../providers/mirror_session_provider.dart';
import 'mirror_session_state_service.dart';

class MirrorSessionStateMutationService {
  const MirrorSessionStateMutationService({
    this.stateService = const MirrorSessionStateService(),
  });

  final MirrorSessionStateService stateService;

  MirrorSessionState? selectFile(MirrorSessionState state, String path) {
    if (!state.files.containsKey(path)) {
      return null;
    }
    return state.copyWith(selectedFile: path);
  }

  MirrorSessionState updateSelectedFileContent(
    MirrorSessionState state,
    String content,
  ) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[state.selectedFile] = content;
    return state.copyWith(
      files: updatedFiles,
      contextFingerprint: stateService.computeContextFingerprint(updatedFiles),
      contextVersion: mirrorDraftContextVersion,
    );
  }

  MirrorSessionState upsertFileContent(
    MirrorSessionState state, {
    required String path,
    required String content,
  }) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[path] = content;
    return state.copyWith(
      files: updatedFiles,
      contextFingerprint: stateService.computeContextFingerprint(updatedFiles),
      contextVersion: mirrorDraftContextVersion,
    );
  }

  MirrorSessionState? appendLiveOutput(
    MirrorSessionState state,
    List<String> lines, {
    int maxLines = 500,
  }) {
    if (lines.isEmpty) {
      return null;
    }
    final merged = <String>[...state.liveOutput, ...lines];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    return state.copyWith(liveOutput: capped);
  }

  MirrorSessionState? appendTerminalLine(
    MirrorSessionState state,
    String line, {
    int maxLines = 1000,
  }) {
    if (line.trim().isEmpty) {
      return null;
    }
    final merged = <String>[...state.terminalLog, line];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    return state.copyWith(terminalLog: capped);
  }

  MirrorSessionState? setCompileValidationArtifacts(
    MirrorSessionState state, {
    required String compileFingerprint,
    String? serverVersionToken,
  }) {
    final normalizedFingerprint = compileFingerprint.trim();
    if (normalizedFingerprint.isEmpty) {
      return null;
    }

    final normalizedToken = serverVersionToken?.trim();
    return state.copyWith(
      compileFingerprint: normalizedFingerprint,
      compileServerVersionToken:
          (normalizedToken == null || normalizedToken.isEmpty)
              ? null
              : normalizedToken,
    );
  }
}