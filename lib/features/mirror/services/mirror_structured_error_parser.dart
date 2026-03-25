import 'dart:convert';

import '../models/mirror_structured_error.dart';

class MirrorStructuredErrorParser {
  const MirrorStructuredErrorParser();

  MirrorStructuredError? findLatest(List<String> lines) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final parsed = tryParse(lines[i]);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  MirrorStructuredError? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final segments = trimmed.split(' | ');
    for (final segment in segments) {
      try {
        final decoded = jsonDecode(segment);
        if (decoded is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(decoded);
        final family = map['error_family']?.toString().trim();
        if (family == null || family.isEmpty) {
          continue;
        }

        final retryableRaw = map['retryable'];
        final retryable = retryableRaw is bool
            ? retryableRaw
            : _isRetryableFamily(family);
        final message = map['message']?.toString().trim();

        return MirrorStructuredError(
          errorFamily: family,
          retryable: retryable,
          message: (message == null || message.isEmpty) ? null : message,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  bool _isRetryableFamily(String family) {
    switch (family) {
      case 'network':
      case 'timeout':
      case 'rate_limited':
      case 'server_error':
        return true;
      default:
        return false;
    }
  }
}
