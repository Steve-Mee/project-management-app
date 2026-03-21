import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../mirror_signed_inputs_backend.dart';

/// Validation result for preview/apply consistency checks.
class ValidateConsistencyResult {
  final bool isValid;
  final String? errorMessage;
  final bool isRetryable;

  ValidateConsistencyResult({
    required this.isValid,
    this.errorMessage,
    this.isRetryable = false,
  });

  factory ValidateConsistencyResult.valid() => ValidateConsistencyResult(
        isValid: true,
      );

  factory ValidateConsistencyResult.fingerprintMismatch() =>
      ValidateConsistencyResult(
        isValid: false,
        errorMessage:
            'Apply blocked: preview fingerprint mismatch. Re-run preview before applying.',
        isRetryable: false,
      );

  factory ValidateConsistencyResult.contextMismatch() =>
      ValidateConsistencyResult(
        isValid: false,
        errorMessage:
            'Apply blocked: preview context mismatch. Re-run preview before applying.',
        isRetryable: false,
      );
}

/// Validates consistency between preview and apply stages in Mirror workflow.
///
/// This service encapsulates all validation logic for:
/// - Compile fingerprint matching between preview and apply
/// - Context file snapshot consistency checks
///
/// Pure domain service: no IO, no provider reads, deterministic.
class MirrorApplyValidatorService {
  const MirrorApplyValidatorService();

  /// Validates that the apply request matches the preview that was shown to the user.
  ValidateConsistencyResult validatePreviewApplyConsistency({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required String expectedCompileFingerprint,
    required String preflightOutput,
  }) {
    final actualFingerprint = computeCompileResultFingerprint(
      prompt: prompt,
      context: context,
      mode: mode,
      output: preflightOutput,
    );
    if (actualFingerprint != expectedCompileFingerprint) {
      return ValidateConsistencyResult.fingerprintMismatch();
    }

    // Contract: context.metadata['previewContextFingerprint'] is validated
    final expectedContextFingerprint =
        context.metadata.previewContextFingerprint ?? '';
    if (expectedContextFingerprint.isNotEmpty) {
      final actualContextFingerprint = fingerprintFileMap(context.files);
      if (actualContextFingerprint != expectedContextFingerprint) {
        return ValidateConsistencyResult.contextMismatch();
      }
    }

    return ValidateConsistencyResult.valid();
  }

  /// Computes SHA256 fingerprint of file map for consistency validation.
  ///
  /// Used to detect if project files changed between preview and apply stages.
  String fingerprintFileMap(Map<String, String> files) {
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
}
