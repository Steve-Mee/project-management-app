import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xterm/xterm.dart';
import '../../generated/app_localizations.dart';

import '../../core/providers/mirror_provider.dart';
import '../../core/providers/mirror_session_provider.dart';
import 'apply_dialog.dart';
import 'providers/mirror_templates_provider.dart';
import 'services/mirror_orchestrator_service.dart';
import 'templates_gallery.dart';
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
  bool _isRunInProgress = false;

  String get _sessionKey => '${widget.projectId}::${widget.taskId}';

  MirrorSessionNotifier get _sessionNotifier =>
      ref.read(mirrorSessionProvider(_sessionKey).notifier);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

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
      _appendTerminalLine(_l10n.mirrorTerminalReady);
      _appendTerminalLine(
        _l10n.mirrorProjectTaskLine(widget.projectId, widget.taskId),
      );
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
                    onPressed: _isRunInProgress ? null : _runCurrentFileInTerminal,
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
    _appendTerminalLine(_l10n.mirrorRealtimeOutputReceived(flushedLines.length));

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
      return <String>[_l10n.mirrorStatusLine(status.toString())];
    }

    return const <String>[];
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _appendTerminalLine(_l10n.mirrorVoiceStopped);
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

  Future<void> _runCurrentFileInTerminal() async {
    if (_isRunInProgress) {
      return;
    }

    final sessionState = ref.read(mirrorSessionProvider(_sessionKey));
    final selectedFile = sessionState.selectedFile;
    final selectedContent = sessionState.files[selectedFile]?.trim() ?? '';

    if (selectedContent.isEmpty) {
      _appendTerminalLine(_l10n.mirrorRunAbortedFileEmpty(selectedFile));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.mirrorSelectedFileEmpty)),
      );
      return;
    }

    setState(() {
      _isRunInProgress = true;
    });

    _appendTerminalLine(_l10n.mirrorRunStarting(selectedFile));
    _appendTerminalLine(_l10n.mirrorRunFlowLine);

    try {
      final backend = await ref.read(mirrorBackendProvider.future);
      final orchestrator = MirrorOrchestratorService(backend: backend);

      final originalFiles = Map<String, String>.from(sessionState.files);
      final originalMetadata = <String, dynamic>{
        'selectedFile': selectedFile,
        'trigger': 'run_button',
      };

      final executionContext = ProjectContext(
        projectId: widget.projectId,
        taskId: widget.taskId,
        files: originalFiles,
        metadata: originalMetadata,
      );

      final originalCompileContext = ProjectContext(
        projectId: executionContext.projectId,
        taskId: executionContext.taskId,
        files: Map<String, String>.from(executionContext.files),
        metadata: Map<String, dynamic>.from(executionContext.metadata),
      );

      _appendTerminalLine(_l10n.mirrorStepGenerateSent);
      final generateResult = await orchestrator.generate(
        ref: ref,
        sessionKey: _sessionKey,
        prompt: selectedContent,
        context: executionContext,
        mode: _selectedMode,
      );

      if (!mounted) {
        return;
      }

      if (!generateResult.success) {
        final errorText =
            _firstNonEmpty(
                  generateResult.message,
                  generateResult.diagnostics.join(' | '),
                ) ??
                  _l10n.mirrorUnknownGenerateError;
                _appendTerminalLine(_l10n.mirrorGenerateFailedTerminal(errorText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.mirrorGenerateFailed(errorText))),
        );
        return;
      }

      _appendTerminalLine(_l10n.mirrorStepGenerateCompleted);
      if (generateResult.diagnostics.isNotEmpty) {
        _appendTerminalLine(
          _l10n.mirrorGenerateDiagnostics(
            generateResult.diagnostics.join(' | '),
          ),
        );
      }

      final generatedPatches = _buildPreviewPatches(
        backend: backend,
        context: executionContext,
        selectedFile: selectedFile,
        compileOutput: generateResult.code,
        generatedCode: generateResult.code,
      );

      final compileContext = generatedPatches.isEmpty
          ? originalCompileContext
          : ProjectContext(
              projectId: originalCompileContext.projectId,
              taskId: originalCompileContext.taskId,
              files: backend.applyPatchesToFiles(
                files: originalCompileContext.files,
                patches: generatedPatches,
              ),
              metadata: originalCompileContext.metadata,
            );

      final runPrompt = _firstNonEmpty(generateResult.code, selectedContent) ??
          selectedContent;

      _appendTerminalLine(_l10n.mirrorStepCompileSent);
      final compileResult = await orchestrator.compile(
        ref: ref,
        sessionKey: _sessionKey,
        prompt: runPrompt,
        context: compileContext,
        mode: _selectedMode,
      );

      if (!mounted) {
        return;
      }

      if (!compileResult.success) {
        final errorText =
          _firstNonEmpty(compileResult.errors.join(' | '), _l10n.mirrorUnknownCompileError)!;
        _appendTerminalLine(_l10n.mirrorCompileFailedTerminal(errorText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.mirrorCompileFailed(errorText))),
        );
        return;
      }

      _appendTerminalLine(_l10n.mirrorStepCompileCompleted);
      if (compileResult.warnings.isNotEmpty) {
        _appendTerminalLine(
          _l10n.mirrorCompileWarnings(compileResult.warnings.join(' | ')),
        );
      }

      _appendTerminalLine(_l10n.mirrorStepPreviewBuilding);
      final patches = _buildPreviewPatches(
        backend: backend,
        context: originalCompileContext,
        selectedFile: selectedFile,
        compileOutput: compileResult.output,
        generatedCode: generateResult.code,
      );

      if (patches.isEmpty) {
        _appendTerminalLine(_l10n.mirrorNoPatchPreviewTerminal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.mirrorNoChangesAfterCompile)),
        );
        return;
      }

      _appendTerminalLine(
        _l10n.mirrorStepPreviewReady(patches.length),
      );

      final previewPatch = patches.firstWhere(
        (MirrorFilePatch patch) => patch.path == selectedFile,
        orElse: () => patches.first,
      );

      _appendTerminalLine(
        _l10n.mirrorStepApplyWaiting(previewPatch.path),
      );
      final applyDecision = await ApplyDialog.show(
        context,
        title: _l10n.mirrorApplyChangesTitle(previewPatch.path),
        originalContent: previewPatch.originalContent,
        updatedContent: previewPatch.updatedContent,
        suggestedBranch: 'mirror/${widget.projectId}-${widget.taskId}',
      );

      if (!mounted) {
        return;
      }

      final applyApproved = applyDecision?.apply == true &&
          applyDecision?.acceptRisk == true;
      if (!applyApproved) {
        _appendTerminalLine(_l10n.mirrorStepApplyCanceled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.mirrorApplyCanceled)),
        );
        return;
      }

      _appendTerminalLine(_l10n.mirrorStepApplySent);
      final applyContext = ProjectContext(
        projectId: originalCompileContext.projectId,
        taskId: originalCompileContext.taskId,
        // Keep backend as source of truth: apply receives original files.
        files: Map<String, String>.from(originalCompileContext.files),
        metadata: originalCompileContext.metadata,
      );
      final applyResult = await orchestrator.apply(
        ref: ref,
        sessionKey: _sessionKey,
        prompt: runPrompt,
        context: applyContext,
        mode: _selectedMode,
      );

      if (!mounted) {
        return;
      }

      if (applyResult.success) {
        _applyPreviewPatchesToSession(
          patches: patches,
          fallbackSelectedFile: selectedFile,
        );
        if (applyResult.appliedFiles.isNotEmpty) {
          _appendTerminalLine(
            _l10n.mirrorAppliedFiles(applyResult.appliedFiles.join(', ')),
          );
        }
        _appendTerminalLine(_l10n.mirrorRunCompletedTerminal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.mirrorRunSuccess)),
        );
        return;
      }

      final errorText = applyResult.message ?? _l10n.mirrorUnknownApplyError;
      _appendTerminalLine(_l10n.mirrorApplyFailedTerminal(errorText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.mirrorApplyFailed(errorText)),
        ),
      );
    } catch (error) {
      _appendTerminalLine(_l10n.mirrorRunCrashedTerminal(error.toString()));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.mirrorRunCrashed(error.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunInProgress = false;
        });
      }
    }
  }

  List<MirrorFilePatch> _buildPreviewPatches({
    required MirrorComputeBackend backend,
    required ProjectContext context,
    required String selectedFile,
    required String? compileOutput,
    required String? generatedCode,
  }) {
    final normalizedCompileOutput = compileOutput?.trim() ?? '';

    if (normalizedCompileOutput.isNotEmpty) {
      final patchesFromCompile = backend.buildPatchesFromApplyPayload(
        context: context,
        output: normalizedCompileOutput,
        fallbackPath: selectedFile,
      );
      if (patchesFromCompile.isNotEmpty) {
        return patchesFromCompile;
      }
    }

    final normalizedGeneratedCode = generatedCode?.trim() ?? '';
    if (normalizedGeneratedCode.isNotEmpty) {
      return backend.buildPatchesFromApplyPayload(
        context: context,
        output: normalizedGeneratedCode,
        fallbackPath: selectedFile,
      );
    }

    return const <MirrorFilePatch>[];
  }

  String? _firstNonEmpty(String? first, String? second) {
    final firstValue = first?.trim();
    if (firstValue != null && firstValue.isNotEmpty) {
      return firstValue;
    }

    final secondValue = second?.trim();
    if (secondValue != null && secondValue.isNotEmpty) {
      return secondValue;
    }

    return null;
  }

  Future<void> _openTemplatesGallery() async {
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _l10n.mirrorNoActiveTemplates,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
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

  void _applyPreviewPatchesToSession({
    required List<MirrorFilePatch> patches,
    required String fallbackSelectedFile,
  }) {
    final previousSelected =
        ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;

    for (final patch in patches) {
      final existsInSession =
          ref.read(mirrorSessionProvider(_sessionKey)).files.containsKey(patch.path);
      if (!existsInSession) {
        _sessionNotifier.upsertFileContent(
          path: patch.path,
          content: patch.updatedContent,
        );
        continue;
      }

      _sessionNotifier.selectFile(patch.path);
      _sessionNotifier.updateSelectedFileContent(patch.updatedContent);
    }

    final restoreTarget = ref
            .read(mirrorSessionProvider(_sessionKey))
            .files
            .containsKey(previousSelected)
        ? previousSelected
        : fallbackSelectedFile;
    _sessionNotifier.selectFile(restoreTarget);
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
    required this.l10n,
    required this.selectedMode,
    required this.isPremium,
    required this.onModeChanged,
  });

  final AppLocalizations l10n;
  final String selectedMode;
  final bool isPremium;
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
