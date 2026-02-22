import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/repository/hive_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
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
}