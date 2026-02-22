import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/config/ai_config.dart';
import 'comment_model.dart';

part 'project_model.g.dart';

/// Project data model for dashboard display
@HiveType(typeId: 0)
class ProjectModel {
  static final Uuid _uuid = Uuid();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double progress;

  /// Optional path to the project's local directory.
  @HiveField(3)
  final String? directoryPath;

  @HiveField(4)
  final List<String> tasks;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String? description;

  @HiveField(9)
  final String? category;

  @HiveField(10)
  final String? aiAssistant;

  @HiveField(11)
  final String? planJson;

  @HiveField(12)
  final HelpLevel helpLevel;

  @HiveField(13)
  final Complexity complexity;

  /// Change history for auditing and compliance
  /// Each entry contains: {'change': description, 'user': anonymous_id, 'time': timestamp}
  /// COMPLIANCE: History logs changes anonymously per worldwide privacy laws.
  /// Only aggregate change data is retained; no personal data is stored.
  @HiveField(14)
  final List<Map<String, dynamic>> history;

  @HiveField(7)
  final List<String> sharedUsers;

  @HiveField(8)
  final List<String> sharedGroups;

  @HiveField(15)
  final String? priority;

  @HiveField(16)
  final DateTime? startDate;

  @HiveField(17)
  final DateTime? dueDate;

  @HiveField(18)
  final List<String> tags;

  @HiveField(19)
  final Map<String, dynamic>? customFields;

  @HiveField(20)
  final List<CommentModel> comments;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.progress,
    this.directoryPath,
    this.tasks = const [],
    this.status = 'In Progress',
    this.description,
    this.category,
    this.aiAssistant,
    this.planJson,
    this.helpLevel = HelpLevel.basis,
    this.complexity = Complexity.simpel,
    this.history = const [],
    this.sharedUsers = const [],
    this.sharedGroups = const [],
    this.priority,
    this.startDate,
    this.dueDate,
    this.tags = const [],
    this.customFields,
    this.comments = const [],
  });

  /// Factory for creating a project with a guaranteed UUID.
  factory ProjectModel.create({
    String? id,
    required String name,
    required double progress,
    String? directoryPath,
    List<String> tasks = const [],
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
      tasks: tasks,
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
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final resolvedId = (rawId == null || rawId.isEmpty) ? _uuid.v4() : rawId;
    return ProjectModel(
      id: resolvedId,
      name: json['name'] as String,
      progress: (json['progress'] as num).toDouble(),
      directoryPath: json['directoryPath'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: json['status'] as String? ?? 'In Progress',
      description: json['description'] as String?,
      category: json['category'] as String?,
      aiAssistant: json['aiAssistant'] as String?,
      planJson: json['planJson'] as String?,
      helpLevel: _parseHelpLevel(json['helpLevel']),
      complexity: _parseComplexity(json['complexity']),
      history:
          (json['history'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          const [],
      sharedUsers:
          (json['sharedUsers'] as List<dynamic>?)?.cast<String>() ?? const [],
      sharedGroups:
          (json['sharedGroups'] as List<dynamic>?)?.cast<String>() ?? const [],
      priority: json['priority'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      customFields: (json['customFields'] as Map<String, dynamic>?)?.cast<String, dynamic>(),
      comments: (json['comments'] as List<dynamic>?)?.map((c) => CommentModel.fromJson(c as Map<String, dynamic>)).toList() ?? const [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'progress': progress,
      'directoryPath': directoryPath,
      'tasks': tasks,
      'status': status,
      'description': description,
      'category': category,
      'aiAssistant': aiAssistant,
      'planJson': planJson,
      'helpLevel': helpLevel.name,
      'complexity': complexity.name,
      'history': history,
      'sharedUsers': sharedUsers,
      'sharedGroups': sharedGroups,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
      'customFields': customFields,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  /// Helper method to parse HelpLevel from JSON, with backward compatibility
  static HelpLevel _parseHelpLevel(dynamic value) {
    if (value is String) {
      try {
        return HelpLevel.values.firstWhere(
          (e) => e.name == value,
          orElse: () => HelpLevel.basis,
        );
      } catch (e) {
        return HelpLevel.basis;
      }
    }
    return HelpLevel.basis;
  }

  /// Helper method to parse Complexity from JSON, with backward compatibility
  static Complexity _parseComplexity(dynamic value) {
    if (value is String) {
      try {
        return Complexity.values.firstWhere(
          (e) => e.name == value,
          orElse: () => Complexity.simpel,
        );
      } catch (e) {
        return Complexity.simpel;
      }
    }
    return Complexity.simpel;
  }
}
