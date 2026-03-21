// Mirror apply security mode decision service.
// Centralizes apply security mode determination (signed vs. direct) for consistency across backends.

import 'package:flutter/foundation.dart';

/// Apply security mode: how patches are delivered to the runner.
enum MirrorApplySecurityMode {
  /// Signed artifact flow: patches stored in Supabase storage with signed URLs.
  /// More secure, audit-friendly, supports large patches, slower (requires upload).
  signed,

  /// Direct inline flow: patches sent in request body as JSON.
  /// Faster, suitable for small patches (<100KB), less audit surface.
  direct,
}

/// Factors influencing apply security mode selection.
@immutable
class ApplySecurityModeFactors {
  /// Total size of all patches in bytes.
  final int totalPatchBytes;

  /// Whether audit logging is enabled (prefer signed if true).
  final bool auditLoggingEnabled;

  /// Whether this is a cloud mode apply (prefer signed if true).
  final bool isCloudMode;

  /// User has explicit "require_signed_apply" policy.
  final bool requireSignedApply;

  /// User trust score (0-100): higher = more lenient on direct flow.
  /// Computed from apply success history, abuse patterns.
  final int userTrustScore;

  const ApplySecurityModeFactors({
    required this.totalPatchBytes,
    required this.auditLoggingEnabled,
    required this.isCloudMode,
    required this.requireSignedApply,
    required this.userTrustScore,
  });
}

/// Result of security mode decision.
@immutable
class ApplySecurityModeDecision {
  final MirrorApplySecurityMode mode;
  final String rationale;
  final bool isSecurityBindingDecision; // true = cannot be overridden by user

  const ApplySecurityModeDecision({
    required this.mode,
    required this.rationale,
    required this.isSecurityBindingDecision,
  });
}

/// Centralized service for apply security mode decisions.
/// Used by both cloud gateway backend and private gRPC backend to ensure consistency.
class MirrorApplySecurityModeService {
  // Constants for decision thresholds
  static const int _directFlowSizeThresholdBytes = 100 * 1024; // 100 KB
  static const int _cloudModeSizeThresholdBytes = 50 * 1024; // 50 KB for cloud (more conservative)
  static const int _minTrustScoreForDirectFlow = 70; // Users with <70 trust score require signed

  /// Determine optimal apply security mode based on context.
  /// This centralizes the logic so both backends make identical decisions.
  ApplySecurityModeDecision determineApplySecurityMode(ApplySecurityModeFactors factors) {
    // Rule 1: Explicit policy always wins
    if (factors.requireSignedApply) {
      return const ApplySecurityModeDecision(
        mode: MirrorApplySecurityMode.signed,
        rationale: 'User policy requires signed apply',
        isSecurityBindingDecision: true,
      );
    }

    // Rule 2: High-risk modes prefer signed flow
    if (factors.isCloudMode) {
      if (factors.totalPatchBytes > _cloudModeSizeThresholdBytes) {
        final formattedSize = _formatBytes(factors.totalPatchBytes);
        return ApplySecurityModeDecision(
          mode: MirrorApplySecurityMode.signed,
          rationale: 'Cloud mode + large patches ($formattedSize) → signed flow',
          isSecurityBindingDecision: true,
        );
      }
    }

    // Rule 3: Trust score gates direct flow
    if (factors.userTrustScore < _minTrustScoreForDirectFlow) {
      return ApplySecurityModeDecision(
        mode: MirrorApplySecurityMode.signed,
        rationale:
            'User trust score (${factors.userTrustScore}) below threshold ($_minTrustScoreForDirectFlow) → signed flow required',
        isSecurityBindingDecision: true,
      );
    }

    // Rule 4: Audit logging enabled → prefer signed (non-binding)
    if (factors.auditLoggingEnabled && factors.totalPatchBytes > _directFlowSizeThresholdBytes / 2) {
      return ApplySecurityModeDecision(
        mode: MirrorApplySecurityMode.signed,
        rationale:
            'Audit logging enabled + medium patches (${_formatBytes(factors.totalPatchBytes)}) → prefer signed flow',
        isSecurityBindingDecision: false,
      );
    }

    // Rule 5: Small patches → direct flow (fast path)
    if (factors.totalPatchBytes <= _directFlowSizeThresholdBytes) {
      return ApplySecurityModeDecision(
        mode: MirrorApplySecurityMode.direct,
        rationale:
            'Small patches (${_formatBytes(factors.totalPatchBytes)} ≤ ${_formatBytes(_directFlowSizeThresholdBytes)}) → direct flow (fast path)',
        isSecurityBindingDecision: false,
      );
    }

    // Rule 6: Default to signed for large patches
    return ApplySecurityModeDecision(
      mode: MirrorApplySecurityMode.signed,
      rationale:
          'Large patches (${_formatBytes(factors.totalPatchBytes)}) → signed flow (secure path)',
      isSecurityBindingDecision: false,
    );
  }

  /// Log security mode decision for observability.
  void logSecurityModeDecision(
    String sessionId,
    ApplySecurityModeDecision decision,
    ApplySecurityModeFactors factors,
  ) {
    print(
      'Mirror apply security mode decision: '
      'sessionId=$sessionId, mode=${decision.mode.name}, '
      'binding=${decision.isSecurityBindingDecision}, '
      'patchBytes=${_formatBytes(factors.totalPatchBytes)}, '
      'cloudMode=${factors.isCloudMode}, '
      'trustScore=${factors.userTrustScore}'
      ' — ${decision.rationale}',
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Singleton instance for use across backends.
final mirrorApplySecurityModeService = MirrorApplySecurityModeService();

/// Helper: Get factors from context.
/// Used by backends to build factor set from current state.
ApplySecurityModeFactors buildApplySecurityModeFactors({
  required int totalPatchBytes,
  required bool auditLoggingEnabled,
  required String mode, // 'private' | 'cloud'
  required bool requireSignedApply,
  required int userTrustScore,
}) {
  return ApplySecurityModeFactors(
    totalPatchBytes: totalPatchBytes,
    auditLoggingEnabled: auditLoggingEnabled,
    isCloudMode: mode == 'cloud',
    requireSignedApply: requireSignedApply,
    userTrustScore: userTrustScore.clamp(0, 100),
  );
}
