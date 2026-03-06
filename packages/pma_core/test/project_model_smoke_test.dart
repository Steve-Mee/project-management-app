import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/project_model.dart';

void main() {
  test('ProjectModel.create creates a valid model with generated id fallback', () {
    final model = ProjectModel.create(
      name: 'Smoke Test',
      progress: 0.0,
    );

    expect(model.id, isNotEmpty);
    expect(model.name, 'Smoke Test');
    expect(model.status, 'In Progress');
  });
}
