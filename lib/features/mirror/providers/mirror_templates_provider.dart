import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mirror_template.dart';

final mirrorTemplatesProvider = FutureProvider<List<MirrorTemplate>>((ref) async {
  final client = Supabase.instance.client;

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
});

MirrorTemplate _toTemplate(Map<String, dynamic> row) {
  final templateKey = _readString(
    row,
    const <String>['template_key', 'templateKey', 'key'],
  );
  final rawId = (row['id'] ?? '').toString().trim();
  final id = templateKey.isNotEmpty ? templateKey : rawId;
  final title = _readString(
    row,
    const <String>['title'],
    fallback: 'Untitled template',
  );
  final description = _readString(row, const <String>['description']);
  final seedContent = _readString(
    row,
    const <String>['seed_content', 'seedContent', 'content'],
  );

  final tagsRaw = row['tags'];
  final tags = tagsRaw is List
      ? tagsRaw.map((tag) => tag.toString()).where((tag) => tag.isNotEmpty).toList()
      : const <String>[];

  return MirrorTemplate(
    id: id,
    title: title,
    description: description,
    iconName: _readString(
      row,
      const <String>['icon_name', 'iconName', 'icon'],
      fallback: templateKey,
    ),
    seedContent: seedContent,
    tags: tags,
  );
}

String _readString(
  Map<String, dynamic> row,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = row[key];
    if (value == null) {
      continue;
    }
    final normalized = value.toString().trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return fallback;
}

