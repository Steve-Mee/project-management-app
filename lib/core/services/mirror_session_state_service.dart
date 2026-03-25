import 'dart:convert';

import 'package:crypto/crypto.dart';

const int mirrorDraftContextVersion = 1;

class MirrorSessionBaseline {
  const MirrorSessionBaseline({
    required this.files,
    required this.selectedFile,
    required this.contextFingerprint,
    required this.contextVersion,
  });

  final Map<String, String> files;
  final String selectedFile;
  final String contextFingerprint;
  final int contextVersion;
}

class MirrorSessionStateService {
  const MirrorSessionStateService();

  MirrorSessionBaseline buildBaseline({
    required String projectId,
    required String taskId,
  }) {
    final files = <String, String>{
      'README.md': '# Mirror Session\n\nProject: $projectId\nTask: $taskId\n',
      'lib/main.dart':
          "void main() {\n  print('Mirror session: $projectId::$taskId');\n}\n",
    };

    return MirrorSessionBaseline(
      files: files,
      selectedFile: 'lib/main.dart',
      contextFingerprint: computeContextFingerprint(files),
      contextVersion: mirrorDraftContextVersion,
    );
  }

  String computeContextFingerprint(Map<String, String> files) {
    final entries = files.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer
        ..write(entry.key)
        ..write('::')
        ..write(entry.value)
        ..write('\n');
    }

    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }
}