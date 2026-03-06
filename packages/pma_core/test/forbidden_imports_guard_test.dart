import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pma_core runtime source does not import app package', () {
    final candidates = <Directory>[
      Directory('packages/pma_core/lib'),
      Directory('lib'),
    ];
    final libDir = candidates.firstWhere(
      (dir) => dir.existsSync(),
      orElse: () => Directory('packages/pma_core/lib'),
    );
    expect(libDir.existsSync(), isTrue);

    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (content.contains('package:project_management_app/')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty, reason: 'Forbidden imports found in: ${offenders.join(', ')}');
  });
}
