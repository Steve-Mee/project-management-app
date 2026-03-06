import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/providers/comment_providers.dart';
import 'package:pma_core/providers/auth_providers.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:project_management_app/generated/app_localizations.dart';

/// Widget for displaying and adding comments with @mention support
/// Implements issue 045: UI enhancements - mention autocomplete
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
  
  // Autocomplete state
  List<AppUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
  }

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
    
    // Watch all users for mention suggestions
    final List<AppUser> allUsers = ref.watch(searchUsersProvider(''));
    _allUsers = allUsers;

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
            child: RawAutocomplete<String>(
              textEditingController: _commentController,
              focusNode: _focusNode,
              optionsBuilder: _buildAutocompleteOptions,
              displayStringForOption: (option) => option,
              onSelected: _onAutocompleteSelected,
              fieldViewBuilder: _buildAutocompleteField,
              optionsViewBuilder: _buildAutocompleteOptionsView,
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

  Iterable<String> _buildAutocompleteOptions(TextEditingValue textEditingValue) {
    // Issue 045: Detect @ character and provide user suggestions
    final text = textEditingValue.text;
    
    // Only show suggestions if there's an @ and we're at the end of a word starting with @
    final cursorPosition = textEditingValue.selection.baseOffset;
    if (cursorPosition == -1) return [];
    
    // Find the last @ before cursor
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) return [];
    
    // Check if we're still in the mention (no space after @)
    final afterAt = beforeCursor.substring(lastAtIndex + 1);
    if (afterAt.contains(' ')) return [];
    
    final query = afterAt.toLowerCase();
    
    // Filter and sort users by relevance
    final filteredUsers = _allUsers
        .where((user) => user.username.toLowerCase().contains(query))
        .map((user) => user.username)
        .toList();
    
    // Sort by relevance: exact matches first, then prefix matches, then contains
    filteredUsers.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      // Exact match gets highest priority
      if (aLower == query) return -1;
      if (bLower == query) return 1;
      
      // Prefix match gets higher priority
      final aStarts = aLower.startsWith(query);
      final bStarts = bLower.startsWith(query);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      
      // Alphabetical sort as tiebreaker
      return a.compareTo(b);
    });
    
    // Limit to 8 suggestions
    final suggestions = filteredUsers.take(8).toList();
    
    // Log when suggestions are loaded (Issue 045)
    if (suggestions.isNotEmpty) {
      AppLogger.debug('mention_suggestions_loaded', params: {
        'count': suggestions.length,
        'query': query,
      });
    }
    
    return suggestions;
  }

  Widget _buildAutocompleteField(BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
      minLines: 1,
      maxLength: 1000,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.addCommentHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        contentPadding: EdgeInsets.all(12.w),
      ),
    );
  }

  Widget _buildAutocompleteOptionsView(BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    if (options.isEmpty) return const SizedBox.shrink();
    
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 300.w),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final username = options.elementAt(index);
              
              return ListTile(
                leading: CircleAvatar(
                  radius: 16.r,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                title: Text(username),
                onTap: () => onSelected(username),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onAutocompleteSelected(String username) {
    final text = _commentController.text;
    final cursorPosition = _commentController.selection.baseOffset;
    
    if (cursorPosition == -1) return;
    
    // Find the last @ before cursor
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) return;
    
    // Replace from @ to cursor with @username
    final newText = '${text.substring(0, lastAtIndex)}@$username ${text.substring(cursorPosition)}';
    _commentController.text = newText;
    
    // Move cursor after the inserted username
    _commentController.selection = TextSelection.collapsed(offset: lastAtIndex + username.length + 2);
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
    final authState = ref.watch(authProvider).value!;

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

    return _buildRichTextWithMentions(context, resolvedText, userProfiles);
  }

  Widget _buildRichTextWithMentions(BuildContext context, String text, Map<String, String> userProfiles) {
    // Issue 045: Render @mentions as clickable blue links in displayed comments
    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before the mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: Theme.of(context).textTheme.bodyMedium,
        ));
      }
      
      // Add the clickable mention
      final username = match.group(1)!;
      final userId = userProfiles.keys.firstWhere(
        (key) => userProfiles[key] == username,
        orElse: () => '',
      );
      
      spans.add(TextSpan(
        text: '@$username',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _onMentionTap(context, username, userId),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: Theme.of(context).textTheme.bodyMedium,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _onMentionTap(BuildContext context, String username, String userId) {
    // Issue 045: Navigate to user profile (placeholder dialog until profile screen exists)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User: $username'),
        content: Text('User ID: $userId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider).value!;
    if (!authState.isAuthenticated || authState.username == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Issue 045: Parse @mentions from comment text and store user IDs
      final mentionedUsernames = CommentModel.parseMentions(text);
      final userProfiles = await ref.read(userProfilesProvider.future);
      final mentionedUsers = mentionedUsernames
          .map((username) => userProfiles[username]) // username -> userId
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

      // Log event if mentions were included (Issue 045)
      if (mentionedUsers.isNotEmpty) {
        AppLogger.event('comment_with_mentions_saved', params: {
          'mentionCount': mentionedUsers.length,
          'mentionedUsers': mentionedUsers,
          'projectId': widget.projectId,
          'taskId': widget.taskId,
        });
      }

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
