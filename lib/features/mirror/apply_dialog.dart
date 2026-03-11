import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

class ApplyDialogResult {
  const ApplyDialogResult({
    required this.apply,
    required this.acceptRisk,
    required this.compileFingerprint,
  });

  final bool apply;
  final bool acceptRisk;
  final String compileFingerprint;
}

class ApplyDialog extends StatefulWidget {
  const ApplyDialog({
    super.key,
    required this.title,
    required this.originalContent,
    required this.updatedContent,
    required this.compileFingerprint,
    this.currentBranch = 'main',
    this.suggestedBranch = 'mirror/apply-changes',
  });

  final String title;
  final String originalContent;
  final String updatedContent;
  final String compileFingerprint;
  final String currentBranch;
  final String suggestedBranch;

  static Future<ApplyDialogResult?> show(
    BuildContext context, {
    required String title,
    required String originalContent,
    required String updatedContent,
    required String compileFingerprint,
    String currentBranch = 'main',
    String suggestedBranch = 'mirror/apply-changes',
  }) {
    return showDialog<ApplyDialogResult>(
      context: context,
      builder: (BuildContext context) {
        return ApplyDialog(
          title: title,
          originalContent: originalContent,
          updatedContent: updatedContent,
          compileFingerprint: compileFingerprint,
          currentBranch: currentBranch,
          suggestedBranch: suggestedBranch,
        );
      },
    );
  }

  @override
  State<ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<ApplyDialog> {
  bool _acceptRisk = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diffLines = _buildDiffLines(
      widget.originalContent,
      widget.updatedContent,
      noDiffText: l10n.mirrorApplyNoDiff,
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 900,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _BranchInfoCard(
              currentBranch: widget.currentBranch,
              suggestedBranch: widget.suggestedBranch,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.mirrorApplyDiffPreview,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: diffLines.length,
                  itemBuilder: (BuildContext context, int index) {
                    final line = diffLines[index];
                    return _DiffLineTile(line: line);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.mirrorApplyRiskAcknowledgeTitle),
              subtitle: Text(
                AppLocalizations.of(context)!.mirrorApplyRiskAcknowledgeSubtitle,
              ),
              value: _acceptRisk,
              onChanged: (bool value) {
                setState(() {
                  _acceptRisk = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              ApplyDialogResult(
                apply: false,
                acceptRisk: false,
                compileFingerprint: widget.compileFingerprint,
              ),
            );
          },
          child: Text(l10n.mirrorApplyNo),
        ),
        FilledButton(
          onPressed: _acceptRisk
              ? () {
                  Navigator.of(context).pop(
                    ApplyDialogResult(
                      apply: true,
                      acceptRisk: _acceptRisk,
                      compileFingerprint: widget.compileFingerprint,
                    ),
                  );
                }
              : null,
          child: Text(l10n.mirrorApplyConfirm),
        ),
      ],
    );
  }

  List<_DiffLine> _buildDiffLines(
    String oldText,
    String newText, {
    required String noDiffText,
  }) {
    final a = oldText.split('\n');
    final b = newText.split('\n');

    final buffer = <_DiffLine>[];
    final maxLines = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < maxLines; i++) {
      final left = i < a.length ? a[i] : null;
      final right = i < b.length ? b[i] : null;

      if (left != null && right != null) {
        if (left == right) {
          buffer.add(_DiffLine(context: ' ', text: left));
        } else {
          buffer.add(_DiffLine(context: '-', text: left));
          buffer.add(_DiffLine(context: '+', text: right));
        }
      } else if (left != null) {
        buffer.add(_DiffLine(context: '-', text: left));
      } else if (right != null) {
        buffer.add(_DiffLine(context: '+', text: right));
      }
    }

    if (buffer.isEmpty) {
      buffer.add(_DiffLine(context: ' ', text: noDiffText));
    }

    return buffer;
  }
}

class _BranchInfoCard extends StatelessWidget {
  const _BranchInfoCard({
    required this.currentBranch,
    required this.suggestedBranch,
  });

  final String currentBranch;
  final String suggestedBranch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.mirrorApplyBranchAdviceTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context)!.mirrorApplyCurrentBranch(currentBranch)),
          Text(AppLocalizations.of(context)!.mirrorApplySuggestedBranch(suggestedBranch)),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.mirrorApplyBranchTip,
          ),
          const SizedBox(height: 6),
          Text(
            'Mirror applies changes in your current working tree and does not create or switch branches automatically.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DiffLineTile extends StatelessWidget {
  const _DiffLineTile({required this.line});

  final _DiffLine line;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = switch (line.context) {
      '+' => colorScheme.tertiaryContainer.withValues(alpha: 0.45),
      '-' => colorScheme.errorContainer.withValues(alpha: 0.45),
      _ => Colors.transparent,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        '${line.context} ${line.text}',
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DiffLine {
  const _DiffLine({
    required this.context,
    required this.text,
  });

  final String context;
  final String text;
}
