import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_requirements.freezed.dart';
part 'project_requirements.g.dart';

/// Model for project requirements
@freezed
abstract class ProjectRequirements with _$ProjectRequirements {
  const ProjectRequirements._();

  const factory ProjectRequirements({
    @Default(<String>[]) List<String> software,
    @Default(<String>[]) List<String> hardware,
  }) = _ProjectRequirements;

  factory ProjectRequirements.fromJson(Map<String, dynamic> json) =>
      _$ProjectRequirementsFromJson(json);

  bool get isEmpty => software.isEmpty && hardware.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
