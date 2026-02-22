import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment_model.dart';
import '../services/app_logger.dart';

/// Provider for comments on a specific project
final projectCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, projectId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('comments')
      .select()
      .eq('project_id', projectId)
      .order('created_at', ascending: true);

  return response.map((json) => CommentModel.fromJson(json)).toList();
});

/// Provider for comments on a specific task
final taskCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, taskId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('comments')
      .select()
      .eq('task_id', taskId)
      .order('created_at', ascending: true);

  return response.map((json) => CommentModel.fromJson(json)).toList();
});

/// Provider for user profiles (for @mentions)
final userProfilesProvider = FutureProvider<Map<String, String>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('profiles')
      .select('id, username');

  final Map<String, String> userMap = {};
  for (final row in response) {
    final userId = row['id'] as String;
    final username = row['username'] as String?;
    if (username != null) {
      userMap[userId] = username;
      userMap[username] = userId; // Bidirectional mapping
    }
  }

  return userMap;
});

/// Notifier for managing comment operations
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  CommentNotifier() : super(const AsyncValue.data(null));

  Future<void> addComment({
    required String userId,
    String? projectId,
    String? taskId,
    required String text,
    required List<String> mentionedUsers,
  }) async {
    state = const AsyncValue.loading();

    try {
      final supabase = Supabase.instance.client;
      final comment = CommentModel.create(
        userId: userId,
        projectId: projectId,
        taskId: taskId,
        text: text,
        mentionedUsers: mentionedUsers,
      );

      await supabase.from('comments').insert(comment.toJson());

      // Send push notifications to mentioned users
      if (mentionedUsers.isNotEmpty) {
        await _sendMentionNotifications(comment, mentionedUsers);
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _sendMentionNotifications(CommentModel comment, List<String> mentionedUsers) async {
    try {
      final supabase = Supabase.instance.client;

      // Call Supabase Edge Function to send push notifications
      await supabase.functions.invoke('send-push-on-mention', body: {
        'commentId': comment.id,
        'mentionedUsers': mentionedUsers,
        'commentText': comment.text,
        'projectId': comment.projectId,
        'taskId': comment.taskId,
      });
    } catch (e) {
      // Log error but don't fail the comment creation
      AppLogger.instance.e('Failed to send mention notifications: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    state = const AsyncValue.loading();

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('comments').delete().eq('id', commentId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for comment operations
final commentNotifierProvider = StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  return CommentNotifier();
});