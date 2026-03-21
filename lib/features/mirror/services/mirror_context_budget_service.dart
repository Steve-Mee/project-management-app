import 'dart:convert';
import 'dart:typed_data';

import '../mirror_signed_inputs_backend.dart';
import '_gzip_helper.dart' if (dart.library.io) '_gzip_helper_io.dart';

/// Describes what [MirrorContextBudgetService.enforce] changed.
class MirrorContextBudgetReport {
  const MirrorContextBudgetReport({
    required this.wasEnforced,
    required this.originalFileCount,
    required this.enforcedFileCount,
    required this.originalBytes,
    required this.enforcedBytes,
    required this.droppedFiles,
    required this.truncatedFiles,
  });

  /// Whether any truncation or file removal was applied.
  final bool wasEnforced;

  /// Number of files in the original context.
  final int originalFileCount;

  /// Number of files in the enforced context.
  final int enforcedFileCount;

  /// Estimated total byte size of the original [ProjectContext.files].
  final int originalBytes;

  /// Estimated total byte size after enforcement.
  final int enforcedBytes;

  /// Files that were removed entirely to meet the byte or count budget.
  final List<String> droppedFiles;

  /// Files whose content was truncated to [MirrorContextBudgetService.maxCharsPerFile].
  final List<String> truncatedFiles;

  @override
  String toString() => 'MirrorContextBudgetReport('
      'wasEnforced=$wasEnforced, '
      'files=$originalFileCount→$enforcedFileCount, '
      'bytes=$originalBytes→$enforcedBytes, '
      'dropped=${droppedFiles.length}, truncated=${truncatedFiles.length}'
      ')';
}

/// Centralised payload budget controls for Mirror context.
///
/// Applies three limits in order before any backend call:
///
///   1. Per-file character truncation ([maxCharsPerFile]).
///   2. Maximum file count ([maxFiles]) — excess files dropped by
///      priority-aware retention.
///   3. Total byte budget ([maxBytes]) — excess files dropped by
///      priority-aware retention.
///
/// Call [enforce] to obtain a budget-enforced [ProjectContext] plus a
/// [MirrorContextBudgetReport] describing every change made.
///
/// Optionally call [encodePayload] to JSON-encode (and optionally gzip-
/// compress) the final HTTP request body. When [enableGzip] is `true` the
/// payload is gzip-compressed on platforms that support it, provided
/// compression actually reduces size. Callers must then add the header
/// `Content-Encoding: gzip` to their HTTP request.
class MirrorContextBudgetService {
  const MirrorContextBudgetService({
    this.maxFiles = 300,
    this.maxBytes = 400 * 1024,
    this.maxCharsPerFile = 50 * 1024,
    this.enableGzip = false,
  });

  /// Maximum number of files allowed in a single context payload (default 300).
  final int maxFiles;

  /// Maximum aggregate byte estimate for [ProjectContext.files]
  /// (default 400 KB = 409 600 bytes).
  final int maxBytes;

  /// Maximum characters per individual file before content is silently
  /// truncated (default 50 000 chars).
  final int maxCharsPerFile;

  /// When `true`, [encodePayload] attempts gzip compression of the JSON
  /// request body, using the result only when it is strictly smaller than
  /// plain JSON.
  final bool enableGzip;

  /// Enforce all budget limits on [context].
  ///
  /// Limits are applied in order:
  ///   1. Per-file character truncation.
  ///   2. File-count cap (lower-priority files are dropped first).
  ///   3. Total byte budget (lower-priority, larger files are dropped first).
  ///
  /// Returns the original [context] object unchanged (no allocation) when no
  /// limits are exceeded.
  ({ProjectContext context, MirrorContextBudgetReport report}) enforce(
    ProjectContext context,
  ) {
    final original = context.files;
    final droppedFiles = <String>[];
    final truncatedFiles = <String>[];
    final protectedPaths = _resolveProtectedPaths(context);

    // Pass 1: per-file character limit.
    final afterTruncate = <String, String>{};
    for (final entry in original.entries) {
      if (entry.value.length > maxCharsPerFile) {
        afterTruncate[entry.key] = entry.value.substring(0, maxCharsPerFile);
        truncatedFiles.add(entry.key);
      } else {
        afterTruncate[entry.key] = entry.value;
      }
    }

    // Pass 2: file-count cap — drop lowest-priority files first.
    var working = afterTruncate;
    if (working.length > maxFiles) {
      final mutableWorking = Map<String, String>.from(working);
      while (mutableWorking.length > maxFiles) {
        final dropKey = _pickDropCandidate(
          mutableWorking,
          protectedPaths: protectedPaths,
          taskId: context.taskId,
          preferLargest: false,
        );
        if (dropKey == null) {
          break;
        }
        mutableWorking.remove(dropKey);
        if (!droppedFiles.contains(dropKey)) {
          droppedFiles.add(dropKey);
        }
      }
      working = mutableWorking;
    }

    // Pass 3: byte budget — drop lowest-priority larger entries first.
    var currentBytes = _estimateBytes(working);
    if (currentBytes > maxBytes) {
      final mutableWorking = Map<String, String>.from(working);
      while (currentBytes > maxBytes) {
        final dropKey = _pickDropCandidate(
          mutableWorking,
          protectedPaths: protectedPaths,
          taskId: context.taskId,
          preferLargest: true,
        );
        if (dropKey == null) {
          break;
        }
        final removedSize = _entrySize(dropKey, mutableWorking[dropKey]!);
        mutableWorking.remove(dropKey);
        if (!droppedFiles.contains(dropKey)) {
          droppedFiles.add(dropKey);
        }
        currentBytes -= removedSize;
      }
      working = mutableWorking;
    }

    final wasEnforced = truncatedFiles.isNotEmpty || droppedFiles.isNotEmpty;
    final originalBytes = _estimateBytes(original);
    final enforcedBytes = wasEnforced ? _estimateBytes(working) : originalBytes;

    final enforcedContext = wasEnforced
        ? ProjectContext(
            projectId: context.projectId,
            taskId: context.taskId,
            files: Map<String, String>.unmodifiable(working),
            metadata: context.metadata,
          )
        : context;

    return (
      context: enforcedContext,
      report: MirrorContextBudgetReport(
        wasEnforced: wasEnforced,
        originalFileCount: original.length,
        enforcedFileCount: working.length,
        originalBytes: originalBytes,
        enforcedBytes: enforcedBytes,
        droppedFiles: List<String>.unmodifiable(droppedFiles),
        truncatedFiles: List<String>.unmodifiable(truncatedFiles),
      ),
    );
  }

  /// JSON-encodes [payload] and optionally gzip-compresses it.
  ///
  /// Returns `(bytes, isGzip)`. When `isGzip` is `true` the caller must
  /// include `Content-Encoding: gzip` in the HTTP request headers.
  ({Uint8List bytes, bool isGzip}) encodePayload(Map<String, dynamic> payload) {
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    if (!enableGzip) {
      return (bytes: jsonBytes, isGzip: false);
    }
    final compressed = tryGzip(jsonBytes);
    if (compressed != null && compressed.length < jsonBytes.length) {
      return (bytes: compressed, isGzip: true);
    }
    return (bytes: jsonBytes, isGzip: false);
  }

  /// Estimates the UTF-8 byte footprint of [files] (keys + values).
  static int _estimateBytes(Map<String, String> files) {
    var total = 0;
    for (final entry in files.entries) {
      total += _entrySize(entry.key, entry.value);
    }
    return total;
  }

  static int _entrySize(String key, String value) {
    return utf8.encode(key).length + utf8.encode(value).length;
  }

  Set<String> _resolveProtectedPaths(ProjectContext context) {
    final protected = <String>{};
    final files = context.files;

    final selected = context.metadata.selectedFile;
    if (selected != null &&
        selected.isNotEmpty &&
        files.containsKey(selected)) {
      protected.add(selected);
    }

    const currentTaskPath = 'context/current_task.md';
    if (files.containsKey(currentTaskPath)) {
      protected.add(currentTaskPath);
    }

    final taskId = context.taskId.trim();
    if (taskId.isNotEmpty) {
      final exactTaskPath = 'context/task_$taskId.md';
      if (files.containsKey(exactTaskPath)) {
        protected.add(exactTaskPath);
      }
    }

    final requiredFiles = context.metadata.requiredFiles;
    for (final file in requiredFiles) {
      if (files.containsKey(file)) {
        protected.add(file);
      }
    }

    return protected;
  }

  String? _pickDropCandidate(
    Map<String, String> files, {
    required Set<String> protectedPaths,
    required String taskId,
    required bool preferLargest,
  }) {
    final candidates = files.entries
        .where((entry) => !protectedPaths.contains(entry.key))
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final aPriority = _dropPriority(a.key, taskId: taskId);
      final bPriority = _dropPriority(b.key, taskId: taskId);
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      if (preferLargest) {
        final aSize = _entrySize(a.key, a.value);
        final bSize = _entrySize(b.key, b.value);
        if (aSize != bSize) {
          return bSize.compareTo(aSize);
        }
      }

      return b.key.compareTo(a.key);
    });

    return candidates.first.key;
  }

  int _dropPriority(String path, {required String taskId}) {
    final normalizedPath = path.trim();
    if (normalizedPath == 'context/current_task.md') {
      return 5;
    }
    if (_isTaskSpecificContextFile(normalizedPath, taskId: taskId)) {
      return 4;
    }
    if (normalizedPath.startsWith('context/')) {
      return 3;
    }
    if (normalizedPath == 'README.md') {
      return 2;
    }
    return 1;
  }

  bool _isTaskSpecificContextFile(String path, {required String taskId}) {
    if (!path.startsWith('context/task_')) {
      return false;
    }

    if (taskId.isEmpty) {
      return true;
    }

    final expected = 'context/task_$taskId.md';
    if (path == expected) {
      return true;
    }

    return path.contains(taskId);
  }
}
