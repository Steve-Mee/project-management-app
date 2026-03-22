// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
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

class MirrorTemplatesLoadReasonCodes {
  const MirrorTemplatesLoadReasonCodes._();

  static const String empty = 'empty';
  static const String stale = 'stale';
  static const String versionMismatch = 'version_mismatch';
  static const String networkOrFetchError = 'network_or_fetch_error';
}

class MirrorTemplatesLoadResult {
  const MirrorTemplatesLoadResult({
    required this.templates,
    required this.freshness,
    required this.source,
    this.reasonCode,
    this.fetchedAtUtc,
  });

  final List<MirrorTemplate> templates;
  final MirrorTemplatesFreshness freshness;
  final String source;
  final String? reasonCode;
  final DateTime? fetchedAtUtc;

  bool get isStaleFallback => freshness == MirrorTemplatesFreshness.staleFallback;
}

final mirrorTemplatesCacheProvider =
    Provider<MirrorTemplatesCache>((ref) => const MirrorTemplatesCache());

final mirrorTemplatesObservabilityProvider =
    Provider<MirrorObservabilityService>((ref) => const MirrorObservabilityService());

final mirrorTemplatesSupabaseClientProvider =
    Provider<SupabaseClient>((ref) => ref.read(supabaseClientProvider));

final mirrorTemplatesProvider =
  FutureProvider<MirrorTemplatesLoadResult>((ref) async {
  final client = ref.read(mirrorTemplatesSupabaseClientProvider);
  final persistentCache = ref.read(mirrorTemplatesCacheProvider);
  final observability = ref.read(mirrorTemplatesObservabilityProvider);
  final now = DateTime.now().toUtc();
  var cached = _MirrorTemplatesMemoryCache.snapshot;
  var cacheSource = 'none';

  if (cached != null) {
    cacheSource = 'memory';
  }

  if (cached == null) {
    final persisted = await persistentCache.readSnapshot();
    if (persisted != null) {
      cacheSource = 'persistent';
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
      observability.recordTemplateCacheEvent(
        result: 'hit',
        source: cacheSource,
        freshness: 'fresh',
        templateCount: cached.templates.length,
      );
      return MirrorTemplatesLoadResult(
        templates: cached.templates,
        freshness: MirrorTemplatesFreshness.fresh,
        source: cacheSource,
        fetchedAtUtc: cached.fetchedAtUtc,
      );
    }

    final missReason = cached == null
        ? MirrorTemplatesLoadReasonCodes.empty
        : now.difference(cached.fetchedAtUtc) > _templatesCacheTtl
            ? MirrorTemplatesLoadReasonCodes.stale
            : MirrorTemplatesLoadReasonCodes.versionMismatch;

    observability.recordTemplateCacheEvent(
      result: 'miss',
      source: cacheSource,
      reason: missReason,
      freshness: 'fresh',
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
      fetchedAtUtc: now,
    );
  } catch (_) {
    final canUseCache = cached != null &&
        now.difference(cached.fetchedAtUtc) <= _templatesCacheTtl;
    if (canUseCache) {
      final stalenessAgeMs = now.difference(cached.fetchedAtUtc).inMilliseconds;
      observability.recordTemplateCacheEvent(
        result: 'fallback',
        source: cacheSource,
        reason: MirrorTemplatesLoadReasonCodes.networkOrFetchError,
        freshness: 'stale_fallback',
        stalenessAgeMs: stalenessAgeMs,
        templateCount: cached.templates.length,
      );
      return MirrorTemplatesLoadResult(
        templates: cached.templates,
        freshness: MirrorTemplatesFreshness.staleFallback,
        source: cacheSource,
        reasonCode: MirrorTemplatesLoadReasonCodes.networkOrFetchError,
        fetchedAtUtc: cached.fetchedAtUtc,
      );
    }
    rethrow;
  }
});

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
