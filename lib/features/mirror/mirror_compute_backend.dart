import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class ApplySecurityArtifacts {
  const ApplySecurityArtifacts({
    required this.backupId,
    required this.signedInputUrls,
    required this.backupSignedUrls,
    required this.createdAt,
    this.uploadFailures = const <ApplyUploadFailure>[],
  });

  final String backupId;
  final Map<String, String> signedInputUrls;
  final Map<String, String> backupSignedUrls;
  final DateTime createdAt;
  final List<ApplyUploadFailure> uploadFailures;
}

class ApplyUploadFailure {
  const ApplyUploadFailure({
    required this.filePath,
    required this.code,
    required this.stage,
    required this.error,
  });

  final String filePath;
  final ApplyUploadFailureCode code;
  final String stage;
  final String error;
}

enum ApplyUploadFailureCode {
  authUserMissing('auth_user_missing'),
  signedInputUploadFailed('signed_input_upload_failed'),
  backupUploadFailed('backup_upload_failed'),
  signedInputUrlFailed('signed_input_url_failed'),
  backupUrlFailed('backup_url_failed');

  const ApplyUploadFailureCode(this.value);

  final String value;
}

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
  });
}

extension MirrorPatchTools on MirrorComputeBackend {
  List<MirrorFilePatch> buildPatchesFromApplyPayload({
    required ProjectContext context,
    required String output,
    String? fallbackPath,
  }) {
    final patches = <MirrorFilePatch>[];
    final parsed = _tryParseApplyPayload(output);

    if (parsed != null) {
      final filesRaw = parsed['files'];
      if (filesRaw is Map) {
        for (final entry in filesRaw.entries) {
          final path = entry.key.toString();
          final updated = entry.value?.toString() ?? '';
          final original = context.files[path] ?? '';
          if (original == updated) {
            continue;
          }
          patches.add(
            MirrorFilePatch(
              path: path,
              originalContent: original,
              updatedContent: updated,
              diff: _buildUnifiedDiff(path: path, before: original, after: updated),
            ),
          );
        }
      }

      final patchListRaw = parsed['patches'];
      if (patchListRaw is List) {
        for (final item in patchListRaw) {
          if (item is! Map) {
            continue;
          }
          final normalized = Map<String, dynamic>.from(item);
          final path = normalized['path']?.toString();
          final updated =
              normalized['updatedContent']?.toString() ??
              normalized['content']?.toString();
          if (path == null || path.isEmpty || updated == null) {
            continue;
          }

          final original = context.files[path] ?? '';
          if (original == updated) {
            continue;
          }

          final alreadyExists = patches.any((patch) => patch.path == path);
          if (alreadyExists) {
            continue;
          }

          patches.add(
            MirrorFilePatch(
              path: path,
              originalContent: original,
              updatedContent: updated,
              diff: _buildUnifiedDiff(path: path, before: original, after: updated),
            ),
          );
        }
      }
    }

    if (patches.isNotEmpty) {
      return patches;
    }

    final targetPath = fallbackPath ?? _resolveFallbackPath(context);
    if (targetPath == null || targetPath.isEmpty) {
      return const <MirrorFilePatch>[];
    }

    final original = context.files[targetPath] ?? '';
    if (original == output) {
      return const <MirrorFilePatch>[];
    }

    return <MirrorFilePatch>[
      MirrorFilePatch(
        path: targetPath,
        originalContent: original,
        updatedContent: output,
        diff: _buildUnifiedDiff(path: targetPath, before: original, after: output),
      ),
    ];
  }

  Map<String, String> applyPatchesToFiles({
    required Map<String, String> files,
    required List<MirrorFilePatch> patches,
  }) {
    final updated = Map<String, String>.from(files);
    for (final patch in patches) {
      updated[patch.path] = patch.updatedContent;
    }
    return updated;
  }

  Future<void> persistApplyToHive({
    required ProjectContext context,
    required String mode,
    required String prompt,
    required List<MirrorFilePatch> patches,
    required ApplySecurityArtifacts artifacts,
    String backend = 'unknown',
    Map<String, String> updatedFiles = const <String, String>{},
  }) async {
    final box = await _openApplyHistoryBox();
    final key = '${context.projectId}::${context.taskId}';
    final existing = box.get(key);

    final history = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          history.add(Map<String, dynamic>.from(item));
        }
      }
    }

    history.add(<String, dynamic>{
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'projectId': context.projectId,
      'taskId': context.taskId,
      'mode': mode,
      'backend': backend,
      'prompt': _truncate(prompt, 1000),
      'backupId': artifacts.backupId,
      'signedInputUrls': artifacts.signedInputUrls,
      'backupSignedUrls': artifacts.backupSignedUrls,
      'appliedFiles': patches.map((patch) => patch.path).toList(),
      'patches': patches
          .map(
            (patch) => <String, dynamic>{
              'path': patch.path,
              'diff': patch.diff,
            },
          )
          .toList(),
      'updatedFiles': updatedFiles,
    });

    const maxHistoryEntries = 40;
    final trimmed = history.length <= maxHistoryEntries
        ? history
        : history.sublist(history.length - maxHistoryEntries);

    await box.put(key, trimmed);
  }
}

extension MirrorApplySecurity on MirrorComputeBackend {
  Future<ApplySecurityArtifacts> prepareSignedInputAndBackup({
    required ProjectContext context,
    Duration signedUrlTtl = const Duration(minutes: 30),
    String signedInputBucket = 'mirror-signed-inputs',
    String backupBucket = 'mirror-backups',
  }) async {
    final client = Supabase.instance.client;
    final authUserId = client.auth.currentUser?.id;
    final backupId = _buildBackupId(context);
    final signedInputUrls = <String, String>{};
    final backupSignedUrls = <String, String>{};
    final uploadFailures = <ApplyUploadFailure>[];

    if (authUserId == null || authUserId.isEmpty) {
      return ApplySecurityArtifacts(
        backupId: backupId,
        signedInputUrls: signedInputUrls,
        backupSignedUrls: backupSignedUrls,
        createdAt: DateTime.now().toUtc(),
        uploadFailures: const <ApplyUploadFailure>[
          ApplyUploadFailure(
            filePath: '*',
            code: ApplyUploadFailureCode.authUserMissing,
            stage: 'auth-user',
            error: 'Authenticated user is required for owner-scoped storage paths.',
          ),
        ],
      );
    }

    for (final entry in context.files.entries) {
      final sanitizedPath = _sanitizeStoragePath(entry.key);
      final signedInputPath =
          '$authUserId/${context.projectId}/${context.taskId}/$backupId/input/$sanitizedPath';
      final backupPath =
          '$authUserId/${context.projectId}/${context.taskId}/$backupId/backup/$sanitizedPath';
      final payload = utf8.encode(entry.value);

      try {
        await _uploadReplaceBinary(
          client: client,
          bucket: signedInputBucket,
          path: signedInputPath,
          bytes: payload,
        );
      } catch (error) {
        uploadFailures.add(
          ApplyUploadFailure(
            filePath: entry.key,
            code: ApplyUploadFailureCode.signedInputUploadFailed,
            stage: 'signed-input-upload',
            error: error.toString(),
          ),
        );
        continue;
      }

      try {
        await _uploadReplaceBinary(
          client: client,
          bucket: backupBucket,
          path: backupPath,
          bytes: payload,
        );
      } catch (error) {
        uploadFailures.add(
          ApplyUploadFailure(
            filePath: entry.key,
            code: ApplyUploadFailureCode.backupUploadFailed,
            stage: 'backup-upload',
            error: error.toString(),
          ),
        );
        continue;
      }

      late final String signedInputUrl;
      try {
        signedInputUrl = await client.storage
            .from(signedInputBucket)
            .createSignedUrl(signedInputPath, signedUrlTtl.inSeconds);
      } catch (error) {
        uploadFailures.add(
          ApplyUploadFailure(
            filePath: entry.key,
            code: ApplyUploadFailureCode.signedInputUrlFailed,
            stage: 'signed-input-url',
            error: error.toString(),
          ),
        );
        continue;
      }

      late final String backupSignedUrl;
      try {
        backupSignedUrl = await client.storage
            .from(backupBucket)
            .createSignedUrl(backupPath, signedUrlTtl.inSeconds);
      } catch (error) {
        uploadFailures.add(
          ApplyUploadFailure(
            filePath: entry.key,
            code: ApplyUploadFailureCode.backupUrlFailed,
            stage: 'backup-url',
            error: error.toString(),
          ),
        );
        continue;
      }

      signedInputUrls[entry.key] = signedInputUrl;
      backupSignedUrls[entry.key] = backupSignedUrl;
    }

    return ApplySecurityArtifacts(
      backupId: backupId,
      signedInputUrls: signedInputUrls,
      backupSignedUrls: backupSignedUrls,
      createdAt: DateTime.now().toUtc(),
      uploadFailures: uploadFailures,
    );
  }

  Future<ApplyResult> secureApply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required Future<ApplyResult> Function(ApplySecurityArtifacts artifacts)
    onApply,
    Duration signedUrlTtl = const Duration(minutes: 30),
    String signedInputBucket = 'mirror-signed-inputs',
    String backupBucket = 'mirror-backups',
  }) async {
    final actorUserId = Supabase.instance.client.auth.currentUser?.id;
    final sourceFingerprint = _fingerprintFiles(context.files);

    await _writeApplyAuditEvent(
      projectId: context.projectId,
      taskId: context.taskId,
      mode: mode,
      event: 'apply_started',
      actorUserId: actorUserId,
      fileSetFingerprint: sourceFingerprint,
    );

    final artifacts = await prepareSignedInputAndBackup(
      context: context,
      signedUrlTtl: signedUrlTtl,
      signedInputBucket: signedInputBucket,
      backupBucket: backupBucket,
    );

    if (artifacts.uploadFailures.isNotEmpty) {
      final lines = artifacts.uploadFailures
          .map((failure) =>
              '${failure.filePath} [${failure.code.value}] (${failure.stage}): ${failure.error}')
          .join('; ');
      await _writeApplyAuditEvent(
        projectId: context.projectId,
        taskId: context.taskId,
        mode: mode,
        event: 'apply_preparation_failed',
        actorUserId: actorUserId,
        backupId: artifacts.backupId,
        success: false,
        fileSetFingerprint: sourceFingerprint,
        details: <String, dynamic>{
          'failureCount': artifacts.uploadFailures.length,
          'details': lines,
        },
      );
      return ApplyResult(
        success: false,
        appliedFiles: const <String>[],
        message:
            'Apply preparation failed for one or more files. Backup ID: ${artifacts.backupId}. Details: $lines',
      );
    }

    late final ApplyResult result;
    try {
      result = await onApply(artifacts);
    } catch (error) {
      await _writeApplyAuditEvent(
        projectId: context.projectId,
        taskId: context.taskId,
        mode: mode,
        event: 'apply_exception',
        actorUserId: actorUserId,
        backupId: artifacts.backupId,
        success: false,
        fileSetFingerprint: sourceFingerprint,
        details: <String, dynamic>{
          'error': error.toString(),
        },
      );
      rethrow;
    }

    await _writeApplyAuditEvent(
      projectId: context.projectId,
      taskId: context.taskId,
      mode: mode,
      event: 'apply_completed',
      actorUserId: actorUserId,
      backupId: artifacts.backupId,
      success: result.success,
      appliedFiles: result.appliedFiles,
      message: result.message,
      fileSetFingerprint: sourceFingerprint,
      appliedFilesFingerprint: _fingerprintStrings(result.appliedFiles),
    );

    if (result.success) {
      return result;
    }

    return ApplyResult(
      success: false,
      appliedFiles: result.appliedFiles,
      message:
          '${result.message ?? 'Apply failed.'} Backup ID: ${artifacts.backupId}',
    );
  }
}

extension MirrorPromptBuilder on MirrorComputeBackend {
  Future<String> buildFullContext({
    required String prompt,
    required ProjectContext context,
    int maxFiles = 24,
    int maxFileChars = 6000,
    int maxTotalChars = 64000,
  }) async {
    final sanitizedPrompt = _normalizeText(prompt).trim();
    final metadataSection = _buildMetadataSection(context.metadata);
    final teamModeEnabled = _isTeamModeEnabled(context.metadata);
    final teamModeSection = _buildTeamModeSection(context.metadata);
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

    if (teamModeEnabled && teamModeSection.isNotEmpty) {
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
      ..writeln('- If Team Mode is enabled: follow Architect -> Coder -> Reviewer flow.');

    final full = buffer.toString();
    return _truncate(full, maxTotalChars);
  }
}

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

String _buildBackupId(ProjectContext context) {
  final now = DateTime.now().toUtc().toIso8601String();
  final seed = '${context.projectId}:${context.taskId}:$now';
  return sha256.convert(utf8.encode(seed)).toString().substring(0, 20);
}

String _sanitizeStoragePath(String value) {
  final normalized = value.replaceAll('\\', '/').trim();
  final parts = normalized
      .split('/')
      .where((part) => part.isNotEmpty)
      .map((part) => part.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_'));
  return parts.join('/');
}

Future<void> _uploadReplaceBinary({
  required SupabaseClient client,
  required String bucket,
  required String path,
  required List<int> bytes,
}) async {
  await client.storage.from(bucket).uploadBinary(
    path,
    Uint8List.fromList(bytes),
    fileOptions: const FileOptions(upsert: true),
  );
}

Future<Box<dynamic>> _openApplyHistoryBox() async {
  const boxName = 'mirror_apply_history';
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box<dynamic>(boxName);
  }
  return Hive.openBox<dynamic>(boxName);
}

Future<Box<dynamic>> _openApplyAuditBox() async {
  const boxName = 'mirror_apply_audit';
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box<dynamic>(boxName);
  }
  return Hive.openBox<dynamic>(boxName);
}

Future<void> _writeApplyAuditEvent({
  required String projectId,
  required String taskId,
  required String mode,
  required String event,
  String? actorUserId,
  String? backupId,
  bool? success,
  List<String> appliedFiles = const <String>[],
  String? message,
  String? fileSetFingerprint,
  String? appliedFilesFingerprint,
  Map<String, dynamic> details = const <String, dynamic>{},
}) async {
  try {
    final box = await _openApplyAuditBox();
    await box.add(<String, dynamic>{
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'projectId': projectId,
      'taskId': taskId,
      'mode': mode,
      'event': event,
      'actorUserId': actorUserId,
      'backupId': backupId,
      'success': success,
      'appliedFiles': appliedFiles,
      'message': message,
      'fileSetFingerprint': fileSetFingerprint,
      'appliedFilesFingerprint': appliedFilesFingerprint,
      'details': details,
    });

    const maxAuditEntries = 500;
    while (box.length > maxAuditEntries) {
      await box.deleteAt(0);
    }
  } catch (_) {
    // Audit logging must never interrupt apply flow.
  }
}

String _fingerprintFiles(Map<String, String> files) {
  final paths = files.keys.toList()..sort();
  final buffer = StringBuffer();
  for (final path in paths) {
    buffer
      ..write(path)
      ..write(':')
      ..write(files[path] ?? '')
      ..write('\n');
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

String _fingerprintStrings(List<String> values) {
  final sorted = values.toList()..sort();
  return sha256.convert(utf8.encode(sorted.join('\n'))).toString();
}

Map<String, dynamic>? _tryParseApplyPayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    return null;
  }
  return null;
}

String? _resolveFallbackPath(ProjectContext context) {
  final fromMetadata =
      context.metadata['activeFile'] ?? context.metadata['active_file'];
  if (fromMetadata != null && fromMetadata.toString().trim().isNotEmpty) {
    return fromMetadata.toString().trim();
  }
  if (context.files.isNotEmpty) {
    return context.files.keys.first;
  }
  return null;
}

String _buildUnifiedDiff({
  required String path,
  required String before,
  required String after,
}) {
  final beforeLines = before.split('\n');
  final afterLines = after.split('\n');
  final max = beforeLines.length > afterLines.length
      ? beforeLines.length
      : afterLines.length;

  final buffer = StringBuffer()
    ..writeln('--- a/$path')
    ..writeln('+++ b/$path');

  for (var index = 0; index < max; index++) {
    final left = index < beforeLines.length ? beforeLines[index] : null;
    final right = index < afterLines.length ? afterLines[index] : null;

    if (left == right) {
      if (left != null) {
        buffer.writeln(' $left');
      }
      continue;
    }

    if (left != null) {
      buffer.writeln('-$left');
    }
    if (right != null) {
      buffer.writeln('+$right');
    }
  }

  return buffer.toString().trimRight();
}

bool _isTeamModeEnabled(Map<String, dynamic> metadata) {
  final value = metadata['teamMode'] ?? metadata['team_mode'] ?? metadata['multiAgent'];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'enabled';
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

String _buildTeamModeSection(Map<String, dynamic> metadata) {
  final roles = _resolveTeamRoles(metadata);
  if (roles.isEmpty) {
    return '';
  }

  final buffer = StringBuffer()
    ..writeln('Active roles: ${roles.join(', ')}')
    ..writeln()
    ..writeln('Orchestration protocol:')
    ..writeln('1. Architect: define implementation plan, constraints, and risk list.')
    ..writeln('2. Coder: implement the planned changes in minimal safe diffs.')
    ..writeln('3. Reviewer: validate correctness, edge cases, regressions, and missing tests.')
    ..writeln()
    ..writeln('Role outputs:');

  if (roles.contains('Architect')) {
    buffer.writeln('- Architect: architecture notes + exact change plan.');
  }
  if (roles.contains('Coder')) {
    buffer.writeln('- Coder: concrete code patch details.');
  }
  if (roles.contains('Reviewer')) {
    buffer.writeln('- Reviewer: findings ordered by severity with follow-up actions.');
  }

  final customGoal = metadata['teamGoal'] ?? metadata['team_goal'];
  if (customGoal != null) {
    buffer
      ..writeln()
      ..writeln('Team objective: ${_stringify(customGoal)}');
  }

  return buffer.toString().trim();
}

List<String> _resolveTeamRoles(Map<String, dynamic> metadata) {
  final rawRoles = metadata['teamRoles'] ?? metadata['team_roles'] ?? metadata['agents'];
  final resolved = <String>{};

  if (rawRoles is Iterable) {
    for (final role in rawRoles) {
      final normalized = role.toString().toLowerCase().trim();
      if (normalized == 'architect') {
        resolved.add('Architect');
      } else if (normalized == 'coder') {
        resolved.add('Coder');
      } else if (normalized == 'reviewer') {
        resolved.add('Reviewer');
      }
    }
  }

  if (resolved.isEmpty && _isTeamModeEnabled(metadata)) {
    return <String>['Architect', 'Coder', 'Reviewer'];
  }

  final ordered = <String>[];
  for (final role in <String>['Architect', 'Coder', 'Reviewer']) {
    if (resolved.contains(role)) {
      ordered.add(role);
    }
  }
  return ordered;
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
