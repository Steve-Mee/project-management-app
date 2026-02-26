// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'comment_model.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

/// Task status enum
@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  review,
  @HiveField(3)
  done,
}

/// Task model for project tasks
@freezed
@HiveType(typeId: 2)
abstract class Task with _$Task {
  const Task._();

  @JsonSerializable(explicitToJson: true)
  const factory Task({
    @HiveField(0) @Default('') String id,
    @HiveField(1) @Default('') String projectId,
    @HiveField(2) @Default('') String title,
    @HiveField(3) @Default('') String description,
    @HiveField(4)
    @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
    @Default(TaskStatus.todo)
    TaskStatus status,
    @HiveField(5) @Default('') String assignee,
    @HiveField(6) @JsonKey(fromJson: _createdAtFromJson) required DateTime createdAt,
    @HiveField(7) @JsonKey(fromJson: _dueDateFromJson) DateTime? dueDate,
    @HiveField(8) @Default(0.5) double priority,
    @HiveField(9)
    @JsonKey(
      readValue: _readAttachments,
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson,
    )
    @Default(<String>[])
    List<String> attachments,
    @HiveField(10) @Default(<String>[]) List<String> subTaskIds,
    @HiveField(11) @JsonKey(includeFromJson: false, includeToJson: false) String? userId,
    @HiveField(12) @Default(<CommentModel>[]) List<CommentModel> comments,
  }) = _Task;

  /// Convert status to display string
  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

TaskStatus _taskStatusFromJson(Object? value) {
  final statusValue = value as String? ?? 'todo';
  return TaskStatus.values.firstWhere(
    (item) => item.name == statusValue,
    orElse: () => TaskStatus.todo,
  );
}

String _taskStatusToJson(TaskStatus value) => value.name;

DateTime _createdAtFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _dueDateFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Object? _readAttachments(Map json, String _) =>
    json['attachments'] ?? json['filePaths'];

List<String> _attachmentsFromJson(Object? rawValue) {
  final raw = rawValue;
  if (raw is List) {
    return raw.whereType<String>().toList();
  }
  return const [];
}

List<String> _attachmentsToJson(List<String> attachments) => attachments;
