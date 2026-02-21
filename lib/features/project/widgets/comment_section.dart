import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project_management_app/models/comment_model.dart';
import 'package:my_project_management_app/core/providers/comment_providers.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Widget for displaying and adding comments with @mention support
class CommentSection extends ConsumerStatefulWidget {
  final String? projectId;
  final String? taskId;

  const CommentSection({
    super.key,
    this.projectId,
    this.taskId,
  }) : assert(projectId != null || taskId != null, 'Either projectId or taskId must be provided');

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = widget.projectId != null
        ? ref.watch(projectCommentsProvider(widget.projectId!))
        : ref.watch(taskCommentsProvider(widget.taskId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            l10n.commentsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Comment input
        _buildCommentInput(context, l10n),

        // Comments list
        commentsAsync.when(
          data: (comments) => _buildCommentsList(context, comments, l10n),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading comments: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 1,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.addCommentHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
              onChanged: (text) {
                // TODO: Implement @mention autocomplete
              },
            ),
          ),
          SizedBox(width: 8.w),
          FloatingActionButton.small(
            onPressed: _isSubmitting ? null : () => _submitComment(),
            child: _isSubmitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context, List<CommentModel> comments, AppLocalizations l10n) {
    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32.w),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.noCommentsYet,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(context, comment, l10n);
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, CommentModel comment, AppLocalizations l10n) {
    final userProfilesAsync = ref.watch(userProfilesProvider);
    final authState = ref.watch(authProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 16.r,
            child: Text(
              _getUserInitials(comment.userId, userProfilesAsync.value ?? {}),
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 12.w),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and timestamp
                Row(
                  children: [
                    Text(
                      _getUsername(comment.userId, userProfilesAsync.value ?? {}),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (comment.isEdited) ...[
                      SizedBox(width: 4.w),
                      Text(
                        l10n.editedLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),

                // Comment text with @mentions highlighted
                _buildCommentText(context, comment),

                // Mentioned users indicator
                if (comment.mentionedUsers.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      '${l10n.mentionedLabel}: ${_getMentionedUsernames(comment.mentionedUsers, userProfilesAsync.value ?? {})}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Delete button (only for comment author)
          if (authState.username == comment.userId)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20.sp),
              onPressed: () => _deleteComment(comment.id),
              tooltip: l10n.deleteCommentTooltip,
            ),
        ],
      ),
    );
  }

  Widget _buildCommentText(BuildContext context, CommentModel comment) {
    final userProfiles = ref.watch(userProfilesProvider).value ?? {};
    final resolvedText = comment.resolveMentions(userProfiles);

    return Text(
      resolvedText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.username == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Parse @mentions
      final mentionedUsernames = CommentModel.parseMentions(text);
      final userProfiles = await ref.read(userProfilesProvider.future);
      final mentionedUsers = mentionedUsernames
          .map((username) => userProfiles[username])
          .where((userId) => userId != null)
          .cast<String>()
          .toList();

      await ref.read(commentNotifierProvider.notifier).addComment(
        userId: authState.username!,
        projectId: widget.projectId,
        taskId: widget.taskId,
        text: text,
        mentionedUsers: mentionedUsers,
      );

      _commentController.clear();
      _focusNode.unfocus();

      // Refresh comments
      if (widget.projectId != null) {
        ref.invalidate(projectCommentsProvider(widget.projectId!));
      } else if (widget.taskId != null) {
        ref.invalidate(taskCommentsProvider(widget.taskId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(commentNotifierProvider.notifier).deleteComment(commentId);

      // Refresh comments
      if (widget.projectId != null) {
        ref.invalidate(projectCommentsProvider(widget.projectId!));
      } else if (widget.taskId != null) {
        ref.invalidate(taskCommentsProvider(widget.taskId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  String _getUserInitials(String userId, Map<String, String> userProfiles) {
    final username = userProfiles[userId] ?? userId;
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  String _getUsername(String userId, Map<String, String> userProfiles) {
    return userProfiles[userId] ?? 'Unknown User';
  }

  String _getMentionedUsernames(List<String> userIds, Map<String, String> userProfiles) {
    return userIds.map((id) => '@${userProfiles[id] ?? 'unknown'}').join(', ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}