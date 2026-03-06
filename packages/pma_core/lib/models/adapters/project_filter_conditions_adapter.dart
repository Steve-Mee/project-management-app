import 'package:hive/hive.dart';
import 'package:pma_core/repository/models/project_models.dart';
import 'package:pma_core/models/project_model.dart';

class ProjectFilterConditionsAdapter extends TypeAdapter<ProjectFilterConditions> {
  @override
  final int typeId = 123;

  @override
  ProjectFilterConditions read(BinaryReader reader) {
    return const ProjectFilterConditions(_alwaysTrueCondition);
  }

  @override
  void write(BinaryWriter writer, ProjectFilterConditions obj) {
    writer.write(<String, dynamic>{});
  }

  static bool _alwaysTrueCondition(ProjectModel _) => true;
}
