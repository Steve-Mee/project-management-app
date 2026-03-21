@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/project_model.dart';

void main() {
  group('ProjectModel.create', () {
    test('project_model_smoke: creates valid model with generated id fallback', () {
      // Arrange
      const name = 'Smoke Test';

      // Act
      final model = ProjectModel.create(
        name: name,
        progress: 0.0,
      );

      // Assert
      expect(model.id, isNotEmpty);
      expect(model.name, name);
      expect(model.status, 'In Progress');
    });
  });
}
