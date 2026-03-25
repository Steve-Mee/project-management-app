import 'package:flutter/material.dart';

import '../../../core/providers/mirror_mode_controller_provider.dart';
import '../../../generated/app_localizations.dart';
import 'mirror_voice_prompt_bar.dart';

class MirrorEditorActionBar extends StatelessWidget {
  const MirrorEditorActionBar({
    super.key,
    required this.l10n,
    required this.projectId,
    required this.taskId,
    required this.mode,
    required this.isPremium,
    required this.isRunInProgress,
    required this.isListening,
    required this.showDiagnostics,
    required this.resolvedState,
    required this.onModeChanged,
    required this.onApplyVoiceToEditor,
    required this.onVoiceStatusMessage,
    required this.onListeningChanged,
    required this.onRunPressed,
    this.retryFeedbackCard,
    this.retryableError,
  });

  final AppLocalizations l10n;
  final String projectId;
  final String taskId;
  final String mode;
  final bool isPremium;
  final bool isRunInProgress;
  final bool isListening;
  final bool showDiagnostics;
  final MirrorState resolvedState;
  final ValueChanged<String> onModeChanged;
  final Future<bool> Function(String text) onApplyVoiceToEditor;
  final ValueChanged<String> onVoiceStatusMessage;
  final void Function({required bool isListening}) onListeningChanged;
  final VoidCallback onRunPressed;
  final Widget? retryFeedbackCard;
  final bool? retryableError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MirrorModeSelector(
          l10n: l10n,
          mode: mode,
          isPremium: isPremium,
          isEnabled: !isRunInProgress,
          onModeChanged: onModeChanged,
        ),
        const SizedBox(height: 12),
        if (showDiagnostics) ...<Widget>[
          MirrorProvenanceDiagnostics(state: resolvedState),
          const SizedBox(height: 8),
        ],
        Text(
          l10n.mirrorProjectTaskHeader(projectId, taskId),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        MirrorVoicePromptBar(
          isDisabled: isRunInProgress,
          onApplyToEditor: onApplyVoiceToEditor,
          onStatusMessage: onVoiceStatusMessage,
          onListeningChanged: onListeningChanged,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isRunInProgress || isListening ? null : onRunPressed,
          icon: isRunInProgress
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  retryableError == true ? Icons.refresh : Icons.play_arrow,
                ),
          label: Text(
            isRunInProgress
                ? l10n.mirrorRunningLabel
                : retryableError == true
                    ? l10n.mirrorRetryButton
                    : l10n.mirrorRunLabel,
          ),
        ),
        if (retryableError == true && retryFeedbackCard != null) ...<Widget>[
          const SizedBox(height: 8),
          retryFeedbackCard!,
        ],
      ],
    );
  }
}

class MirrorModeSelector extends StatelessWidget {
  const MirrorModeSelector({
    super.key,
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
                          horizontal: 8,
                          vertical: 2,
                        ),
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

class MirrorProvenanceDiagnostics extends StatelessWidget {
  const MirrorProvenanceDiagnostics({
    super.key,
    required this.state,
  });

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