library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../templates_gallery.dart';

final mirrorTemplatesProvider = FutureProvider<List<MirrorTemplate>>((ref) async {
  final client = Supabase.instance.client;

  try {
    final rows = await client
        .from('mirror_templates')
        .select('id,title,description,seed_content,tags')
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(100);

    return rows
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(_toTemplate)
        .toList(growable: false);
  } catch (_) {
    return const <MirrorTemplate>[];
  }
});

MirrorTemplate _toTemplate(Map<String, dynamic> row) {
  final id = (row['id'] ?? '').toString();
  final title = (row['title'] ?? 'Untitled template').toString();
  final description = (row['description'] ?? '').toString();
  final seedContent = (row['seed_content'] ?? '').toString();

  final tagsRaw = row['tags'];
  final tags = tagsRaw is List
      ? tagsRaw.map((tag) => tag.toString()).where((tag) => tag.isNotEmpty).toList()
      : const <String>[];

  return MirrorTemplate(
    id: id,
    title: title,
    description: description,
    icon: _iconForTemplate(row),
    seedContent: seedContent,
    tags: tags,
  );
}

IconData _iconForTemplate(Map<String, dynamic> row) {
  final kind = (row['kind'] ?? row['type'] ?? '').toString().toLowerCase();

  switch (kind) {
    case 'widget':
      return Icons.widgets;
    case 'service':
      return Icons.settings;
    case 'doc':
    case 'markdown':
      return Icons.description;
    default:
      return Icons.auto_awesome;
  }
}
