import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/models/task_model.dart';

import '../../core/providers/ai_chat_provider.dart';
import '../mirror/mirror_editor_screen.dart';

/// Task card with deep link action to Mirror Editor.
class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.preferredMode = 'private',
  });

  final Task task;
  final String preferredMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(task.description),
        trailing: FilledButton.tonalIcon(
          onPressed: () => _openMirrorEditor(context, ref),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Mirror Editor'),
        ),
      ),
    );
  }

  Future<void> _openMirrorEditor(BuildContext context, WidgetRef ref) async {
    final payload = await ref.read(aiChatBridgeProvider.notifier).openMirrorFromTask(
      projectId: task.projectId,
      taskId: task.id,
      preferredMode: preferredMode,
    );

    if (!context.mounted) {
      return;
    }

    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mirror is not available for your account.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MirrorEditorScreen(
          projectId: payload.projectId,
          taskId: payload.taskId,
        ),
      ),
    );
  }
}
