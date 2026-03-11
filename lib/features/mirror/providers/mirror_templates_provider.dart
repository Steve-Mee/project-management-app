// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mirror_template.dart';

const Duration _templatesCacheTtl = Duration(minutes: 10);

final mirrorTemplatesProvider =
    FutureProvider<List<MirrorTemplate>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final cached = _MirrorTemplatesMemoryCache.snapshot;

  try {
    final serverVersion = await _fetchTemplatesServerVersion(client);
    final cacheIsFresh = cached != null &&
        now.difference(cached.fetchedAtUtc) <= _templatesCacheTtl &&
        cached.serverVersion == serverVersion;

    if (cacheIsFresh) {
      return cached.templates;
    }

    final templates = await _fetchTemplates(client);
    _MirrorTemplatesMemoryCache.snapshot = _TemplatesCacheSnapshot(
      templates: templates,
      serverVersion: serverVersion,
      fetchedAtUtc: now,
    );
    return templates;
  } catch (_) {
    final canUseCache = cached != null &&
        now.difference(cached.fetchedAtUtc) <= _templatesCacheTtl;
    if (canUseCache) {
      return cached.templates;
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
