import 'dart:convert';
import 'dart:typed_data';

import '../mirror_compute_backend.dart';
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
  String toString() =>
      'MirrorContextBudgetReport('
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
///   2. Maximum file count ([maxFiles]) — excess files dropped, keeping the
///      alphabetically first paths.
///   3. Total byte budget ([maxBytes]) — excess files dropped largest-first.
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
  ///   2. File-count cap (alphabetically last paths are dropped).
  ///   3. Total byte budget (largest files dropped first).
  ///
  /// Returns the original [context] object unchanged (no allocation) when no
  /// limits are exceeded.
  ({ProjectContext context, MirrorContextBudgetReport report}) enforce(
    ProjectContext context,
  ) {
    final original = context.files;
    final droppedFiles = <String>[];
    final truncatedFiles = <String>[];

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

    // Pass 2: file-count cap — keep first maxFiles paths alphabetically.
    var working = afterTruncate;
    if (working.length > maxFiles) {
      final limited = <String, String>{};
      final sorted = working.keys.toList()..sort();
      for (final key in sorted.take(maxFiles)) {
        limited[key] = working[key]!;
      }
      for (final key in sorted.skip(maxFiles)) {
        droppedFiles.add(key);
      }
      working = limited;
    }

    // Pass 3: byte budget — drop largest entries first.
    var currentBytes = _estimateBytes(working);
    if (currentBytes > maxBytes) {
      final mutableWorking = Map<String, String>.from(working);
      final sized = mutableWorking.entries.map((e) {
        final sz =
            utf8.encode(e.key).length + utf8.encode(e.value).length;
        return (key: e.key, size: sz);
      }).toList()
        ..sort((a, b) => b.size.compareTo(a.size));

      for (final item in sized) {
        if (currentBytes <= maxBytes) break;
        mutableWorking.remove(item.key);
        if (!droppedFiles.contains(item.key)) droppedFiles.add(item.key);
        currentBytes -= item.size;
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
    final jsonBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(payload)));
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
      total +=
          utf8.encode(entry.key).length + utf8.encode(entry.value).length;
    }
    return total;
  }
}
