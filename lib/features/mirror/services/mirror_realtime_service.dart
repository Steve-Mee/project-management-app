import 'dart:async';
import 'dart:collection';

import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MirrorRealtimeService {
  MirrorRealtimeService({
    required this.projectId,
    required this.taskId,
    required this.sessionKey,
    this.maxLiveOutputLines = 500,
    this.maxRealtimeCharsPerLine = 500,
    this.maxRealtimeLinesPerEvent = 50,
    this.maxRealtimeCharsPerDebounceWindow = 10000,
    this.maxProcessedRealtimeEventIds = 2000,
    this.realtimeDebounceDuration = const Duration(milliseconds: 300),
  });

  final String projectId;
  final String taskId;
  final String sessionKey;
  final int maxLiveOutputLines;
  final int maxRealtimeCharsPerLine;
  final int maxRealtimeLinesPerEvent;
  final int maxRealtimeCharsPerDebounceWindow;
  final int maxProcessedRealtimeEventIds;
  final Duration realtimeDebounceDuration;

  final List<String> _pendingRealtimeLines = <String>[];
  final Set<String> _processedRealtimeEventIds = <String>{};
  final Queue<String> _processedRealtimeEventOrder = Queue<String>();
  DateTime? _lastProcessedRealtimeUpdatedAt;
  Timer? _realtimeDebounceTimer;

  void dispose() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = null;
  }

  void handleRealtimeRecord({
    required Map<String, dynamic> record,
    required bool mounted,
    required void Function(List<String> lines) onFlush,
    String Function(String status)? statusLineLabel,
    bool enforceScope = true,
  }) {
    if (enforceScope && !_isRecordInRealtimeScope(record)) {
      return;
    }

    final outputLines = _extractOutputLines(
      record,
      statusLineLabel: statusLineLabel,
    );
    if (outputLines.isEmpty || !mounted) {
      return;
    }

    final dedupKey = buildRealtimeRecordDedupKey(
      record: record,
      outputLines: outputLines,
    );
    final updatedAt = parseRealtimeRecordUpdatedAt(record['updated_at']);
    final isDuplicate = _processedRealtimeEventIds.contains(dedupKey);
    if (isDuplicate) {
      AppLogger.warning(
        'Mirror realtime duplicate event skipped',
        params: <String, Object?>{
          'projectId': projectId,
          'taskId': taskId,
          'sessionKey': sessionKey,
          'dedupKey': dedupKey,
          'updatedAt': updatedAt?.toIso8601String(),
          'lastProcessedUpdatedAt': _lastProcessedRealtimeUpdatedAt?.toIso8601String(),
          'pendingLines': _pendingRealtimeLines.length,
        },
      );
      return;
    }

    _processedRealtimeEventIds.add(dedupKey);
    _processedRealtimeEventOrder.addLast(dedupKey);
    while (_processedRealtimeEventOrder.length > maxProcessedRealtimeEventIds) {
      final oldest = _processedRealtimeEventOrder.removeFirst();
      _processedRealtimeEventIds.remove(oldest);
    }

    if (updatedAt != null &&
        (_lastProcessedRealtimeUpdatedAt == null ||
            updatedAt.isAfter(_lastProcessedRealtimeUpdatedAt!))) {
      _lastProcessedRealtimeUpdatedAt = updatedAt;
    }

    final eventGuarded = guardRealtimeEventLines(
      lines: outputLines,
      maxCharsPerLine: maxRealtimeCharsPerLine,
      maxLinesPerEvent: maxRealtimeLinesPerEvent,
    );
    if (eventGuarded.lines.isEmpty) {
      return;
    }

    final mergedPending = mergeRealtimeDebounceLinesWithCharCap(
      currentLines: _pendingRealtimeLines,
      incomingLines: eventGuarded.lines,
      maxTotalChars: maxRealtimeCharsPerDebounceWindow,
      maxCharsPerLine: maxRealtimeCharsPerLine,
    );

    _pendingRealtimeLines
      ..clear()
      ..addAll(mergedPending.lines);

    if (eventGuarded.wasTruncated || mergedPending.wasTruncated) {
      AppLogger.warning(
        'Mirror realtime payload truncated',
        params: <String, Object?>{
          'projectId': projectId,
          'taskId': taskId,
          'eventTruncated': eventGuarded.wasTruncated,
          'debounceTruncated': mergedPending.wasTruncated,
          'incomingLines': outputLines.length,
          'pendingLines': _pendingRealtimeLines.length,
        },
      );
    }

    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(realtimeDebounceDuration, () {
      _flushDebouncedRealtimeOutput(
        mounted: mounted,
        onFlush: onFlush,
      );
    });
  }

  Map<String, dynamic>? extractBroadcastRecord(Map<String, dynamic> payload) {
    final directNew = payload['new'];
    if (directNew is Map) {
      return Map<String, dynamic>.from(directNew);
    }

    final nestedPayload = payload['payload'];
    if (nestedPayload is Map) {
      final nestedNew = nestedPayload['new'];
      if (nestedNew is Map) {
        return Map<String, dynamic>.from(nestedNew);
      }
    }

    final record = payload['record'];
    if (record is Map) {
      return Map<String, dynamic>.from(record);
    }

    return null;
  }

  void _flushDebouncedRealtimeOutput({
    required bool mounted,
    required void Function(List<String> lines) onFlush,
  }) {
    if (!mounted || _pendingRealtimeLines.isEmpty) {
      return;
    }

    final flushedLines = List<String>.from(_pendingRealtimeLines);
    _pendingRealtimeLines.clear();

    onFlush(flushedLines);
  }

  bool _isRecordInRealtimeScope(Map<String, dynamic> record) {
    String? currentUserId;
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return false;
    }
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final recordTaskId = record['task_id']?.toString();
    final recordProjectId = record['project_id']?.toString();
    final recordUserId = record['user_id']?.toString();

    return recordTaskId == taskId &&
        recordProjectId == projectId &&
        recordUserId == currentUserId;
  }

  List<String> _extractOutputLines(
    Map<String, dynamic> record, {
    String Function(String status)? statusLineLabel,
  }) {
    final versions = record['versions'];
    if (versions is List) {
      final lines = <String>[];
      for (final item in versions) {
        if (item is Map && item['output'] != null) {
          lines.add(item['output'].toString());
        } else if (item != null) {
          lines.add(item.toString());
        }
      }
      return lines;
    }

    final status = record['status'];
    if (status != null) {
      final value = status.toString();
      return <String>[
        statusLineLabel == null ? 'Status: $value' : statusLineLabel(value),
      ];
    }

    return const <String>[];
  }
}

List<String> mergeLiveOutputWithCap({
  required List<String> currentLines,
  required List<String> incomingLines,
  int maxLines = 500,
}) {
  final merged = <String>[...currentLines, ...incomingLines];
  if (merged.length <= maxLines) {
    return merged;
  }
  return merged.sublist(merged.length - maxLines);
}

const String realtimeTruncationSuffix = '... [truncated]';

class RealtimePayloadGuardResult {
  const RealtimePayloadGuardResult({
    required this.lines,
    required this.wasTruncated,
  });

  final List<String> lines;
  final bool wasTruncated;
}

RealtimePayloadGuardResult guardRealtimeEventLines({
  required List<String> lines,
  int maxCharsPerLine = 500,
  int maxLinesPerEvent = 50,
}) {
  if (lines.isEmpty || maxCharsPerLine <= 0 || maxLinesPerEvent <= 0) {
    return const RealtimePayloadGuardResult(
      lines: <String>[],
      wasTruncated: false,
    );
  }

  var wasTruncated = false;
  final limit = lines.length > maxLinesPerEvent ? maxLinesPerEvent : lines.length;
  if (lines.length > maxLinesPerEvent) {
    wasTruncated = true;
  }

  final guarded = <String>[];
  for (var index = 0; index < limit; index += 1) {
    final line = lines[index];
    final normalized = line.length <= maxCharsPerLine
        ? line
        : truncateRealtimeLine(line, maxCharsPerLine);
    if (normalized.length < line.length) {
      wasTruncated = true;
    }
    guarded.add(normalized);
  }

  if (lines.length > maxLinesPerEvent && guarded.isNotEmpty) {
    guarded[guarded.length - 1] = ensureRealtimeTruncationSuffix(
      guarded.last,
      maxCharsPerLine,
    );
  }

  return RealtimePayloadGuardResult(lines: guarded, wasTruncated: wasTruncated);
}

RealtimePayloadGuardResult mergeRealtimeDebounceLinesWithCharCap({
  required List<String> currentLines,
  required List<String> incomingLines,
  int maxTotalChars = 10000,
  int maxCharsPerLine = 500,
}) {
  if (maxTotalChars <= 0 || maxCharsPerLine <= 0) {
    return const RealtimePayloadGuardResult(
      lines: <String>[],
      wasTruncated: true,
    );
  }

  final merged = <String>[...currentLines];
  var totalChars = 0;
  for (final line in merged) {
    totalChars += line.length;
  }

  var wasTruncated = false;
  for (final line in incomingLines) {
    final remaining = maxTotalChars - totalChars;
    if (remaining <= 0) {
      wasTruncated = true;
      break;
    }

    if (line.length <= remaining) {
      merged.add(line);
      totalChars += line.length;
      continue;
    }

    final maxCharsForLine = remaining < maxCharsPerLine ? remaining : maxCharsPerLine;
    if (maxCharsForLine > 0) {
      final truncatedLine = truncateRealtimeLine(line, maxCharsForLine);
      merged.add(truncatedLine);
      totalChars += truncatedLine.length;
    }
    wasTruncated = true;
    break;
  }

  if (wasTruncated && merged.isNotEmpty) {
    var charsBeforeLast = 0;
    for (var index = 0; index < merged.length - 1; index += 1) {
      charsBeforeLast += merged[index].length;
    }
    final remainingForLast = maxTotalChars - charsBeforeLast;
    final maxCharsForLast = remainingForLast < maxCharsPerLine
        ? remainingForLast
        : maxCharsPerLine;
    merged[merged.length - 1] = ensureRealtimeTruncationSuffix(
      merged.last,
      maxCharsForLast,
    );
  }

  return RealtimePayloadGuardResult(lines: merged, wasTruncated: wasTruncated);
}

String truncateRealtimeLine(String line, int maxCharsPerLine) {
  if (maxCharsPerLine <= 0) {
    return '';
  }
  if (line.length <= maxCharsPerLine) {
    return line;
  }

  if (maxCharsPerLine <= realtimeTruncationSuffix.length) {
    return realtimeTruncationSuffix.substring(0, maxCharsPerLine);
  }

  final keep = maxCharsPerLine - realtimeTruncationSuffix.length;
  return '${line.substring(0, keep)}$realtimeTruncationSuffix';
}

String ensureRealtimeTruncationSuffix(String line, int maxCharsPerLine) {
  if (maxCharsPerLine <= 0) {
    return '';
  }
  if (line.contains(realtimeTruncationSuffix)) {
    return line.length <= maxCharsPerLine
        ? line
        : truncateRealtimeLine(line, maxCharsPerLine);
  }
  return truncateRealtimeLine('$line $realtimeTruncationSuffix', maxCharsPerLine);
}

DateTime? parseRealtimeRecordUpdatedAt(dynamic rawUpdatedAt) {
  if (rawUpdatedAt == null) {
    return null;
  }

  final parsed = DateTime.tryParse(rawUpdatedAt.toString());
  return parsed?.toUtc();
}

String buildRealtimeRecordDedupKey({
  required Map<String, dynamic> record,
  required List<String> outputLines,
}) {
  final eventId =
      record['event_id']?.toString() ?? record['id']?.toString() ?? record['version_id']?.toString();
  if (eventId != null && eventId.trim().isNotEmpty) {
    return 'event:$eventId';
  }

  final updatedAt = parseRealtimeRecordUpdatedAt(record['updated_at']);
  final status = record['status']?.toString() ?? '';
  final taskId = record['task_id']?.toString() ?? '';
  final projectId = record['project_id']?.toString() ?? '';
  final userId = record['user_id']?.toString() ?? '';
  final versionsHash = Object.hashAll(outputLines);

  final hash = Object.hash(
    updatedAt?.toIso8601String() ?? '',
    status,
    taskId,
    projectId,
    userId,
    versionsHash,
  );

  return 'hash:$hash';
}

class MirrorRealtimeEventSetDeduplicator {
  MirrorRealtimeEventSetDeduplicator({this.maxEntries = 2000});

  final int maxEntries;
  final Set<String> _seenKeys = <String>{};
  final Queue<String> _seenOrder = Queue<String>();

  bool shouldProcess(Map<String, dynamic> record) {
    final key = _buildSetKey(record);
    if (key == null) {
      return true;
    }

    if (_seenKeys.contains(key)) {
      return false;
    }

    _seenKeys.add(key);
    _seenOrder.addLast(key);

    while (_seenOrder.length > maxEntries) {
      final oldest = _seenOrder.removeFirst();
      _seenKeys.remove(oldest);
    }

    return true;
  }

  String? _buildSetKey(Map<String, dynamic> record) {
    final rawEventId =
        record['event_id']?.toString() ??
        record['id']?.toString() ??
        record['version_id']?.toString();

    if (rawEventId != null) {
      final eventId = rawEventId.trim();
      if (eventId.isNotEmpty) {
        return 'event:$eventId';
      }
    }

    final updatedAt = parseRealtimeRecordUpdatedAt(record['updated_at']);
    if (updatedAt != null) {
      return 'updated_at:${updatedAt.toIso8601String()}';
    }

    return null;
  }
}
