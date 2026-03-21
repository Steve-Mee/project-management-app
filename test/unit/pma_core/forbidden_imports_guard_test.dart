@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pma_core dependency boundaries', () {
    test('forbidden_imports_guard: runtime sources avoid app package imports', () {
      // Arrange
      final candidates = <Directory>[
        Directory('packages/pma_core/lib'),
        Directory('lib'),
      ];
      final libDir = candidates.firstWhere(
        (dir) => dir.existsSync(),
        orElse: () => Directory('packages/pma_core/lib'),
      );
      expect(libDir.existsSync(), isTrue);

      // Act
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

      // Assert
      expect(offenders, isEmpty, reason: 'Forbidden imports found in: ${offenders.join(', ')}');
    });
  });
}
