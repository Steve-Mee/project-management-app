import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart' show projectsProvider;
import 'package:my_project_management_app/core/providers/auth_providers.dart' show currentUserProvider;
import 'package:my_project_management_app/core/providers/ai/ai_chat_provider.dart' show aiChatProvider, aiHelpLevelProvider;
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/core/providers/task_provider.dart';
import 'package:my_project_management_app/core/repository/auth_repository.dart';
import 'package:my_project_management_app/core/config/ai_config.dart';
import 'package:my_project_management_app/core/services/ai_planning_helpers.dart';

/// Model for chat history entries
class ChatHistoryEntry {
  final String id;
  final String action;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ChatHistoryEntry({
    required this.id,
    required this.action,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    this.metadata,
  });
}

/// Notifier for managing chat history
class ChatHistoryNotifier extends Notifier<List<ChatHistoryEntry>> {
  @override
  List<ChatHistoryEntry> build() {
    return [];
  }

  void addEntry(String action, String userId, String userName, String userRole, [Map<String, dynamic>? metadata]) {
    final entry = ChatHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      userId: userId,
      userName: userName,
      userRole: userRole,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    state = [...state, entry];
  }
}

/// Provider for chat history
final chatHistoryProvider = NotifierProvider<ChatHistoryNotifier, List<ChatHistoryEntry>>(
  ChatHistoryNotifier.new,
);

/// AI Chat Bottom Sheet for project assistance
class AiChatBottomSheet extends ConsumerStatefulWidget {
  final String projectId;

  const AiChatBottomSheet({super.key, required this.projectId});

  @override
  ConsumerState<AiChatBottomSheet> createState() => _AiChatBottomSheetState();
}

class _AiChatBottomSheetState extends ConsumerState<AiChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _lastAiResponse;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final history = ref.watch(chatHistoryProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    // Update last AI response when chat state changes
    if (chatState.messages.isNotEmpty && _isLoading) {
      final lastMessage = chatState.messages.last;
      if (!lastMessage.isUser) {
        _lastAiResponse = lastMessage.content;
        setState(() {
          _isLoading = false;
        });
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.smart_toy),
              const SizedBox(width: 8),
              Text(
                'AI Project Assistant',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _showHistoryDialog(context, history),
                tooltip: 'View History',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),

          // Chat messages area
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                if (_lastAiResponse != null) ...[
                  _buildAiMessage(_lastAiResponse!),
                  const SizedBox(height: 16),
                ],
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ask me anything about this project...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _showApplyConfirmationDialog(context, currentUserAsync),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Apply Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Grok',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(message),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
      _lastAiResponse = null;
    });

    try {
      final context = await _buildProjectContext();
      final systemPrompt = await _getModularSystemPromptForProject();
      final fullMessage = '$systemPrompt\n\nProject Context:\n$context\n\nUser Question: $message\n\n'
          'Please provide helpful, actionable advice for this project. If suggesting changes, '
          'format them clearly so they can be applied automatically.';

      await ref.read(aiChatProvider.notifier).sendMessage(fullMessage);
      _messageController.clear();

      // Log to history
      final currentUserAsync = ref.watch(currentUserProvider);
      final currentUser = currentUserAsync.maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
      if (currentUser != null) {
        ref.read(chatHistoryProvider.notifier).addEntry(
          'Asked: $message',
          currentUser.username,
          currentUser.username,
          'contributor', // Default role
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastAiResponse = 'Error: Failed to send message. Please try again.';
      });
    }
  }

  Future<String> _buildProjectContext() async {
    final projectsState = ref.read(projectsProvider);
    final tasksState = ref.read(tasksProvider);

    final project = projectsState.maybeWhen(
      data: (projects) => projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => ProjectModel.create(name: 'Unknown Project', progress: 0.0),
      ),
      orElse: () => ProjectModel.create(name: 'Unknown Project', progress: 0.0),
    );

    final tasks = tasksState.maybeWhen(
      data: (tasks) => tasks,
      orElse: () => <Task>[],
    );

    return '''
Project: ${project.name}
Description: ${project.description ?? 'No description'}
Status: ${project.status}
Progress: ${(project.progress * 100).round()}%
Category: ${project.category ?? 'Not specified'}

Tasks (${tasks.length}):
${tasks.map((t) => '- ${t.title} (${t.statusLabel})').join('\n')}

Current Date: ${DateTime.now().toString().split(' ')[0]}
''';
  }

  Future<String> _getModularSystemPromptForProject() async {
    // Get project to determine help level and complexity
    final projectsState = ref.read(projectsProvider);
    final project = projectsState.maybeWhen(
      data: (projects) => projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => ProjectModel.create(name: 'Unknown Project', progress: 0.0),
      ),
      orElse: () => ProjectModel.create(name: 'Unknown Project', progress: 0.0),
    );

    // Use modular prompt helpers from AiConfig
    final helpLevelPrompt = AiConfig.getSystemPromptForHelpLevel(project.helpLevel);
    final complexityPrompt = AiConfig.getSystemPromptForComplexity(project.complexity);

    // Use ai_planning_helpers to generate additional context questions for better prompts
    try {
      final contextData = {
        'project_name': project.name,
        'description': project.description ?? '',
        'category': project.category ?? 'general',
        'status': project.status.toString(),
        'progress': project.progress.toString(),
      };

      final questionsResult = await AiPlanningHelpers.generatePlanningQuestions(
        contextData,
        project.helpLevel,
      );

      final additionalContext = questionsResult.content.isNotEmpty
          ? '\n\nAdditional Context Questions:\n${questionsResult.content.take(3).join('\n')}\n\nUse these questions to provide more targeted assistance.'
          : '';

      return '${AiConfig.systemPrompt}\n\n$helpLevelPrompt\n\n$complexityPrompt$additionalContext';
    } catch (e) {
      // Fallback to basic prompt if helpers fail
      return '${AiConfig.systemPrompt}\n\n$helpLevelPrompt\n\n$complexityPrompt';
    }
  }

  void _showApplyConfirmationDialog(BuildContext context, AsyncValue<AuthUser?> currentUserAsync) {
    if (_lastAiResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI response to apply')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply AI Changes - Compliance Warning'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚠️ COMPLIANCE NOTICE - Worldwide Legal Requirements',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                'Before applying AI-generated changes, ensure compliance with ALL applicable laws and regulations in your jurisdiction and globally:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '• Data Privacy & Protection Laws (GDPR, CCPA, PIPEDA, LGPD, PDPA, POPIA, etc.)\n'
                '• Intellectual Property Rights (Copyright, Patents, Trademarks)\n'
                '• Export Controls & Economic Sanctions\n'
                '• Content Moderation & Harmful Content Regulations\n'
                '• Local Business & Professional Regulations\n'
                '• AI-Specific Regulations (EU AI Act, etc.)\n'
                '• Cybersecurity & Data Security Standards',
                style: TextStyle(fontSize: 11),
              ),
              SizedBox(height: 12),
              Text(
                'Changes will be permanently logged in the project history with user identification, timestamps, and change details for audit and compliance purposes. '
                'This action cannot be undone and may have legal implications.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red),
              ),
              SizedBox(height: 12),
              Text(
                'By proceeding, you confirm that you have reviewed the AI suggestions for compliance and accept responsibility for their application.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 12),
              Text(
                'Do you want to proceed with applying the AI suggestions?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyChanges(context, currentUserAsync);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyChanges(BuildContext context, AsyncValue<AuthUser?> currentUserAsync) async {
    if (_lastAiResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI response to apply')),
      );
      return;
    }

    try {
      // Parse AI response for actionable changes
      final changes = _parseChangesFromResponse(_lastAiResponse!);

      if (changes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No actionable changes found in AI response')),
        );
        return;
      }

      // Apply changes with project history logging
      await _executeChangesWithHistory(changes);

      // Log to history
      final currentUser = currentUserAsync.maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
      if (currentUser != null) {
        ref.read(chatHistoryProvider.notifier).addEntry(
          'Applied AI changes',
          currentUser.username,
          currentUser.username,
          'owner', // Only owners can apply changes
          {'changes': changes},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes applied successfully')),
        );

        // Close bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply changes: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseChangesFromResponse(String response) {
    final changes = <Map<String, dynamic>>[];

    // Simple parsing logic - look for common patterns
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('Add task:') || trimmed.startsWith('Create task:')) {
        final taskTitle = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        changes.add({
          'type': 'add_task',
          'title': taskTitle,
        });
      } else if (trimmed.startsWith('Update description:') || trimmed.startsWith('Set description:')) {
        final description = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        changes.add({
          'type': 'update_description',
          'description': description,
        });
      }
    }

    return changes;
  }

  Future<void> _executeChangesWithHistory(List<Map<String, dynamic>> changes) async {
    // Get current project
    final projectsState = ref.read(projectsProvider);
    final project = projectsState.maybeWhen(
      data: (projects) => projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => throw Exception('Project not found'),
      ),
      orElse: () => throw Exception('Failed to load projects'),
    );

    ProjectModel updatedProject = project;

    for (final change in changes) {
      switch (change['type']) {
        case 'add_task':
          final task = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: widget.projectId,
            title: change['title'],
            description: 'Created by AI assistant',
            status: TaskStatus.todo,
            assignee: '',
            createdAt: DateTime.now(),
            priority: 0.5,
          );
          await ref.read(tasksProvider.notifier).addTask(task);
          break;

        case 'update_description':
          updatedProject = ProjectModel(
            id: project.id,
            name: project.name,
            progress: project.progress,
            directoryPath: project.directoryPath,
            tasks: project.tasks,
            status: project.status,
            description: change['description'],
            category: project.category,
            aiAssistant: project.aiAssistant,
            planJson: project.planJson,
            helpLevel: project.helpLevel,
            complexity: project.complexity,
            history: project.history,
            sharedUsers: project.sharedUsers,
            sharedGroups: project.sharedGroups,
          );
          break;
      }
    }

    // Apply project updates with change history logging
    if (updatedProject != project) {
      final changeDescription = 'AI suggestions applied: ${changes.map((c) => c['type']).join(', ')}';
      await ref.read(projectsProvider.notifier).updateProject(
        widget.projectId,
        updatedProject,
        changeDescription: changeDescription,
      );
    }
  }

  void _showHistoryDialog(BuildContext context, List<ChatHistoryEntry> history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: history.isEmpty
              ? const Center(child: Text('No history yet'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(entry.userRole[0].toUpperCase()),
                      ),
                      title: Text(entry.action),
                      subtitle: Text('${entry.userName} (${entry.userRole})'),
                      trailing: Text(_formatTimestamp(entry.timestamp)),
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