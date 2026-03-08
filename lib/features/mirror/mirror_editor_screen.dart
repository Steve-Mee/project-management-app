import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/mirror_provider.dart';

class MirrorEditorScreen extends ConsumerStatefulWidget {
  const MirrorEditorScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  final String projectId;
  final String taskId;

  @override
  ConsumerState<MirrorEditorScreen> createState() => _MirrorEditorScreenState();
}

class _MirrorEditorScreenState extends ConsumerState<MirrorEditorScreen> {
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = 'private';
  }

  @override
  Widget build(BuildContext context) {
    final mirrorState = ref.watch(mirrorProvider);
    final isPremium = mirrorState.isPremium;

    if (_selectedMode != mirrorState.mode) {
      _selectedMode = mirrorState.mode;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mirror Editor'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ModeSelector(
                selectedMode: _selectedMode,
                isPremium: isPremium,
                onModeChanged: (String mode) {
                  if (mode == 'cloud' && !isPremium) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cloud mode is beschikbaar voor premium gebruikers.'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _selectedMode = mode;
                  });
                  ref.read(mirrorProvider.notifier).setMode(mode);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Project: ${widget.projectId}  •  Task: ${widget.taskId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: const Center(
                    child: Text(
                      'Monaco editor placeholder',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.isPremium,
    required this.onModeChanged,
  });

  final String selectedMode;
  final bool isPremium;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text('Mode:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: 'private',
                child: Text('Private'),
              ),
              DropdownMenuItem<String>(
                value: 'cloud',
                child: Row(
                  children: <Widget>[
                    const Text('Cloud'),
                    const SizedBox(width: 8),
                    if (!isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        child: Text(
                          'Premium',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              onModeChanged(value);
            },
          ),
        ),
      ],
    );
  }
}
