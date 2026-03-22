import 'dart:core';

class MirrorRequestValidator {
  static const int maxPromptChars = 50000;
  static const int maxIdChars = 256;
  static const int maxBackupIdChars = 512;
  static const int maxFilePathChars = 512;
  static const int maxFileContentBytes = 1024 * 1024;
  static const int maxFiles = 1000;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static List<String> validateCompileBody(Map<String, dynamic> body) {
    return _validateCommonBody(body);
  }

  static List<String> validateApplyBody(Map<String, dynamic> body) {
    final errors = _validateCommonBody(body);
    final applyDiffId = _stringOrNull(body['applyDiffId'] ?? body['apply_diff_id']);
    if (applyDiffId != null && applyDiffId.isEmpty) {
      errors.add('applyDiffId: must be non-empty string when provided');
    }

    final contextFingerprint = _stringOrNull(body['contextFingerprint'] ?? body['context_fingerprint']);
    if (contextFingerprint != null && !_isValidHash(contextFingerprint)) {
      errors.add('contextFingerprint: must be valid hash format, e.g. sha256:...');
    }

    final compileFingerprint = _stringOrNull(body['compileFingerprint'] ?? body['compile_fingerprint']);
    if (compileFingerprint != null && !_isValidHash(compileFingerprint)) {
      errors.add('compileFingerprint: must be valid hash format, e.g. sha256:...');
    }

    final compileServerVersionToken =
        _stringOrNull(body['compileServerVersionToken'] ?? body['compile_server_version_token']);
    if (compileServerVersionToken != null && compileServerVersionToken.length > maxBackupIdChars) {
      errors.add('compileServerVersionToken: must be <= $maxBackupIdChars characters');
    }

    return errors;
  }

  static List<String> _validateCommonBody(Map<String, dynamic> body) {
    final errors = <String>[];

    final prompt = _stringOrNull(body['prompt']);
    if (prompt == null || prompt.isEmpty) {
      errors.add('prompt: must be non-empty string');
    } else if (prompt.length > maxPromptChars) {
      errors.add('prompt: must be <= $maxPromptChars characters');
    }

    final projectId = _stringOrNull(body['projectId'] ?? body['project_id']);
    if (projectId == null || projectId.isEmpty) {
      errors.add('projectId: must be non-empty string');
    } else {
      if (projectId.length > maxIdChars) {
        errors.add('projectId: must be <= $maxIdChars characters');
      }
      if (!_isValidUuid(projectId)) {
        errors.add('projectId: must be valid UUID');
      }
    }

    final taskId = _stringOrNull(body['taskId'] ?? body['task_id']);
    if (taskId == null || taskId.isEmpty) {
      errors.add('taskId: must be non-empty string');
    } else {
      if (taskId.length > maxIdChars) {
        errors.add('taskId: must be <= $maxIdChars characters');
      }
      if (!_isValidUuid(taskId)) {
        errors.add('taskId: must be valid UUID');
      }
    }

    final mode = _stringOrNull(body['mode']);
    if (mode == null || (mode != 'private' && mode != 'cloud')) {
      errors.add('mode: must be "private" or "cloud"');
    }

    final actorUserId = _stringOrNull(body['actorUserId'] ?? body['actor_user_id']);
    if (actorUserId != null && !_isValidUuid(actorUserId)) {
      errors.add('actorUserId: must be valid UUID when provided');
    }

    final backupId = _stringOrNull(body['backupId'] ?? body['backup_id']);
    if (backupId != null && backupId.length > maxBackupIdChars) {
      errors.add('backupId: must be <= $maxBackupIdChars characters');
    }

    final fileSetFingerprint = _stringOrNull(body['fileSetFingerprint'] ?? body['file_set_fingerprint']);
    if (fileSetFingerprint != null && !_isValidHash(fileSetFingerprint)) {
      errors.add('fileSetFingerprint: must be valid hash format, e.g. sha256:...');
    }

    final signedInputUrlsRaw = body['signedInputUrls'] ?? body['signed_input_urls'];
    if (signedInputUrlsRaw != null) {
      if (signedInputUrlsRaw is! Map) {
        errors.add('signedInputUrls: must be an object map when provided');
      } else {
        for (final entry in signedInputUrlsRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value?.toString() ?? '';
          if (key.isEmpty || key.length > maxFilePathChars) {
            errors.add('signedInputUrls key "$key": must be 1-$maxFilePathChars chars');
          }
          if (!_isValidHttpsUrl(value)) {
            errors.add('signedInputUrls[$key]: must be valid HTTPS URL');
          }
        }
      }
    }

    final filesRaw = body['files'];
    if (filesRaw != null) {
      if (filesRaw is! Map) {
        errors.add('files: must be an object map when provided');
      } else {
        if (filesRaw.length > maxFiles) {
          errors.add('files: must contain <= $maxFiles entries');
        }
        for (final entry in filesRaw.entries) {
          final path = entry.key.toString();
          final content = entry.value?.toString() ?? '';
          if (path.isEmpty || path.length > maxFilePathChars) {
            errors.add('files key "$path": must be 1-$maxFilePathChars chars');
          }
          if (content.length > maxFileContentBytes) {
            errors.add('files[$path]: content must be <= $maxFileContentBytes bytes');
          }
        }
      }
    }

    final metadataRaw = body['metadata'];
    if (metadataRaw != null && metadataRaw is! Map) {
      errors.add('metadata: must be an object when provided');
    }

    return errors;
  }

  static bool _isValidUuid(String value) => _uuidRegex.hasMatch(value);

  static bool _isValidHash(String value) {
    final parts = value.split(':');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
  }

  static bool _isValidHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized;
  }
}
