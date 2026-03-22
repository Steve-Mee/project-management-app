// ignore_for_file: subtype_of_sealed_class
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_management_app/core/providers/supabase_client_provider.dart';
import 'package:project_management_app/features/mirror/models/mirror_template.dart';
import 'package:project_management_app/features/mirror/providers/mirror_templates_provider.dart';
import 'package:project_management_app/features/mirror/services/mirror_templates_cache.dart';

// ── Fake helpers ──────────────────────────────────────────────────────────────

/// Fake Supabase client: any method call goes through [noSuchMethod] and
/// throws [UnsupportedError].  This forces [_fetchTemplatesServerVersion]
/// to fail inside the try-block so the error-fallback path is exercised.
class _FakeSupabaseClient extends Fake implements SupabaseClient {}

/// Controllable in-memory implementation of [MirrorTemplatesCache].
/// Call [seed] before a test to pre-populate the persistent cache layer.
class _FakeMirrorTemplatesCache extends MirrorTemplatesCache {
  MirrorTemplatesCacheSnapshot? _stored;

  void seed(MirrorTemplatesCacheSnapshot snapshot) => _stored = snapshot;

  @override
  Future<MirrorTemplatesCacheSnapshot?> readSnapshot() async => _stored;

  @override
  Future<void> writeSnapshot(MirrorTemplatesCacheSnapshot snapshot) async {
    _stored = snapshot;
  }

  @override
  Future<void> clear() async => _stored = null;
}

// ── Test utilities ────────────────────────────────────────────────────────────

MirrorTemplate _tpl(String id) => MirrorTemplate(
      id: id,
      title: 'Title $id',
      description: 'Desc $id',
      seedContent: 'Content $id',
      // Non-empty iconName is required for Hive round-trip hash correctness:
      // MirrorTemplate.fromMap promotes an empty icon_name to the template key,
      // which would cause _computeTemplatesHash to produce a different value on
      // read-back than on write.
      iconName: 'icon-$id',
    );

ProviderContainer _makeContainer(_FakeMirrorTemplatesCache fakeCache) =>
    ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWith((ref) => _FakeSupabaseClient()),
        mirrorTemplatesCacheProvider.overrideWith((ref) => fakeCache),
      ],
    );

// ── Test suite ────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp
        .createTemp('mirror_templates_cache_test_');
    Hive.init(hiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  setUp(() async {
    if (Hive.isBoxOpen('mirror_templates_cache')) {
      await Hive.box<dynamic>('mirror_templates_cache').clear();
    }
    debugResetMirrorTemplatesMemoryCache();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Group 1 — MirrorTemplatesCache service (Hive persistence layer)
  // ──────────────────────────────────────────────────────────────────────────

  group('MirrorTemplatesCache', () {
    test('readSnapshot returns null on empty box', () async {
      const cache = MirrorTemplatesCache();
      expect(await cache.readSnapshot(), isNull);
    });

    test('readSnapshot returns null when schemaVersion does not match',
        () async {
      final box = await Hive.openBox<dynamic>('mirror_templates_cache');
      await box.put('snapshot', <String, dynamic>{
        'schemaVersion': 99, // wrong version
        'serverVersion': 'v1',
        'fetchedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'templatesHash': 'any',
        'templates': <dynamic>[],
      });
      expect(await const MirrorTemplatesCache().readSnapshot(), isNull);
    });

    test('readSnapshot returns null when fetchedAtUtc is missing', () async {
      final box = await Hive.openBox<dynamic>('mirror_templates_cache');
      await box.put('snapshot', <String, dynamic>{
        'schemaVersion': 1,
        'serverVersion': 'v1',
        // fetchedAtUtc intentionally omitted
        'templatesHash': 'any',
        'templates': <dynamic>[],
      });
      expect(await const MirrorTemplatesCache().readSnapshot(), isNull);
    });

    test('readSnapshot returns null when serverVersion is empty', () async {
      final box = await Hive.openBox<dynamic>('mirror_templates_cache');
      await box.put('snapshot', <String, dynamic>{
        'schemaVersion': 1,
        'serverVersion': '',
        'fetchedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'templatesHash': 'any',
        'templates': <dynamic>[],
      });
      expect(await const MirrorTemplatesCache().readSnapshot(), isNull);
    });

    test('readSnapshot returns null when templatesHash does not match',
        () async {
      final box = await Hive.openBox<dynamic>('mirror_templates_cache');
      await box.put('snapshot', <String, dynamic>{
        'schemaVersion': 1,
        'serverVersion': 'v1',
        'fetchedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'templatesHash': 'intentionally-wrong-hash',
        'templates': <dynamic>[],
      });
      expect(await const MirrorTemplatesCache().readSnapshot(), isNull);
    });

    test('writeSnapshot → readSnapshot round-trip preserves all fields',
        () async {
      final templates = [_tpl('alpha'), _tpl('beta')];
      final now = DateTime.utc(2024, 6, 1, 12);
      const cache = MirrorTemplatesCache();

      await cache.writeSnapshot(
        MirrorTemplatesCacheSnapshot(
          templates: templates,
          serverVersion: 'server-v2',
          fetchedAtUtc: now,
        ),
      );

      final result = await cache.readSnapshot();
      expect(result, isNotNull);
      expect(result!.serverVersion, 'server-v2');
      expect(result.fetchedAtUtc, now);
      expect(result.templates.map((t) => t.id).toList(),
          containsAllInOrder(['alpha', 'beta']));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Group 2 — mirrorTemplatesProvider cache-layer behaviour
  //
  // All tests in this group use a _FakeSupabaseClient, which throws
  // UnsupportedError on any method call.  That error is thrown inside the
  // try-block of mirrorTemplatesProvider, so the catch-fallback path runs.
  // Depending on cache state, the provider either returns cached templates
  // or rethrows the error.
  // ──────────────────────────────────────────────────────────────────────────

  group('mirrorTemplatesProvider', () {
    late _FakeMirrorTemplatesCache fakeCache;

    setUp(() {
      fakeCache = _FakeMirrorTemplatesCache();
    });

    test(
        'returns memory-cached templates on network error when memory cache '
        'is within TTL', () async {
      debugSetMirrorTemplatesMemoryCache(
        templates: [_tpl('mem-1')],
        serverVersion: 'v1',
        fetchedAtUtc:
            DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      );

      final container = _makeContainer(fakeCache);
      addTearDown(container.dispose);

      final result = await container.read(mirrorTemplatesProvider.future);
      expect(result.templates.map((t) => t.id).toList(), ['mem-1']);
      expect(result.isStaleFallback, isTrue);
      expect(
        result.reasonCode,
        MirrorTemplatesLoadReasonCodes.networkOrFetchError,
      );
    });

    test(
        'returns persistent-cached templates on network error when '
        'persistent cache is within TTL and memory cache is empty', () async {
      fakeCache.seed(
        MirrorTemplatesCacheSnapshot(
          templates: [_tpl('per-1'), _tpl('per-2')],
          serverVersion: 'v1',
          fetchedAtUtc:
              DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
        ),
      );

      final container = _makeContainer(fakeCache);
      addTearDown(container.dispose);

      final result = await container.read(mirrorTemplatesProvider.future);
      expect(result.templates.map((t) => t.id).toList(), ['per-1', 'per-2']);
      expect(result.isStaleFallback, isTrue);
      expect(
        result.reasonCode,
        MirrorTemplatesLoadReasonCodes.networkOrFetchError,
      );
    });

    test(
        'rethrows network error when memory cache is stale (> 10 min TTL)',
        () async {
      debugSetMirrorTemplatesMemoryCache(
        templates: [_tpl('old-1')],
        serverVersion: 'v1',
        fetchedAtUtc:
            DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
      );

      final container = _makeContainer(fakeCache);
      addTearDown(container.dispose);

      await expectLater(
        container.read(mirrorTemplatesProvider.future),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
        'rethrows network error when no cache is available', () async {
      // Memory cache was reset in outer setUp; fakeCache returns null.
      final container = _makeContainer(fakeCache);
      addTearDown(container.dispose);

      await expectLater(
        container.read(mirrorTemplatesProvider.future),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
