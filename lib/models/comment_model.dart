// ignore_for_file: prefer_const_constructors, invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

/// Comment model for project and task comments with @mentions
@freezed
@HiveType(typeId: 3)
abstract class CommentModel with _$CommentModel {
  const CommentModel._();

  static const Uuid _uuid = Uuid();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CommentModel({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) String? projectId,
    @HiveField(3) String? taskId,
    @HiveField(4) required String text,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) @Default(<String>[]) List<String> mentionedUsers,
    @HiveField(7) @Default(false) bool isEdited,
    @HiveField(8) DateTime? editedAt,
  }) = _CommentModel;

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

  /// Create from JSON (Supabase)
  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

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
