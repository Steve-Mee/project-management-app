/// Model for project plan tasks
class PlanTask {
  final String description;
  final String status; // 'pending', 'in_progress', 'completed'
  final String? assignedUserId;
  final String? assignedUserName;

  const PlanTask({
    required this.description,
    this.status = 'pending',
    this.assignedUserId,
    this.assignedUserName,
  });

  PlanTask copyWith({
    String? description,
    String? status,
    String? assignedUserId,
    String? assignedUserName,
  }) {
    return PlanTask(
      description: description ?? this.description,
      status: status ?? this.status,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      assignedUserName: assignedUserName ?? this.assignedUserName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'status': status,
      'assignedUserId': assignedUserId,
      'assignedUserName': assignedUserName,
    };
  }

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      description: json['description'] as String,
      status: json['status'] as String? ?? 'pending',
      assignedUserId: json['assignedUserId'] as String?,
      assignedUserName: json['assignedUserName'] as String?,
    );
  }
}

/// Model for project plan chapters
class PlanChapter {
  final String title;
  final String overview;
  final List<PlanTask> tasks;

  const PlanChapter({
    required this.title,
    required this.overview,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'overview': overview,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory PlanChapter.fromJson(Map<String, dynamic> json) {
    return PlanChapter(
      title: json['title'] as String,
      overview: json['overview'] as String,
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((t) => PlanTask.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Model for complete project plan
class ProjectPlan {
  final String overview;
  final List<PlanChapter> chapters;

  const ProjectPlan({
    required this.overview,
    required this.chapters,
  });

  Map<String, dynamic> toJson() {
    return {
      'overview': overview,
      'chapters': chapters.map((c) => c.toJson()).toList(),
    };
  }

  factory ProjectPlan.fromJson(Map<String, dynamic> json) {
    return ProjectPlan(
      overview: json['overview'] as String,
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((c) => PlanChapter.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}