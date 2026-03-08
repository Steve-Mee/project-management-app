import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/repository/hive_initializer.dart' as core_hive;

class HiveInitializer {
  static const String mirrorSessionsCacheBox = 'mirror_sessions_cache';

  static Future<void> initialize() async {
    await core_hive.HiveInitializer.initialize();
    await _openMirrorSessionsCacheBox();
  }

  static Future<Box<Map>> _openMirrorSessionsCacheBox() async {
    if (Hive.isBoxOpen(mirrorSessionsCacheBox)) {
      return Hive.box<Map>(mirrorSessionsCacheBox);
    }
    return Hive.openBox<Map>(mirrorSessionsCacheBox);
  }

  static String _sessionKey(String projectId, String taskId) => '$projectId::$taskId';

  static Future<void> saveSessionVersion({
    required String projectId,
    required String taskId,
    required Map<String, dynamic> version,
  }) async {
    final box = await _openMirrorSessionsCacheBox();
    final key = _sessionKey(projectId, taskId);

    final current = box.get(key);
    final versions = <Map<String, dynamic>>[];

    if (current != null) {
      final raw = current['versions'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            versions.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    versions.add(<String, dynamic>{
      ...version,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await box.put(key, <String, dynamic>{
      'projectId': projectId,
      'taskId': taskId,
      'versions': versions,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getSessionVersions({
    required String projectId,
    required String taskId,
  }) async {
    final box = await _openMirrorSessionsCacheBox();
    final key = _sessionKey(projectId, taskId);
    final payload = box.get(key);

    if (payload == null) {
      return <Map<String, dynamic>>[];
    }

    final raw = payload['versions'];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  static Future<void> clearSessionVersions({
    required String projectId,
    required String taskId,
  }) async {
    final box = await _openMirrorSessionsCacheBox();
    final key = _sessionKey(projectId, taskId);
    await box.delete(key);
  }

  static Future<void> clearAllMirrorSessions() async {
    final box = await _openMirrorSessionsCacheBox();
    await box.clear();
  }
}
