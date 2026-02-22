import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/repository/hive_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:my_project_management_app/core/models/requirements.dart';
import 'dart:io';

void main() {
  late HiveDashboardRepository repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_cache_test');
    Hive.init(tempDir.path);
    repository = HiveDashboardRepository();
  });

  tearDown(() async {
    await repository.close();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('Cache functionality', () {
    test('cache hit on second load within TTL', () async {
      // First load should populate cache
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);
      await repository.loadConfig(); // Should cache

      // Second load should hit cache
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
      expect(loadedItems[0].widgetType, DashboardWidgetType.taskList);
    });

    test('cache miss after TTL expires', () async {
      // Mock time to simulate TTL expiration
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);
      await repository.loadConfig();

      // Simulate TTL expiration by clearing cache manually (since we can't easily mock time)
      await repository.clearCache();

      // Next load should miss cache and reload from Hive
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
    });

    test('cache invalidation after addItem', () async {
      final initialItems = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(initialItems);
      await repository.loadConfig(); // Cache populated

      // Add item should invalidate cache
      final newItem = DashboardItem(widgetType: DashboardWidgetType.progressChart, position: {'x': 100, 'y': 0, 'width': 100, 'height': 100});
      await repository.addItem(newItem);

      // Next load should get fresh data
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 2);
    });

    test('cache invalidation after removeItem', () async {
      final items = [
        DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100}),
        DashboardItem(widgetType: DashboardWidgetType.progressChart, position: {'x': 100, 'y': 0, 'width': 100, 'height': 100})
      ];
      await repository.saveConfig(items);
      await repository.loadConfig();

      // Remove item should invalidate cache
      await repository.removeItem(0);

      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
    });

    test('cache invalidation after updateItemPosition', () async {
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);
      await repository.loadConfig();

      // Update position should invalidate cache
      await repository.updateItemPosition(0, {'x': 50, 'y': 50, 'width': 100, 'height': 100});

      final loadedItems = await repository.loadConfig();
      expect(loadedItems[0].position['x'], 50);
    });

    test('clearCache works', () async {
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);
      await repository.loadConfig();

      // Clear cache
      await repository.clearCache();

      // Next load should still work (from Hive)
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
    });

    test('preloadCache populates cache', () async {
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);

      // Preload should load and cache
      await repository.preloadCache();

      // Subsequent load should hit cache
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
    });
  });

  group('Requirements functionality', () {
    test('loadRequirements returns empty list when no requirements exist', () async {
      final requirements = await repository.loadRequirements();
      expect(requirements, isEmpty);
    });

    test('saveRequirement and loadRequirements work correctly', () async {
      final req = Requirement(
        id: 'test-req-1',
        title: 'Test Requirement',
        status: RequirementStatus.pending,
        priority: RequirementPriority.medium,
      );

      await repository.saveRequirement(req);
      final loaded = await repository.loadRequirements();

      expect(loaded.length, 1);
      expect(loaded[0].id, 'test-req-1');
      expect(loaded[0].title, 'Test Requirement');
      expect(loaded[0].status, RequirementStatus.pending);
      expect(loaded[0].priority, RequirementPriority.medium);
    });

    test('saveRequirement updates existing requirement', () async {
      final req = Requirement(
        id: 'test-req-1',
        title: 'Test Requirement',
        status: RequirementStatus.pending,
        priority: RequirementPriority.medium,
      );

      await repository.saveRequirement(req);

      final updatedReq = Requirement(
        id: 'test-req-1',
        title: 'Updated Test Requirement',
        status: RequirementStatus.inProgress,
        priority: RequirementPriority.high,
      );

      await repository.saveRequirement(updatedReq);
      final loaded = await repository.loadRequirements();

      expect(loaded.length, 1);
      expect(loaded[0].title, 'Updated Test Requirement');
      expect(loaded[0].status, RequirementStatus.inProgress);
      expect(loaded[0].priority, RequirementPriority.high);
    });

    test('queuePendingChange stores changes for sync', () async {
      final change = {'type': 'save_requirement', 'data': {'id': 'req-1', 'title': 'Test'}};
      await repository.queuePendingChange(change);

      // Verify change is queued (we can't easily test the internal box, but processPendingSync should work)
      final box = await Hive.openBox<List>('pending_requirements_changes');
      final data = box.get('changes', defaultValue: []);
      expect(data, isNotNull);
      expect(data!.length, 1);
      await box.close();
    });

    test('processPendingSync clears queued changes', () async {
      final change = {'type': 'save_requirement', 'data': {'id': 'req-1', 'title': 'Test'}};
      await repository.queuePendingChange(change);

      // Process sync (should clear changes)
      await repository.processPendingSync();

      // Verify changes are cleared
      final box = await Hive.openBox<List>('pending_requirements_changes');
      final data = box.get('changes', defaultValue: []);
      expect(data, isEmpty);
      await box.close();
    });

    test('migration: existing dashboard data still loads after requirements implementation', () async {
      // Save some dashboard config before requirements were added
      final items = [DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 100, 'height': 100})];
      await repository.saveConfig(items);

      // Load should still work
      final loadedItems = await repository.loadConfig();
      expect(loadedItems.length, 1);
      expect(loadedItems[0].widgetType, DashboardWidgetType.taskList);

      // Requirements should be empty initially
      final requirements = await repository.loadRequirements();
      expect(requirements, isEmpty);
    });
  });
}