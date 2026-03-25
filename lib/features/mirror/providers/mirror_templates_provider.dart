// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../models/mirror_template.dart';
import '../services/mirror_observability_service.dart';
import '../services/mirror_templates_cache.dart';

const Duration _templatesCacheTtl = Duration(minutes: 10);

enum MirrorTemplatesFreshness {
  fresh,
  staleFallback,
}

enum MirrorTemplatesDataSource {
  network,
  memory,
  persistent,
  none,
}

class MirrorTemplatesLoadReasonCodes {
  const MirrorTemplatesLoadReasonCodes._();

  static const String empty = 'empty';
  static const String stale = 'stale';
  static const String versionMismatch = 'version_mismatch';
  static const String networkError = 'network_error';
  static const String timeout = 'timeout';
}

class MirrorTemplatesLoadResult {
  const MirrorTemplatesLoadResult({
    required this.templates,
    required this.freshness,
    required this.source,
    required this.sourceKind,
    this.reasonCode,
    this.fetchedAtUtc,
    this.cacheAge,
  });

  final List<MirrorTemplate> templates;
  final MirrorTemplatesFreshness freshness;
  final String source;
  final MirrorTemplatesDataSource sourceKind;
  final String? reasonCode;
  final DateTime? fetchedAtUtc;
  final Duration? cacheAge;

  bool get isStaleFallback => freshness == MirrorTemplatesFreshness.staleFallback;

  String get staleFallbackSourceLabel {
    switch (sourceKind) {
      case MirrorTemplatesDataSource.memory:
        return 'memory cache';
      case MirrorTemplatesDataSource.persistent:
        return 'persistent cache';
      case MirrorTemplatesDataSource.network:
        return 'network';
      case MirrorTemplatesDataSource.none:
        return 'cache unavailable';
    }
  }
}

final mirrorTemplatesCacheProvider =
    Provider<MirrorTemplatesCache>((ref) => const MirrorTemplatesCache());

final mirrorTemplatesObservabilityProvider =
    Provider<MirrorObservabilityService>((ref) => const MirrorObservabilityService());

final mirrorTemplatesSupabaseClientProvider =
    Provider<SupabaseClient>((ref) => ref.read(supabaseClientProvider));

final mirrorTemplatesInvalidationControllerProvider =
    Provider<MirrorTemplatesInvalidationController>(
  (ref) => MirrorTemplatesInvalidationController(ref),
);

/// Keeps template cache coherent when mirror template rows change server-side,
/// such as after seed/sync operations from admin tooling.
final mirrorTemplatesRealtimeInvalidationProvider =
    Provider.autoDispose<void>((ref) {
  final client = ref.read(mirrorTemplatesSupabaseClientProvider);
  final channel = client.channel('mirror-templates-cache-invalidation');

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'mirror_templates',
        callback: (PostgresChangePayload _) {
          unawaited(
            ref
                .read(mirrorTemplatesInvalidationControllerProvider)
                .invalidateTemplatesCache(),
          );
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

final mirrorTemplatesProvider =
  FutureProvider<MirrorTemplatesLoadResult>((ref) async {
  final client = ref.read(mirrorTemplatesSupabaseClientProvider);
  final persistentCache = ref.read(mirrorTemplatesCacheProvider);
  final observability = ref.read(mirrorTemplatesObservabilityProvider);
  final now = DateTime.now().toUtc();
  var cached = _MirrorTemplatesMemoryCache.snapshot;
  String? missReason;
  var cacheSource = 'none';
  var cacheSourceKind = MirrorTemplatesDataSource.none;

  if (cached != null) {
    cacheSource = 'memory';
    cacheSourceKind = MirrorTemplatesDataSource.memory;
  }

  if (cached == null) {
    final persisted = await persistentCache.readSnapshot();
    if (persisted != null) {
      cacheSource = 'persistent';
      cacheSourceKind = MirrorTemplatesDataSource.persistent;
      cached = _TemplatesCacheSnapshot(
        templates: persisted.templates,
        serverVersion: persisted.serverVersion,
        fetchedAtUtc: persisted.fetchedAtUtc,
      );
      _MirrorTemplatesMemoryCache.snapshot = cached;
    }
  }

  try {
    final serverVersion = await _fetchTemplatesServerVersion(client);
    final cacheIsFresh = cached != null &&
        now.difference(cached.fetchedAtUtc) <= _templatesCacheTtl &&
        cached.serverVersion == serverVersion;

    if (cacheIsFresh) {
      final cacheAge = now.difference(cached.fetchedAtUtc);
      observability.recordTemplateCacheEvent(
        result: 'hit',
        source: cacheSource,
        freshness: 'fresh',
        stalenessAgeMs: cacheAge.inMilliseconds,
        templateCount: cached.templates.length,
      );
      return MirrorTemplatesLoadResult(
        templates: cached.templates,
        freshness: MirrorTemplatesFreshness.fresh,
        source: cacheSource,
        sourceKind: cacheSourceKind,
        fetchedAtUtc: cached.fetchedAtUtc,
        cacheAge: cacheAge,
      );
    }

    missReason = cached == null
        ? MirrorTemplatesLoadReasonCodes.empty
        : now.difference(cached.fetchedAtUtc) > _templatesCacheTtl
            ? MirrorTemplatesLoadReasonCodes.stale
            : MirrorTemplatesLoadReasonCodes.versionMismatch;

    observability.recordTemplateCacheEvent(
      result: 'miss',
      source: cacheSource,
      reason: missReason,
      freshness: 'fresh',
      stalenessAgeMs: cached == null
          ? null
          : now.difference(cached.fetchedAtUtc).inMilliseconds,
      templateCount: cached?.templates.length,
    );

    final templates = await _fetchTemplates(client);
    _MirrorTemplatesMemoryCache.snapshot = _TemplatesCacheSnapshot(
      templates: templates,
      serverVersion: serverVersion,
      fetchedAtUtc: now,
    );
    await persistentCache.writeSnapshot(
      MirrorTemplatesCacheSnapshot(
        templates: templates,
        serverVersion: serverVersion,
        fetchedAtUtc: now,
      ),
    );
    return MirrorTemplatesLoadResult(
      templates: templates,
      freshness: MirrorTemplatesFreshness.fresh,
      source: 'network',
      sourceKind: MirrorTemplatesDataSource.network,
      fetchedAtUtc: now,
      cacheAge: Duration.zero,
    );
  } catch (error) {
    final canUseCache = cached != null &&
        now.difference(cached.fetchedAtUtc) <= _templatesCacheTtl;
    if (canUseCache) {
      final fallbackReason = _classifyTemplatesFallbackReason(
        error: error,
        missReason: missReason,
      );
      final stalenessAgeMs = now.difference(cached.fetchedAtUtc).inMilliseconds;
      observability.recordTemplateCacheEvent(
        result: 'fallback',
        source: cacheSource,
        reason: fallbackReason,
        freshness: 'stale_fallback',
        stalenessAgeMs: stalenessAgeMs,
        templateCount: cached.templates.length,
      );
      observability.recordTemplateCacheFallback(
        source: cacheSource,
        reason: fallbackReason,
        stalenessAgeMs: stalenessAgeMs,
        templateCount: cached.templates.length,
      );
      return MirrorTemplatesLoadResult(
        templates: cached.templates,
        freshness: MirrorTemplatesFreshness.staleFallback,
        source: cacheSource,
        sourceKind: cacheSourceKind,
        reasonCode: fallbackReason,
        fetchedAtUtc: cached.fetchedAtUtc,
        cacheAge: now.difference(cached.fetchedAtUtc),
      );
    }
    rethrow;
  }
});

String _classifyTemplatesFallbackReason({
  required Object error,
  required String? missReason,
}) {
  if (error is TimeoutException) {
    return MirrorTemplatesLoadReasonCodes.timeout;
  }

  if (missReason == MirrorTemplatesLoadReasonCodes.versionMismatch) {
    return MirrorTemplatesLoadReasonCodes.versionMismatch;
  }

  return MirrorTemplatesLoadReasonCodes.networkError;
}

/// Exposes fallback reason classification for unit tests.
@visibleForTesting
String debugClassifyTemplatesFallbackReason({
  required Object error,
  required String? missReason,
}) {
  return _classifyTemplatesFallbackReason(error: error, missReason: missReason);
}

Future<List<MirrorTemplate>> _fetchTemplates(SupabaseClient client) async {
  final rows = await client
      .from('mirror_templates')
      .select('id,template_key,title,description,seed_content,tags,icon_name')
      .eq('is_active', true)
      .order('updated_at', ascending: false)
      .limit(100);

  return rows
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .map(MirrorTemplate.fromMap)
      .toList(growable: false);
}

Future<String> _fetchTemplatesServerVersion(SupabaseClient client) async {
  final rows = await client
      .from('mirror_templates')
      .select('id,updated_at')
      .eq('is_active', true)
      .order('updated_at', ascending: false)
      .order('id', ascending: false)
      .limit(1);

  if (rows.isEmpty) {
    return 'empty';
  }

  final row = Map<String, dynamic>.from(rows.first);
  final updatedAt = row['updated_at']?.toString() ?? 'none';
  final id = row['id']?.toString() ?? 'none';
  return '$updatedAt::$id';
}

class _TemplatesCacheSnapshot {
  const _TemplatesCacheSnapshot({
    required this.templates,
    required this.serverVersion,
    required this.fetchedAtUtc,
  });

  final List<MirrorTemplate> templates;
  final String serverVersion;
  final DateTime fetchedAtUtc;
}

class _MirrorTemplatesMemoryCache {
  static _TemplatesCacheSnapshot? snapshot;
}

class MirrorTemplatesInvalidationController {
  MirrorTemplatesInvalidationController(this._ref);

  final Ref _ref;

  Future<void> invalidateTemplatesCache({bool refresh = false}) async {
    _MirrorTemplatesMemoryCache.snapshot = null;
    await _ref.read(mirrorTemplatesCacheProvider).clear();
    _ref.invalidate(mirrorTemplatesProvider);
    if (refresh) {
      final _ = _ref.refresh(mirrorTemplatesProvider);
    }
  }
}

/// Resets the in-process template memory cache.
/// FOR TESTING ONLY — never call from production code.
@visibleForTesting
void debugResetMirrorTemplatesMemoryCache() {
  _MirrorTemplatesMemoryCache.snapshot = null;
}

/// Seeds the in-process template memory cache with a specific snapshot.
/// FOR TESTING ONLY — never call from production code.
@visibleForTesting
void debugSetMirrorTemplatesMemoryCache({
  required List<MirrorTemplate> templates,
  required String serverVersion,
  required DateTime fetchedAtUtc,
}) {
  _MirrorTemplatesMemoryCache.snapshot = _TemplatesCacheSnapshot(
    templates: templates,
    serverVersion: serverVersion,
    fetchedAtUtc: fetchedAtUtc,
  );
}
