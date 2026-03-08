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
  late final Map<String, String> _files;
  late String _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedMode = 'private';
    _files = <String, String>{
      'lib/main.dart': "void main() {\n  print('Mirror');\n}\n",
      'lib/services/compiler.dart':
          'class CompilerService {\n  Future<void> run() async {}\n}\n',
      'README.md': '# Mirror Project\n\nMulti-file coding workspace.\n',
    };
    _selectedFile = _files.keys.first;
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final isCompact = constraints.maxWidth < 900;

                      if (isCompact) {
                        return Column(
                          children: <Widget>[
                            SizedBox(
                              height: 180,
                              child: _buildFileExplorer(context),
                            ),
                            const Divider(height: 1),
                            Expanded(child: _buildMonacoEditor(context)),
                          ],
                        );
                      }

                      return Row(
                        children: <Widget>[
                          SizedBox(
                            width: 280,
                            child: _buildFileExplorer(context),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: _buildMonacoEditor(context)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileExplorer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            'Files',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final filePath = _files.keys.elementAt(index);
              final isActive = filePath == _selectedFile;

              return ListTile(
                dense: true,
                selected: isActive,
                leading: Icon(
                  _iconForFile(filePath),
                  size: 18,
                ),
                title: Text(
                  filePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  setState(() {
                    _selectedFile = filePath;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonacoEditor(BuildContext context) {
    final currentContent = _files[_selectedFile] ?? '';

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            _selectedFile,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: MonacoEditor(
            code: currentContent,
            language: _languageForFile(_selectedFile),
            theme: Theme.of(context).brightness == Brightness.dark ? 'vs-dark' : 'vs',
            onChanged: (String value) {
              setState(() {
                _files[_selectedFile] = value;
              });
            },
          ),
        ),
      ],
    );
  }

  IconData _iconForFile(String path) {
    if (path.endsWith('.dart')) {
      return Icons.code;
    }
    if (path.endsWith('.md')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _languageForFile(String path) {
    if (path.endsWith('.dart')) {
      return 'dart';
    }
    if (path.endsWith('.md')) {
      return 'markdown';
    }
    if (path.endsWith('.json')) {
      return 'json';
    }
    return 'plaintext';
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

class MonacoEditor extends StatefulWidget {
  const MonacoEditor({
    super.key,
    required this.code,
    required this.language,
    required this.theme,
    required this.onChanged,
  });

  final String code;
  final String language;
  final String theme;
  final ValueChanged<String> onChanged;

  @override
  State<MonacoEditor> createState() => _MonacoEditorState();
}

class _MonacoEditorState extends State<MonacoEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant MonacoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.theme == 'vs-dark' ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Monaco (${widget.language}) editor',
        ),
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 14,
          color: widget.theme == 'vs-dark' ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
