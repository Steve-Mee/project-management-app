import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';

void main() {
  group('Mirror editor integration', () {
    test('mergeLiveOutputWithCap keeps most recent lines only', () {
      final current = List<String>.generate(450, (index) => 'old-$index');
      final incoming = List<String>.generate(100, (index) => 'new-$index');

      final merged = mergeLiveOutputWithCap(
        currentLines: current,
        incomingLines: incoming,
        maxLines: 500,
      );

      expect(merged.length, 500);
      expect(merged.first, 'old-50');
      expect(merged.last, 'new-99');
    });
  });
}
