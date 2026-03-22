// Shared error formatting utilities for Mirror compute backends.
// Used by both HTTP gateway backend and gRPC backend to produce
// consistent structured error messages in ApplyResult/CompileResult fields.
import 'dart:convert';

/// Semantic error families for backend-level validation failures.
/// These map to the same string values used by [MirrorGatewayBackend]
/// so that callers can parse error_family uniformly regardless of backend.
enum MirrorBackendErrorFamily {
  validation('validation_error', false),
  consistency('consistency_error', false),
  config('config_error', false),
  timeout('timeout', true),
  network('network', true);

  const MirrorBackendErrorFamily(this.value, this.defaultRetryable);

  final String value;
  final bool defaultRetryable;
}

/// Encode a structured error message string suitable for
/// [ApplyResult.message] and [CompileResult.errors] entries.
///
/// Format: `{"error_family":"...","retryable":...,"message":"..."}`
String formatMirrorBackendError({
  required MirrorBackendErrorFamily family,
  required String message,
  bool? retryable,
}) {
  return jsonEncode(<String, dynamic>{
    'error_family': family.value,
    'retryable': retryable ?? family.defaultRetryable,
    'message': message,
  });
}
