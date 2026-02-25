import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/models/project_meta.dart';

/// Repository for project metadata such as urgency and tracked time.
class ProjectMetaRepository {
  static const String _boxName = 'project_meta';
  late Box<Map> _box;

  Future<void> initialize() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Map>(_boxName);
      return;
    }

    _box = await Hive.openBox<Map>(_boxName);
  }

  bool get isInitialized => _box.isOpen;

  ProjectMeta getMeta(String projectId) {
    final raw = _box.get(projectId);
    if (raw is Map) {
      return ProjectMeta.fromMap(projectId, Map<String, dynamic>.from(raw));
    }
    return ProjectMeta.defaultFor(projectId);
  }

  Map<String, ProjectMeta> getAllMeta() {
    final result = <String, ProjectMeta>{};
    for (final key in _box.keys) {
      final id = key.toString();
      final raw = _box.get(key);
      if (raw is Map) {
        result[id] = ProjectMeta.fromMap(id, Map<String, dynamic>.from(raw));
      }
    }
    return result;
  }

  Future<void> setUrgency(String projectId, UrgencyLevel urgency) async {
    final current = getMeta(projectId);
    await _box.put(
      projectId,
      current.copyWith(urgency: urgency).toMap(),
    );
  }

  Future<void> setTrackedSeconds(String projectId, int seconds) async {
    final current = getMeta(projectId);
    await _box.put(
      projectId,
      current.copyWith(trackedSeconds: seconds).toMap(),
    );
  }

  Future<void> addTrackedSeconds(String projectId, int delta) async {
    final current = getMeta(projectId);
    await _box.put(
      projectId,
      current.copyWith(trackedSeconds: current.trackedSeconds + delta).toMap(),
    );
  }

  Future<void> close() async {
    await _box.compact();
    await _box.close();
  }
}
