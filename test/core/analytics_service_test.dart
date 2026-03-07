import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/core/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveTempDir;

  setUpAll(() async {
    hiveTempDir = await Directory.systemTemp.createTemp('analytics_service_test_');
    Hive.init(hiveTempDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('analytics_events_cache')) {
      final box = Hive.box('analytics_events_cache');
      await box.clear();
      await box.close();
    }
  });

  tearDownAll(() async {
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  List<Map<String, dynamic>> pendingEvents() {
    final box = Hive.box('analytics_events_cache');
    final raw = box.get('pending_events');
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  test('caches event when user is unauthenticated', () async {
    final inserted = <Map<String, dynamic>>[];
    String? currentUserId;

    final service = SupabaseAnalyticsService(
      _FakeSupabaseClient(),
      useFlutterHiveInit: false,
      currentUserIdOverride: () => currentUserId,
      insertOverride: (payload) async => inserted.add(payload),
    );

    await service.logEvent('event_without_user');

    expect(inserted, isEmpty);
    final pending = pendingEvents();
    expect(pending.length, 1);
    expect(pending.first['event'], 'event_without_user');
    expect(pending.first['__retry_count'], 0);
  });

  test('flushes pending events when user becomes available', () async {
    final inserted = <Map<String, dynamic>>[];
    String? currentUserId;

    final service = SupabaseAnalyticsService(
      _FakeSupabaseClient(),
      useFlutterHiveInit: false,
      currentUserIdOverride: () => currentUserId,
      insertOverride: (payload) async => inserted.add(payload),
    );

    await service.logEvent('deferred_event');
    expect(pendingEvents(), hasLength(1));

    currentUserId = 'user-1';
    await service.flushPendingEvents();

    expect(pendingEvents(), isEmpty);
    expect(inserted, hasLength(1));
    expect(inserted.first['event'], 'deferred_event');
    expect(inserted.first['user_id'], 'user-1');
  });

  test('drops poison event after retry cap', () async {
    String? currentUserId = 'user-1';

    final service = SupabaseAnalyticsService(
      _FakeSupabaseClient(),
      useFlutterHiveInit: false,
      currentUserIdOverride: () => currentUserId,
      insertOverride: (_) async {
        throw Exception('simulated insert failure');
      },
    );

    await service.logEvent('poison_event');
    expect(pendingEvents(), hasLength(1));

    for (var i = 0; i < 6; i++) {
      await service.flushPendingEvents();
    }

    expect(pendingEvents(), isEmpty);
  });

  test('keeps pending queue bounded to max size', () async {
    String? currentUserId;

    final service = SupabaseAnalyticsService(
      _FakeSupabaseClient(),
      useFlutterHiveInit: false,
      currentUserIdOverride: () => currentUserId,
      insertOverride: (_) async {},
    );

    for (var i = 0; i < 1010; i++) {
      await service.logEvent('queued_event_$i');
    }

    final pending = pendingEvents();
    expect(pending.length, lessThanOrEqualTo(1000));
  });
}
