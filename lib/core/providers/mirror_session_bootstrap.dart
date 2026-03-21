enum MirrorSessionBootstrapPhase {
  initial,
  ready,
  degraded,
}

class MirrorSessionBootstrapDraft {
  const MirrorSessionBootstrapDraft({
    required this.files,
    required this.selectedFile,
    this.contextVersion,
  });

  final Map<String, String> files;
  final String selectedFile;
  final int? contextVersion;
}

class MirrorSessionBootstrapRepository {
  const MirrorSessionBootstrapRepository({
    required this.files,
    required this.preferredSelectedFile,
    this.infoMessage,
    this.errorMessage,
  });

  final Map<String, String> files;
  final String preferredSelectedFile;
  final String? infoMessage;
  final String? errorMessage;
}

class MirrorSessionBootstrapResult {
  const MirrorSessionBootstrapResult({
    required this.files,
    required this.selectedFile,
    required this.contextVersion,
    required this.terminalLines,
    required this.phase,
    required this.sourceSummary,
  });

  final Map<String, String> files;
  final String selectedFile;
  final int contextVersion;
  final List<String> terminalLines;
  final MirrorSessionBootstrapPhase phase;
  final String sourceSummary;
}

MirrorSessionBootstrapResult resolveMirrorSessionBootstrap({
  required Map<String, String> baselineFiles,
  required String baselineSelectedFile,
  required int baselineContextVersion,
  MirrorSessionBootstrapDraft? draft,
  MirrorSessionBootstrapRepository? repository,
}) {
  final files = repository == null
      ? Map<String, String>.from(baselineFiles)
      : Map<String, String>.from(repository.files);
  if (draft != null) {
    files.addAll(draft.files);
  }

  final selectedFileCandidates = <String>[
    if (draft != null) draft.selectedFile,
    if (repository != null) repository.preferredSelectedFile,
    baselineSelectedFile,
  ];
  final selectedFile = _resolveSelectedFile(files, selectedFileCandidates);

  final terminalLines = <String>[
    if (draft != null && draft.files.isNotEmpty)
      'Mirror session restored unsaved draft from local cache.',
    if (repository?.infoMessage != null) repository!.infoMessage!,
    if (repository?.errorMessage != null) repository!.errorMessage!,
  ];
  final phase = repository?.errorMessage != null
      ? MirrorSessionBootstrapPhase.degraded
      : MirrorSessionBootstrapPhase.ready;
  final sourceSummary = <String>[
    if (draft != null && draft.files.isNotEmpty) 'draft',
    if (repository != null && repository.files.isNotEmpty) 'repository',
    if (draft == null && (repository == null || repository.files.isEmpty))
      'baseline',
  ].join('+');

  return MirrorSessionBootstrapResult(
    files: files,
    selectedFile: selectedFile,
    contextVersion: draft?.contextVersion ?? baselineContextVersion,
    terminalLines: terminalLines,
    phase: phase,
    sourceSummary: sourceSummary,
  );
}

String _resolveSelectedFile(
  Map<String, String> files,
  List<String> candidates,
) {
  for (final candidate in candidates) {
    if (candidate.isNotEmpty && files.containsKey(candidate)) {
      return candidate;
    }
  }

  if (files.isEmpty) {
    return '';
  }
  return files.keys.first;
}