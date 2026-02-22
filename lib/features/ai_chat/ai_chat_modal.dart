import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
// bring in only the necessary providers to avoid name clashes
import '../../core/providers/ai/index.dart' show aiChatProvider, useProjectFilesProvider, AiChatState;
import '../../core/providers/auth_providers.dart' show privacyConsentProvider;
import '../../core/providers/project_providers.dart' show projectsProvider;
import '../../core/services/project_file_service.dart';
import '../../models/chat_message_model.dart';

/// AI Chat Modal - Dialog/Drawer with chat interface
class AiChatModal extends ConsumerStatefulWidget {
  final String? projectId;

  const AiChatModal({super.key, this.projectId});

  @override
  ConsumerState<AiChatModal> createState() => _AiChatModalState();
}

class _AiChatModalState extends ConsumerState<AiChatModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ProjectFileService _fileService = ProjectFileService();
  bool _isErrorDialogVisible = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _sendMessageWithText(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendMessageWithText(String message) async {
    final includeProjectFiles = ref.read(useProjectFilesProvider);
    final prompt = await _buildPrompt(message, includeProjectFiles);

    await ref
        .read(aiChatProvider.notifier)
        .sendMessage(
          message,
          promptOverride: prompt,
          projectId: widget.projectId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncChatState = ref.watch(aiChatProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dialogHeight = MediaQuery.of(context).size.height * 0.65 - keyboardHeight.clamp(0, 200);

    return asyncChatState.when(
      data: (chatState) {
        if (chatState.error != null && !_isErrorDialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(chatState.error!);
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            width: double.infinity,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Chat messages and input
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: _buildMessagesList(chatState),
                      ),
                      _buildInputField(chatState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  /// Build header with title and close button
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            label: l10n.aiChatSemanticsLabel,
            child: Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              l10n.aiAssistantTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.white, size: 20.sp),
            tooltip: l10n.clearChatTooltip,
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
            tooltip: l10n.closeButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Build messages list with chat bubbles
  Widget _buildMessagesList(AiChatState chatState) {
    final l10n = AppLocalizations.of(context)!;
    if (chatState.messages.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: l10n.noMessagesLabel,
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48.sp,
                    color: Theme.of(context)
                        .colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.aiEmptyTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  l10n.aiEmptySubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      children: [
        ...chatState.messages.map((message) => _buildMessageRow(message)),
        if (chatState.isLoading) _buildTypingIndicator(),
      ],
    );
  }

  /// Build message row with avatar and bubble
  Widget _buildMessageRow(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.isUser ? [
          // User message: bubble first, then avatar
          Flexible(
            child: _buildMessageBubble(message),
          ),
          SizedBox(width: 8.w),
          _buildAvatar(message.isUser),
        ] : [
          // AI message: avatar first, then bubble
          _buildAvatar(message.isUser),
          SizedBox(width: 8.w),
          Flexible(
            child: _buildMessageBubble(message),
          ),
        ],
      ),
    );
  }

  /// Build message bubble container
  Widget _buildMessageBubble(ChatMessage message) {
    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: message.isUser
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: message.isUser
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14.sp,
            ),
            maxLines: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  /// Build avatar for user/AI
  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 16.sp,
      ),
    );
  }

  /// Build typing indicator with SpinKit
  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(false),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SpinKitThreeBounce(
              color: Theme.of(context).colorScheme.primary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Build input field with send button
  Widget _buildInputField(AiChatState chatState) {
    final l10n = AppLocalizations.of(context)!;
    final includeProjectFiles = ref.watch(useProjectFilesProvider);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Switch(
                      value: includeProjectFiles,
                      onChanged: chatState.isLoading
                          ? null
                          : (value) {
                              ref
                                  .read(useProjectFilesProvider.notifier)
                                  .setEnabled(value);
                            },
                    ),
                    Expanded(
                      child: Text(
                        l10n.useProjectFilesLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !chatState.isLoading,
                        decoration: InputDecoration(
                          hintText: l10n.typeMessageHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          isDense: true,
                        ),
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: Icon(
                          chatState.isLoading
                              ? Icons.hourglass_empty
                              : Icons.send,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        onPressed: chatState.isLoading ? null : _sendMessage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _buildPrompt(
    String userInput,
    bool includeProjectFiles,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!includeProjectFiles) {
      return userInput;
    }

    final allowRead = await _showPrivacyWarningDialog();
    if (!allowRead) {
      return userInput;
    }

    final consentEnabled = ref.read(privacyConsentProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );
    if (!consentEnabled) {
      _showSnackBar(l10n.enableConsentInSettings);
      return userInput;
    }

    final projectInfo = _getLinkedProjectInfo();
    final directoryPath = projectInfo?.directoryPath;
    if (directoryPath == null || directoryPath.isEmpty) {
      return userInput;
    }

    try {
      // Read a limited set of project files to enrich the prompt.
      final contents = await _fileService.readAllTextFiles(directoryPath);
      if (contents.isEmpty) {
        return userInput;
      }

      final projectName = projectInfo?.name ?? l10n.unknownProject;
      final combined = contents
          .map(
            (entry) =>
                'Project: $projectName\nFile: ${entry.name}\n${entry.content}',
          )
          .join('\n\n');

      return 'Bouw verder op: $combined\n\nUser: $userInput';
    } catch (_) {
      _showSnackBar(l10n.projectFilesReadFailed);
      return userInput;
    }
  }

  _ProjectInfo? _getLinkedProjectInfo() {
    final projectsState = ref.read(projectsProvider);
    return projectsState.maybeWhen(
      data: (projects) {
        final projectId = widget.projectId;
        if (projectId != null) {
          final project = _firstWhereOrNull(
            projects,
            (item) => item.id == projectId,
          );
          if (project == null) {
            return null;
          }

          final path = project.directoryPath;
          return (path != null && path.isNotEmpty)
              ? _ProjectInfo(name: project.name, directoryPath: path)
              : null;
        }

        final project = _firstWhereOrNull(
          projects,
          (item) => (item.directoryPath?.isNotEmpty ?? false),
        );
        if (project == null) {
          return null;
        }

        return _ProjectInfo(
          name: project.name,
          directoryPath: project.directoryPath!,
        );
      },
      orElse: () => null,
    );
  }

  T? _firstWhereOrNull<T>(
    Iterable<T> items,
    bool Function(T item) test,
  ) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }

    return null;
  }

  /// Format timestamp to readable time
  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showErrorDialog(String error) async {
    final l10n = AppLocalizations.of(context)!;
    _isErrorDialogVisible = true;

    final retryMessage = _lastUserMessage();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.aiResponseFailedTitle),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(aiChatProvider.notifier).clearChat();
                Navigator.of(context).pop();
              },
              child: Text(l10n.closeButton),
            ),
            TextButton(
              onPressed: retryMessage == null
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _sendMessageWithText(retryMessage);
                    },
              child: Text(l10n.retryButton),
            ),
          ],
        );
      },
    );

    _isErrorDialogVisible = false;
  }

  String? _lastUserMessage() {
    final asyncState = ref.read(aiChatProvider);
    if (asyncState.hasValue) {
      final messages = asyncState.value!.messages;
      for (var i = messages.length - 1; i >= 0; i -= 1) {
        final message = messages[i];
        if (message.isUser) {
          return message.content;
        }
      }
    }
    return null;
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showPrivacyWarningDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.privacyWarningTitle),
          content: Text(l10n.privacyWarningContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.continueButton),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class _ProjectInfo {
  final String name;
  final String directoryPath;

  const _ProjectInfo({
    required this.name,
    required this.directoryPath,
  });
}
