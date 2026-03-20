class MirrorDiffLine {
  const MirrorDiffLine({
    required this.text,
    required this.kind,
  });

  final String text;
  final MirrorDiffLineKind kind;
}

enum MirrorDiffLineKind {
  added,
  removed,
  context,
  hunkHeader,
  fileHeader,
  info,
}

class MirrorDiffService {
  const MirrorDiffService();

  List<MirrorDiffLine> buildUnifiedDiffLines({
    required String oldText,
    required String newText,
    required String noDiffText,
    String oldLabel = 'a/file',
    String newLabel = 'b/file',
    int contextLines = 3,
  }) {
    final oldLines = _splitLines(oldText);
    final newLines = _splitLines(newText);
    final ops = _buildOps(oldLines, newLines);

    final hasChanges = ops.any((op) => op.kind != _DiffOpKind.equal);
    if (!hasChanges) {
      return <MirrorDiffLine>[
        MirrorDiffLine(text: noDiffText, kind: MirrorDiffLineKind.info),
      ];
    }

    final lines = <MirrorDiffLine>[
      MirrorDiffLine(text: '--- $oldLabel', kind: MirrorDiffLineKind.fileHeader),
      MirrorDiffLine(text: '+++ $newLabel', kind: MirrorDiffLineKind.fileHeader),
    ];

    final hunks = _buildHunks(ops, contextLines);
    for (final hunk in hunks) {
      lines.add(
        MirrorDiffLine(
          text:
              '@@ -${hunk.oldStart},${hunk.oldLength} +${hunk.newStart},${hunk.newLength} @@',
          kind: MirrorDiffLineKind.hunkHeader,
        ),
      );

      for (final op in hunk.lines) {
        switch (op.kind) {
          case _DiffOpKind.equal:
            lines.add(
              MirrorDiffLine(
                text: ' ${op.text}',
                kind: MirrorDiffLineKind.context,
              ),
            );
            break;
          case _DiffOpKind.remove:
            lines.add(
              MirrorDiffLine(
                text: '-${op.text}',
                kind: MirrorDiffLineKind.removed,
              ),
            );
            break;
          case _DiffOpKind.add:
            lines.add(
              MirrorDiffLine(
                text: '+${op.text}',
                kind: MirrorDiffLineKind.added,
              ),
            );
            break;
        }
      }
    }

    return lines;
  }

  List<String> _splitLines(String value) {
    if (value.isEmpty) {
      return const <String>[];
    }
    return value.split('\n');
  }

  List<_DiffOp> _buildOps(List<String> oldLines, List<String> newLines) {
    final n = oldLines.length;
    final m = newLines.length;
    final lcs = List<List<int>>.generate(
      n + 1,
      (_) => List<int>.filled(m + 1, 0),
    );

    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        if (oldLines[i] == newLines[j]) {
          lcs[i][j] = lcs[i + 1][j + 1] + 1;
        } else {
          final down = lcs[i + 1][j];
          final right = lcs[i][j + 1];
          lcs[i][j] = down >= right ? down : right;
        }
      }
    }

    final ops = <_DiffOp>[];
    var i = 0;
    var j = 0;

    while (i < n && j < m) {
      if (oldLines[i] == newLines[j]) {
        ops.add(_DiffOp(kind: _DiffOpKind.equal, text: oldLines[i]));
        i += 1;
        j += 1;
        continue;
      }

      if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        ops.add(_DiffOp(kind: _DiffOpKind.remove, text: oldLines[i]));
        i += 1;
      } else {
        ops.add(_DiffOp(kind: _DiffOpKind.add, text: newLines[j]));
        j += 1;
      }
    }

    while (i < n) {
      ops.add(_DiffOp(kind: _DiffOpKind.remove, text: oldLines[i]));
      i += 1;
    }

    while (j < m) {
      ops.add(_DiffOp(kind: _DiffOpKind.add, text: newLines[j]));
      j += 1;
    }

    return ops;
  }

  List<_Hunk> _buildHunks(List<_DiffOp> ops, int contextLines) {
    final changeIndexes = <int>[];
    for (var i = 0; i < ops.length; i++) {
      if (ops[i].kind != _DiffOpKind.equal) {
        changeIndexes.add(i);
      }
    }

    if (changeIndexes.isEmpty) {
      return const <_Hunk>[];
    }

    final ranges = <_Range>[];
    var blockStart = changeIndexes.first;
    var blockEnd = changeIndexes.first;

    for (var i = 1; i < changeIndexes.length; i++) {
      final current = changeIndexes[i];
      if (current - blockEnd <= contextLines * 2 + 1) {
        blockEnd = current;
      } else {
        ranges.add(_Range(start: blockStart, end: blockEnd));
        blockStart = current;
        blockEnd = current;
      }
    }
    ranges.add(_Range(start: blockStart, end: blockEnd));

    final hunks = <_Hunk>[];
    for (final range in ranges) {
      final start = (range.start - contextLines).clamp(0, ops.length);
      final end = (range.end + contextLines + 1).clamp(0, ops.length);

      var oldStart = 1;
      var newStart = 1;
      for (var i = 0; i < start; i++) {
        final op = ops[i];
        if (op.kind != _DiffOpKind.add) {
          oldStart += 1;
        }
        if (op.kind != _DiffOpKind.remove) {
          newStart += 1;
        }
      }

      var oldLength = 0;
      var newLength = 0;
      for (var i = start; i < end; i++) {
        final op = ops[i];
        if (op.kind != _DiffOpKind.add) {
          oldLength += 1;
        }
        if (op.kind != _DiffOpKind.remove) {
          newLength += 1;
        }
      }

      hunks.add(
        _Hunk(
          oldStart: oldStart,
          oldLength: oldLength,
          newStart: newStart,
          newLength: newLength,
          lines: ops.sublist(start, end),
        ),
      );
    }

    return hunks;
  }
}

class _DiffOp {
  const _DiffOp({
    required this.kind,
    required this.text,
  });

  final _DiffOpKind kind;
  final String text;
}

enum _DiffOpKind { equal, remove, add }

class _Hunk {
  const _Hunk({
    required this.oldStart,
    required this.oldLength,
    required this.newStart,
    required this.newLength,
    required this.lines,
  });

  final int oldStart;
  final int oldLength;
  final int newStart;
  final int newLength;
  final List<_DiffOp> lines;
}

class _Range {
  const _Range({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}
