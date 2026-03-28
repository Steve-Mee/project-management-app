// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers.dart';
import 'package:pma_core/models/models.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:xterm/xterm.dart';
import '../../generated/app_localizations.dart';

import '../../core/config/feature_flags.dart';
import '../../core/providers/mirror_entitlement_provider.dart';
import '../../core/providers/mirror_mode_controller_provider.dart';
import '../../core/providers/mirror_premium_provider.dart';
import '../../core/providers/mirror_session_provider.dart';
import '../../core/providers/supabase_client_provider.dart';
import '../three_d_visualization/providers/three_d_visualization_providers.dart';
import 'models/mirror_template.dart';
import 'models/mirror_structured_error.dart';
import 'providers/mirror_editor_orchestration_provider.dart';
import 'providers/mirror_templates_provider.dart';
import 'services/mirror_editor_file_presentation_service.dart';
import 'services/mirror_editor_realtime_controller.dart';
import 'services/mirror_apply_post_hooks_service.dart';
import 'services/mirror_run_attempt_service.dart';
import 'services/mirror_run_post_execution_analysis_service.dart';
import 'services/mirror_run_retry_feedback_service.dart';
import 'services/mirror_run_start_service.dart';
import 'services/mirror_run_ui_state_transition_service.dart';
import 'services/mirror_structured_error_parser.dart';
import 'services/mirror_terminal_line_processing_service.dart';
import 'services/mirror_templates_ui_service.dart';
import 'services/mirror_voice_draft_sanitizer.dart';
import 'services/mirror_voice_insert_flow.dart';
import 'widgets/mirror_editor_action_bar.dart';
import 'widgets/mirror_editor_panels.dart';
import 'widgets/mirror_permission_revoked_view.dart';
import 'widgets/mirror_retry_feedback_card.dart';
import 'widgets/mirror_editor_workspace_shell.dart';
import 'widgets/mirror_templates_sheet.dart';

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
  static const MirrorVoiceDraftSanitizer _voiceDraftSanitizer =
      MirrorVoiceDraftSanitizer();
  static const MirrorVoiceInsertFlow _voiceInsertFlow =
      MirrorVoiceInsertFlow();
  static const MirrorStructuredErrorParser _structuredErrorParser =
      MirrorStructuredErrorParser();
  static const MirrorTemplatesUiService _templatesUiService =
      MirrorTemplatesUiService();
    static const MirrorEditorFilePresentationService
      _filePresentationService = MirrorEditorFilePresentationService();
      static const MirrorRunRetryFeedbackService _retryFeedbackService =
        MirrorRunRetryFeedbackService();
        static const MirrorRunPostExecutionAnalysisService
          _postExecutionAnalysisService = MirrorRunPostExecutionAnalysisService();
          static const MirrorRunAttemptService _runAttemptService =
            MirrorRunAttemptService();
          static const MirrorRunStartService _runStartService =
            MirrorRunStartService();
          static const MirrorRunUiStateTransitionService
            _runUiStateTransitionService = MirrorRunUiStateTransitionService();
          static const MirrorTerminalLineProcessingService
            _terminalLineProcessingService = MirrorTerminalLineProcessingService();

  late final Terminal _terminal;
  late final TerminalController _terminalController;
  late final MirrorEditorRealtimeController _realtimeController;
  late final ProviderSubscription<bool> _mirrorPermissionSubscription;
  late final MirrorSessionNotifier _sessionNotifier;
  late final MirrorApplyPostHooksService _postHooksService;
  final ScrollController _liveOutputScrollController = ScrollController();
  bool _isListening = false;
  bool _isRunInProgress = false;
  bool _isPermissionRevoked = false;
  bool _isRealtimeControllerDisposed = false;
  MirrorStructuredError? _lastStructuredError;

  String get _sessionKey => '${widget.projectId}::${widget.taskId}';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final canUseMirror = ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    _sessionNotifier = ref.read(mirrorSessionProvider(_sessionKey).notifier);
    _postHooksService = ref.read(mirrorApplyPostHooksServiceProvider);
    _terminal = Terminal(maxLines: 1000);
    _terminalController = TerminalController();
    _realtimeController = MirrorEditorRealtimeController(
      projectId: widget.projectId,
      taskId: widget.taskId,
      sessionKey: _sessionKey,
      supabaseClient: ref.read(supabaseClientProvider),
    );
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
      statusLineLabel: (String status) {
        return _filePresentationService.statusLineLabel(
          l10n: _l10n,
          status: status,
        );
      },
    );
  }

  @override
  void dispose() {
    _mirrorPermissionSubscription.close();
    unawaited(
      _postHooksService.persistOnRouteExit(
            sessionNotifier: _sessionNotifier,
          ),
    );
    _disposeRealtimeController();
    _liveOutputScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mirrorTemplatesRealtimeInvalidationProvider);
    final l10n = _l10n;
    final canUseMirror = ref.watch(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror || _isPermissionRevoked) {
      return MirrorPermissionRevokedView(l10n: l10n);
    }

    final selectedMode = ref.watch(mirrorResolvedModeProvider);
    final resolvedState = ref.watch(mirrorResolvedStateProvider);
    final sessionState = ref.watch(mirrorSessionProvider(_sessionKey));
    final isPremium = ref.watch(mirrorPremiumProvider).valueOrNull ?? false;

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
              MirrorEditorActionBar(
                l10n: _l10n,
                projectId: widget.projectId,
                taskId: widget.taskId,
                mode: selectedMode,
                isPremium: isPremium,
                isRunInProgress: _isRunInProgress,
                isListening: _isListening,
                showDiagnostics: kDebugMode,
                resolvedState: resolvedState,
                onModeChanged: (String mode) {
                  if (mode == 'cloud' && !isPremium) {
                    _appendTerminalLine(_l10n.mirrorCloudPremiumOnly);
                    return;
                  }

                  ref.read(mirrorModeControllerProvider.notifier).setMode(mode);
                },
                onApplyVoiceToEditor: _applyVoiceDraftToEditor,
                onVoiceStatusMessage: _appendTerminalLine,
                onListeningChanged: ({required bool isListening}) {
                  setState(() => _isListening = isListening);
                },
                onRunPressed: _runCurrentFileInTerminal,
                retryableError: _lastStructuredError?.retryable,
                retryFeedbackCard: _lastStructuredError?.retryable == true
                    ? MirrorRetryFeedbackCard(
                        l10n: _l10n,
                        error: _lastStructuredError!,
                        isRunInProgress: _isRunInProgress,
                        onRetry: _runCurrentFileInTerminal,
                      )
                    : null,
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
                  child: MirrorEditorWorkspaceShell(
                    fileExplorer: MirrorEditorFileExplorer(
                      files: sessionState.files,
                      selectedFile: sessionState.selectedFile,
                      filesLabel: _l10n.mirrorFilesLabel,
                      iconForFile: _filePresentationService.iconForFile,
                      onFileSelected: _sessionNotifier.selectFile,
                    ),
                    editorAndTerminal: MirrorEditorAndTerminalPanel(
                      sessionState: sessionState,
                      terminal: _terminal,
                      terminalController: _terminalController,
                      liveOutputScrollController: _liveOutputScrollController,
                      isRunInProgress: _isRunInProgress,
                      l10n: _l10n,
                      languageForFile: _filePresentationService.languageForFile,
                      onEditorChanged: _sessionNotifier.updateSelectedFileContent,
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

  void _handlePermissionRevoked() {
    if (_isPermissionRevoked) {
      return;
    }

    _isPermissionRevoked = true;
    _isRunInProgress = false;
    _isListening = false;
    _appendTerminalLine(_l10n.mirrorPermissionRevokedTerminal);

    _disposeRealtimeController();
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

  Future<void> _openTemplatesGallery() async {
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
          child: MirrorTemplatesSheet(
            formatStaleUpdatedAt: _templatesUiService.formatStaleUpdatedAt,
            formatTemplatesFallbackReason:
                _templatesUiService.formatFallbackReason,
            formatTemplatesCacheAge: _templatesUiService.formatCacheAge,
            onTemplateSelected: (MirrorTemplate template) {
              Navigator.of(context).pop();
              _applyTemplateToSelectedFile(template);
            },
          ),
        );
      },
    );
  }

  Future<bool> _applyVoiceDraftToEditor(String text) async {
    final sanitizationResult = _voiceDraftSanitizer.sanitize(text);
    if (!sanitizationResult.isAccepted ||
        sanitizationResult.sanitizedText == null) {
      _appendTerminalLine(
        sanitizationResult.rejectionReason ??
            'Voice draft blocked by safety policy.',
      );
      return false;
    }

    final sanitizedText = sanitizationResult.sanitizedText!;
    final sessionState = ref.read(mirrorSessionProvider(_sessionKey));
    final selectedFile = sessionState.selectedFile;
    final confirmed = await _voiceInsertFlow.confirmInsert(
      context: context,
      selectedFile: selectedFile,
      sanitizedText: sanitizedText,
    );
    if (!confirmed) {
      _appendTerminalLine('Voice draft insert canceled.');
      return false;
    }

    final existing = sessionState.files[selectedFile] ?? '';
    final separator = existing.endsWith('\n') || existing.isEmpty ? '' : '\n';
    final updatedContent = '$existing$separator$sanitizedText';
    _sessionNotifier.updateSelectedFileContent(updatedContent);
    _appendTerminalLine(_l10n.mirrorVoiceAppended(selectedFile));
    if (mounted) {
      _voiceInsertFlow.showUndoSnackBar(
        context: context,
        selectedFile: selectedFile,
        onUndo: () {
          if (!mounted) {
            return;
          }

          final currentState = ref.read(mirrorSessionProvider(_sessionKey));
          if (currentState.selectedFile != selectedFile) {
            _sessionNotifier.selectFile(selectedFile);
          }
          _sessionNotifier.updateSelectedFileContent(existing);
          _appendTerminalLine('Voice draft insert undone for $selectedFile.');
        },
      );
    }
    return true;
  }

  void _applyTemplateToSelectedFile(MirrorTemplate template) {
    final selectedFile =
        ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;
    final presentation = _templatesUiService.buildTemplateApplyPresentation(
      selectedFile: selectedFile,
      template: template,
      l10n: _l10n,
    );
    _sessionNotifier.updateSelectedFileContent(presentation.updatedContent);
    _appendTerminalLine(presentation.terminalMessage);
  }

  void _appendTerminalLine(String line) {
    final result = _terminalLineProcessingService.process(
      rawLine: line,
      l10n: _l10n,
      parser: _structuredErrorParser,
    );
    final structured = result.structuredError;
    final displayLine = result.displayLine;

    _sessionNotifier.appendTerminalLine(displayLine, maxLines: 1000);
    _terminal.write('$displayLine\\r\\n');

    if (structured == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _lastStructuredError = structured;
      });
      _retryFeedbackService.showRetryFeedback(
        context: context,
        l10n: _l10n,
        error: structured,
        onRetry: _runCurrentFileInTerminal,
      );
    }
  }

  void _runCurrentFileInTerminal() {
    if (_isRunInProgress) {
      return;
    }

    final preflightState = ref.read(mirrorSessionProvider(_sessionKey));
    final selectedContent =
        preflightState.files[preflightState.selectedFile] ?? '';
    final visualizePrompt = _extractVisualizePrompt(selectedContent);
    if (visualizePrompt != null) {
      unawaited(_runVisualizeCommand(visualizePrompt));
      return;
    }

    final budgetService = ref.read(mirrorContextBudgetServiceProvider);
    final startPreparation = _runStartService.prepare(
      budgetService: budgetService,
      projectId: widget.projectId,
      taskId: widget.taskId,
      files: preflightState.files,
      terminalLog: preflightState.terminalLog,
    );
    final budgetMessage = startPreparation.budgetMessage;
    if (budgetMessage != null) {
      _appendTerminalLine(budgetMessage);
    }

    final beforeTerminalCount = startPreparation.beforeTerminalCount;

    final startState = _runUiStateTransitionService.onRunStarted(
      MirrorRunUiStateSnapshot(
        isRunInProgress: _isRunInProgress,
        lastStructuredError: _lastStructuredError,
      ),
    );
    setState(() {
      _isRunInProgress = startState.isRunInProgress;
      _lastStructuredError = startState.lastStructuredError;
    });

    final coordinator = ref.read(mirrorInteractiveRunCoordinatorProvider);
    _runAttemptService.execute(
      runAction: () => coordinator.runCurrentFileInTerminal(
        context: context,
        ref: ref,
        projectId: widget.projectId,
        taskId: widget.taskId,
        selectedMode: ref.read(mirrorResolvedModeProvider),
        sessionKey: _sessionKey,
        l10n: _l10n,
        isMounted: () => mounted,
        appendTerminalLine: _appendTerminalLine,
      ),
      terminalLogReader: () =>
          ref.read(mirrorSessionProvider(_sessionKey)).terminalLog,
      beforeTerminalCount: beforeTerminalCount,
      analysisService: _postExecutionAnalysisService,
      parser: _structuredErrorParser,
      completedMarker: _l10n.mirrorRunCompletedTerminal,
      currentState: MirrorRunUiStateSnapshot(
        isRunInProgress: _isRunInProgress,
        lastStructuredError: _lastStructuredError,
      ),
    ).then((transition) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunInProgress = transition.nextState.isRunInProgress;
        _lastStructuredError = transition.nextState.lastStructuredError;
      });

      final parsed = transition.retryFeedbackError;
      if (parsed != null) {
        _retryFeedbackService.showRetryFeedback(
          context: context,
          l10n: _l10n,
          error: parsed,
          onRetry: _runCurrentFileInTerminal,
        );
      }
    });
  }

  String? _extractVisualizePrompt(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      if (!line.startsWith('/')) {
        return null;
      }
      if (line == '/visualize') {
        return '';
      }
      if (line.startsWith('/visualize ')) {
        return line.substring('/visualize'.length).trim();
      }
      return null;
    }
    return null;
  }

  Future<void> _runVisualizeCommand(String promptOverride) async {
    _appendTerminalLine('Mirror command detected: /visualize');

    final featureFlags = ref.read(featureFlagProvider);
    final isThreeDEnabled = featureFlags.maybeWhen(
      data: (flags) => FeatureFlagResolver.isEnabled(
        flags,
        AppFeatureFlags.threeDVisualizationEnabled,
        defaultValue: true,
      ),
      orElse: () => true,
    );
    if (!isThreeDEnabled) {
      _appendTerminalLine(
        '3D visualization is disabled by feature flag '
        '(${AppFeatureFlags.threeDVisualizationEnabled}).',
      );
      return;
    }

    try {
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final tasks = taskRepository.getTasksForProject(widget.projectId);
      Task? selectedTask;
      for (final task in tasks) {
        if (task.id == widget.taskId) {
          selectedTask = task;
          break;
        }
      }

      final description = selectedTask?.description.trim();
      final attachments = selectedTask?.attachments ?? const <String>[];
      final prompt = promptOverride.trim().isNotEmpty
          ? promptOverride.trim()
          : description != null && description.isNotEmpty
              ? 'Generate a production-ready 3D asset for this task.\n'
                  'Task context: $description'
              : 'Generate a production-ready 3D asset for task ${widget.taskId}.';

      final request = ThreeDGenerationRequest(
        projectId: widget.projectId,
        taskId: widget.taskId,
        prompt: prompt,
        metadata: <String, dynamic>{
          'source': 'mirror_slash_visualize',
          'mirror_session_key': _sessionKey,
          if (description != null && description.isNotEmpty)
            'task_description': description,
          if (attachments.isNotEmpty) 'attachments': attachments,
        },
      );

      final job = await ref
          .read(threeDGenerationProvider.notifier)
          .generate(request);
      final jobId = job?.jobId ?? 'unknown';
      _appendTerminalLine('3D generation queued successfully. Job ID: $jobId');
    } catch (error) {
      _appendTerminalLine('3D generation request failed: $error');
    }
  }

}
