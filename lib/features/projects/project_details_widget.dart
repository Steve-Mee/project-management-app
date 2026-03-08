import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/ai_chat_provider.dart';
import '../mirror/mirror_editor_screen.dart';

class ProjectDetailsWidget extends ConsumerWidget {
  const ProjectDetailsWidget({
    super.key,
    required this.projectId,
    required this.taskId,
    this.preferredMode = 'private',
  });

  final String projectId;
  final String taskId;
  final String preferredMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => _openMirrorEditor(context, ref),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open Mirror Editor'),
    );
  }

  Future<void> _openMirrorEditor(BuildContext context, WidgetRef ref) async {
    final payload = await ref.read(aiChatBridgeProvider.notifier).openMirrorFromTask(
      projectId: projectId,
      taskId: taskId,
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
