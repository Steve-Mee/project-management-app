import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync-related providers (placeholder – ready for future offline/sync logic)
/// NOTE: converted to issue 039

/// Provider for tracking last sync timestamp
/// NOTE: converted to issue 039
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for sync status (idle, syncing, error)
/// NOTE: converted to issue 039
final syncStatusProvider = StateProvider<String>((ref) => 'idle');

/// Stub provider for future Supabase sync service
/// NOTE: converted to issue 039
final supabaseSyncProvider = Provider<SupabaseSyncService>((ref) {
  return SupabaseSyncService();
});

/// Placeholder class for future Supabase sync implementation
/// NOTE: converted to issue 039
class SupabaseSyncService {
  /// Sync all local data to Supabase
  /// NOTE: converted to issue 039
  Future<void> syncAll() async {
    // Stub implementation - to be replaced with actual sync logic
    // This would sync projects, dashboard config, user settings, etc.
  }

  /// Sync specific data type
  /// NOTE: converted to issue 039
  Future<void> syncData(String dataType) async {
    // Stub implementation - to be replaced with actual sync logic
  }

  /// Check if device is online and can sync
  /// NOTE: converted to issue 039
  Future<bool> canSync() async {
    // Stub implementation - always return true for now
    return true;
  }
}
