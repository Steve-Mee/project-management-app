import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../../core/providers/mirror_session_provider.dart';
import '../../../generated/app_localizations.dart';
import 'monaco_editor_host.dart';

class MirrorEditorAndTerminalPanel extends StatelessWidget {
  const MirrorEditorAndTerminalPanel({
    super.key,
    required this.sessionState,
    required this.terminal,
    required this.terminalController,
    required this.liveOutputScrollController,
    required this.isRunInProgress,
    required this.l10n,
    required this.languageForFile,
    required this.onEditorChanged,
  });

  final MirrorSessionState sessionState;
  final Terminal terminal;
  final TerminalController terminalController;
  final ScrollController liveOutputScrollController;
  final bool isRunInProgress;
  final AppLocalizations l10n;
  final String Function(String path) languageForFile;
  final ValueChanged<String> onEditorChanged;

  @override
  Widget build(BuildContext context) {
    final selectedFile = sessionState.selectedFile;
    final currentContent = sessionState.files[selectedFile] ?? '';

    return Column(
      children: <Widget>[
        Expanded(
          child: MirrorMonacoEditorPanel(
            selectedFile: selectedFile,
            code: currentContent,
            language: languageForFile(selectedFile),
            isRunInProgress: isRunInProgress,
            onChanged: onEditorChanged,
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 220,
          child: MirrorTerminalPanel(
            l10n: l10n,
            terminal: terminal,
            terminalController: terminalController,
            liveOutput: sessionState.liveOutput,
            liveOutputScrollController: liveOutputScrollController,
          ),
        ),
      ],
    );
  }
}

class MirrorMonacoEditorPanel extends StatelessWidget {
  const MirrorMonacoEditorPanel({
    super.key,
    required this.selectedFile,
    required this.code,
    required this.language,
    required this.isRunInProgress,
    required this.onChanged,
  });

  final String selectedFile;
  final String code;
  final String language;
  final bool isRunInProgress;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            selectedFile,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: MonacoEditorHost(
            code: code,
            language: language,
            theme: Theme.of(context).brightness == Brightness.dark
                ? 'vs-dark'
                : 'vs',
            onChanged: (String content) {
              if (isRunInProgress) {
                return;
              }
              onChanged(content);
            },
          ),
        ),
      ],
    );
  }
}

class MirrorTerminalPanel extends StatelessWidget {
  const MirrorTerminalPanel({
    super.key,
    required this.l10n,
    required this.terminal,
    required this.terminalController,
    required this.liveOutput,
    required this.liveOutputScrollController,
  });

  final AppLocalizations l10n;
  final Terminal terminal;
  final TerminalController terminalController;
  final List<String> liveOutput;
  final ScrollController liveOutputScrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Text(
            l10n.mirrorTerminalLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: TerminalView(
                  terminal,
                  controller: terminalController,
                  backgroundOpacity: 1,
                  autofocus: false,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: MirrorLiveOutputPanel(
                  l10n: l10n,
                  liveOutput: liveOutput,
                  liveOutputScrollController: liveOutputScrollController,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MirrorLiveOutputPanel extends StatelessWidget {
  const MirrorLiveOutputPanel({
    super.key,
    required this.l10n,
    required this.liveOutput,
    required this.liveOutputScrollController,
  });

  final AppLocalizations l10n;
  final List<String> liveOutput;
  final ScrollController liveOutputScrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Text(
            l10n.mirrorLiveOutputLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: liveOutput.isEmpty
              ? Center(
                  child: Text(
                    l10n.mirrorWaitingRealtime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  controller: liveOutputScrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: liveOutput.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext context, int index) {
                    final line = liveOutput[index];
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
}