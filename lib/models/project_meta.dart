enum UrgencyLevel {
  low,
  medium,
  high,
}

extension UrgencyLevelX on UrgencyLevel {
  String get label {
    switch (this) {
      case UrgencyLevel.low:
        return 'Laag';
      case UrgencyLevel.medium:
        return 'Normaal';
      case UrgencyLevel.high:
        return 'Hoog';
    }
  }

  int get weight {
    switch (this) {
      case UrgencyLevel.low:
        return 1;
      case UrgencyLevel.medium:
        return 2;
      case UrgencyLevel.high:
        return 3;
    }
  }
}

class ProjectMeta {
  final String projectId;
  final UrgencyLevel urgency;
  final int trackedSeconds;

  const ProjectMeta({
    required this.projectId,
    required this.urgency,
    required this.trackedSeconds,
  });

  factory ProjectMeta.fromMap(String projectId, Map<String, dynamic> map) {
    final urgencyValue = map['urgency'] as String?;
    final urgency = UrgencyLevel.values.firstWhere(
      (value) => value.name == urgencyValue,
      orElse: () => UrgencyLevel.medium,
    );
    final trackedSeconds = map['trackedSeconds'] as int? ?? 0;
    return ProjectMeta(
      projectId: projectId,
      urgency: urgency,
      trackedSeconds: trackedSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'urgency': urgency.name,
      'trackedSeconds': trackedSeconds,
    };
  }

  ProjectMeta copyWith({
    UrgencyLevel? urgency,
    int? trackedSeconds,
  }) {
    return ProjectMeta(
      projectId: projectId,
      urgency: urgency ?? this.urgency,
      trackedSeconds: trackedSeconds ?? this.trackedSeconds,
    );
  }

  static ProjectMeta defaultFor(String projectId) {
    return ProjectMeta(
      projectId: projectId,
      urgency: UrgencyLevel.medium,
      trackedSeconds: 0,
    );
  }
}
