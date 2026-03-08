import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';

class ApplyDialogResult {
  const ApplyDialogResult({
    required this.apply,
    required this.acceptRisk,
  });

  final bool apply;
  final bool acceptRisk;
}

class ApplyDialog extends StatefulWidget {
  const ApplyDialog({
    super.key,
    required this.title,
    required this.originalContent,
    required this.updatedContent,
    this.currentBranch = 'main',
    this.suggestedBranch = 'mirror/apply-changes',
  });

  final String title;
  final String originalContent;
  final String updatedContent;
  final String currentBranch;
  final String suggestedBranch;

  static Future<ApplyDialogResult?> show(
    BuildContext context, {
    required String title,
    required String originalContent,
    required String updatedContent,
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
    final diffLines = _buildDiffLines(
      widget.originalContent,
      widget.updatedContent,
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
              'Diff preview',
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
              title: const Text('Ik begrijp het risico van direct toepassen'),
              subtitle: const Text(
                'Wijzigingen worden toegepast op je werkmap. Gebruik bij voorkeur een aparte branch.',
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
              const ApplyDialogResult(apply: false, acceptRisk: false),
            );
          },
          child: const Text('Nee'),
        ),
        FilledButton(
          onPressed: _acceptRisk
              ? () {
                  Navigator.of(context).pop(
                    ApplyDialogResult(apply: true, acceptRisk: _acceptRisk),
                  );
                }
              : null,
          child: const Text('Ja, toepassen'),
        ),
      ],
    );
  }

  List<_DiffLine> _buildDiffLines(String oldText, String newText) {
    final a = oldText.split('\n');
    final b = newText.split('\n');

    final buffer = <_DiffLine>[];
    final diffs = calculateListDiff<String>(a, b, equalityChecker: (x, y) => x == y);

    var ai = 0;
    var bi = 0;

    for (final diff in diffs.getUpdates()) {
      while (ai < diff.source.start && bi < diff.destination.start) {
        buffer.add(_DiffLine(context: ' ', text: a[ai]));
        ai++;
        bi++;
      }

      for (var i = diff.source.start; i < diff.source.end; i++) {
        buffer.add(_DiffLine(context: '-', text: a[i]));
      }
      for (var i = diff.destination.start; i < diff.destination.end; i++) {
        buffer.add(_DiffLine(context: '+', text: b[i]));
      }

      ai = diff.source.end;
      bi = diff.destination.end;
    }

    while (ai < a.length && bi < b.length) {
      buffer.add(_DiffLine(context: ' ', text: a[ai]));
      ai++;
      bi++;
    }

    while (ai < a.length) {
      buffer.add(_DiffLine(context: '-', text: a[ai]));
      ai++;
    }

    while (bi < b.length) {
      buffer.add(_DiffLine(context: '+', text: b[bi]));
      bi++;
    }

    if (buffer.isEmpty) {
      buffer.add(const _DiffLine(context: ' ', text: '(Geen verschillen gedetecteerd)'));
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
            'Git branch advies',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text('Huidige branch: $currentBranch'),
          Text('Aanbevolen branch: $suggestedBranch'),
          const SizedBox(height: 6),
          const Text(
            'Tip: maak eerst een nieuwe branch voor veilige review en rollback.',
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
      '+' => colorScheme.tertiaryContainer.withOpacity(0.45),
      '-' => colorScheme.errorContainer.withOpacity(0.45),
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
