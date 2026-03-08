import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xterm/xterm.dart';

import '../../core/providers/mirror_provider.dart';
import '../../core/providers/mirror_session_provider.dart';
import 'widgets/monaco_editor_host.dart';

class MirrorEditorScreen extends ConsumerStatefulWidget {
  const MirrorEditorScreen({
    super.key,
    required this.projectId,
    required this.taskId,
    this.debugRealtimeRecords,
  });

  final String projectId;
  final String taskId;
  final Stream<Map<String, dynamic>>? debugRealtimeRecords;

  @override
  ConsumerState<MirrorEditorScreen> createState() => _MirrorEditorScreenState();
}

class _MirrorEditorScreenState extends ConsumerState<MirrorEditorScreen> {
  static const int _maxLiveOutputLines = 500;
  static const Duration _realtimeDebounceDuration = Duration(milliseconds: 300);

  late String _selectedMode;
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  late final stt.SpeechToText _speechToText;
  final ScrollController _liveOutputScrollController = ScrollController();
  RealtimeChannel? _aiOutputChannel;
  StreamSubscription<Map<String, dynamic>>? _debugRealtimeSubscription;
  Timer? _realtimeDebounceTimer;
  final List<String> _pendingRealtimeLines = <String>[];
  bool _isListening = false;

  String get _sessionKey => '${widget.projectId}::${widget.taskId}';

  MirrorSessionNotifier get _sessionNotifier =>
      ref.read(mirrorSessionProvider(_sessionKey).notifier);

  @override
  void initState() {
    super.initState();
    _selectedMode = 'private';
    _terminal = Terminal(maxLines: 1000);
    _terminalController = TerminalController();
    _speechToText = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _appendTerminalLine('Mirror terminal ready.');
      _appendTerminalLine(
          'Project: ${widget.projectId} Task: ${widget.taskId}');
    });
    if (widget.debugRealtimeRecords != null) {
      _debugRealtimeSubscription = widget.debugRealtimeRecords!.listen(
        _handleRealtimeRecord,
      );
    } else {
      _subscribeToLiveOutput();
    }
  }

  @override
  void dispose() {
    if (_aiOutputChannel != null) {
      Supabase.instance.client.removeChannel(_aiOutputChannel!);
    }
    _debugRealtimeSubscription?.cancel();
    _realtimeDebounceTimer?.cancel();
    _liveOutputScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mirrorState = ref.watch(mirrorProvider);
    final sessionState = ref.watch(mirrorSessionProvider(_sessionKey));
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
                        content: Text(
                            'Cloud mode is beschikbaar voor premium gebruikers.'),
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
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _toggleVoiceInput,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening ? 'Listening...' : 'Voice Input'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _runCurrentFileInTerminal,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run'),
                  ),
                ],
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
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final isCompact = constraints.maxWidth < 900;

                      if (isCompact) {
                        return Column(
                          children: <Widget>[
                            SizedBox(
                              height: 180,
                              child: _buildFileExplorer(context, sessionState),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: _buildEditorAndTerminal(
                                context,
                                sessionState,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: <Widget>[
                          SizedBox(
                            width: 280,
                            child: _buildFileExplorer(context, sessionState),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: _buildEditorAndTerminal(
                              context,
                              sessionState,
                            ),
                          ),
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

  Widget _buildEditorAndTerminal(
    BuildContext context,
    MirrorSessionState sessionState,
  ) {
    return Column(
      children: <Widget>[
        Expanded(child: _buildMonacoEditor(context, sessionState)),
        const Divider(height: 1),
        SizedBox(
          height: 220,
          child: _buildTerminal(context, sessionState),
        ),
      ],
    );
  }

  Widget _buildFileExplorer(
    BuildContext context,
    MirrorSessionState sessionState,
  ) {
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
            itemCount: sessionState.files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final filePath = sessionState.files.keys.elementAt(index);
              final isActive = filePath == sessionState.selectedFile;

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
                  _sessionNotifier.selectFile(filePath);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonacoEditor(
    BuildContext context,
    MirrorSessionState sessionState,
  ) {
    final currentContent = sessionState.files[sessionState.selectedFile] ?? '';

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            sessionState.selectedFile,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: MonacoEditorHost(
            code: currentContent,
            language: _languageForFile(sessionState.selectedFile),
            theme: Theme.of(context).brightness == Brightness.dark
                ? 'vs-dark'
                : 'vs',
            onChanged: _sessionNotifier.updateSelectedFileContent,
          ),
        ),
      ],
    );
  }

  Widget _buildTerminal(BuildContext context, MirrorSessionState sessionState) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            'Terminal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: TerminalView(
                  _terminal,
                  controller: _terminalController,
                  backgroundOpacity: 1,
                  autofocus: false,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildLiveOutputList(context, sessionState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveOutputList(
    BuildContext context,
    MirrorSessionState sessionState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Text(
            'Live AI Output',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: sessionState.liveOutput.isEmpty
              ? Center(
                  child: Text(
                    'Waiting for realtime output...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  controller: _liveOutputScrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: sessionState.liveOutput.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext context, int index) {
                    final line = sessionState.liveOutput[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Text(line),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _subscribeToLiveOutput() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    final topic =
        'mirror_ai_sessions:$currentUserId:${widget.projectId}:${widget.taskId}';
    final channel =
        Supabase.instance.client.channel('mirror-ai-output-$topic');

    _aiOutputChannel = channel
        .onBroadcast(
          event: 'ai_session_update',
          callback: (Map<String, dynamic> payload, [String? _]) {
            final record = _extractBroadcastRecord(payload);
            if (record == null) {
              return;
            }
            _handleRealtimeRecord(record);
          },
        )
        .subscribe();
  }

  Map<String, dynamic>? _extractBroadcastRecord(Map<String, dynamic> payload) {
    final directNew = payload['new'];
    if (directNew is Map) {
      return Map<String, dynamic>.from(directNew);
    }

    final nestedPayload = payload['payload'];
    if (nestedPayload is Map) {
      final nestedNew = nestedPayload['new'];
      if (nestedNew is Map) {
        return Map<String, dynamic>.from(nestedNew);
      }
    }

    final record = payload['record'];
    if (record is Map) {
      return Map<String, dynamic>.from(record);
    }

    return null;
  }

  void _handleRealtimeRecord(Map<String, dynamic> record) {
    if (!_isRecordInRealtimeScope(record)) {
      return;
    }

    final outputLines = _extractOutputLines(record);
    if (outputLines.isEmpty || !mounted) {
      return;
    }

    _pendingRealtimeLines.addAll(outputLines);
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer =
        Timer(_realtimeDebounceDuration, _flushDebouncedRealtimeOutput);
  }

  bool _isRecordInRealtimeScope(Map<String, dynamic> record) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final recordTaskId = record['task_id']?.toString();
    final recordProjectId = record['project_id']?.toString();
    final recordUserId = record['user_id']?.toString();

    return recordTaskId == widget.taskId &&
        recordProjectId == widget.projectId &&
        recordUserId == currentUserId;
  }

  void _flushDebouncedRealtimeOutput() {
    if (!mounted || _pendingRealtimeLines.isEmpty) {
      return;
    }

    final flushedLines = List<String>.from(_pendingRealtimeLines);
    _pendingRealtimeLines.clear();

    _sessionNotifier.appendLiveOutput(flushedLines, maxLines: _maxLiveOutputLines);
    _appendTerminalLine('Realtime output ontvangen (${flushedLines.length} regels).');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_liveOutputScrollController.hasClients) {
        return;
      }
      _liveOutputScrollController.animateTo(
        _liveOutputScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  List<String> _extractOutputLines(Map<String, dynamic> record) {
    final versions = record['versions'];
    if (versions is List) {
      final lines = <String>[];
      for (final item in versions) {
        if (item is Map && item['output'] != null) {
          lines.add(item['output'].toString());
        } else if (item != null) {
          lines.add(item.toString());
        }
      }
      return lines;
    }

    final status = record['status'];
    if (status != null) {
      return <String>['Status: $status'];
    }

    return const <String>[];
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _appendTerminalLine('Voice input stopped.');
      return;
    }

    final available = await _speechToText.initialize();
    if (!available) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Voice input is not available on this device.')),
      );
      _appendTerminalLine('Voice input unavailable.');
      return;
    }

    setState(() {
      _isListening = true;
    });
    _appendTerminalLine('Voice input started...');

    await _speechToText.listen(
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) {
          return;
        }

        setState(() {
          final sessionState = ref.read(mirrorSessionProvider(_sessionKey));
          final selectedFile = sessionState.selectedFile;
          final existing = sessionState.files[selectedFile] ?? '';
          final separator =
              existing.endsWith('\n') || existing.isEmpty ? '' : '\n';
          _sessionNotifier
              .updateSelectedFileContent('$existing$separator$recognized');
        });

        final selectedFile =
            ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;
        _appendTerminalLine('Voice appended to $selectedFile');

        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
        }
      },
      onSoundLevelChange: (_) {},
      // ignore: deprecated_member_use
      cancelOnError: true,
      // ignore: deprecated_member_use
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _runCurrentFileInTerminal() {
    final selectedFile =
        ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;
    _appendTerminalLine('\$ run $selectedFile');
    _appendTerminalLine('Execution stub completed for $selectedFile');
  }

  void _appendTerminalLine(String line) {
    _sessionNotifier.appendTerminalLine(line, maxLines: 1000);
    _terminal.write('$line\\r\\n');
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

List<String> mergeLiveOutputWithCap({
  required List<String> currentLines,
  required List<String> incomingLines,
  int maxLines = 500,
}) {
  final merged = <String>[...currentLines, ...incomingLines];
  if (merged.length <= maxLines) {
    return merged;
  }
  return merged.sublist(merged.length - maxLines);
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
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
