// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
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
      .map(MirrorTemplate.fromMap)
      .toList(growable: false);
});

