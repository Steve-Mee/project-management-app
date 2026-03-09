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
      .select('id,template_key,title,description,seed_content,tags,icon_name')
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
  final templateKey = (row['template_key'] ?? '').toString().trim();
  final rawId = (row['id'] ?? '').toString().trim();
  final id = templateKey.isNotEmpty ? templateKey : rawId;
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
    icon: _iconForTemplate(
      templateKey: templateKey,
      iconName: (row['icon_name'] ?? '').toString(),
    ),
    seedContent: seedContent,
    tags: tags,
  );
}

IconData _iconForTemplate({
  required String templateKey,
  required String iconName,
}) {
  final normalizedIcon = iconName.trim().toLowerCase();
  switch (normalizedIcon) {
    case 'widgets':
      return Icons.widgets;
    case 'settings':
    case 'build':
      return Icons.settings;
    case 'description':
    case 'article':
      return Icons.description;
    case 'code':
      return Icons.code;
    case 'bug_report':
      return Icons.bug_report;
    case 'terminal':
      return Icons.terminal;
    case 'rocket_launch':
      return Icons.rocket_launch;
    case 'bolt':
      return Icons.bolt;
    case 'palette':
      return Icons.palette;
    case 'data_object':
      return Icons.data_object;
    case 'storage':
      return Icons.storage;
  }

  final normalizedKey = templateKey.toLowerCase();
  if (normalizedKey.contains('widget') || normalizedKey.contains('ui')) {
      return Icons.widgets;
  }
  if (normalizedKey.contains('service') ||
      normalizedKey.contains('backend')) {
      return Icons.settings;
  }
  if (normalizedKey.contains('doc') || normalizedKey.contains('markdown')) {
      return Icons.description;
  }

  return Icons.auto_awesome;
}
