// Shared request schema validation for Mirror compile/apply requests.
// Centralized contract for payload validation across edge gateway, runners, and tests.
// This module is referenced by both gateway and runner implementations to ensure consistent validation.

import 'package:flutter/foundation.dart';

/// Compile request payload contract.
/// Used by both gateway and runners to validate incoming compile requests.
@immutable
class MirrorCompileRequestSchema {
  final String prompt;
  final String projectId;
  final String taskId;
  final String mode; // 'private' | 'cloud'
  final Map<String, String>? files;
  final Map<String, dynamic>? metadata;
  final String? actorUserId;
  final String? backupId;
  final String? fileSetFingerprint;
  final Map<String, String>? signedInputUrls;

  const MirrorCompileRequestSchema({
    required this.prompt,
    required this.projectId,
    required this.taskId,
    required this.mode,
    this.files,
    this.metadata,
    this.actorUserId,
    this.backupId,
    this.fileSetFingerprint,
    this.signedInputUrls,
  });

  /// Validate compile request payload.
  /// Returns list of validation errors (empty = valid).
  List<String> validate() {
    final errors = <String>[];

    // Required fields
    if (prompt.isEmpty) {
      errors.add('prompt: must be non-empty string');
    }
    if (prompt.length > 50000) {
      errors.add('prompt: must be ≤50000 characters');
    }

    if (projectId.isEmpty) {
      errors.add('projectId: must be non-empty string');
    }
    if (projectId.length > 256) {
      errors.add('projectId: must be ≤256 characters');
    }

    if (taskId.isEmpty) {
      errors.add('taskId: must be non-empty string');
    }
    if (taskId.length > 256) {
      errors.add('taskId: must be ≤256 characters');
    }

    if (mode != 'private' && mode != 'cloud') {
      errors.add('mode: must be "private" or "cloud"');
    }

    // Optional fields
    if (files case _ when files != null) {
      if (files!.isEmpty) {
        errors.add('files: if provided, must be non-empty');
      }
      if (files!.length > 1000) {
        errors.add('files: must contain ≤1000 entries');
      }
      for (final entry in files!.entries) {
        if (entry.key.isEmpty || entry.key.length > 512) {
          errors.add('files: key "${entry.key}" must be 1-512 characters');
        }
        if (entry.value.length > 1024 * 1024) {
          errors.add('files["${entry.key}"]: value must be ≤1MB');
        }
      }
    }

    if (actorUserId case String v when v.isNotEmpty) {
      if (!_isValidUuid(v)) {
        errors.add('actorUserId: must be valid UUID or empty');
      }
    }

    if (backupId case String v when v.isNotEmpty) {
      if (v.length > 512) {
        errors.add('backupId: must be ≤512 characters');
      }
    }

    if (fileSetFingerprint case String v when v.isNotEmpty) {
      if (!_isValidHash(v)) {
        errors.add('fileSetFingerprint: must be valid hash format (e.g., sha256:...)');
      }
    }

    if (signedInputUrls case _ when signedInputUrls != null) {
      for (final entry in signedInputUrls!.entries) {
        if (entry.key.isEmpty || entry.key.length > 512) {
          errors.add('signedInputUrls: key must be 1-512 characters');
        }
        if (!_isValidUrl(entry.value)) {
          errors.add('signedInputUrls["${entry.key}"]: must be valid HTTPS URL');
        }
      }
    }

    return errors;
  }

  bool _isValidUuid(String value) {
    // Simple UUID v4 check: 8-4-4-4-12 hex digits with hyphens
    final pattern = RegExp(r'^[0-9a-fA-F-]{36}$');
    return pattern.hasMatch(value);
  }

  bool _isValidHash(String value) {
    // Expect format like "sha256:abc123..."
    return value.contains(':') && value.split(':').length == 2;
  }

  bool _isValidUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.scheme == 'https' && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Apply request payload contract.
/// Used by both gateway and runners to validate incoming apply requests.
@immutable
class MirrorApplyRequestSchema {
  final String prompt;
  final String projectId;
  final String taskId;
  final String mode; // 'private' | 'cloud'
  final Map<String, String>? files;
  final Map<String, dynamic>? metadata;
  final String? applyDiffId;
  final String? contextFingerprint;
  final String? compileFingerprint;
  final String? compileServerVersionToken;

  const MirrorApplyRequestSchema({
    required this.prompt,
    required this.projectId,
    required this.taskId,
    required this.mode,
    this.files,
    this.metadata,
    this.applyDiffId,
    this.contextFingerprint,
    this.compileFingerprint,
    this.compileServerVersionToken,
  });

  /// Validate apply request payload.
  /// Returns list of validation errors (empty = valid).
  List<String> validate() {
    final errors = <String>[];

    // Required fields (same as compile)
    if (prompt.isEmpty) {
      errors.add('prompt: must be non-empty string');
    }
    if (prompt.length > 50000) {
      errors.add('prompt: must be ≤50000 characters');
    }

    if (projectId.isEmpty) {
      errors.add('projectId: must be non-empty string');
    }
    if (projectId.length > 256) {
      errors.add('projectId: must be ≤256 characters');
    }

    if (taskId.isEmpty) {
      errors.add('taskId: must be non-empty string');
    }
    if (taskId.length > 256) {
      errors.add('taskId: must be ≤256 characters');
    }

    if (mode != 'private' && mode != 'cloud') {
      errors.add('mode: must be "private" or "cloud"');
    }

    // Apply-specific fields
    if (applyDiffId case String v when v.isEmpty) {
      errors.add('applyDiffId: must be non-empty string for apply');
    }

    if (contextFingerprint case String v when v.isNotEmpty) {
      if (!_isValidHash(v)) {
        errors.add('contextFingerprint: must be valid hash format');
      }
    }

    if (compileFingerprint case String v when v.isNotEmpty) {
      if (!_isValidHash(v)) {
        errors.add('compileFingerprint: must be valid hash format');
      }
    }

    if (compileServerVersionToken case String v when v.isNotEmpty) {
      if (v.length > 512) {
        errors.add('compileServerVersionToken: must be ≤512 characters');
      }
    }

    // Optional fields (same as compile)
    if (files case _ when files != null) {
      if (files!.isEmpty) {
        errors.add('files: if provided, must be non-empty');
      }
      if (files!.length > 1000) {
        errors.add('files: must contain ≤1000 entries');
      }
    }

    return errors;
  }

  bool _isValidHash(String value) {
    return value.contains(':') && value.split(':').length == 2;
  }
}

/// Validation result wrapper.
@immutable
class SchemaValidationResult {
  final bool isValid;
  final List<String> errors;

  const SchemaValidationResult({
    required this.isValid,
    required this.errors,
  });

  factory SchemaValidationResult.valid() => const SchemaValidationResult(
        isValid: true,
        errors: [],
      );

  factory SchemaValidationResult.invalid(List<String> errors) => SchemaValidationResult(
        isValid: false,
        errors: errors,
      );

  String get errorMessage => errors.join('; ');
}
