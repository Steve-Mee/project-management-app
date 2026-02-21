import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/models/project_model.dart';


/// Model for chat messages
class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String role;
  final DateTime timestamp;
  final bool isSystemMessage;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.role,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  bool get isUser => role == 'user';
}

/// Notifier for managing project chat
class ProjectChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    // Initialize with some sample messages
    return [
      ChatMessage(
        id: '1',
        content: 'Project discussion started',
        senderId: 'system',
        senderName: 'System',
        role: 'system',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isSystemMessage: true,
      ),
    ];
  }

  void addMessage(String content, String senderId, String senderName, String role) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: senderId,
      senderName: senderName,
      role: role,
      timestamp: DateTime.now(),
    );

    state = [...state, message];
  }

  void applySuggestion(String suggestionId) {
    // Logic to apply a suggestion to the project
    addMessage(
      'Suggestion applied: $suggestionId',
      'system',
      'System',
      'system',
    );
  }

  /// Apply AI suggestion to project with full change logging and compliance
  Future<void> applyAiSuggestion(
    String projectId,
    String suggestionContent,
    String userId,
    String userName,
  ) async {
    // Log the application for compliance
    addMessage(
      '🔄 Applying AI suggestion by $userName at ${DateTime.now().toIso8601String()}',
      'system',
      'System',
      'system',
    );

    // The actual application is handled by the widget's _applyAiSuggestions
    // This method ensures modular logging and compliance tracking
  }
}

/// Provider for project chat
final projectChatProvider = NotifierProvider<ProjectChatNotifier, List<ChatMessage>>(
  ProjectChatNotifier.new,
);

/// Project chat widget
class ProjectChat extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectChat({super.key, required this.projectId});

  @override
  ConsumerState<ProjectChat> createState() => _ProjectChatState();
}

class _ProjectChatState extends ConsumerState<ProjectChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(projectChatProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        // Chat header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.chat),
              const SizedBox(width: 8),
              Text(
                'Project Discussion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _showChatHistory(context),
                tooltip: 'Chat History',
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageItem(context, message);
            },
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(currentUser),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(currentUser),
              ),
            ],
          ),
        ),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApplyDialog(context),
                icon: const Icon(Icons.check_circle),
                label: const Text('Pas Toe'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showDiscussDialog(context),
                icon: const Icon(Icons.forum),
                label: const Text('Discuss'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage message) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.maybeWhen(
      data: (user) => user?.username,
      orElse: () => null,
    );
    final isCurrentUser = message.senderId == currentUserId;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isSystemMessage
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : isCurrentUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isSystemMessage)
              Text(
                '${message.senderName} (${message.role})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: message.isSystemMessage
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : isCurrentUser
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white60 : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(dynamic currentUser) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = currentUser;
    if (user == null) return;

    ref.read(projectChatProvider.notifier).addMessage(
      content,
      user.id,
      user.email ?? 'Unknown',
      'member', // Default role
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showChatHistory(BuildContext context) {
    final messages = ref.read(projectChatProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                title: Text(message.senderName),
                subtitle: Text(message.content),
                trailing: Text(_formatTimestamp(message.timestamp)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pas Toe - Apply AI Suggestions'),
        content: const Text(
          'This will apply the latest AI suggestions to the project, update the project model, '
          'and log the changes for compliance. This action cannot be undone.\n\n'
          'Are you sure you want to apply the AI suggestions?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _applyAiSuggestions(context),
            child: const Text('Pas Toe'),
          ),
        ],
      ),
    );
  }

  void _applyAiSuggestions(BuildContext context) async {
    try {
      // Get current user for compliance logging
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUserValue = currentUserAsync.maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
      final currentUser = currentUserValue;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Get the latest AI message as the suggestion to apply
      final messages = ref.read(projectChatProvider);
      final latestAiMessage = messages.lastWhere(
        (msg) => !msg.isSystemMessage && !msg.isUser,
        orElse: () => throw Exception('No AI suggestions found to apply'),
      );

      // Modular apply logic with compliance logging
      await ref.read(projectChatProvider.notifier).applyAiSuggestion(
        widget.projectId,
        latestAiMessage.content,
        currentUser.username,
        currentUser.username, // Using username as display name
      );

      // Get current project
      final projectsAsync = ref.read(projectsProvider);
      final projects = projectsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('Failed to load projects'),
      );

      final project = projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => throw Exception('Project not found'),
      );

      // For now, we'll update the project description with the AI suggestion
      // In a more advanced implementation, this could parse specific changes
      final updatedProject = ProjectModel(
        id: project.id,
        name: project.name,
        progress: project.progress,
        directoryPath: project.directoryPath,
        tasks: project.tasks,
        status: project.status,
        description: latestAiMessage.content, // Apply AI suggestion as new description
        category: project.category,
        aiAssistant: project.aiAssistant,
        planJson: project.planJson,
        helpLevel: project.helpLevel,
        complexity: project.complexity,
        history: project.history,
        sharedUsers: project.sharedUsers,
        sharedGroups: project.sharedGroups,
      );

      // Apply the update with change logging (includes user, time, compliance)
      await ref.read(projectsProvider.notifier).updateProject(
        widget.projectId,
        updatedProject,
        changeDescription: 'AI suggestion applied by ${currentUser.username} at ${DateTime.now().toIso8601String()}: ${latestAiMessage.content.substring(0, 100)}...',
      );

      // Add success message to chat
      ref.read(projectChatProvider.notifier).addMessage(
        '✅ AI suggestion successfully applied to project',
        'system',
        'System',
        'system',
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close apply dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI suggestions applied successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close apply dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply AI suggestions: $e')),
        );
      }
    }
  }

  void _showDiscussDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Discussion'),
        content: const Text('Open discussion about project requirements and implementation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(projectChatProvider.notifier).addMessage(
                'Discussion started about project requirements',
                'system',
                'System',
                'system',
              );
              Navigator.of(context).pop();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
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
      return 'now';
    }
  }
}