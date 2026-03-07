import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend-agnostic analytics contract for the app.
///
/// Why this abstraction exists:
/// - Keeps feature code independent from a specific analytics provider.
/// - Allows swapping Supabase for Firebase (or another backend) without
///   changing call sites.
/// - Centralizes event payload shape and persistence behavior.
///
/// Current default backend:
/// - Supabase (`analytics_events` table)
///
/// Example usage:
/// ```dart
/// final analytics = AnalyticsService.create();
/// await analytics.logEvent('project_created', parameters: {
///   'project_id': '...uuid...',
///   'source': 'project_repository',
/// });
/// ```
abstract class AnalyticsService {
  /// Logs a named analytics event.
  ///
  /// [name] is the canonical event name (for example `project_created`).
  /// [parameters] is optional structured metadata that should be JSON-safe.
  ///
  /// Implementations should avoid throwing for non-critical analytics failures;
  /// event loss is preferable to user-flow interruption.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  });

  /// Factory for the default analytics backend.
  ///
  /// Today this returns a Supabase-based implementation. In a future Firebase
  /// migration, update this factory (or add a separate constructor) while
  /// keeping consumers unchanged.
  factory AnalyticsService.create({SupabaseClient? supabaseClient}) {
    return SupabaseAnalyticsService(
      supabaseClient ?? Supabase.instance.client,
    );
  }
}

/// Supabase-backed analytics implementation with offline caching.
///
/// Behavior:
/// - Writes events to `analytics_events` when network/auth are available.
/// - Caches failed events locally in Hive and retries them on subsequent calls.
/// - Never throws to callers for analytics failures.
class SupabaseAnalyticsService implements AnalyticsService {
  SupabaseAnalyticsService(
    this._supabase, {
    bool useFlutterHiveInit = true,
    Future<void> Function(Map<String, dynamic> payload)? insertOverride,
    String? Function()? currentUserIdOverride,
  })  : _useFlutterHiveInit = useFlutterHiveInit,
        _insertOverride = insertOverride,
        _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient _supabase;
  final bool _useFlutterHiveInit;
  final Future<void> Function(Map<String, dynamic> payload)? _insertOverride;
  final String? Function()? _currentUserIdOverride;

  static const String _table = 'analytics_events';
  static const String _boxName = 'analytics_events_cache';
  static const String _pendingEventsKey = 'pending_events';
  static const int _maxPendingEvents = 1000;
  static const int _maxRetryCount = 5;
  static const Duration _pendingRetention = Duration(days: 7);

  bool _initialized = false;

  /// Initializes the local cache box used for offline event buffering.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_useFlutterHiveInit) {
      await Hive.initFlutter();
    }

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    _initialized = true;
  }

  Box get _box => Hive.box(_boxName);

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    if (name.trim().isEmpty) {
      return;
    }

    try {
      await initialize();
      await flushPendingEvents();
    } catch (_) {
      // Initialization or pending flush errors should not block new logging.
    }

    final payload = _buildPayload(name, parameters: parameters);

    try {
      await _insertRemote(payload);
    } catch (_) {
      // If remote write fails (offline/network/RLS/transient), keep event in
      // local cache for best-effort retry.
      await _cacheEvent(payload);
    }
  }

  /// Retries all cached events in FIFO order.
  Future<void> flushPendingEvents() async {
    await initialize();

    final pending = _readPendingEvents()
      ..removeWhere(_isExpiredPendingEvent);
    if (pending.isEmpty) {
      return;
    }

    final remaining = <Map<String, dynamic>>[];
    for (final event in pending) {
      try {
        final payload = _payloadFromPendingEvent(event);
        await _insertRemote(payload);
      } catch (_) {
        final retryCount = (event['__retry_count'] as int? ?? 0) + 1;
        if (retryCount <= _maxRetryCount) {
          remaining.add({
            ...event,
            '__retry_count': retryCount,
          });
        }
      }
    }

    await _writePendingEvents(_boundedPendingEvents(remaining));
  }

  Map<String, dynamic> _buildPayload(
    String name, {
    Map<String, dynamic>? parameters,
  }) {
    final currentUserId = _currentUserId();
    return <String, dynamic>{
      'event': name,
      'user_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
      if (parameters != null && parameters.isNotEmpty) 'parameters': parameters,
    };
  }

  Map<String, dynamic> _ensureUserId(Map<String, dynamic> event) {
    final currentUserId = _currentUserId();
    if (event['user_id'] != null || currentUserId == null) {
      return event;
    }

    return <String, dynamic>{
      ...event,
      'user_id': currentUserId,
    };
  }

  Future<void> _insertRemote(Map<String, dynamic> payload) async {
    final normalized = _ensureUserId(_sanitizeForInsert(payload));

    // If still unauthenticated, defer write and keep the event cached.
    if (normalized['user_id'] == null) {
      throw StateError('No authenticated user for analytics insert');
    }

    if (_insertOverride != null) {
      await _insertOverride!(normalized);
      return;
    }

    await _supabase.from(_table).insert(normalized);
  }

  String? _currentUserId() {
    if (_currentUserIdOverride != null) {
      return _currentUserIdOverride!();
    }

    return _supabase.auth.currentUser?.id;
  }

  Future<void> _cacheEvent(Map<String, dynamic> event) async {
    await initialize();
    final pending = _readPendingEvents()
      ..removeWhere(_isExpiredPendingEvent);

    pending.add({
      ...event,
      '__retry_count': 0,
      '__queued_at': DateTime.now().toIso8601String(),
    });

    await _writePendingEvents(_boundedPendingEvents(pending));
  }

  List<Map<String, dynamic>> _readPendingEvents() {
    final raw = _box.get(_pendingEventsKey);
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: true);
  }

  List<Map<String, dynamic>> _boundedPendingEvents(List<Map<String, dynamic>> events) {
    if (events.length <= _maxPendingEvents) {
      return events;
    }

    return events.sublist(events.length - _maxPendingEvents);
  }

  bool _isExpiredPendingEvent(Map<String, dynamic> event) {
    final queuedAtRaw = event['__queued_at'];
    if (queuedAtRaw is! String) {
      return false;
    }

    final queuedAt = DateTime.tryParse(queuedAtRaw);
    if (queuedAt == null) {
      return false;
    }

    return DateTime.now().difference(queuedAt) > _pendingRetention;
  }

  Map<String, dynamic> _payloadFromPendingEvent(Map<String, dynamic> event) {
    if (event['payload'] is Map) {
      return Map<String, dynamic>.from(event['payload'] as Map);
    }

    return Map<String, dynamic>.from(event);
  }

  Map<String, dynamic> _sanitizeForInsert(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};
    payload.forEach((key, value) {
      if (!key.startsWith('__')) {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  Future<void> _writePendingEvents(List<Map<String, dynamic>> events) async {
    await _box.put(_pendingEventsKey, events);
  }
}
