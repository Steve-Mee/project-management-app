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
}
