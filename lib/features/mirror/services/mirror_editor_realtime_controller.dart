import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'mirror_realtime_service.dart';

class MirrorEditorRealtimeController {
  MirrorEditorRealtimeController({
    required this.projectId,
    required this.taskId,
    required this.sessionKey,
    this.supabaseClient,
    MirrorRealtimeService? realtimeService,
    MirrorRealtimeEventSetDeduplicator? deduplicator,
  }) : _realtimeService =
           realtimeService ??
           MirrorRealtimeService(
             projectId: projectId,
             taskId: taskId,
             sessionKey: sessionKey,
             supabaseClient: supabaseClient,
           ),
       _realtimeDeduplicator =
           deduplicator ?? MirrorRealtimeEventSetDeduplicator();

  final String projectId;
  final String taskId;
  final String sessionKey;
  final SupabaseClient? supabaseClient;
  final MirrorRealtimeService _realtimeService;
  final MirrorRealtimeEventSetDeduplicator _realtimeDeduplicator;

  RealtimeChannel? _aiOutputChannel;
  StreamSubscription<Map<String, dynamic>>? _debugRealtimeSubscription;

  void start({
    required Stream<Map<String, dynamic>>? debugRealtimeRecords,
    required bool Function() isMounted,
    required void Function(List<String> lines) onFlush,
    required String Function(String status) statusLineLabel,
  }) {
    if (debugRealtimeRecords != null) {
      _debugRealtimeSubscription = debugRealtimeRecords.listen(
        (Map<String, dynamic> record) {
          _handleRealtimeRecord(
            record,
            enforceScope: false,
            isMounted: isMounted,
            onFlush: onFlush,
            statusLineLabel: statusLineLabel,
          );
        },
      );
      return;
    }

    _subscribeToLiveOutput(
      isMounted: isMounted,
      onFlush: onFlush,
      statusLineLabel: statusLineLabel,
    );
  }

  void dispose() {
    if (_aiOutputChannel != null) {
      (supabaseClient ?? Supabase.instance.client).removeChannel(_aiOutputChannel!);
    }
    _debugRealtimeSubscription?.cancel();
    _realtimeService.dispose();
  }

  void _subscribeToLiveOutput({
    required bool Function() isMounted,
    required void Function(List<String> lines) onFlush,
    required String Function(String status) statusLineLabel,
  }) {
    final resolvedClient = supabaseClient ?? Supabase.instance.client;
    final currentUserId = resolvedClient.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    final topic = 'mirror_ai_sessions:$currentUserId:$projectId:$taskId';
    final channel = resolvedClient.channel('mirror-ai-output-$topic');

    _aiOutputChannel = channel
        .onBroadcast(
          event: 'ai_session_update',
          callback: (Map<String, dynamic> payload, [String? _]) {
            final record = _realtimeService.extractBroadcastRecord(payload);
            if (record == null) {
              return;
            }
            _handleRealtimeRecord(
              record,
              isMounted: isMounted,
              onFlush: onFlush,
              statusLineLabel: statusLineLabel,
            );
          },
        )
        .subscribe();
  }

  void _handleRealtimeRecord(
    Map<String, dynamic> record, {
    required bool Function() isMounted,
    required void Function(List<String> lines) onFlush,
    required String Function(String status) statusLineLabel,
    bool enforceScope = true,
  }) {
    if (!_realtimeDeduplicator.shouldProcess(record)) {
      return;
    }

    _realtimeService.handleRealtimeRecord(
      record: record,
      mounted: isMounted(),
      onFlush: onFlush,
      statusLineLabel: statusLineLabel,
      enforceScope: enforceScope,
    );
  }
}
