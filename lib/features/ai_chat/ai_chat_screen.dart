import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/core/auth/permissions.dart';
import 'package:project_management_app/core/utils/accessibility_helper.dart';
// ai providers are pulled from the general barrel to avoid duplicate definitions
import '../../core/providers/ai_providers.dart' show aiChatProvider;
import '../../core/providers/auth_providers.dart' show hasPermissionProvider;
import '../../models/chat_message_model.dart';

/// AI Chat screen - chat interface for AI interactions
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncChatState = ref.watch(aiChatProvider);
    final canUseAi = ref.watch(hasPermissionProvider(AppPermissions.useAi));

    if (!canUseAi) {
      return Center(
        child: Text(
          l10n.accessDeniedMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return asyncChatState.when(
      data: (chatState) => Column(
        children: [
          // Chat messages
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Text(
                      l10n.noMessagesLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : wrapSemanticList(
                    label: 'AI chat messages list',
                    itemCount: chatState.messages.length,
                    hint: 'Swipe to navigate conversation messages',
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return _buildChatBubble(context, message);
                      },
                    ),
                  ),
          ),

          if (chatState.isLoading)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: const CircularProgressIndicator(),
            ),

          // Message input area
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    textField: true,
                    label: 'AI chat message input',
                    hint: l10n.typeMessageHint,
                    child: TextField(
                      controller: _messageController,
                      enabled: !chatState.isLoading,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Semantics(
                  button: true,
                  label: l10n.sendMessageTooltip,
                  hint: 'Sends the typed message to AI assistant',
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: chatState.isLoading ? null : _sendMessage,
                    tooltip: l10n.sendMessageTooltip,
                    child: labeledIcon(
                      icon: Icons.send,
                      label: l10n.sendMessageTooltip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Semantics(
              container: true,
              label: message.isUser ? 'Your message' : 'AI response',
              value: message.content,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

