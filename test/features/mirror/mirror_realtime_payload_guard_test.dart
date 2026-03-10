import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';

void main() {
  group('Mirror realtime payload guards', () {
    test('caps per-event lines and per-line characters', () {
      final lines = List<String>.generate(80, (index) {
        return 'line-$index ${'x' * 700}';
      });

      final result = guardRealtimeEventLines(
        lines: lines,
        maxCharsPerLine: 500,
        maxLinesPerEvent: 50,
      );

      expect(result.wasTruncated, isTrue);
      expect(result.lines.length, 50);
      expect(result.lines.every((line) => line.length <= 500), isTrue);
      expect(result.lines.last, contains(realtimeTruncationSuffix));
    });

    test('caps debounce window by total characters with graceful truncation', () {
      final incoming = List<String>.generate(100, (_) => 'y' * 400);

      final result = mergeRealtimeDebounceLinesWithCharCap(
        currentLines: const <String>[],
        incomingLines: incoming,
        maxTotalChars: 10000,
        maxCharsPerLine: 500,
      );

      final totalChars = result.lines.fold<int>(
        0,
        (sum, line) => sum + line.length,
      );

      expect(result.wasTruncated, isTrue);
      expect(totalChars <= 10000, isTrue);
      expect(result.lines.isNotEmpty, isTrue);
      expect(result.lines.last, contains(realtimeTruncationSuffix));
    });

    test('handles high event volume while preserving debounce memory cap', () {
      var pending = <String>[];

      for (var event = 0; event < 20; event += 1) {
        final rawEventLines = List<String>.generate(
          120,
          (index) => 'event-$event-line-$index ${'z' * 320}',
        );

        final perEvent = guardRealtimeEventLines(
          lines: rawEventLines,
          maxCharsPerLine: 500,
          maxLinesPerEvent: 50,
        );

        final merged = mergeRealtimeDebounceLinesWithCharCap(
          currentLines: pending,
          incomingLines: perEvent.lines,
          maxTotalChars: 10000,
          maxCharsPerLine: 500,
        );

        pending = merged.lines;
      }

      final totalChars = pending.fold<int>(
        0,
        (sum, line) => sum + line.length,
      );

      expect(totalChars <= 10000, isTrue);
      expect(pending.isNotEmpty, isTrue);
      expect(pending.last, contains(realtimeTruncationSuffix));
    });
  });
}
