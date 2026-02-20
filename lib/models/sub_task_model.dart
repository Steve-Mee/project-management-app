import 'package:hive/hive.dart';

part 'sub_task_model.g.dart';

/// Sub-task model for breaking down tasks into smaller components
@HiveType(typeId: 3)
class SubTask {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String taskId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final bool isCompleted;
  @HiveField(5)
  final String? assignedTo;
  @HiveField(6)
  final DateTime createdAt;

  const SubTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.assignedTo,
    required this.createdAt,
  });

  /// Create a copy with modified fields
  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    String? description,
    bool? isCompleted,
    String? assignedTo,
    DateTime? createdAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'],
      taskId: json['taskId'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      assignedTo: json['assignedTo'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}