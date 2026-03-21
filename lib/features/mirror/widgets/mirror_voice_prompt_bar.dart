// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../generated/app_localizations.dart';

/// A self-contained voice-input bar for the Mirror editor.
///
/// The widget owns the [stt.SpeechToText] lifecycle so the parent screen no
/// longer needs to hold voice state. The recognised transcript is surfaced in
/// an explicit preview card; **no text is ever written to a code file without
/// the user pressing the "Apply to editor" button**.
///
/// Callbacks
/// - [onApplyToEditor]   — called when the user confirms the draft should be
///   inserted into the active editor file. The string is trimmed.
/// - [onListeningChanged] — optional, notified whenever the listening state
///   changes, useful for suppressing other interactions in the parent.
class MirrorVoicePromptBar extends StatefulWidget {
  const MirrorVoicePromptBar({
    super.key,
    required this.isDisabled,
    required this.onApplyToEditor,
    this.onListeningChanged,
    this.onStatusMessage,
  });

  /// When true the "Apply to editor" button is disabled (e.g. a run is in
  /// progress). The microphone can still be toggled.
  final bool isDisabled;

  /// Called with the trimmed draft text when the user explicitly presses
  /// "Apply to editor". The parent should insert the string into the session.
  final Future<bool> Function(String text) onApplyToEditor;

  /// Optional: notified each time listening starts or stops.
  final void Function({required bool isListening})? onListeningChanged;

  /// Optional: called with a human-readable status line whenever a notable
  /// voice event occurs (started, stopped, error). The parent can write this
  /// to its terminal log.
  final void Function(String message)? onStatusMessage;

  @override
  State<MirrorVoicePromptBar> createState() => _MirrorVoicePromptBarState();
}

class _MirrorVoicePromptBarState extends State<MirrorVoicePromptBar> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isApplyingDraft = false;
  String _draft = '';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    // Best-effort async cleanup; no ref involved so no dispose-guard needed.
    _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  // ── Microphone toggle ─────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      widget.onStatusMessage?.call(_l10n.mirrorVoiceUnavailableTerminal);
      return;
    }

    _setListening(true);
    widget.onStatusMessage?.call(_l10n.mirrorVoiceStarted);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        setState(() => _draft = recognized);

        if (result.finalResult) {
          _setListening(false);
        }
      },
      onSoundLevelChange: (_) {},
      // ignore: deprecated_member_use
      cancelOnError: true,
      // ignore: deprecated_member_use
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    _setListening(false);
    widget.onStatusMessage?.call(_l10n.mirrorVoiceStopped);
  }

  void _setListening(bool value) {
    setState(() => _isListening = value);
    widget.onListeningChanged?.call(isListening: value);
  }

  // ── Actions from the draft card ───────────────────────────────────────────

  Future<void> _applyToEditor() async {
    if (_isApplyingDraft) {
      return;
    }

    final text = _draft.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isApplyingDraft = true);
    final applied = await widget.onApplyToEditor(text);
    if (!mounted) {
      return;
    }

    setState(() {
      _isApplyingDraft = false;
      if (applied) {
        _draft = '';
      }
    });
  }

  void _clearDraft() => setState(() => _draft = '');

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MicButton(
          isListening: _isListening,
          onTap: _toggleListening,
          l10n: _l10n,
        ),
        if (_draft.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _VoiceDraftCard(
            draft: _draft,
            isDisabled: widget.isDisabled || _isApplyingDraft,
            onApply: _applyToEditor,
            onClear: _clearDraft,
          ),
        ],
      ],
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isListening,
    required this.onTap,
    required this.l10n,
  });

  final bool isListening;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(isListening ? Icons.mic : Icons.mic_none),
      label: Text(
        isListening ? l10n.mirrorListeningLabel : l10n.mirrorVoiceInputLabel,
      ),
    );
  }
}

/// Read-only preview of the recognised transcript with explicit action buttons.
/// Text is **never** touched without the user pressing "Apply to editor".
class _VoiceDraftCard extends StatelessWidget {
  const _VoiceDraftCard({
    required this.draft,
    required this.isDisabled,
    required this.onApply,
    required this.onClear,
  });

  final String draft;
  final bool isDisabled;
  final Future<void> Function() onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
        color: cs.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.record_voice_over_outlined,
                  size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text('Voice draft — review before applying',
                  style: tt.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            draft,
            style: tt.bodyMedium,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: isDisabled ? null : onApply,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Apply to editor'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
