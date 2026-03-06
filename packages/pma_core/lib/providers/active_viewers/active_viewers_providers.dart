import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'active_viewers_providers.freezed.dart';
part 'active_viewers_providers.g.dart';

/// Represents an active viewer in the projects list
@freezed
abstract class ActiveViewer with _$ActiveViewer {
  const factory ActiveViewer({
    required String userId,
    String? displayName,
    String? avatarUrl,
    required DateTime lastSeen,
    Map<String, dynamic>? currentFilter,
  }) = _ActiveViewer;

  factory ActiveViewer.fromJson(Map<String, dynamic> json) =>
      _$ActiveViewerFromJson(json);
}

/// Provider for managing active viewers using Supabase presence
final activeViewersProvider = StateNotifierProvider<ActiveViewersNotifier, List<ActiveViewer>>((ref) {
  return ActiveViewersNotifier();
});

class ActiveViewersNotifier extends StateNotifier<List<ActiveViewer>> {
  ActiveViewersNotifier() : super([]) {
    _initializePresence();
  }

  static const String _channelName = 'active_views';
  RealtimeChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;

  Future<void> _initializePresence() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) return;

      // Get user profile data
      final profile = await supabase
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', currentUser.id)
          .single();

      final userData = {
        'userId': currentUser.id,
        'displayName': profile['display_name'] as String?,
        'avatarUrl': profile['avatar_url'] as String?,
        'lastSeen': DateTime.now().toIso8601String(),
        'currentFilter': null,
      };

      _channel = supabase.channel(_channelName);

      _channel!.onPresenceSync((payload) {
        _updateViewersFromPresence();
      });

      _channel!.onPresenceLeave((payload) {
        _updateViewersFromPresence();
      });

      _channel!.subscribe();

      // Track our presence
      await _channel!.track(userData);

      // Start heartbeat to keep presence alive
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        await _updatePresence(userData);
      });

      // Clean up inactive viewers
      _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        _cleanupInactiveViewers();
      });

    } catch (e) {
      // Silently fail if presence is not available
    }
  }

  void _updateViewersFromPresence() {
    if (_channel == null) return;

    final presenceState = _channel!.presenceState();
    final viewers = <ActiveViewer>[];

    for (final presence in presenceState) {
      for (final occupant in presence.presences) {
        try {
          final viewer = ActiveViewer.fromJson(occupant as Map<String, dynamic>);
          // Don't include ourselves
          if (viewer.userId != Supabase.instance.client.auth.currentUser?.id) {
            viewers.add(viewer);
          }
        } catch (e) {
          // Skip invalid presence data
          continue;
        }
      }
    }

    state = viewers;
  }

  Future<void> _updatePresence(Map<String, dynamic> userData) async {
    if (_channel == null) return;

    userData['lastSeen'] = DateTime.now().toIso8601String();
    await _channel!.track(userData);
  }

  void _cleanupInactiveViewers() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 5));

    state = state.where((viewer) => viewer.lastSeen.isAfter(cutoff)).toList();
  }

  /// Update current filter and broadcast to other viewers
  Future<void> updateCurrentFilter(Map<String, dynamic>? filter) async {
    if (_channel == null) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', currentUser.id)
          .single();

      final userData = {
        'userId': currentUser.id,
        'displayName': profile['display_name'] as String?,
        'avatarUrl': profile['avatar_url'] as String?,
        'lastSeen': DateTime.now().toIso8601String(),
        'currentFilter': filter,
      };

      await _channel!.track(userData);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _channel?.untrack();
    _channel?.unsubscribe();
    super.dispose();
  }
}

/// Provider to check if user is online (has internet connection)
final isOnlineProvider = StateProvider<bool>((ref) => true);
