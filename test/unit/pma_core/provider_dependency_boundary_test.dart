@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('provider dependency boundaries', () {
    test('provider_dependency_boundary: providers avoid direct app feature imports', () {
      // Arrange
      final candidateDirs = <Directory>[
        Directory('lib/providers'),
        Directory('packages/pma_core/lib/providers'),
      ];
      final providerDir = candidateDirs.firstWhere(
        (dir) => dir.existsSync(),
        orElse: () => candidateDirs.first,
      );
      expect(providerDir.existsSync(), isTrue);

      final offenders = <String>[];
      final appFeatureImportPattern = RegExp(
        r'''import\s+['"]package:project_management_app/features/''',
      );

      // Act
      for (final entity in providerDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        if (appFeatureImportPattern.hasMatch(content)) {
          offenders.add(entity.path);
        }
      }

      // Assert
      expect(offenders, isEmpty, reason: 'Forbidden feature-layer imports in providers: ${offenders.join(', ')}');
    });
  });
}
