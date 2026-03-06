// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'requirements.freezed.dart';
part 'requirements.g.dart';

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

@freezed
abstract class Requirement with _$Requirement {
  const factory Requirement({
    required String id,
    required String title,
    @JsonKey(fromJson: _requirementStatusFromJson, toJson: _requirementStatusToJson)
    @Default(RequirementStatus.pending)
    RequirementStatus status,
    @JsonKey(fromJson: _requirementPriorityFromJson, toJson: _requirementPriorityToJson)
    @Default(RequirementPriority.medium)
    RequirementPriority priority,
  }) = _Requirement;

  factory Requirement.fromJson(Map<String, dynamic> json) =>
      _$RequirementFromJson(json);
}

RequirementStatus _requirementStatusFromJson(String? value) =>
    RequirementStatus.fromString(value ?? 'pending');

String _requirementStatusToJson(RequirementStatus value) => value.name;

RequirementPriority _requirementPriorityFromJson(String? value) =>
    RequirementPriority.fromString(value ?? 'medium');

String _requirementPriorityToJson(RequirementPriority value) => value.name;
