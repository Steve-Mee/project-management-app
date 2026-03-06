import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('providers do not import app feature layer directly', () {
    final providerDir = Directory('packages/pma_core/lib/providers');
    expect(providerDir.existsSync(), isTrue);

    final offenders = <String>[];

    for (final entity in providerDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (content.contains('/features/') || content.contains('package:project_management_app/features/')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty, reason: 'Forbidden feature-layer imports in providers: ${offenders.join(', ')}');
  });
}
