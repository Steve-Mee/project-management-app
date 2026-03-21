// Simple post-apply cleanup service (no cache invalidation - done in UI layer).

import 'package:shared_preferences/shared_preferences.dart';

/// Post-apply hook result.
class ApplyPostHookResult {
  final bool success;
  final String? error;

  const ApplyPostHookResult({
    required this.success,
    this.error,
  });
}

/// Service for non-provider state cleanup after apply (timestamps, drafts only).
class MirrorApplyPostHooksService {
  final SharedPreferences prefs;

  const MirrorApplyPostHooksService({required this.prefs});

  /// Record apply timestamp.
  Future<void> recordApplyTimestamp(String projectId, String taskId) async {
    final key = 'mirror_last_apply_${projectId}_$taskId';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Get cached last apply timestamp.
  DateTime? getLastApplyTimestamp(String projectId, String taskId) {
    final key = 'mirror_last_apply_${projectId}_$taskId';
    final isoStr = prefs.getString(key);
    return isoStr != null ? DateTime.tryParse(isoStr) : null;
  }
}

