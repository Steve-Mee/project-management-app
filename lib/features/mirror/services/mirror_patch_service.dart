import 'dart:convert';

import '../models/project_context.dart';

class MirrorPatch {
  const MirrorPatch({
    required this.path,
    required this.originalContent,
    required this.updatedContent,
    required this.diff,
  });

  final String path;
  final String originalContent;
  final String updatedContent;
  final String diff;
}

class MirrorPatchService {
  const MirrorPatchService();

  List<MirrorPatch> buildPatchesFromApplyPayload({
    required Map<String, String> files,
    required ProjectContextMetadata metadata,
    required String output,
    String? fallbackPath,
  }) {
    final patches = <MirrorPatch>[];
    final parsed = _tryParseApplyPayload(output);

    if (parsed != null) {
      final filesRaw = parsed['files'];
      if (filesRaw is Map) {
        for (final entry in filesRaw.entries) {
          final path = entry.key.toString();
          final updated = entry.value?.toString() ?? '';
          final original = files[path] ?? '';
          if (original == updated) {
            continue;
          }
          patches.add(
            MirrorPatch(
              path: path,
              originalContent: original,
              updatedContent: updated,
              diff: _buildUnifiedDiff(
                path: path,
                before: original,
                after: updated,
              ),
            ),
          );
        }
      }

      final patchListRaw = parsed['patches'];
      if (patchListRaw is List) {
        for (final item in patchListRaw) {
          if (item is! Map) {
            continue;
          }
          final normalized = Map<String, dynamic>.from(item);
          final path = normalized['path']?.toString();
          final updated = normalized['updatedContent']?.toString() ??
              normalized['content']?.toString();
          if (path == null || path.isEmpty || updated == null) {
            continue;
          }

          final original = files[path] ?? '';
          if (original == updated) {
            continue;
          }

          final alreadyExists = patches.any((patch) => patch.path == path);
          if (alreadyExists) {
            continue;
          }

          patches.add(
            MirrorPatch(
              path: path,
              originalContent: original,
              updatedContent: updated,
              diff: _buildUnifiedDiff(
                path: path,
                before: original,
                after: updated,
              ),
            ),
          );
        }
      }
    }

    if (patches.isNotEmpty) {
      return patches;
    }

    final targetPath = fallbackPath ?? _resolveFallbackPath(files, metadata);
    if (targetPath == null || targetPath.isEmpty) {
      return const <MirrorPatch>[];
    }

    final original = files[targetPath] ?? '';
    if (original == output) {
      return const <MirrorPatch>[];
    }

    return <MirrorPatch>[
      MirrorPatch(
        path: targetPath,
        originalContent: original,
        updatedContent: output,
        diff: _buildUnifiedDiff(
            path: targetPath, before: original, after: output),
      ),
    ];
  }

  Map<String, String> applyPatchesToFiles({
    required Map<String, String> files,
    required List<MirrorPatch> patches,
  }) {
    final updated = Map<String, String>.from(files);
    for (final patch in patches) {
      updated[patch.path] = patch.updatedContent;
    }
    return updated;
  }

  Map<String, dynamic>? _tryParseApplyPayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _resolveFallbackPath(
    Map<String, String> files,
    ProjectContextMetadata metadata,
  ) {
    final fromMetadata = metadata.activeFile;
    if (fromMetadata != null && fromMetadata.isNotEmpty) {
      return fromMetadata;
    }
    if (files.isNotEmpty) {
      return files.keys.first;
    }
    return null;
  }

  String _buildUnifiedDiff({
    required String path,
    required String before,
    required String after,
  }) {
    final beforeLines = before.split('\n');
    final afterLines = after.split('\n');
    final max = beforeLines.length > afterLines.length
        ? beforeLines.length
        : afterLines.length;

    final buffer = StringBuffer()
      ..writeln('--- a/$path')
      ..writeln('+++ b/$path');

    for (var index = 0; index < max; index++) {
      final left = index < beforeLines.length ? beforeLines[index] : null;
      final right = index < afterLines.length ? afterLines[index] : null;

      if (left == right) {
        if (left != null) {
          buffer.writeln(' $left');
        }
        continue;
      }

      if (left != null) {
        buffer.writeln('-$left');
      }
      if (right != null) {
        buffer.writeln('+$right');
      }
    }

    return buffer.toString().trimRight();
  }
}
