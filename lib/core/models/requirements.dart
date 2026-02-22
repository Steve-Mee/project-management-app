enum RequirementStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case RequirementStatus.pending:
        return 'Pending';
      case RequirementStatus.inProgress:
        return 'In Progress';
      case RequirementStatus.completed:
        return 'Completed';
      case RequirementStatus.cancelled:
        return 'Cancelled';
    }
  }

  static RequirementStatus fromString(String value) {
    return RequirementStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequirementStatus.pending,
    );
  }
}

enum RequirementPriority {
  low,
  medium,
  high,
  urgent;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case RequirementPriority.low:
        return 'Low';
      case RequirementPriority.medium:
        return 'Medium';
      case RequirementPriority.high:
        return 'High';
      case RequirementPriority.urgent:
        return 'Urgent';
    }
  }

  static RequirementPriority fromString(String value) {
    return RequirementPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequirementPriority.medium,
    );
  }
}

class Requirement {
  final String id;
  final String title;
  final RequirementStatus status;
  final RequirementPriority priority;

  const Requirement({
    required this.id,
    required this.title,
    this.status = RequirementStatus.pending,
    this.priority = RequirementPriority.medium,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status.name,
        'priority': priority.name,
      };

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      id: json['id'] as String,
      title: json['title'] as String,
      status: RequirementStatus.fromString(json['status'] as String? ?? 'pending'),
      priority: RequirementPriority.fromString(json['priority'] as String? ?? 'medium'),
    );
  }
}