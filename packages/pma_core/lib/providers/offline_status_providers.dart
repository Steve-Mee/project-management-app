import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/core/providers/supabase_client_provider.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/services/cloud_sync_service.dart';

/// Global offline/sync status used for top-level UI indicators.
enum OfflineSyncStatus {
  synced,
  syncing,
  offline,
}

/// Immutable state for the offline/sync status provider.
class OfflineStatusState {
  const OfflineStatusState({
    required this.status,
    required this.lastSyncTime,
    required this.isSyncing,
  });

  final OfflineSyncStatus status;
  final DateTime? lastSyncTime;
  final bool isSyncing;

  bool get isOffline => status == OfflineSyncStatus.offline;

  String get statusLabel {
    switch (status) {
      case OfflineSyncStatus.synced:
        return 'Synced';
      case OfflineSyncStatus.syncing:
        return 'Syncing';
      case OfflineSyncStatus.offline:
        return 'Offline';
    }
  }

  String get connectivityLabel => isOffline ? 'Offline' : 'Online';

  /// Color mapping for UI indicator requirements:
  /// - synced: green
  /// - syncing: orange
  /// - offline: red
  Color get statusColor {
    switch (status) {
      case OfflineSyncStatus.synced:
        return Colors.green;
      case OfflineSyncStatus.syncing:
        return Colors.orange;
      case OfflineSyncStatus.offline:
        return Colors.red;
    }
  }

  OfflineStatusState copyWith({
    OfflineSyncStatus? status,
    DateTime? lastSyncTime,
    bool? isSyncing,
  }) {
    return OfflineStatusState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  factory OfflineStatusState.synced({DateTime? lastSyncTime}) {
    return OfflineStatusState(
      status: OfflineSyncStatus.synced,
      lastSyncTime: lastSyncTime,
      isSyncing: false,
    );
  }

  factory OfflineStatusState.syncing({DateTime? lastSyncTime}) {
    return OfflineStatusState(
      status: OfflineSyncStatus.syncing,
      lastSyncTime: lastSyncTime,
      isSyncing: true,
    );
  }

  factory OfflineStatusState.offline({DateTime? lastSyncTime}) {
    return OfflineStatusState(
      status: OfflineSyncStatus.offline,
      lastSyncTime: lastSyncTime,
      isSyncing: false,
    );
  }
}

class OfflineStatusNotifier extends Notifier<OfflineStatusState> {
  late final CloudSyncService _cloudSyncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  OfflineStatusState build() {
    _cloudSyncService =
        CloudSyncService(supabaseClient: ref.read(pmaSupabaseClientProvider));
    _startConnectivityListener();

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    return const OfflineStatusState(
      status: OfflineSyncStatus.synced,
      lastSyncTime: null,
      isSyncing: false,
    );
  }

  Future<void> manualSync() async {
    if (!_isOnline) {
      state = OfflineStatusState.offline(lastSyncTime: state.lastSyncTime);
      return;
    }

    state = OfflineStatusState.syncing(lastSyncTime: state.lastSyncTime);

    try {
      await _cloudSyncService.syncAll();
      state = OfflineStatusState.synced(lastSyncTime: DateTime.now());
    } catch (e, st) {
      AppLogger.instance.w('Manual sync failed', error: e, stackTrace: st);

      state = _isOnline
          ? OfflineStatusState.synced(lastSyncTime: state.lastSyncTime)
          : OfflineStatusState.offline(lastSyncTime: state.lastSyncTime);
    }
  }

  /// Marks the global status as syncing when an online sync process starts.
  void markSyncStarted() {
    if (!_isOnline) {
      state = OfflineStatusState.offline(lastSyncTime: state.lastSyncTime);
      return;
    }

    state = OfflineStatusState.syncing(lastSyncTime: state.lastSyncTime);
  }

  /// Marks a successful sync completion and refreshes the last sync timestamp.
  void markSyncSucceeded() {
    state = OfflineStatusState.synced(lastSyncTime: DateTime.now());
  }

  /// Marks a failed sync while preserving connectivity semantics.
  void markSyncFailed() {
    state = _isOnline
        ? OfflineStatusState.synced(lastSyncTime: state.lastSyncTime)
        : OfflineStatusState.offline(lastSyncTime: state.lastSyncTime);
  }

  void _startConnectivityListener() {
    Connectivity().checkConnectivity().then(_handleConnectivityResults);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityResults);
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    final hasConnection = _hasUsableConnection(results);
    _isOnline = hasConnection;

    if (!hasConnection) {
      state = OfflineStatusState.offline(lastSyncTime: state.lastSyncTime);
      return;
    }

    if (!state.isSyncing) {
      state = OfflineStatusState.synced(lastSyncTime: state.lastSyncTime);
    }
  }

  bool _hasUsableConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }

    return results.any((result) {
      return result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other;
    });
  }
}

final offlineStatusProvider =
    NotifierProvider<OfflineStatusNotifier, OfflineStatusState>(
  OfflineStatusNotifier.new,
);
