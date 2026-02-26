// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanTask _$PlanTaskFromJson(Map<String, dynamic> json) => _PlanTask(
      description: json['description'] as String,
      status: json['status'] as String? ?? 'pending',
      assignedUserId: json['assignedUserId'] as String?,
      assignedUserName: json['assignedUserName'] as String?,
    );

Map<String, dynamic> _$PlanTaskToJson(_PlanTask instance) => <String, dynamic>{
      'description': instance.description,
      'status': instance.status,
      'assignedUserId': instance.assignedUserId,
      'assignedUserName': instance.assignedUserName,
    };

_PlanChapter _$PlanChapterFromJson(Map<String, dynamic> json) => _PlanChapter(
      title: json['title'] as String,
      overview: json['overview'] as String,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => PlanTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PlanTask>[],
    );

Map<String, dynamic> _$PlanChapterToJson(_PlanChapter instance) =>
    <String, dynamic>{
      'title': instance.title,
      'overview': instance.overview,
      'tasks': instance.tasks,
    };

_ProjectPlan _$ProjectPlanFromJson(Map<String, dynamic> json) => _ProjectPlan(
      overview: json['overview'] as String,
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => PlanChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PlanChapter>[],
    );

Map<String, dynamic> _$ProjectPlanToJson(_ProjectPlan instance) =>
    <String, dynamic>{
      'overview': instance.overview,
      'chapters': instance.chapters,
    };
