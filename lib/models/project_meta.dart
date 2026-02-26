import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_meta.freezed.dart';
part 'project_meta.g.dart';

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

@freezed
abstract class ProjectMeta with _$ProjectMeta {
  const ProjectMeta._();

  const factory ProjectMeta({
    required String projectId,
    required UrgencyLevel urgency,
    required int trackedSeconds,
  }) = _ProjectMeta;

  factory ProjectMeta.fromJson(Map<String, dynamic> json) =>
      _$ProjectMetaFromJson(json);

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

  static ProjectMeta defaultFor(String projectId) {
    return ProjectMeta(
      projectId: projectId,
      urgency: UrgencyLevel.medium,
      trackedSeconds: 0,
    );
  }
}
