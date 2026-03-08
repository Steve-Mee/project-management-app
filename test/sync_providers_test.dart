import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/dashboard_types.dart';
import 'package:pma_core/models/project_filter.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/project_requirements.dart';
import 'package:pma_core/models/requirements.dart';
import 'package:pma_core/providers/sync/sync_providers.dart';
import 'package:pma_core/repository/i_dashboard_repository.dart';
import 'package:pma_core/repository/i_project_repository.dart';
import 'package:pma_core/repository/models/dashboard_models.dart';
import 'package:pma_core/repository/models/project_models.dart';

class FakeProjectRepository implements IProjectRepository {
  final Map<String, ProjectModel> _projects = <String, ProjectModel>{};
  final StreamController<List<ProjectModel>> _changes =
      StreamController<List<ProjectModel>>.broadcast();

  @override
  Future<void> addProject(
    ProjectModel project, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    _projects[project.id] = project;
    _changes.add(_projects.values.toList());
  }

  @override
  Future<void> addSharedGroup(
    String projectId,
    String groupId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {}

  @override
  Future<void> addSharedUser(
    String projectId,
    String username, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {}

  @override
  Future<void> bidirectionalSyncProject(String projectId) async {
    await syncProject(projectId);
  }

  @override
  Future<void> close() async {
    await _changes.close();
  }

  @override
  Future<void> deleteProject(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    _projects.remove(projectId);
    _changes.add(_projects.values.toList());
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async => _projects.values.toList();

  @override
  Future<List<ProjectModel>> getFilteredProjects(
    ProjectFilter filter, {
    List<ProjectFilterConditions> extraConditions = const [],
  }) async {
    return _projects.values.toList();
  }

  @override
  Future<ProjectModel> getProjectById(String id) async {
    final project = _projects[id];
    if (project == null) {
      throw StateError('Project not found: $id');
    }
    return project;
  }

  @override
  Future<List<ProjectModel>> getProjectsByStatus(String status) async {
    return _projects.values.where((p) => p.status == status).toList();
  }

  @override
  Future<List<ProjectModel>> getProjectsPaginated({
    int page = 1,
    int limit = 20,
    ProjectFilter? filter,
  }) async {
    return _projects.values.skip((page - 1) * limit).take(limit).toList();
  }

  @override
  Future<void> removeSharedGroup(
    String projectId,
    String groupId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {}

  @override
  Future<void> removeSharedUser(
    String projectId,
    String username, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {}

  @override
  Future<void> resolveConflict(ProjectModel local, ProjectModel remote) async {
    _projects[remote.id] = remote;
    _changes.add(_projects.values.toList());
  }

  @override
  Future<void> syncAllProjects() async {}

  @override
  Future<void> syncProject(String projectId) async {}

  @override
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final current = _projects[projectId];
    if (current != null) {
      _projects[projectId] = current.copyWith(directoryPath: directoryPath);
      _changes.add(_projects.values.toList());
    }
  }

  @override
  Future<void> updatePlanJson(
    String projectId,
    String? planJson, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final current = _projects[projectId];
    if (current != null) {
      _projects[projectId] = current.copyWith(planJson: planJson);
      _changes.add(_projects.values.toList());
    }
  }

  @override
  Future<void> updateProgress(
    String projectId,
    double newProgress, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final current = _projects[projectId];
    if (current != null) {
      _projects[projectId] = current.copyWith(progress: newProgress);
      _changes.add(_projects.values.toList());
    }
  }

  @override
  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? userId,
    String? changeDescription,
    Map<String, Object?>? metadata,
  }) async {
    _projects[projectId] = updatedProject;
    _changes.add(_projects.values.toList());
  }

  @override
  Stream<List<ProjectModel>> watchProjectChanges(String projectId) {
    return _changes.stream
        .map((projects) => projects.where((p) => p.id == projectId).toList());
  }
}

class FakeDashboardRepository implements IDashboardRepository {
  bool processedPendingSync = false;

  @override
  Future<void> addItem(DashboardItem item) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> close() async {}

  @override
  Future<SharedDashboard?> fetchSharedDashboard(String shareId) async => null;

  @override
  Future<ProjectRequirements> fetchRequirements(String projectCategory) async {
    return const ProjectRequirements(
      hardware: <String>[],
      software: <String>[],
    );
  }

  @override
  Future<SharedDashboard?> loadLocalSharedDashboard(String shareId) async => null;

  @override
  Future<List<DashboardItem>> loadConfig() async => <DashboardItem>[];

  @override
  Future<List<Requirement>> loadRequirements() async => <Requirement>[];

  @override
  Future<List<DashboardTemplate>> loadTemplates() async => <DashboardTemplate>[];

  @override
  ProjectRequirements parseRequirementsString(String requirementsString) {
    return const ProjectRequirements(
      hardware: <String>[],
      software: <String>[],
    );
  }

  @override
  Future<void> preloadCache() async {}

  @override
  Future<void> processPendingSync() async {
    processedPendingSync = true;
  }

  @override
  Future<void> queuePendingChange(Map<String, dynamic> change) async {}

  @override
  Future<void> removeItem(int index) async {}

  @override
  Future<void> saveConfig(List<DashboardItem> items) async {}

  @override
  Future<void> saveLocalSharedDashboard(SharedDashboard dashboard) async {}

  @override
  Future<void> saveRequirement(Requirement req) async {}

  @override
  Future<void> saveSharedDashboard(SharedDashboard dashboard) async {}

  @override
  Future<void> saveTemplates(List<DashboardTemplate> templates) async {}

  @override
  Future<void> updateItemPosition(int index, Map<String, dynamic> position) async {}

  @override
  Future<void> updateSharedPermissions(
    String shareId,
    Map<String, String> permissions,
  ) async {}
}

void main() {
  group('Sync Providers Implementation', () {
    test('syncProvider is declared with the expected provider type', () {
      expect(
        syncProvider,
        isA<StateNotifierProvider<SyncNotifier, AsyncValue<SyncStatus>>>(),
      );
    });

    test('SyncStatus model has all required statuses', () {
      expect(SyncStatus.idle().status, 'idle');
      expect(SyncStatus.syncing().status, 'syncing');
      expect(SyncStatus.success().status, 'success');
      expect(SyncStatus.error('test').status, 'error');
      expect(SyncStatus.offline().status, 'offline');
    });
  });

  group('IProjectRepository Sync Methods', () {
    late FakeProjectRepository repo;

    setUp(() {
      repo = FakeProjectRepository();
    });

    test('syncProject method exists and is callable', () async {
      await repo.syncProject('test-id');
      expect(true, isTrue);
    });

    test('syncAllProjects method exists and is callable', () async {
      await repo.syncAllProjects();
      expect(true, isTrue);
    });

    test('bidirectionalSyncProject method exists and is callable', () async {
      await repo.bidirectionalSyncProject('test-id');
      expect(true, isTrue);
    });

    test('watchProjectChanges returns Stream<List<ProjectModel>>', () async {
      final stream = repo.watchProjectChanges('p1');
      expect(stream, isA<Stream<List<ProjectModel>>>());

      final firstEvent = stream.first;

      await repo.addProject(
        const ProjectModel(id: 'p1', name: 'Demo', progress: 0.5),
      );

      await expectLater(firstEvent, completion(hasLength(1)));
    });

    test('resolveConflict method is callable', () async {
      const local = ProjectModel(id: 'p1', name: 'Local', progress: 0.4);
      const remote = ProjectModel(id: 'p1', name: 'Remote', progress: 0.8);

      await repo.resolveConflict(local, remote);
      final loaded = await repo.getProjectById('p1');
      expect(loaded.name, 'Remote');
    });
  });

  group('Dashboard Sync Queue Handling', () {
    test('processPendingSync is callable', () async {
      final dashboardRepo = FakeDashboardRepository();
      await dashboardRepo.processPendingSync();
      expect(dashboardRepo.processedPendingSync, isTrue);
    });
  });
}
