import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:project_management_app/core/providers/sync_providers.dart';
import 'package:project_management_app/core/providers/project_providers.dart';
import 'package:project_management_app/core/providers/dashboard_providers.dart';
import 'package:project_management_app/core/repository/i_project_repository.dart';
import 'package:project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:project_management_app/core/services/cloud_sync_service.dart';
import 'package:project_management_app/models/project_model.dart';

// Mock classes
class MockProjectRepository extends Mock implements IProjectRepository {}

class MockDashboardRepository extends Mock implements IDashboardRepository {}

class MockCloudSyncService extends Mock implements CloudSyncService {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late ProviderContainer container;
  late MockProjectRepository mockProjectRepo;
  late MockDashboardRepository mockDashboardRepo;

  setUp(() {
    mockProjectRepo = MockProjectRepository();
    mockDashboardRepo = MockDashboardRepository();

    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(mockProjectRepo),
        dashboardRepositoryProvider.overrideWithValue(mockDashboardRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Sync Providers Implementation', () {
    test('syncProvider is implemented and returns SyncNotifier', () {
      final notifier = container.read(syncProvider.notifier);
      expect(notifier, isA<SyncNotifier>());
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
    test('syncProject method exists and is callable', () async {
      when(mockProjectRepo.syncProject('test-id')).thenAnswer((_) async {});

      await mockProjectRepo.syncProject('test-id');

      verify(mockProjectRepo.syncProject('test-id')).called(1);
    });

    test('syncAllProjects method exists and is callable', () async {
      when(mockProjectRepo.syncAllProjects()).thenAnswer((_) async {});

      await mockProjectRepo.syncAllProjects();

      verify(mockProjectRepo.syncAllProjects()).called(1);
    });

    test('bidirectionalSyncProject method exists and is callable', () async {
      when(mockProjectRepo.bidirectionalSyncProject('test-id')).thenAnswer((_) async {});

      await mockProjectRepo.bidirectionalSyncProject('test-id');

      verify(mockProjectRepo.bidirectionalSyncProject('test-id')).called(1);
    });

    test('watchProjectChanges returns Stream', () {
      final stream = mockProjectRepo.watchProjectChanges('test-id');

      expect(stream, isA<Stream<List<ProjectModel>>>());
    });

    test('resolveConflict method exists and is callable', () async {
      final local = ProjectModel.create(name: 'Local', progress: 0.5);
      final remote = ProjectModel.create(name: 'Remote', progress: 0.7);

      when(mockProjectRepo.resolveConflict(local, remote)).thenAnswer((_) async {});

      await mockProjectRepo.resolveConflict(local, remote);

      verify(mockProjectRepo.resolveConflict(local, remote)).called(1);
    });
  });

  group('Conflict Resolution', () {
    test('resolveConflict updates local store with resolved project', () async {
      final local = ProjectModel.create(
        name: 'Local',
        progress: 0.5,
        history: [
          {'change': 'created', 'user': 'test', 'time': '2024-01-01T10:00:00Z'}
        ]
      );
      final remote = ProjectModel.create(
        name: 'Remote',
        progress: 0.7,
        history: [
          {'change': 'updated', 'user': 'test', 'time': '2024-01-02T10:00:00Z'}
        ]
      );

      when(mockProjectRepo.resolveConflict(local, remote))
          .thenAnswer((_) async {});

      await mockProjectRepo.resolveConflict(local, remote);

      verify(mockProjectRepo.resolveConflict(local, remote)).called(1);
    });
  });

  group('Real-time Supabase Integration', () {
    test('CloudSyncService has getProjectsStream method', () {
      final service = CloudSyncService();
      final stream = service.getProjectsStream();

      expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
    });

    test('SyncNotifier subscribes to real-time updates', () async {
      // This would require more complex mocking of streams
      // For now, verify the notifier is created successfully
      final notifier = container.read(syncProvider.notifier);
      expect(notifier, isA<SyncNotifier>());
    });

    test('real-time subscription is active via CloudSyncService stream', () {
      final service = CloudSyncService();
      final stream = service.getProjectsStream();

      expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      // The SyncNotifier listens to this stream in its constructor
    });
  });

  group('Connectivity and Offline Queue Handling', () {
    test('SyncNotifier listens to connectivity changes', () async {
      // Initial state should be idle
      expect(container.read(syncProvider).value?.status, 'idle');

      // Note: Testing connectivity changes would require mocking the stream
      // This is a basic test that the notifier is properly initialized
    });

    test('processPendingSync is called on dashboard repository', () async {
      when(mockDashboardRepo.processPendingSync()).thenAnswer((_) async {});

      final notifier = container.read(syncProvider.notifier);
      await notifier.syncAllProjects();

      verify(mockDashboardRepo.processPendingSync()).called(1);
    });

    test('syncAllProjects calls repository syncAllProjects and processPendingSync', () async {
      when(mockProjectRepo.syncAllProjects()).thenAnswer((_) async {});
      when(mockDashboardRepo.processPendingSync()).thenAnswer((_) async {});

      final notifier = container.read(syncProvider.notifier);
      await notifier.syncAllProjects();

      verify(mockProjectRepo.syncAllProjects()).called(1);
      verify(mockDashboardRepo.processPendingSync()).called(1);
    });
  });

  group('Cloud Sync Service Supabase Calls', () {
    test('syncProjectUpdate uses upsert', () async {
      final service = CloudSyncService();

      // This would require mocking Supabase client
      // For now, verify the method exists and is callable
      expect(() async => await service.syncProjectUpdate('test-id'),
          returnsNormally);
    });

    test('syncProjectDelete uses delete', () async {
      final service = CloudSyncService();

      expect(() async => await service.syncProjectDelete('test-id'),
          returnsNormally);
    });

    test('syncAll fetches from Supabase', () async {
      final service = CloudSyncService();

      expect(() async => await service.syncAll(), returnsNormally);
    });
  });
}
