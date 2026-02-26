// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'sub_task_model.freezed.dart';
part 'sub_task_model.g.dart';

/// Sub-task model for breaking down tasks into smaller components
@freezed
@HiveType(typeId: 4)
abstract class SubTask with _$SubTask {
  const factory SubTask({
    @HiveField(0) required String id,
    @HiveField(1) required String taskId,
    @HiveField(2) required String title,
    @HiveField(3) required String description,
    @HiveField(4) @Default(false) bool isCompleted,
    @HiveField(5) String? assignedTo,
    @HiveField(6) required DateTime createdAt,
  }) = _SubTask;

  factory SubTask.fromJson(Map<String, dynamic> json) =>
      _$SubTaskFromJson(json);
}
