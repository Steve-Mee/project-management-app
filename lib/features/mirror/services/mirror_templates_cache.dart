import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/mirror_template.dart';

const int _mirrorTemplatesCacheSchemaVersion = 1;
const String _mirrorTemplatesCacheBoxName = 'mirror_templates_cache';
const String _mirrorTemplatesCacheSnapshotKey = 'snapshot';

class MirrorTemplatesCacheSnapshot {
  const MirrorTemplatesCacheSnapshot({
    required this.templates,
    required this.serverVersion,
    required this.fetchedAtUtc,
  });

  final List<MirrorTemplate> templates;
  final String serverVersion;
  final DateTime fetchedAtUtc;
}

class MirrorTemplatesCache {
  const MirrorTemplatesCache();

  Future<MirrorTemplatesCacheSnapshot?> readSnapshot() async {
    final box = await _openBox();
    final raw = box.get(_mirrorTemplatesCacheSnapshotKey);
    if (raw is! Map) {
      return null;
    }

    final normalized = Map<String, dynamic>.from(raw);
    final schemaVersion = _readInt(normalized['schemaVersion']);
    if (schemaVersion != _mirrorTemplatesCacheSchemaVersion) {
      await box.delete(_mirrorTemplatesCacheSnapshotKey);
      return null;
    }

    final fetchedAtRaw = normalized['fetchedAtUtc']?.toString();
    final fetchedAt = fetchedAtRaw == null
        ? null
        : DateTime.tryParse(fetchedAtRaw)?.toUtc();
    if (fetchedAt == null) {
      await box.delete(_mirrorTemplatesCacheSnapshotKey);
      return null;
    }

    final serverVersion = normalized['serverVersion']?.toString() ?? '';
    if (serverVersion.isEmpty) {
      await box.delete(_mirrorTemplatesCacheSnapshotKey);
      return null;
    }

    final templatesRaw = normalized['templates'];
    if (templatesRaw is! List) {
      await box.delete(_mirrorTemplatesCacheSnapshotKey);
      return null;
    }

    final templates = <MirrorTemplate>[];
    for (final item in templatesRaw) {
      if (item is! Map) {
        await box.delete(_mirrorTemplatesCacheSnapshotKey);
        return null;
      }
      final row = Map<String, dynamic>.from(item);
      templates.add(MirrorTemplate.fromMap(row));
    }

    final storedHash = normalized['templatesHash']?.toString() ?? '';
    final expectedHash = _computeTemplatesHash(templates);
    if (storedHash.isEmpty || storedHash != expectedHash) {
      await box.delete(_mirrorTemplatesCacheSnapshotKey);
      return null;
    }

    return MirrorTemplatesCacheSnapshot(
      templates: List<MirrorTemplate>.unmodifiable(templates),
      serverVersion: serverVersion,
      fetchedAtUtc: fetchedAt,
    );
  }

  Future<void> writeSnapshot(MirrorTemplatesCacheSnapshot snapshot) async {
    final box = await _openBox();
    final templates = snapshot.templates
        .map(_templateToMap)
        .toList(growable: false);

    await box.put(
      _mirrorTemplatesCacheSnapshotKey,
      <String, dynamic>{
        'schemaVersion': _mirrorTemplatesCacheSchemaVersion,
        'serverVersion': snapshot.serverVersion,
        'fetchedAtUtc': snapshot.fetchedAtUtc.toUtc().toIso8601String(),
        'templatesHash': _computeTemplatesHash(snapshot.templates),
        'templates': templates,
      },
    );
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_mirrorTemplatesCacheSnapshotKey);
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_mirrorTemplatesCacheBoxName)) {
      return Hive.box<dynamic>(_mirrorTemplatesCacheBoxName);
    }
    return Hive.openBox<dynamic>(_mirrorTemplatesCacheBoxName);
  }

  Map<String, dynamic> _templateToMap(MirrorTemplate template) {
    return <String, dynamic>{
      'id': template.id,
      'template_key': template.id,
      'title': template.title,
      'description': template.description,
      'seed_content': template.seedContent,
      'tags': template.tags,
      'icon_name': template.iconName,
    };
  }

  String _computeTemplatesHash(List<MirrorTemplate> templates) {
    final normalizedRows = templates
        .map(_templateToMap)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false)
      ..sort((a, b) {
        final aKey = a['template_key']?.toString() ?? a['id']?.toString() ?? '';
        final bKey = b['template_key']?.toString() ?? b['id']?.toString() ?? '';
        return aKey.compareTo(bKey);
      });
    final encoded = jsonEncode(normalizedRows);
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
