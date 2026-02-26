import 'package:project_management_app/models/project_model.dart';

/// Advanced filter conditions for projects
class ProjectFilterConditions {
  final bool Function(ProjectModel) condition;

  const ProjectFilterConditions(this.condition);
}
