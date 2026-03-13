// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:xterm/xterm.dart';
import '../../generated/app_localizations.dart';

import '../../core/providers/mirror_session_provider.dart';
import 'models/mirror_template.dart';
import 'providers/mirror_templates_provider.dart';
import 'services/mirror_editor_realtime_controller.dart';
import 'services/mirror_editor_run_service.dart';
import 'templates_gallery.dart';
import 'widgets/monaco_editor_host.dart';
import '../../core/providers/mirror_provider.dart';

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
  late String _selectedMode;
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  late final stt.SpeechToText _speechToText;
  late final MirrorEditorRealtimeController _realtimeController;
  late final MirrorEditorRunService _runService;
  late final ProviderSubscription<bool> _mirrorPermissionSubscription;
  final ScrollController _liveOutputScrollController = ScrollController();
  bool _isListening = false;
  bool _isRunInProgress = false;
  bool _isPermissionRevoked = false;
  bool _isRealtimeControllerDisposed = false;

  String get _sessionKey => '${widget.projectId}::${widget.taskId}';

  MirrorSessionNotifier get _sessionNotifier =>
      ref.read(mirrorSessionProvider(_sessionKey).notifier);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final canUseMirror = ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    _selectedMode = 'private';
    _terminal = Terminal(maxLines: 1000);
    _terminalController = TerminalController();
    _speechToText = stt.SpeechToText();
    _realtimeController = MirrorEditorRealtimeController(
      projectId: widget.projectId,
      taskId: widget.taskId,
      sessionKey: _sessionKey,
    );
    _runService = const MirrorEditorRunService();
    _mirrorPermissionSubscription = ref.listenManual<bool>(
      hasPermissionProvider(AppPermissions.useMirror),
      (bool? previous, bool next) {
        if ((previous ?? true) && !next) {
          _handlePermissionRevoked();
        }
      },
    );
    if (!canUseMirror) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _appendTerminalLine(_l10n.mirrorTerminalReady);
      _appendTerminalLine(
        _l10n.mirrorProjectTaskLine(widget.projectId, widget.taskId),
      );
    });
    _realtimeController.start(
      debugRealtimeRecords: widget.debugRealtimeRecords,
      isMounted: () => mounted,
      onFlush: _handleRealtimeFlush,
      onTerminalLine: _appendTerminalLine,
      realtimeOutputReceivedLabel: _realtimeOutputReceivedLabel,
      statusLineLabel: _statusLineLabel,
    );
  }

  @override
  void dispose() {
    unawaited(_speechToText.stop());
    unawaited(_speechToText.cancel());
    _mirrorPermissionSubscription.close();
    _disposeRealtimeController();
    _liveOutputScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final canUseMirror = ref.watch(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror || _isPermissionRevoked) {
      return _buildPermissionRevokedState(context, l10n);
    }

    final mirrorState = ref.watch(mirrorProvider);
    final sessionState = ref.watch(mirrorSessionProvider(_sessionKey));
    final isPremium = mirrorState.isPremium;

    if (_selectedMode != mirrorState.mode) {
      _selectedMode = mirrorState.mode;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.mirrorEditorTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTemplatesGallery,
        icon: const Icon(Icons.auto_awesome),
        label: Text(_l10n.mirrorTemplatesLabel),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ModeSelector(
                l10n: _l10n,
                selectedMode: _selectedMode,
                isPremium: isPremium,
                isEnabled: !_isRunInProgress,
                onModeChanged: (String mode) {
                  if (mode == 'cloud' && !isPremium) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_l10n.mirrorCloudPremiumOnly),
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
                _l10n.mirrorProjectTaskHeader(widget.projectId, widget.taskId),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _toggleVoiceInput,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening
                        ? _l10n.mirrorListeningLabel
                        : _l10n.mirrorVoiceInputLabel),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isRunInProgress
                        ? null
                        : () {
                            _runService.runCurrentFileInTerminal(
                              context: context,
                              ref: ref,
                              projectId: widget.projectId,
                              taskId: widget.taskId,
                              selectedMode: _selectedMode,
                              sessionKey: _sessionKey,
                              l10n: _l10n,
                              isRunInProgress: _isRunInProgress,
                              isMounted: () => mounted,
                              setRunInProgress: (bool inProgress) {
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  _isRunInProgress = inProgress;
                                });
                              },
                              appendTerminalLine: _appendTerminalLine,
                            );
                          },
                    icon: _isRunInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunInProgress
                        ? _l10n.mirrorRunningLabel
                        : _l10n.mirrorRunLabel),
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

  void _handlePermissionRevoked() {
    if (_isPermissionRevoked) {
      return;
    }

    _isPermissionRevoked = true;
    _isRunInProgress = false;
    _isListening = false;
    _appendTerminalLine(_l10n.mirrorPermissionRevokedTerminal);

    _disposeRealtimeController();
    unawaited(_speechToText.stop());
    unawaited(_speechToText.cancel());
    ref.invalidate(mirrorSessionProvider(_sessionKey));

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _disposeRealtimeController() {
    if (_isRealtimeControllerDisposed) {
      return;
    }
    _isRealtimeControllerDisposed = true;
    _realtimeController.dispose();
  }

  Widget _buildPermissionRevokedState(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.mirrorEditorTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.lock,
                      size: 44,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.mirrorPermissionDenied,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mirrorPermissionRevokedSessionDisabled,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.closeButton),
                    ),
                  ],
                ),
              ),
            ),
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
            _l10n.mirrorFilesLabel,
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
            onChanged: (String content) {
              if (_isRunInProgress) {
                return;
              }
              _sessionNotifier.updateSelectedFileContent(content);
            },
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
            _l10n.mirrorTerminalLabel,
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
            _l10n.mirrorLiveOutputLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: sessionState.liveOutput.isEmpty
              ? Center(
                  child: Text(
                    _l10n.mirrorWaitingRealtime,
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

  void _handleRealtimeFlush(List<String> lines) {
    _sessionNotifier.appendLiveOutput(lines, maxLines: 500);
    if (!mounted) {
      return;
    }
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

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _stopVoiceInput();
      return;
    }

    final available = await _speechToText.initialize();
    if (!available) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.mirrorVoiceUnavailable)),
      );
      _appendTerminalLine(_l10n.mirrorVoiceUnavailableTerminal);
      return;
    }

    setState(() {
      _isListening = true;
    });
    _appendTerminalLine(_l10n.mirrorVoiceStarted);

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) {
          return;
        }
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
        _appendTerminalLine(_l10n.mirrorVoiceAppended(selectedFile));

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

  Future<void> _openTemplatesGallery() async {
    if (_isListening) {
      await _stopVoiceInput(announceStop: false);
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final templatesAsync = ref.watch(mirrorTemplatesProvider);

              return templatesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (Object error, StackTrace stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _l10n.mirrorTemplatesLoadFailed,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref.invalidate(mirrorTemplatesProvider);
                            final _ = ref.refresh(mirrorTemplatesProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(_l10n.mirrorRetryButton),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (List<MirrorTemplate> templates) {
                  if (templates.isEmpty) {
                    return _buildTemplatesEmptyState(ref);
                  }

                  return TemplatesGallery(
                    templates: templates,
                    onTemplateSelected: (MirrorTemplate template) {
                      Navigator.of(context).pop();
                      _applyTemplateToSelectedFile(template);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTemplatesEmptyState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _l10n.mirrorNoActiveTemplates,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                ref.invalidate(mirrorTemplatesProvider);
                final _ = ref.refresh(mirrorTemplatesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: Text(_l10n.mirrorRetryButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopVoiceInput({bool announceStop = true}) async {
    await _speechToText.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
    });
    if (announceStop) {
      _appendTerminalLine(_l10n.mirrorVoiceStopped);
    }
  }

  void _applyTemplateToSelectedFile(MirrorTemplate template) {
    final selectedFile = ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;
    _sessionNotifier.updateSelectedFileContent(template.seedContent);
    _appendTerminalLine(
      _l10n.mirrorTemplateAppliedTerminal(selectedFile, template.title),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_l10n.mirrorTemplateLoaded(template.title)),
      ),
    );
  }

  void _appendTerminalLine(String line) {
    _sessionNotifier.appendTerminalLine(line, maxLines: 1000);
    _terminal.write('$line\\r\\n');
  }
  String _realtimeOutputReceivedLabel(int count) {
    return _l10n.mirrorRealtimeOutputReceived(count);
  }

  String _statusLineLabel(String status) {
    return _l10n.mirrorStatusLine(status);
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
    required this.l10n,
    required this.selectedMode,
    required this.isPremium,
    required this.isEnabled,
    required this.onModeChanged,
  });

  final AppLocalizations l10n;
  final String selectedMode;
  final bool isPremium;
  final bool isEnabled;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(l10n.mirrorModeLabel),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'private',
                child: Text(l10n.mirrorPrivateMode),
              ),
              DropdownMenuItem<String>(
                value: 'cloud',
                child: Row(
                  children: <Widget>[
                    Text(l10n.mirrorCloudMode),
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
                          l10n.mirrorPremiumLabel,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            onChanged: !isEnabled
                ? null
                : (String? value) {
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
