import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MirrorSecureApplyArtifacts {
  const MirrorSecureApplyArtifacts({
    required this.backupId,
    required this.signedInputUrls,
    required this.backupSignedUrls,
    required this.createdAt,
    this.uploadFailures = const <MirrorSecureApplyUploadFailure>[],
  });

  final String backupId;
  final Map<String, String> signedInputUrls;
  final Map<String, String> backupSignedUrls;
  final DateTime createdAt;
  final List<MirrorSecureApplyUploadFailure> uploadFailures;
}

class MirrorSecureApplyUploadFailure {
  const MirrorSecureApplyUploadFailure({
    required this.filePath,
    required this.code,
    required this.stage,
    required this.error,
  });

  final String filePath;
  final MirrorSecureApplyUploadFailureCode code;
  final String stage;
  final String error;
}

enum MirrorSecureApplyUploadFailureCode {
  authUserMissing('auth_user_missing'),
  signedInputUploadFailed('signed_input_upload_failed'),
  backupUploadFailed('backup_upload_failed'),
  signedInputUrlFailed('signed_input_url_failed'),
  backupUrlFailed('backup_url_failed');

  const MirrorSecureApplyUploadFailureCode(this.value);

  final String value;
}

class MirrorSecureApplyResult {
  const MirrorSecureApplyResult({
    required this.success,
    this.appliedFiles = const <String>[],
    this.message,
  });

  final bool success;
  final List<String> appliedFiles;
  final String? message;
}

class MirrorSecureApplyService {
  MirrorSecureApplyService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  // Threat model: apply-artifact signed URLs can be replayed if leaked from
  // logs, browser history, or intermediary telemetry. Keep expiry short by
  // default and allow explicit override per environment via --dart-define.
  static const Duration defaultSignedUrlTtl = Duration(
    seconds: int.fromEnvironment(
      'MIRROR_APPLY_ARTIFACTS_SIGNED_URL_TTL_SECONDS',
      defaultValue: 120,
    ),
  );

  static const String defaultSignedInputBucket = 'mirror-signed-inputs';
  static const String defaultBackupBucket = 'mirror-backups';
  static const int _artifactOperationMaxAttempts = 3;
  static const Duration _artifactInitialBackoff = Duration(milliseconds: 150);

  Future<MirrorSecureApplyArtifacts> prepareSignedInputAndBackup({
    required String projectId,
    required String taskId,
    required Map<String, String> files,
    Duration signedUrlTtl = defaultSignedUrlTtl,
    String signedInputBucket = defaultSignedInputBucket,
    String backupBucket = defaultBackupBucket,
  }) async {
    final client = supabaseClient;
    final authUserId = client.auth.currentUser?.id;
    final backupId = _buildBackupId(projectId: projectId, taskId: taskId);
    final signedInputUrls = <String, String>{};
    final backupSignedUrls = <String, String>{};
    final uploadFailures = <MirrorSecureApplyUploadFailure>[];

    if (authUserId == null || authUserId.isEmpty) {
      return MirrorSecureApplyArtifacts(
        backupId: backupId,
        signedInputUrls: signedInputUrls,
        backupSignedUrls: backupSignedUrls,
        createdAt: DateTime.now().toUtc(),
        uploadFailures: const <MirrorSecureApplyUploadFailure>[
          MirrorSecureApplyUploadFailure(
            filePath: '*',
            code: MirrorSecureApplyUploadFailureCode.authUserMissing,
            stage: 'auth-user',
            error:
                'Authenticated user is required for owner-scoped storage paths.',
          ),
        ],
      );
    }

    for (final entry in files.entries) {
      final sanitizedPath = _sanitizeStoragePath(entry.key);
      final signedInputPath =
          '$authUserId/$projectId/$taskId/$backupId/input/$sanitizedPath';
      final backupPath =
          '$authUserId/$projectId/$taskId/$backupId/backup/$sanitizedPath';
      final payload = utf8.encode(entry.value);

      try {
        await _runArtifactOperationWithRetry(
          () => _uploadReplaceBinary(
            client: client,
            bucket: signedInputBucket,
            path: signedInputPath,
            bytes: payload,
          ),
        );
      } catch (error) {
        uploadFailures.add(
          MirrorSecureApplyUploadFailure(
            filePath: entry.key,
            code: MirrorSecureApplyUploadFailureCode.signedInputUploadFailed,
            stage: 'signed-input-upload',
            error: error.toString(),
          ),
        );
        continue;
      }

      try {
        await _runArtifactOperationWithRetry(
          () => _uploadReplaceBinary(
            client: client,
            bucket: backupBucket,
            path: backupPath,
            bytes: payload,
          ),
        );
      } catch (error) {
        uploadFailures.add(
          MirrorSecureApplyUploadFailure(
            filePath: entry.key,
            code: MirrorSecureApplyUploadFailureCode.backupUploadFailed,
            stage: 'backup-upload',
            error: error.toString(),
          ),
        );
        continue;
      }

      late final String signedInputUrl;
      try {
        signedInputUrl = await _runArtifactOperationWithRetry(
          () => client.storage
              .from(signedInputBucket)
              .createSignedUrl(signedInputPath, signedUrlTtl.inSeconds),
        );
      } catch (error) {
        uploadFailures.add(
          MirrorSecureApplyUploadFailure(
            filePath: entry.key,
            code: MirrorSecureApplyUploadFailureCode.signedInputUrlFailed,
            stage: 'signed-input-url',
            error: error.toString(),
          ),
        );
        continue;
      }

      late final String backupSignedUrl;
      try {
        backupSignedUrl = await _runArtifactOperationWithRetry(
          () => client.storage
              .from(backupBucket)
              .createSignedUrl(backupPath, signedUrlTtl.inSeconds),
        );
      } catch (error) {
        uploadFailures.add(
          MirrorSecureApplyUploadFailure(
            filePath: entry.key,
            code: MirrorSecureApplyUploadFailureCode.backupUrlFailed,
            stage: 'backup-url',
            error: error.toString(),
          ),
        );
        continue;
      }

      signedInputUrls[entry.key] = signedInputUrl;
      backupSignedUrls[entry.key] = backupSignedUrl;
    }

    return MirrorSecureApplyArtifacts(
      backupId: backupId,
      signedInputUrls: signedInputUrls,
      backupSignedUrls: backupSignedUrls,
      createdAt: DateTime.now().toUtc(),
      uploadFailures: uploadFailures,
    );
  }

  Future<MirrorSecureApplyResult> secureApply({
    required String prompt,
    required String projectId,
    required String taskId,
    required String mode,
    required Map<String, String> files,
    required Future<MirrorSecureApplyResult> Function(
      MirrorSecureApplyArtifacts artifacts,
    ) onApply,
    Duration signedUrlTtl = defaultSignedUrlTtl,
    String signedInputBucket = defaultSignedInputBucket,
    String backupBucket = defaultBackupBucket,
  }) async {
    const eventApplyStarted = 'apply_started';
    const eventApplyPreparationFailed = 'apply_preparation_failed';
    const eventApplyException = 'apply_exception';
    const eventApplyCompleted = 'apply_completed';

    final actorUserId = supabaseClient.auth.currentUser?.id;
    final sourceFingerprint = _fingerprintFiles(files);

    await _writeApplyAuditEvent(
      projectId: projectId,
      taskId: taskId,
      mode: mode,
      event: eventApplyStarted,
      actorUserId: actorUserId,
      fileSetFingerprint: sourceFingerprint,
    );

    final artifacts = await prepareSignedInputAndBackup(
      projectId: projectId,
      taskId: taskId,
      files: files,
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
        projectId: projectId,
        taskId: taskId,
        mode: mode,
        event: eventApplyPreparationFailed,
        actorUserId: actorUserId,
        backupId: artifacts.backupId,
        success: false,
        fileSetFingerprint: sourceFingerprint,
        details: <String, dynamic>{
          'failureCount': artifacts.uploadFailures.length,
          'details': lines,
        },
      );
      return MirrorSecureApplyResult(
        success: false,
        appliedFiles: const <String>[],
        message:
            'Apply preparation failed for one or more files. Backup ID: ${artifacts.backupId}. Details: $lines',
      );
    }

    late final MirrorSecureApplyResult result;
    try {
      result = await onApply(artifacts);
    } catch (error) {
      await _writeApplyAuditEvent(
        projectId: projectId,
        taskId: taskId,
        mode: mode,
        event: eventApplyException,
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
      projectId: projectId,
      taskId: taskId,
      mode: mode,
      event: eventApplyCompleted,
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

    return MirrorSecureApplyResult(
      success: false,
      appliedFiles: result.appliedFiles,
      message:
          '${result.message ?? 'Apply failed.'} Backup ID: ${artifacts.backupId}',
    );
  }
}

Future<T> _runArtifactOperationWithRetry<T>(
  Future<T> Function() operation,
) async {
  Object? lastError;
  var backoff = MirrorSecureApplyService._artifactInitialBackoff;

  for (var attempt = 1;
      attempt <= MirrorSecureApplyService._artifactOperationMaxAttempts;
      attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (attempt == MirrorSecureApplyService._artifactOperationMaxAttempts) {
        break;
      }
      await Future<void>.delayed(backoff);
      backoff *= 2;
    }
  }

  throw lastError ?? StateError('Artifact operation failed without error.');
}

String _buildBackupId({
  required String projectId,
  required String taskId,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  final seed = '$projectId:$taskId:$now';
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

Future<Box<dynamic>> _openApplyAuditBox() async {
  const boxName = 'mirror_apply_audit';
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box<dynamic>(boxName);
  }

  try {
    return EncryptedHiveBox<dynamic>(
      boxName: boxName,
      encryptionKey: 'hive_encryption_key_mirror_apply_audit',
    ).open();
  } catch (error) {
    if (_failClosedOnEncryptionError) {
      throw StateError(
        'Encrypted apply audit storage is unavailable in production: $error',
      );
    }
    return Hive.openBox<dynamic>(boxName);
  }
}

const bool _failClosedOnEncryptionError = bool.fromEnvironment(
  'MIRROR_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
  defaultValue: bool.fromEnvironment('dart.vm.product'),
);

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
