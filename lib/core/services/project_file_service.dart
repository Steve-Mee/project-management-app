import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for selecting a project directory and reading text files within it.
class ProjectFileService {
  static const int _maxFiles = 15;
  static const int _maxCharsPerFile = 80000;
  final Map<String, _CachedFile> _cache = {};

  /// Prompts the user to select a directory and returns its path, or null.
  Future<String?> pickProjectDirectory() async {
    try {
      if (!await _ensureStoragePermission()) {
        return null;
      }

      return await FilePicker.platform.getDirectoryPath();
    } catch (_) {
      // Swallow errors to keep the UI flow intact.
      return null;
    }
  }

  /// Recursively reads text files from a directory with safety limits.
  Future<List<ProjectFileContent>> readAllTextFiles(
    String directoryPath,
  ) async {
    final results = <ProjectFileContent>[];

    try {
      if (!await _ensureStoragePermission()) {
        return results;
      }

      final root = Directory(directoryPath);
      if (!await root.exists()) {
        return results;
      }

      final paths = await _walkTextFiles(root.path);
      for (final path in paths) {
        if (results.length >= _maxFiles) {
          break;
        }

        final content = await _readFileLimited(File(path));
        if (content != null) {
          results.add(
            ProjectFileContent(
              name: _fileNameFromPath(path),
              content: content,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore read errors and return whatever has been collected.
    }

    return results;
  }

  /// Recursively yields text file paths under a directory using an isolate.
  Future<List<String>> _walkTextFiles(String rootPath) async {
    return Isolate.run(() {
      final results = <String>[];
      final toVisit = <Directory>[Directory(rootPath)];

      while (toVisit.isNotEmpty) {
        final current = toVisit.removeLast();
        final entries = current.listSync(recursive: false, followLinks: false);

        for (final entry in entries) {
          if (entry is Directory) {
            toVisit.add(entry);
          } else if (entry is File && _isTextFile(entry.path)) {
            results.add(entry.path);
          }
        }
      }

      return results;
    });
  }

  /// Reads a file and limits its size by character count.
  Future<String?> _readFileLimited(File file) async {
    try {
      final cached = _cache[file.path];
      final lastModified = await file.lastModified();
      if (cached != null && cached.lastModified == lastModified) {
        return cached.content;
      }

      final content = await file.readAsString();
      if (content.length <= _maxCharsPerFile) {
        _cache[file.path] = _CachedFile(
          content: content,
          lastModified: lastModified,
        );
        return content;
      }
      final trimmed = content.substring(0, _maxCharsPerFile);
      _cache[file.path] = _CachedFile(
        content: trimmed,
        lastModified: lastModified,
      );
      return trimmed;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether the path matches the supported text extensions.
  bool _isTextFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.json');
  }

  /// Requests storage permission on mobile platforms.
  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    final requested = await Permission.storage.request();
    return requested.isGranted;
  }

  String _fileNameFromPath(String path) {
    final separator = Platform.pathSeparator;
    final index = path.lastIndexOf(separator);
    if (index == -1 || index == path.length - 1) {
      return path;
    }

    return path.substring(index + 1);
  }
}

/// File content wrapper for prompts and previews.
class ProjectFileContent {
  final String name;
  final String content;

  const ProjectFileContent({
    required this.name,
    required this.content,
  });
}

class _CachedFile {
  final String content;
  final DateTime lastModified;

  const _CachedFile({
    required this.content,
    required this.lastModified,
  });
}
