import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HiveAuthRepository does not keep in-memory failed-attempt maps', () async {
    final file = File('packages/pma_core/lib/repository/impl/hive_auth_repository.dart');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content.contains('final Map<String, List<DateTime>> _failedAttempts = {}'), isFalse);
  });

  test('HiveAuthRepository rate-limit methods delegate to LoginRateLimiter helpers', () async {
    final file = File('packages/pma_core/lib/repository/impl/hive_auth_repository.dart');
    final content = await file.readAsString();

    expect(content.contains('_isLoginBlockedSafely('), isTrue);
    expect(content.contains('_recordLoginAttemptSafely('), isTrue);
    expect(content.contains('_resetLoginAttemptsSafely('), isTrue);
  });
}
