import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncProjectCreate does not log project_created analytics', () async {
    final file = File('packages/pma_core/lib/services/cloud_sync_service.dart');
    final source = await file.readAsString();

    final createStart = source.indexOf('Future<void> syncProjectCreate');
    final updateStart = source.indexOf('Future<void> syncProjectUpdate');

    expect(createStart, isNonNegative);
    expect(updateStart, greaterThan(createStart));

    final createSection = source.substring(createStart, updateStart);

    expect(createSection.contains('AnalyticsEventName.projectCreated'), isFalse);
    expect(createSection.contains("'project_created'"), isFalse);
  });
}
