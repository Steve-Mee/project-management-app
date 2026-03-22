// Simple post-apply cleanup service (no cache invalidation - done in UI layer).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/mirror_session_provider.dart';

/// Post-apply hook result.
class ApplyPostHookResult {
  final bool success;
  final String? error;

  const ApplyPostHookResult({
    required this.success,
    this.error,
  });
}

final mirrorApplyPostHooksServiceProvider =
    Provider<MirrorApplyPostHooksService>(
  (ref) => const MirrorApplyPostHooksService(),
);

/// Service for non-provider state cleanup after apply (timestamps, drafts only).
class MirrorApplyPostHooksService {
  const MirrorApplyPostHooksService({
    Future<SharedPreferences> Function()? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefsLoader;

  /// Persist session snapshot at compile start.
  Future<ApplyPostHookResult> persistOnCompileStart({
    required MirrorSessionNotifier sessionNotifier,
  }) async {
    try {
      await sessionNotifier.persistOnRunStart();
      return const ApplyPostHookResult(success: true);
    } catch (error) {
      return ApplyPostHookResult(success: false, error: error.toString());
    }
  }

  /// Persist session snapshot and update apply timestamp after apply success.
  Future<ApplyPostHookResult> persistOnApplyComplete({
    required MirrorSessionNotifier sessionNotifier,
    required String projectId,
    required String taskId,
  }) async {
    try {
      await sessionNotifier.persistOnApply();
      await recordApplyTimestamp(projectId, taskId);
      return const ApplyPostHookResult(success: true);
    } catch (error) {
      return ApplyPostHookResult(success: false, error: error.toString());
    }
  }

  /// Persist session snapshot when user exits the route.
  Future<ApplyPostHookResult> persistOnRouteExit({
    required MirrorSessionNotifier sessionNotifier,
  }) async {
    try {
      await sessionNotifier.persistOnRouteExit();
      return const ApplyPostHookResult(success: true);
    } catch (error) {
      return ApplyPostHookResult(success: false, error: error.toString());
    }
  }

  /// Record apply timestamp.
  Future<void> recordApplyTimestamp(String projectId, String taskId) async {
    final key = 'mirror_last_apply_${projectId}_$taskId';
    final prefs = await _prefsLoader();
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Get cached last apply timestamp.
  Future<DateTime?> getLastApplyTimestamp(String projectId, String taskId) async {
    final key = 'mirror_last_apply_${projectId}_$taskId';
    final prefs = await _prefsLoader();
    final isoStr = prefs.getString(key);
    return isoStr != null ? DateTime.tryParse(isoStr) : null;
  }
}

