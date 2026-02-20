import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/core/providers/ai/index.dart';
import 'package:my_project_management_app/core/services/ai_planning_helpers.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;
import 'package:my_project_management_app/models/task_model.dart';

/// Dialog for displaying task help with adjustable detail level and AI chat
class TaskHelpDialog extends ConsumerStatefulWidget {
  final Task task;
  final String? projectCategory;
  final String? aiAssistant;

  const TaskHelpDialog({super.key, required this.task, this.projectCategory, this.aiAssistant});

  @override
  ConsumerState<TaskHelpDialog> createState() => _TaskHelpDialogState();
}

class _TaskHelpDialogState extends ConsumerState<TaskHelpDialog> {
  late ai_config.HelpLevel _selectedLevel;
  final TextEditingController _chatController = TextEditingController();
  bool _isAnonymized = true;
  String? _generatedContent;
  bool _isGenerating = false;
  String? _lastAiResponse;
  late String _selectedAiAssistant;
  List<String>? _generatedQuestions;
  bool _isGeneratingQuestions = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ref.read(helpLevelProvider);
    _selectedAiAssistant = widget.aiAssistant ?? 'none';
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(aiChatProvider);

    // Update last AI response when chat state changes
    if (chatState.messages.isNotEmpty && (_isGenerating || _isGeneratingQuestions)) {
      final lastMessage = chatState.messages.last;
      if (!lastMessage.isUser) {
        _lastAiResponse = lastMessage.content;
        
        if (_isGeneratingQuestions && _generatedQuestions == null) {
          // Parse questions from response
          final questions = _parseQuestionsFromResponse(_lastAiResponse!);
          setState(() {
            _generatedQuestions = questions;
            _isGeneratingQuestions = false;
          });
        } else if (_isGenerating && _generatedContent == null) {
          setState(() {
            _generatedContent = _lastAiResponse;
            _isGenerating = false;
          });
        }
      }
    }

    return AlertDialog(
      title: Text('Task Help: ${widget.task.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help level selector
            const Text('Help Level:', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<ai_config.HelpLevel>(
              segments: const [
                ButtonSegment<ai_config.HelpLevel>(
                  value: ai_config.HelpLevel.basis,
                  label: Text('Basis'),
                ),
                ButtonSegment<ai_config.HelpLevel>(
                  value: ai_config.HelpLevel.gedetailleerd,
                  label: Text('Gedetailleerd'),
                ),
                ButtonSegment<ai_config.HelpLevel>(
                  value: ai_config.HelpLevel.stapVoorStap,
                  label: Text('Stap voor Stap'),
                ),
              ],
              selected: {_selectedLevel},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  setState(() => _selectedLevel = selected.first);
                }
              },
            ),
            const SizedBox(height: 16),

            // AI Assistant selection for software category
            if (widget.projectCategory?.toLowerCase() == 'software') ...[
              ListTile(
                title: const Text('AI Assistant Recommendations'),
                subtitle: const Text('Copilot for Flutter/Dart'),
                leading: const Icon(Icons.smart_toy),
              ),
              const Text('Select AI Assistant:', style: TextStyle(fontWeight: FontWeight.bold)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'copilot',
                    label: Text('Copilot'),
                  ),
                  ButtonSegment<String>(
                    value: 'cursor',
                    label: Text('Cursor'),
                  ),
                  ButtonSegment<String>(
                    value: 'none',
                    label: Text('None'),
                  ),
                ],
                selected: {_selectedAiAssistant},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    setState(() => _selectedAiAssistant = selected.first);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Task description
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_getAdjustedDescription()),
            ),
            const SizedBox(height: 16),

            // Task-specific questions section
            const Text('Task Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Get AI-generated questions to clarify and improve this task',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isGeneratingQuestions ? null : () => _generateTaskQuestions(),
                  icon: _isGeneratingQuestions
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.question_answer),
                  label: const Text('Generate Questions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Generated questions display
            if (_generatedQuestions != null && _generatedQuestions!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI-Generated Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._generatedQuestions!.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final question = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('$index. $question'),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AI Chat section
            const Text('Ask AI Assistant:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Privacy toggle
            Row(
              children: [
                Checkbox(
                  value: _isAnonymized,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _isAnonymized = value);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    'Anonymize data for privacy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),

            // Chat input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Ask for help with this task...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 2,
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendChatMessage,
                  tooltip: 'Send to AI',
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              _isAnonymized
                  ? 'Data will be anonymized before sending to AI'
                  : 'Full task data will be shared with AI',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _isAnonymized ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            // Category-specific action buttons
            if (_shouldShowActionButtons()) ...[
              const Text('Quick Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],

            // Generated content display
            if (_generatedContent != null) ...[
              const Text('Generated Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_generatedContent!),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }

  String _getAdjustedDescription() {
    final baseDescription = widget.task.description;

    if (_selectedLevel == ai_config.HelpLevel.basis) {
      // For basic help, provide a simplified version
      return _simplifyDescription(baseDescription);
    } else {
      // For detailed help, provide the full description with additional context
      return _enhanceDescription(baseDescription);
    }
  }

  String _simplifyDescription(String description) {
    // Simple logic to shorten and simplify
    final sentences = description.split('.');
    if (sentences.length <= 2) return description;

    // Take first 2 sentences and add a summary note
    return '${sentences.take(2).join('. ')}. (This is a simplified view. Switch to detailed for more information.)';
  }

  String _enhanceDescription(String description) {
    // Add more context and details
    return '$description\n\nTask Details:\n'
        '• Status: ${widget.task.statusLabel}\n'
        '• Priority: ${widget.task.priority > 0.75 ? 'High' : widget.task.priority > 0.5 ? 'Medium' : 'Low'}\n'
        '• Assignee: ${widget.task.assignee}\n'
        '${widget.task.dueDate != null ? '• Due: ${widget.task.dueDate!.toLocal().toString().split(' ')[0]}\n' : ''}'
        '${widget.task.attachments.isNotEmpty ? '• Attachments: ${widget.task.attachments.length} files\n' : ''}';
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    final contextData = _isAnonymized
        ? _anonymizeTaskData()
        : _getFullTaskContext();

    final fullMessage = 'Task: ${widget.task.title}\n\n$message\n\nContext:\n$contextData';

    try {
      await ref.read(aiChatProvider.notifier).sendMessage(fullMessage);
      _chatController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent to AI assistant')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  String _anonymizeTaskData() {
    // Remove or anonymize sensitive information
    return 'Title: ${widget.task.title}\n'
        'Description: ${widget.task.description}\n'
        'Status: ${widget.task.statusLabel}\n'
        'Priority: ${widget.task.priority > 0.75 ? 'High' : widget.task.priority > 0.5 ? 'Medium' : 'Low'}\n'
        'Due Date: ${widget.task.dueDate?.toLocal().toString().split(' ')[0] ?? 'None'}\n'
        'Attachments: ${widget.task.attachments.length} files';
  }

  String _getFullTaskContext() {
    return 'Title: ${widget.task.title}\n'
        'Description: ${widget.task.description}\n'
        'Status: ${widget.task.statusLabel}\n'
        'Assignee: ${widget.task.assignee}\n'
        'Priority: ${widget.task.priority}\n'
        'Created: ${widget.task.createdAt.toLocal()}\n'
        'Due Date: ${widget.task.dueDate?.toLocal() ?? 'None'}\n'
        'Attachments: ${widget.task.attachments.join(', ')}\n'
        'Project ID: ${widget.task.projectId}';
  }

  bool _shouldShowActionButtons() {
    final category = widget.projectCategory?.toLowerCase();
    return category == 'software' || category == 'board game';
  }

  Widget _buildActionButtons() {
    final category = widget.projectCategory?.toLowerCase();
    final buttons = <Widget>[];

    if (category == 'software') {
      buttons.addAll([
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _generateCode(),
          icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.code),
          label: const Text('Generate Code'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _generatePrompt(),
          icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.description),
          label: const Text('Generate Prompt'),
        ),
      ]);
    } else if (category == 'board game') {
      buttons.add(
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _generateImage(),
          icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image),
          label: const Text('Generate Image'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Future<void> _generateTaskQuestions() async {
    setState(() {
      _isGeneratingQuestions = true;
      _generatedQuestions = null;
    });

    try {
      // Create task data map for AI processing
      final taskData = _isAnonymized ? _anonymizeTaskDataForQuestions() : _getFullTaskDataForQuestions();

      // Use ai_planning_helpers for modular generation with compliance
      final result = await AiPlanningHelpers.generatePlanningQuestions(taskData, _selectedLevel);

      if (mounted) {
        setState(() {
          _generatedQuestions = result.content;
          _isGeneratingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingQuestions = false;
          _generatedQuestions = ['Failed to generate questions. Error: $e'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate questions: $e')),
        );
      }
    }
  }

  List<String> _parseQuestionsFromResponse(String response) {
    try {
      // Try to parse as JSON first
      final parsed = response.contains('[') && response.contains(']')
          ? jsonDecode(response.replaceAll('```json', '').replaceAll('```', '').trim())
          : null;
      
      if (parsed is List) {
        return parsed.map((q) => q.toString()).toList();
      }
    } catch (e) {
      // Fallback: extract questions from text
    }

    // Fallback: extract questions from text response
    final lines = response.split('\n');
    final questions = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('?') ||
          trimmed.contains('?') ||
          trimmed.toLowerCase().startsWith('what') ||
          trimmed.toLowerCase().startsWith('how') ||
          trimmed.toLowerCase().startsWith('when') ||
          trimmed.toLowerCase().startsWith('where') ||
          trimmed.toLowerCase().startsWith('why') ||
          trimmed.toLowerCase().startsWith('who')) {
        questions.add(trimmed.replaceAll(RegExp(r'^\d+\.\s*'), '')); // Remove numbering
      }
    }

    return questions.take(5).toList(); // Limit to 5 questions
  }

  Map<String, dynamic> _anonymizeTaskDataForQuestions() {
    return {
      'title': widget.task.title,
      'description': widget.task.description,
      'status': widget.task.statusLabel,
      'priority': widget.task.priority > 0.75 ? 'High' : widget.task.priority > 0.5 ? 'Medium' : 'Low',
      'category': widget.projectCategory ?? 'general',
      'has_due_date': widget.task.dueDate != null,
      'attachment_count': widget.task.attachments.length,
      'subtask_count': widget.task.subTaskIds.length,
    };
  }

  Map<String, dynamic> _getFullTaskDataForQuestions() {
    return {
      'title': widget.task.title,
      'description': widget.task.description,
      'status': widget.task.statusLabel,
      'priority': widget.task.priority,
      'assignee': widget.task.assignee,
      'created_at': widget.task.createdAt.toIso8601String(),
      'due_date': widget.task.dueDate?.toIso8601String(),
      'attachments': widget.task.attachments,
      'subtask_ids': widget.task.subTaskIds,
      'project_id': widget.task.projectId,
      'category': widget.projectCategory ?? 'general',
      'user_id': widget.task.userId,
    };
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _lastAiResponse = null;
    });

    try {
      final context = _isAnonymized ? _anonymizeTaskData() : _getFullTaskContext();
      String prompt;

      // Format prompt based on selected AI assistant
      switch (_selectedAiAssistant) {
        case 'copilot':
          prompt = 'Generate Dart/Flutter code for this task using GitHub Copilot style:\n\n'
              'Task: $context\n\n'
              'Provide complete, working code with proper imports, comments, and follow Flutter best practices. '
              'Format the response as clean, readable code that Copilot would suggest.\n\n'
              'IMPORTANT: Ensure all code complies with worldwide legal and regulatory requirements. '
              'Do not generate code that violates intellectual property laws, export controls, or data privacy regulations.';
          break;
        case 'cursor':
          prompt = 'Generate Dart/Flutter code for this task optimized for Cursor IDE:\n\n'
              'Task: $context\n\n'
              'Provide complete, working code with proper imports, detailed comments, and follow Flutter/Dart conventions. '
              'Format the response as production-ready code suitable for Cursor\'s AI assistance.\n\n'
              'IMPORTANT: Ensure all code complies with worldwide legal and regulatory requirements. '
              'Do not generate code that violates intellectual property laws, export controls, or data privacy regulations.';
          break;
        default:
          prompt = 'Generate Dart/Flutter code for this task:\n\n$context\n\n'
              'Please provide complete, working code with proper imports and comments.\n\n'
              'IMPORTANT: Ensure all code complies with worldwide legal and regulatory requirements. '
              'Do not generate code that violates intellectual property laws, export controls, or data privacy regulations.';
      }

      await ref.read(aiChatProvider.notifier).sendMessage(prompt);
      // The response will be captured by the state watcher
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generatedContent = 'Failed to generate code. Try again. Error: $e';
      });
    }
  }

  Future<void> _generatePrompt() async {
    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _lastAiResponse = null;
    });

    try {
      final context = _isAnonymized ? _anonymizeTaskData() : _getFullTaskContext();
      final prompt = 'Create a detailed prompt for an AI agent to help with this software development task:\n\n$context\n\n'
          'The prompt should be clear, specific, and include all necessary context for the AI to provide helpful assistance.\n\n'
          'IMPORTANT: The generated prompt must ensure compliance with worldwide legal and regulatory requirements. '
          'Include instructions for the AI to respect intellectual property laws, data privacy regulations, export controls, and other applicable laws.';

      await ref.read(aiChatProvider.notifier).sendMessage(prompt);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generatedContent = 'Failed to generate prompt. Try again. Error: $e';
      });
    }
  }

  Future<void> _generateImage() async {
    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _lastAiResponse = null;
    });

    try {
      final context = _isAnonymized ? _anonymizeTaskData() : _getFullTaskContext();
      final prompt = 'Generate an image description for this board game task:\n\n$context\n\n'
          'Create a detailed prompt for an image generation AI (like Flux) to create visual assets for this board game element.\n\n'
          'IMPORTANT: Ensure the image description complies with content guidelines and legal requirements. '
          'Do not suggest content that violates intellectual property, depicts harmful material, or infringes on copyrights.';

      await ref.read(aiChatProvider.notifier).sendMessage(prompt);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generatedContent = 'Failed to generate image prompt. Try again. Error: $e';
      });
    }
  }


}