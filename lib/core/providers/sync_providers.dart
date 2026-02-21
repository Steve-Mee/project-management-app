import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync-related providers (placeholder – ready for future offline/sync logic)
/// TODO: Implement when Supabase sync is added

/// Provider for tracking last sync timestamp
/// TODO: Implement actual sync logic with Supabase
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for sync status (idle, syncing, error)
/// TODO: Implement sync status tracking
final syncStatusProvider = StateProvider<String>((ref) => 'idle');

/// Stub provider for future Supabase sync service
/// TODO: Create actual SupabaseSyncService and implement sync logic
final supabaseSyncProvider = Provider<SupabaseSyncService>((ref) {
  return SupabaseSyncService();
});

/// Placeholder class for future Supabase sync implementation
/// TODO: Implement actual sync methods
class SupabaseSyncService {
  /// Sync all local data to Supabase
  /// TODO: Implement full sync logic
  Future<void> syncAll() async {
    // Stub implementation - to be replaced with actual sync logic
    // This would sync projects, dashboard config, user settings, etc.
  }

  /// Sync specific data type
  /// TODO: Implement selective sync
  Future<void> syncData(String dataType) async {
    // Stub implementation - to be replaced with actual sync logic
  }

  /// Check if device is online and can sync
  /// TODO: Implement connectivity checking
  Future<bool> canSync() async {
    // Stub implementation - always return true for now
    return true;
  }
}
