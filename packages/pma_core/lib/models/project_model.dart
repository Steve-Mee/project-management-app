// ignore_for_file: prefer_const_constructors, invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/config/ai_config.dart';
import 'comment_model.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

/// Project data model for dashboard display
@freezed
@HiveType(typeId: 0)
abstract class ProjectModel with _$ProjectModel {
  const ProjectModel._();

  static const Uuid _uuid = Uuid();

  const factory ProjectModel({
    @HiveField(0)
    @JsonKey(fromJson: _parseId)
    required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double progress,
    @HiveField(3) String? directoryPath,
    @HiveField(5) @Default('In Progress') String status,
    @HiveField(6) String? description,
    @HiveField(9) String? category,
    @HiveField(10) String? aiAssistant,
    @HiveField(11) String? planJson,
    @HiveField(12)
    @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
    @Default(HelpLevel.basis)
    HelpLevel helpLevel,
    @HiveField(13)
    @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
    @Default(Complexity.simpel)
    Complexity complexity,
    /// Change history for auditing and compliance
    /// Each entry contains: {'change': description, 'user': anonymous_id, 'time': timestamp}
    /// COMPLIANCE: History logs changes anonymously per worldwide privacy laws.
    /// Only aggregate change data is retained; no personal data is stored.
    @HiveField(14)
    @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> history,
    @HiveField(7) @Default(<String>[]) List<String> sharedUsers,
    @HiveField(8) @Default(<String>[]) List<String> sharedGroups,
    @HiveField(15) String? priority,
    @HiveField(16) DateTime? startDate,
    @HiveField(17) DateTime? dueDate,
    @HiveField(18) @Default(<String>[]) List<String> tags,
    @HiveField(19) Map<String, dynamic>? customFields,
    @HiveField(20) @Default(<CommentModel>[]) List<CommentModel> comments,
  }) = _ProjectModel;

  /// Factory for creating a project with a guaranteed UUID.
  factory ProjectModel.create({
    String? id,
    required String name,
    required double progress,
    String? directoryPath,
    String status = 'In Progress',
    String? description,
    String? category,
    String? aiAssistant,
    String? planJson,
    HelpLevel helpLevel = HelpLevel.basis,
    Complexity complexity = Complexity.simpel,
    List<Map<String, dynamic>> history = const [],
    List<String> sharedUsers = const [],
    List<String> sharedGroups = const [],
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
    List<String> tags = const [],
    Map<String, dynamic>? customFields,
    List<CommentModel> comments = const [],
  }) {
    final resolvedId = (id == null || id.isEmpty) ? _uuid.v4() : id;
    return ProjectModel(
      id: resolvedId,
      name: name,
      progress: progress,
      directoryPath: directoryPath,
      status: status,
      description: description,
      category: category,
      aiAssistant: aiAssistant,
      planJson: planJson,
      helpLevel: helpLevel,
      complexity: complexity,
      history: history,
      sharedUsers: sharedUsers,
      sharedGroups: sharedGroups,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
      tags: tags,
      customFields: customFields,
      comments: comments,
    );
  }

  /// Factory constructor for creating from JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  /// Get the last updated timestamp from project history
  DateTime get lastUpdated {
    if (history.isNotEmpty) {
      final lastEntry = history.last;
      final timeStr = lastEntry['time'] as String?;
      if (timeStr != null) {
        try {
          return DateTime.parse(timeStr);
        } catch (e) {
          // Invalid timestamp, fall back to now
        }
      }
    }
    // No history or invalid, use current time as fallback
    return DateTime.now();
  }
}

HelpLevel _parseHelpLevel(Object? value) {
  return HelpLevelApi.fromApiName(value);
}

String _helpLevelToJson(HelpLevel value) => value.apiName;

Complexity _parseComplexity(Object? value) {
  return ComplexityApi.fromApiName(value);
}

String _complexityToJson(Complexity value) => value.apiName;

String _parseId(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return const Uuid().v4();
}

List<Map<String, dynamic>> _parseHistory(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => entry.map(
              (key, val) => MapEntry(key.toString(), val),
            ))
        .toList();
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _historyToJson(List<Map<String, dynamic>> value) =>
    value;
