import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'comment_model.g.dart';

/// Comment model for project and task comments with @mentions
@HiveType(typeId: 3)
class CommentModel {
  static final Uuid _uuid = Uuid();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? projectId;

  @HiveField(3)
  final String? taskId;

  @HiveField(4)
  final String text;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final List<String> mentionedUsers; // User IDs mentioned with @

  @HiveField(7)
  final bool isEdited;

  @HiveField(8)
  final DateTime? editedAt;

  const CommentModel({
    required this.id,
    required this.userId,
    this.projectId,
    this.taskId,
    required this.text,
    required this.createdAt,
    this.mentionedUsers = const [],
    this.isEdited = false,
    this.editedAt,
  });

  /// Factory for creating a comment with a guaranteed UUID
  factory CommentModel.create({
    String? id,
    required String userId,
    String? projectId,
    String? taskId,
    required String text,
    List<String> mentionedUsers = const [],
  }) {
    final resolvedId = (id == null || id.isEmpty) ? _uuid.v4() : id;
    return CommentModel(
      id: resolvedId,
      userId: userId,
      projectId: projectId,
      taskId: taskId,
      text: text,
      createdAt: DateTime.now(),
      mentionedUsers: mentionedUsers,
    );
  }

  /// Create a copy with modified fields
  CommentModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? taskId,
    String? text,
    DateTime? createdAt,
    List<String>? mentionedUsers,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'task_id': taskId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'mentioned_users': mentionedUsers,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase)
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      taskId: json['task_id'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      mentionedUsers: (json['mentioned_users'] as List<dynamic>?)?.cast<String>() ?? const [],
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
    );
  }

  /// Parse @mentions from text and return list of mentioned usernames
  static List<String> parseMentions(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Replace @mentions with usernames in text for display
  String resolveMentions(Map<String, String> userIdToUsername) {
    String resolvedText = text;
    for (final userId in mentionedUsers) {
      final username = userIdToUsername[userId];
      if (username != null) {
        resolvedText = resolvedText.replaceAll('@$userId', '@$username');
      }
    }
    return resolvedText;
  }
}