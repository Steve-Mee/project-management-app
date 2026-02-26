import 'package:json_annotation/json_annotation.dart';
import 'package:project_management_app/models/project_model.dart';

/// Advanced filter conditions for projects
class ProjectFilterConditions {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool Function(ProjectModel) condition;

  const ProjectFilterConditions(this.condition);
}
