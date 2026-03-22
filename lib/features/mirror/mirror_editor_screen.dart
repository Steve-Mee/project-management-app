// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:xterm/xterm.dart';
import 'widgets/mirror_voice_prompt_bar.dart';
import '../../generated/app_localizations.dart';

import '../../core/providers/mirror_entitlement_provider.dart';
import '../../core/providers/mirror_mode_controller_provider.dart';
import '../../core/providers/mirror_premium_provider.dart';
import '../../core/providers/mirror_session_provider.dart';
import '../../core/providers/supabase_client_provider.dart';
import 'models/mirror_template.dart';
import 'providers/mirror_editor_orchestration_provider.dart';
import 'providers/mirror_templates_provider.dart';
import 'services/mirror_editor_preflight_service.dart';
import 'services/mirror_editor_realtime_controller.dart';
import 'services/mirror_apply_post_hooks_service.dart';
import 'services/mirror_voice_draft_sanitizer.dart';
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
  static const MirrorEditorPreflightService _preflightService =
      MirrorEditorPreflightService();
  static const MirrorVoiceDraftSanitizer _voiceDraftSanitizer =
      MirrorVoiceDraftSanitizer();

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
  _MirrorStructuredError? _lastStructuredError;

  String get _sessionKey => '${widget.projectId}::${widget.taskId}';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String _formatStaleUpdatedAt(DateTime timestampUtc) {
    final local = timestampUtc.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _formatTemplatesFallbackReason(String? reasonCode) {
    switch (reasonCode) {
      case MirrorTemplatesLoadReasonCodes.timeout:
        return 'timeout';
      case MirrorTemplatesLoadReasonCodes.versionMismatch:
        return 'version mismatch';
      case MirrorTemplatesLoadReasonCodes.networkError:
        return 'network error';
      default:
        return 'unknown reason';
    }
  }

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
      statusLineLabel: _statusLineLabel,
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
      return _buildPermissionRevokedState(context, l10n);
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
              _ModeSelector(
                l10n: _l10n,
                mode: selectedMode,
                isPremium: isPremium,
                isEnabled: !_isRunInProgress,
                onModeChanged: (String mode) {
                  if (mode == 'cloud' && !isPremium) {
                    _appendTerminalLine(_l10n.mirrorCloudPremiumOnly);
                    return;
                  }

                  ref.read(mirrorModeControllerProvider.notifier).setMode(mode);
                },
              ),
              const SizedBox(height: 12),
              if (kDebugMode) ...<Widget>[
                _MirrorProvenanceDiagnostics(state: resolvedState),
                const SizedBox(height: 8),
              ],
              Text(
                _l10n.mirrorProjectTaskHeader(widget.projectId, widget.taskId),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              MirrorVoicePromptBar(
                isDisabled: _isRunInProgress,
                onApplyToEditor: _applyVoiceDraftToEditor,
                onStatusMessage: _appendTerminalLine,
                onListeningChanged: ({required bool isListening}) {
                  setState(() => _isListening = isListening);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isRunInProgress || _isListening
                    ? null
                    : _runCurrentFileInTerminal,
                icon: _isRunInProgress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _lastStructuredError?.retryable == true
                            ? Icons.refresh
                            : Icons.play_arrow,
                      ),
                label: Text(_isRunInProgress
                    ? _l10n.mirrorRunningLabel
                    : _lastStructuredError?.retryable == true
                        ? _l10n.mirrorRetryButton
                        : _l10n.mirrorRunLabel),
              ),
              if (_lastStructuredError?.retryable == true) ...<Widget>[
                const SizedBox(height: 8),
                _buildRetryFeedbackCard(context, _lastStructuredError!),
              ],
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
                            final _ = ref
                                .read(
                                  mirrorTemplatesInvalidationControllerProvider,
                                )
                                .invalidateTemplatesCache(refresh: true);
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(_l10n.mirrorRetryButton),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (MirrorTemplatesLoadResult result) {
                  final templates = result.templates;
                  if (templates.isEmpty) {
                    return _buildTemplatesEmptyState(ref);
                  }

                  final staleWarningMessage = result.isStaleFallback
                      ? result.fetchedAtUtc == null
                          ? _l10n.mirrorTemplatesStaleFallbackWarning
                          : _l10n.mirrorTemplatesStaleFallbackWarningWithTime(
                              _formatStaleUpdatedAt(result.fetchedAtUtc!),
                            )
                      : null;
                    final staleReasonMessage =
                      _formatTemplatesFallbackReason(result.reasonCode);

                  return Column(
                    children: <Widget>[
                      if (result.isStaleFallback)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Icon(Icons.warning_amber_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${staleWarningMessage ?? _l10n.mirrorTemplatesStaleFallbackWarning} ($staleReasonMessage)',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    final _ = ref
                                        .read(
                                          mirrorTemplatesInvalidationControllerProvider,
                                        )
                                        .invalidateTemplatesCache(refresh: true);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: Text(_l10n.mirrorRetryButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: TemplatesGallery(
                          templates: templates,
                          onTemplateSelected: (MirrorTemplate template) {
                            Navigator.of(context).pop();
                            _applyTemplateToSelectedFile(template);
                          },
                        ),
                      ),
                    ],
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
                final _ = ref
                    .read(mirrorTemplatesInvalidationControllerProvider)
                    .invalidateTemplatesCache(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text(_l10n.mirrorRetryButton),
            ),
          ],
        ),
      ),
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
    final confirmed = await _confirmVoiceInsert(
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
    _showVoiceInsertUndo(
      selectedFile: selectedFile,
      previousContent: existing,
    );
    return true;
  }

  Future<bool> _confirmVoiceInsert({
    required String selectedFile,
    required String sanitizedText,
  }) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm voice insert'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Target file: $selectedFile'),
                const SizedBox(height: 6),
                Text('Characters: ${sanitizedText.length}'),
                const SizedBox(height: 10),
                const Text('Preview'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SelectableText(
                    sanitizedText,
                    maxLines: 8,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Insert into editor'),
            ),
          ],
        );
      },
    );

    return decision == true;
  }

  void _showVoiceInsertUndo({
    required String selectedFile,
    required String previousContent,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Voice draft inserted into $selectedFile'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (!mounted) {
                return;
              }

              final currentState = ref.read(mirrorSessionProvider(_sessionKey));
              if (currentState.selectedFile != selectedFile) {
                _sessionNotifier.selectFile(selectedFile);
              }
              _sessionNotifier.updateSelectedFileContent(previousContent);
              _appendTerminalLine(
                  'Voice draft insert undone for $selectedFile.');
            },
          ),
        ),
      );
  }

  void _applyTemplateToSelectedFile(MirrorTemplate template) {
    final selectedFile =
        ref.read(mirrorSessionProvider(_sessionKey)).selectedFile;
    _sessionNotifier.updateSelectedFileContent(template.seedContent);
    _appendTerminalLine(
      _l10n.mirrorTemplateAppliedTerminal(selectedFile, template.title),
    );
  }

  void _appendTerminalLine(String line) {
    final structured = _tryParseStructuredMirrorError(line);
    final displayLine = structured == null
        ? line
        : _l10n.mirrorRunCrashedTerminal(
            structured.message ?? structured.errorFamily,
          );

    _sessionNotifier.appendTerminalLine(displayLine, maxLines: 1000);
    _terminal.write('$displayLine\\r\\n');

    if (structured == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _lastStructuredError = structured;
      });
    }
    if (structured.retryable) {
      _showRetryFeedback(structured);
    }
  }

  void _runCurrentFileInTerminal() {
    if (_isRunInProgress) {
      return;
    }

    final preflightState = ref.read(mirrorSessionProvider(_sessionKey));
    final budgetService = ref.read(mirrorContextBudgetServiceProvider);
    final budgetMessage = _preflightService.buildBudgetPreflightMessage(
      budgetService: budgetService,
      projectId: widget.projectId,
      taskId: widget.taskId,
      files: preflightState.files,
    );
    if (budgetMessage != null) {
      _appendTerminalLine(budgetMessage);
    }

    final beforeState = ref.read(mirrorSessionProvider(_sessionKey));
    final beforeTerminalCount = beforeState.terminalLog.length;

    setState(() {
      _lastStructuredError = null;
      _isRunInProgress = true;
    });

    final coordinator = ref.read(mirrorInteractiveRunCoordinatorProvider);
    coordinator
        .runCurrentFileInTerminal(
      context: context,
      ref: ref,
      projectId: widget.projectId,
      taskId: widget.taskId,
      selectedMode: ref.read(mirrorResolvedModeProvider),
      sessionKey: _sessionKey,
      l10n: _l10n,
      isMounted: () => mounted,
      appendTerminalLine: _appendTerminalLine,
    )
        .then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunInProgress = false;
      });

      final afterState = ref.read(mirrorSessionProvider(_sessionKey));
      final recentTerminalLines = afterState.terminalLog
          .skip(beforeTerminalCount)
          .toList(growable: false);
      final parsed = _findLatestStructuredError(recentTerminalLines);
      if (parsed != null) {
        setState(() {
          _lastStructuredError = parsed;
        });
        if (parsed.retryable) {
          _showRetryFeedback(parsed);
        }
        return;
      }

      final completed = recentTerminalLines
          .any((line) => line.contains(_l10n.mirrorRunCompletedTerminal));
      if (completed) {
        setState(() {
          _lastStructuredError = null;
        });
      }
    }).catchError((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRunInProgress = false;
      });
    });
  }

  Widget _buildRetryFeedbackCard(
    BuildContext context,
    _MirrorStructuredError error,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.refresh, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _l10n.mirrorRunCrashed(error.message ?? error.errorFamily),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _isRunInProgress ? null : _runCurrentFileInTerminal,
            child: Text(_l10n.mirrorRetryButton),
          ),
        ],
      ),
    );
  }

  _MirrorStructuredError? _findLatestStructuredError(List<String> lines) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final parsed = _tryParseStructuredMirrorError(lines[i]);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  _MirrorStructuredError? _tryParseStructuredMirrorError(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final segments = trimmed.split(' | ');
    for (final segment in segments) {
      try {
        final decoded = jsonDecode(segment);
        if (decoded is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(decoded);
        final family = map['error_family']?.toString().trim();
        if (family == null || family.isEmpty) {
          continue;
        }

        final retryableRaw = map['retryable'];
        final retryable =
            retryableRaw is bool ? retryableRaw : _isRetryableFamily(family);
        final message = map['message']?.toString().trim();

        return _MirrorStructuredError(
          errorFamily: family,
          retryable: retryable,
          message: (message == null || message.isEmpty) ? null : message,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  bool _isRetryableFamily(String family) {
    switch (family) {
      case 'network':
      case 'timeout':
      case 'rate_limited':
      case 'server_error':
        return true;
      default:
        return false;
    }
  }

  void _showRetryFeedback(_MirrorStructuredError error) {
    if (!mounted || !error.retryable) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _l10n.mirrorRunCrashed(error.message ?? error.errorFamily),
        ),
        action: SnackBarAction(
          label: _l10n.mirrorRetryButton,
          onPressed: _runCurrentFileInTerminal,
        ),
      ),
    );
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
    required this.mode,
    required this.isPremium,
    required this.isEnabled,
    required this.onModeChanged,
  });

  final AppLocalizations l10n;
  final String mode;
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
            key: ValueKey<String>(mode),
            initialValue: mode,
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

class _MirrorProvenanceDiagnostics extends StatelessWidget {
  const _MirrorProvenanceDiagnostics({required this.state});

  final MirrorState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = [
      'phase=${state.hydrationPhase.name}',
      'modeSource=${state.modeSource}',
      'premium=${state.premiumSource.name}',
      'team=${state.teamModeVariantSource.name}',
      'runner=${state.runnerModeVariantSource.name}',
      if (state.hydrationReasonCode != null) 'reason=${state.hydrationReasonCode}',
      if (state.fallbackReason != null) 'fallback=${state.fallbackReason}',
    ].join(' | ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        'Mirror diagnostics: $label',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _MirrorStructuredError {
  const _MirrorStructuredError({
    required this.errorFamily,
    required this.retryable,
    this.message,
  });

  final String errorFamily;
  final bool retryable;
  final String? message;
}
