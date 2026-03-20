import '../models/project_context.dart';

class MirrorPromptBuilderService {
  const MirrorPromptBuilderService();

  String buildFullContext({
    required String prompt,
    required String projectId,
    required String taskId,
    required Map<String, String> files,
    required ProjectContextMetadata metadata,
    int maxFiles = 24,
    int maxFileChars = 6000,
    int maxTotalChars = 64000,
  }) {
    final sanitizedPrompt = _normalizeText(prompt).trim();
    final metadataSection = _buildMetadataSection(metadata);
    final teamModeSection = _buildTeamModeSection(metadata);
    final filesSection = _buildFilesSection(
      files,
      maxFiles: maxFiles,
      maxFileChars: maxFileChars,
      maxTotalChars: maxTotalChars,
    );

    final buffer = StringBuffer()
      ..writeln('### Mirror Context')
      ..writeln('project_id: $projectId')
      ..writeln('task_id: $taskId')
      ..writeln();

    if (metadataSection.isNotEmpty) {
      buffer
        ..writeln('### Metadata')
        ..writeln(metadataSection)
        ..writeln();
    }

    if (filesSection.isNotEmpty) {
      buffer
        ..writeln('### Workspace Files')
        ..writeln(filesSection)
        ..writeln();
    }

    if (metadata.hasTeamMode && teamModeSection.isNotEmpty) {
      buffer
        ..writeln('### Team Mode')
        ..writeln(teamModeSection)
        ..writeln();
    }

    buffer
      ..writeln('### User Request')
      ..writeln(sanitizedPrompt)
      ..writeln()
      ..writeln('### Response Contract')
      ..writeln('- Return deterministic output when possible.')
      ..writeln('- Prefer minimal edits and include only necessary changes.')
      ..writeln('- Mention assumptions if critical information is missing.')
      ..writeln(
          '- If Team Mode is enabled: follow Architect -> Coder -> Reviewer flow.');

    final full = buffer.toString();
    return _truncate(full, maxTotalChars);
  }
}

String _buildMetadataSection(ProjectContextMetadata metadata) {
  final lines = <String>[];
  _appendMetadataLine(lines, 'selectedFile', metadata.selectedFile);
  _appendMetadataLine(lines, 'trigger', metadata.trigger);
  _appendMetadataLine(lines, 'buildTarget', metadata.buildTarget);
  _appendMetadataLine(lines, 'priority', metadata.priority);
  _appendMetadataLine(lines, 'branch', metadata.branch);
  if (metadata.requiredFiles.isNotEmpty) {
    _appendMetadataLine(lines, 'requiredFiles', metadata.requiredFiles);
  }
  if (metadata.teamModeEnabled) {
    _appendMetadataLine(lines, 'teamMode', true);
  }
  if (metadata.teamRoles.isNotEmpty) {
    _appendMetadataLine(
      lines,
      'teamRoles',
      metadata.teamRoles.map((role) => role.name).toList(growable: false),
    );
  }
  _appendMetadataLine(lines, 'teamGoal', metadata.teamGoal);
  _appendMetadataLine(
    lines,
    'previewContextFingerprint',
    metadata.previewContextFingerprint,
  );
  _appendMetadataLine(
    lines,
    'previewCompileFingerprint',
    metadata.previewCompileFingerprint,
  );
  _appendMetadataLine(
    lines,
    'previewCompileOutputSha256',
    metadata.previewCompileOutputSha256,
  );
  final shouldWritePreviewReuseFields = metadata.previewReuseRequested ||
      metadata.previewReuseStrategy != ProjectContextPreviewReuseStrategy.none ||
      (metadata.previewServerVersionToken?.isNotEmpty ?? false) ||
      (metadata.previewArtifactPath?.isNotEmpty ?? false) ||
      metadata.previewReusePayload != null;
  if (shouldWritePreviewReuseFields) {
    _appendMetadataLine(
      lines,
      'previewReuseRequested',
      metadata.previewReuseRequested,
    );
    _appendMetadataLine(
      lines,
      'previewReuseStrategy',
      metadata.previewReuseStrategy.value,
    );
  }
  _appendMetadataLine(
    lines,
    'previewServerVersionToken',
    metadata.previewServerVersionToken,
  );
  _appendMetadataLine(lines, 'previewArtifactPath', metadata.previewArtifactPath);
  if (metadata.previewReusePayload != null) {
    _appendMetadataLine(
      lines,
      'previewReusePayload',
      metadata.previewReusePayload!.toJson(),
    );
  }
  _appendMetadataLine(lines, 'compileFingerprint', metadata.compileFingerprint);
  _appendMetadataLine(lines, 'idempotencyKey', metadata.idempotencyKey);

  if (lines.isEmpty) {
    return '';
  }

  return lines.join('\n');
}

void _appendMetadataLine(List<String> lines, String key, Object? value) {
  if (value == null) {
    return;
  }
  if (value is String && value.isEmpty) {
    return;
  }
  if (value is Iterable && value.isEmpty) {
    return;
  }
  if (value is Map && value.isEmpty) {
    return;
  }
  lines.add('- $key: ${_stringify(value)}');
}

String _buildTeamModeSection(ProjectContextMetadata metadata) {
  final roles = metadata.effectiveTeamRoles;
  if (roles.isEmpty) {
    return '';
  }

  final buffer = StringBuffer()
    ..writeln('Active roles: ${roles.map((role) => role.label).join(', ')}')
    ..writeln()
    ..writeln('Orchestration protocol:')
    ..writeln(
        '1. Architect: define implementation plan, constraints, and risk list.')
    ..writeln('2. Coder: implement the planned changes in minimal safe diffs.')
    ..writeln(
        '3. Reviewer: validate correctness, edge cases, regressions, and missing tests.')
    ..writeln()
    ..writeln('Role outputs:');

  if (roles.contains(ProjectContextTeamRole.architect)) {
    buffer.writeln('- Architect: architecture notes + exact change plan.');
  }
  if (roles.contains(ProjectContextTeamRole.coder)) {
    buffer.writeln('- Coder: concrete code patch details.');
  }
  if (roles.contains(ProjectContextTeamRole.reviewer)) {
    buffer.writeln(
        '- Reviewer: findings ordered by severity with follow-up actions.');
  }

  final customGoal = metadata.teamGoal;
  if (customGoal != null) {
    buffer
      ..writeln()
      ..writeln('Team objective: ${_stringify(customGoal)}');
  }

  return buffer.toString().trim();
}

String _buildFilesSection(
  Map<String, String> files, {
  required int maxFiles,
  required int maxFileChars,
  required int maxTotalChars,
}) {
  if (files.isEmpty) {
    return '';
  }

  final sortedPaths = files.keys.toList()..sort();
  final selectedPaths = sortedPaths.take(maxFiles);
  final buffer = StringBuffer();
  var budgetLeft = maxTotalChars;

  for (final path in selectedPaths) {
    if (budgetLeft <= 0) {
      break;
    }

    final raw = files[path] ?? '';
    final normalized = _normalizeText(raw);
    final content = _truncate(normalized, maxFileChars);

    final entry = StringBuffer()
      ..writeln('```file:$path')
      ..writeln(content)
      ..writeln('```')
      ..writeln();

    final entryText = entry.toString();
    if (entryText.length > budgetLeft) {
      final shortened = _truncate(entryText, budgetLeft);
      buffer.writeln(shortened);
      break;
    }

    buffer.write(entryText);
    budgetLeft -= entryText.length;
  }

  final remaining = files.length - selectedPaths.length;
  if (remaining > 0 && budgetLeft > 0) {
    buffer.writeln('- ... $remaining additional files omitted');
  }

  return buffer.toString().trim();
}

String _normalizeText(String input) {
  return input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String _truncate(String input, int maxChars) {
  if (maxChars <= 0) {
    return '';
  }
  if (input.length <= maxChars) {
    return input;
  }
  return '${input.substring(0, maxChars)}\n...[truncated]';
}

String _stringify(dynamic value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  if (value is Iterable) {
    return value.map(_stringify).join(', ');
  }
  if (value is Map) {
    final entries = value.entries
        .map((entry) => '${entry.key}: ${_stringify(entry.value)}')
        .join(', ');
    return '{$entries}';
  }
  return value.toString();
}
