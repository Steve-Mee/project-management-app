import 'package:hive/hive.dart';

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
@HiveType(typeId: 2)
class Task {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final TaskStatus status;
  @HiveField(5)
  final String assignee;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime? dueDate;
  @HiveField(8)
  final double priority; // 0.0 to 1.0
  @HiveField(9)
  final List<String> attachments;
  @HiveField(10)
  final List<String> subTaskIds; // IDs of sub-tasks
  @HiveField(11)
  final String? userId; // Creator/owner of the task

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.assignee,
    required this.createdAt,
    this.dueDate,
    this.priority = 0.5,
    this.attachments = const [],
    this.subTaskIds = const [],
    this.userId,
  });

  /// Create a copy with modified fields
  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    String? assignee,
    DateTime? createdAt,
    DateTime? dueDate,
    double? priority,
    List<String>? attachments,
    List<String>? subTaskIds,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      subTaskIds: subTaskIds ?? this.subTaskIds,
      userId: userId ?? this.userId,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.name,
      'assignee': assignee,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'attachments': attachments,
      'subTaskIds': subTaskIds,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'] as String? ?? 'todo';
    final attachments = _parseAttachments(json);
    return Task(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (item) => item.name == statusValue,
        orElse: () => TaskStatus.todo,
      ),
      assignee: json['assignee'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      priority: (json['priority'] as num?)?.toDouble() ?? 0.5,
      attachments: attachments,
      subTaskIds: (json['subTaskIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  static List<String> _parseAttachments(Map<String, dynamic> json) {
    final raw = json['attachments'] ?? json['filePaths'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  }
}
