library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MirrorSessionState {
  const MirrorSessionState({
    required this.projectId,
    required this.taskId,
    required this.files,
    required this.selectedFile,
    required this.liveOutput,
    required this.terminalLog,
  });

  final String projectId;
  final String taskId;
  final Map<String, String> files;
  final String selectedFile;
  final List<String> liveOutput;
  final List<String> terminalLog;

  MirrorSessionState copyWith({
    String? projectId,
    String? taskId,
    Map<String, String>? files,
    String? selectedFile,
    List<String>? liveOutput,
    List<String>? terminalLog,
  }) {
    return MirrorSessionState(
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      files: files ?? this.files,
      selectedFile: selectedFile ?? this.selectedFile,
      liveOutput: liveOutput ?? this.liveOutput,
      terminalLog: terminalLog ?? this.terminalLog,
    );
  }

  static MirrorSessionState initial({
    required String projectId,
    required String taskId,
  }) {
    const defaultFiles = <String, String>{
      'lib/main.dart': "void main() {\n  print('Mirror');\n}\n",
      'lib/services/compiler.dart':
          'class CompilerService {\n  Future<void> run() async {}\n}\n',
      'README.md': '# Mirror Project\n\nMulti-file coding workspace.\n',
    };

    return const MirrorSessionState(
      projectId: '',
      taskId: '',
      files: defaultFiles,
      selectedFile: 'lib/main.dart',
      liveOutput: <String>[],
      terminalLog: <String>[],
    ).copyWith(projectId: projectId, taskId: taskId);
  }
}

class MirrorSessionNotifier extends FamilyNotifier<MirrorSessionState, String> {
  @override
  MirrorSessionState build(String sessionKey) {
    final parts = sessionKey.split('::');
    final projectId = parts.isNotEmpty ? parts[0] : '';
    final taskId = parts.length > 1 ? parts[1] : '';
    return MirrorSessionState.initial(projectId: projectId, taskId: taskId);
  }

  void selectFile(String path) {
    if (!state.files.containsKey(path)) {
      return;
    }
    state = state.copyWith(selectedFile: path);
  }

  void updateSelectedFileContent(String content) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[state.selectedFile] = content;
    state = state.copyWith(files: updatedFiles);
  }

  void appendLiveOutput(List<String> lines, {int maxLines = 500}) {
    if (lines.isEmpty) {
      return;
    }
    final merged = <String>[...state.liveOutput, ...lines];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    state = state.copyWith(liveOutput: capped);
  }

  void appendTerminalLine(String line, {int maxLines = 1000}) {
    if (line.trim().isEmpty) {
      return;
    }
    final merged = <String>[...state.terminalLog, line];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    state = state.copyWith(terminalLog: capped);
  }
}

final mirrorSessionProvider = NotifierProvider.family<
  MirrorSessionNotifier,
  MirrorSessionState,
  String
>(MirrorSessionNotifier.new);
