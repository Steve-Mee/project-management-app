// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';

void main() {
  group('Mirror realtime deduplication', () {
    test('deduplicates high-volume broadcasts by event_id', () {
      final processedKeys = <String>{};
      var pending = <String>[];
      var acceptedEvents = 0;

      for (var index = 0; index < 300; index += 1) {
        final eventId = 'evt-${index ~/ 2}';
        final record = <String, dynamic>{
          'event_id': eventId,
          'project_id': 'project-1',
          'task_id': 'task-1',
          'user_id': 'user-1',
          'updated_at': DateTime.utc(2026, 3, 10, 10, 0, index ~/ 2)
              .toIso8601String(),
          'versions': <Map<String, dynamic>>[
            <String, dynamic>{'output': 'line ${index ~/ 2}'},
          ],
        };

        final outputLines = <String>['line ${index ~/ 2}'];
        final dedupKey = buildRealtimeRecordDedupKey(
          record: record,
          outputLines: outputLines,
        );
        if (!processedKeys.add(dedupKey)) {
          continue;
        }

        acceptedEvents += 1;

        final guarded = guardRealtimeEventLines(
          lines: outputLines,
          maxCharsPerLine: 500,
          maxLinesPerEvent: 50,
        );

        final merged = mergeRealtimeDebounceLinesWithCharCap(
          currentLines: pending,
          incomingLines: guarded.lines,
          maxTotalChars: 10000,
          maxCharsPerLine: 500,
        );

        pending = merged.lines;
      }

      expect(acceptedEvents, 150);
      expect(processedKeys.length, 150);

      final totalChars = pending.fold<int>(
        0,
        (sum, line) => sum + line.length,
      );
      expect(totalChars <= 10000, isTrue);
    });

    test('deduplicates hash fallback when event_id is missing', () {
      final baseRecord = <String, dynamic>{
        'project_id': 'project-1',
        'task_id': 'task-1',
        'user_id': 'user-1',
        'updated_at': '2026-03-10T10:01:00Z',
        'versions': <Map<String, dynamic>>[
          <String, dynamic>{'output': 'same-line'},
        ],
      };

      final outputLines = <String>['same-line'];
      final keyA = buildRealtimeRecordDedupKey(
        record: baseRecord,
        outputLines: outputLines,
      );
      final keyB = buildRealtimeRecordDedupKey(
        record: Map<String, dynamic>.from(baseRecord),
        outputLines: List<String>.from(outputLines),
      );

      expect(keyA, keyB);
      expect(parseRealtimeRecordUpdatedAt(baseRecord['updated_at']), isNotNull);
    });

    test('screen deduplicator skips duplicate event_id records', () {
      final deduplicator = MirrorRealtimeEventSetDeduplicator(maxEntries: 8);

      final first = deduplicator.shouldProcess(<String, dynamic>{
        'event_id': 'evt-100',
        'updated_at': '2026-03-10T10:20:00Z',
      });
      final duplicate = deduplicator.shouldProcess(<String, dynamic>{
        'event_id': 'evt-100',
        'updated_at': '2026-03-10T10:20:01Z',
      });
      final different = deduplicator.shouldProcess(<String, dynamic>{
        'event_id': 'evt-101',
        'updated_at': '2026-03-10T10:20:02Z',
      });

      expect(first, isTrue);
      expect(duplicate, isFalse);
      expect(different, isTrue);
    });

    test('screen deduplicator uses updated_at key when event_id is missing', () {
      final deduplicator = MirrorRealtimeEventSetDeduplicator(maxEntries: 8);

      final first = deduplicator.shouldProcess(<String, dynamic>{
        'updated_at': '2026-03-10T11:00:00Z',
      });
      final duplicate = deduplicator.shouldProcess(<String, dynamic>{
        'updated_at': '2026-03-10T11:00:00Z',
      });
      final newer = deduplicator.shouldProcess(<String, dynamic>{
        'updated_at': '2026-03-10T11:00:01Z',
      });

      expect(first, isTrue);
      expect(duplicate, isFalse);
      expect(newer, isTrue);
    });

    test('screen deduplicator bounds memory with fifo eviction', () {
      final deduplicator = MirrorRealtimeEventSetDeduplicator(maxEntries: 2);

      expect(
        deduplicator.shouldProcess(<String, dynamic>{'event_id': 'evt-a'}),
        isTrue,
      );
      expect(
        deduplicator.shouldProcess(<String, dynamic>{'event_id': 'evt-b'}),
        isTrue,
      );
      expect(
        deduplicator.shouldProcess(<String, dynamic>{'event_id': 'evt-c'}),
        isTrue,
      );

      expect(
        deduplicator.shouldProcess(<String, dynamic>{'event_id': 'evt-a'}),
        isTrue,
      );
      expect(
        deduplicator.shouldProcess(<String, dynamic>{'event_id': 'evt-c'}),
        isFalse,
      );
    });
  });
}
