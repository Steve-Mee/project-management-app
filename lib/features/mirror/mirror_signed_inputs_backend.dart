import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models/project_context.dart';
import 'services/mirror_secure_apply_service.dart';

export 'models/project_context.dart';

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
    this.serverVersionToken,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final bool success;
  final String? output;
  final String? serverVersionToken;
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

typedef ApplySecurityArtifacts = MirrorSecureApplyArtifacts;
typedef ApplyUploadFailure = MirrorSecureApplyUploadFailure;
typedef ApplyUploadFailureCode = MirrorSecureApplyUploadFailureCode;

class MirrorFilePatch {
  const MirrorFilePatch({
    required this.path,
    required this.originalContent,
    required this.updatedContent,
    required this.diff,
  });

  final String path;
  final String originalContent;
  final String updatedContent;
  final String diff;
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
    String? compileFingerprint,
  });
}

String computeCompileResultFingerprint({
  required String prompt,
  required ProjectContext context,
  required String mode,
  required String output,
}) {
  final files = context.files.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final filesPayload =
      files.map((entry) => '${entry.key}:${entry.value}').join('|');
  final payload = <String>[
    prompt,
    context.projectId,
    context.taskId,
    mode,
    filesPayload,
    output,
  ].join('||');
  return sha256.convert(utf8.encode(payload)).toString();
}
