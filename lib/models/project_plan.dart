import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_plan.freezed.dart';
part 'project_plan.g.dart';

/// Model for project plan tasks
@freezed
abstract class PlanTask with _$PlanTask {
  const factory PlanTask({
    required String description,
    @Default('pending') String status,
    String? assignedUserId,
    String? assignedUserName,
  }) = _PlanTask;

  factory PlanTask.fromJson(Map<String, dynamic> json) =>
      _$PlanTaskFromJson(json);
}

/// Model for project plan chapters
@freezed
abstract class PlanChapter with _$PlanChapter {
  const factory PlanChapter({
    required String title,
    required String overview,
    @Default(<PlanTask>[]) List<PlanTask> tasks,
  }) = _PlanChapter;

  factory PlanChapter.fromJson(Map<String, dynamic> json) =>
      _$PlanChapterFromJson(json);
}

/// Model for complete project plan
@freezed
abstract class ProjectPlan with _$ProjectPlan {
  const factory ProjectPlan({
    required String overview,
    @Default(<PlanChapter>[]) List<PlanChapter> chapters,
  }) = _ProjectPlan;

  factory ProjectPlan.fromJson(Map<String, dynamic> json) =>
      _$ProjectPlanFromJson(json);
}
