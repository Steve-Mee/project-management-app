class ProjectContext {
  const ProjectContext({
    required this.projectId,
    required this.taskId,
    this.files = const <String, String>{},
    this.metadata = const <String, dynamic>{},
  });

  final String projectId;
  final String taskId;
  final Map<String, String> files;
  final Map<String, dynamic> metadata;
}

class GenerateResult {
  const GenerateResult({
    required this.success,
    this.code,
    this.message,
    this.diagnostics = const <String>[],
  });

  final bool success;
  final String? code;
  final String? message;
  final List<String> diagnostics;
}

class CompileResult {
  const CompileResult({
    required this.success,
    this.output,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final bool success;
  final String? output;
  final List<String> errors;
  final List<String> warnings;
}

class ApplyResult {
  const ApplyResult({
    required this.success,
    this.appliedFiles = const <String>[],
    this.message,
  });

  final bool success;
  final List<String> appliedFiles;
  final String? message;
}

abstract class MirrorComputeBackend {
  Future<String> buildFullContext({
    required String prompt,
    required ProjectContext context,
    int maxFiles = 24,
    int maxFileChars = 6000,
    int maxTotalChars = 64000,
  }) async {
    final sanitizedPrompt = _normalizeText(prompt).trim();
    final metadataSection = _buildMetadataSection(context.metadata);
    final filesSection = _buildFilesSection(
      context.files,
      maxFiles: maxFiles,
      maxFileChars: maxFileChars,
      maxTotalChars: maxTotalChars,
    );

    final buffer = StringBuffer()
      ..writeln('### Mirror Context')
      ..writeln('project_id: ${context.projectId}')
      ..writeln('task_id: ${context.taskId}')
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

    buffer
      ..writeln('### User Request')
      ..writeln(sanitizedPrompt)
      ..writeln()
      ..writeln('### Response Contract')
      ..writeln('- Return deterministic output when possible.')
      ..writeln('- Prefer minimal edits and include only necessary changes.')
      ..writeln('- Mention assumptions if critical information is missing.');

    final full = buffer.toString();
    return _truncate(full, maxTotalChars);
  }

  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  String _buildMetadataSection(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) {
      return '';
    }

    final sortedKeys = metadata.keys.toList()..sort();
    final lines = <String>[];
    for (final key in sortedKeys) {
      lines.add('- $key: ${_stringify(metadata[key])}');
    }
    return lines.join('\n');
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
}
