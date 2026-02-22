import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

class FakeDashboardRepository implements IDashboardRepository {
  final List<DashboardItem> _items = [];

  @override
  Future<List<DashboardItem>> loadDashboardConfig() async {
    return _items;
  }

  @override
  Future<void> saveDashboardConfig(List<DashboardItem> items) async {
    _items.clear();
    _items.addAll(items);
  }

  @override
  Future<void> addDashboardItem(DashboardItem item) async {
    _items.add(item);
  }

  @override
  Future<void> removeDashboardItem(int index) async {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  @override
  Future<void> updateDashboardItemPosition(int index, Map<String, dynamic> newPosition) async {
    if (index >= 0 && index < _items.length) {
      _items[index] = DashboardItem(
        widgetType: _items[index].widgetType,
        position: newPosition,
      );
    }
  }

  @override
  Future<ProjectRequirements> fetchRequirements(String projectCategory) async {
    return const ProjectRequirements();
  }

  @override
  ProjectRequirements parseRequirementsString(String requirementsString) {
    return const ProjectRequirements();
  }

  @override
  Future<void> close() async {}
}

void main() {
  late ProviderContainer container;
  late FakeDashboardRepository fakeRepo;

  setUp(() async {
    fakeRepo = FakeDashboardRepository();
    final tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    // Clean up Hive boxes
    await Hive.close();
  });

  group('validateWidgetType', () {
    test('valid widget types do not throw', () {
      const validTypes = [
        'metricCard',
        'taskList',
        'progressChart',
        'kanbanBoard',
        'calendar',
        'notificationFeed',
        'projectOverview',
        'timeline',
      ];

      for (final type in validTypes) {
        expect(() => validateWidgetType(type), returnsNormally);
        expect(validateWidgetType(type), isA<DashboardWidgetType>());
      }
    });

    test('invalid widget type throws InvalidWidgetTypeException with correct message', () {
      const invalidType = 'invalidType';

      expect(
        () => validateWidgetType(invalidType),
        throwsA(isA<InvalidWidgetTypeException>()),
      );

      try {
        validateWidgetType(invalidType);
      } catch (e) {
        expect(e, isA<InvalidWidgetTypeException>());
        expect(
          e.toString(),
          contains('Invalid widget type \'invalidType\''),
        );
        expect(
          e.toString(),
          contains('Valid types are:'),
        );
        // Check that all valid types are listed
        const validTypes = [
          'metricCard',
          'taskList',
          'progressChart',
          'kanbanBoard',
          'calendar',
          'notificationFeed',
          'projectOverview',
          'timeline',
        ];
        for (final type in validTypes) {
          expect(e.toString(), contains(type));
        }
      }
    });
  });

  group('DashboardItem.fromJson', () {
    test('valid widgetType in json succeeds', () {
      const json = {
        'widgetType': 'metricCard',
        'position': {'x': 0, 'y': 0},
      };

      final item = DashboardItem.fromJson(json);
      expect(item.widgetType, DashboardWidgetType.metricCard);
      expect(item.position['x'], 0.0);
      expect(item.position['y'], 0.0);
      expect(item.position['width'], 180.0);
      expect(item.position['height'], 120.0);
    });

    test('invalid widgetType in json throws InvalidWidgetTypeException', () {
      const json = {
        'widgetType': 'invalidType',
        'position': {'x': 0, 'y': 0},
      };

      expect(
        () => DashboardItem.fromJson(json),
        throwsA(isA<InvalidWidgetTypeException>()),
      );

      try {
        DashboardItem.fromJson(json);
      } catch (e) {
        expect(e, isA<InvalidWidgetTypeException>());
        expect(
          e.toString(),
          contains('Invalid widget type \'invalidType\''),
        );
      }
    });
  });

  group('DashboardConfigNotifier.addItem', () {
    test('valid widgetType succeeds', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );

      final notifier = container.read(dashboardConfigProvider.notifier);
      await notifier.addItem(item);

      final state = container.read(dashboardConfigProvider);
      expect(state.length, 1);
      expect(state[0].widgetType, DashboardWidgetType.metricCard);
    });
  });

  group('Position constraints', () {
    late DashboardConfigNotifier notifier;

    setUp(() {
      notifier = container.read(dashboardConfigProvider.notifier);
    });

    test('enforcePositionConstraints clamps x < 0 to 0', () async {
      final result = await notifier.enforcePositionConstraints(
        {'x': -10, 'y': 0, 'width': 200, 'height': 150},
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result['x'], 0);
    });

    test('enforcePositionConstraints clamps y < 0 to 0', () async {
      final result = await notifier.enforcePositionConstraints(
        {'x': 0, 'y': -10, 'width': 200, 'height': 150},
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result['y'], 0);
    });

    test('enforcePositionConstraints enforces minimum width', () async {
      final result = await notifier.enforcePositionConstraints(
        {'x': 0, 'y': 0, 'width': 100, 'height': 150},
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result['width'], 180);
    });

    test('enforcePositionConstraints enforces minimum height', () async {
      final result = await notifier.enforcePositionConstraints(
        {'x': 0, 'y': 0, 'width': 200, 'height': 100},
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result['height'], 120);
    });

    test('enforcePositionConstraints corrects widget beyond max bounds', () async {
      final result = await notifier.enforcePositionConstraints(
        {'x': 1100, 'y': 700, 'width': 200, 'height': 150},
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result['x'], 1000); // 1200 - 200
      expect(result['y'], 650);  // 800 - 150
    });

    test('enforcePositionConstraints leaves normal position unchanged', () async {
      final original = {'x': 100, 'y': 100, 'width': 200, 'height': 150};
      final result = await notifier.enforcePositionConstraints(
        original,
        containerWidth: 1200,
        containerHeight: 800,
      );
      expect(result, original);
    });

    test('addItem clamps position', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': -10, 'y': -10, 'width': 100, 'height': 100},
      );

      await notifier.addItem(item);
      final state = container.read(dashboardConfigProvider);
      expect(state[0].position['x'], 0);
      expect(state[0].position['y'], 0);
      expect(state[0].position['width'], 180);
      expect(state[0].position['height'], 120);
    });

    test('updateItemPosition clamps position', () async {
      // First add an item
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0, 'width': 200, 'height': 150},
      );
      await notifier.addItem(item);

      // Update with invalid position
      await notifier.updateItemPosition(0, {'x': 1100, 'y': 700, 'width': 300, 'height': 200});

      final state = container.read(dashboardConfigProvider);
      expect(state[0].position['x'], 900); // 1200 - 300
      expect(state[0].position['y'], 600); // 800 - 200
      expect(state[0].position['width'], 300);
      expect(state[0].position['height'], 200);
    });

    test('DashboardItem.fromJson clamps invalid position', () {
      const json = {
        'widgetType': 'metricCard',
        'position': {'x': -10, 'y': -10, 'width': 100, 'height': 100},
      };

      final item = DashboardItem.fromJson(json);
      expect(item.position['x'], 0);
      expect(item.position['y'], 0);
      expect(item.position['width'], 180);
      expect(item.position['height'], 120);
    });
  });

  group('Undo/Redo functionality', () {
    late DashboardConfigNotifier notifier;

    setUp(() {
      notifier = container.read(dashboardConfigProvider.notifier);
    });

    test('canUndo is false initially (no history)', () {
      expect(notifier.canUndo, false);
    });

    test('canRedo is false initially (no history)', () {
      expect(notifier.canRedo, false);
    });

    test('after addItem, canUndo is true', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );

      await notifier.addItem(item);
      expect(notifier.canUndo, true);
    });

    test('undo restores previous state', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );

      await notifier.addItem(item);

      await notifier.undo();
      final stateAfterUndo = container.read(dashboardConfigProvider);

      expect(stateAfterUndo.length, 0); // Back to empty
      expect(notifier.canRedo, true);
    });

    test('redo restores next state', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );

      await notifier.addItem(item);
      final stateAfterAdd = container.read(dashboardConfigProvider);

      await notifier.undo();
      await notifier.redo();
      final stateAfterRedo = container.read(dashboardConfigProvider);

      expect(stateAfterRedo, stateAfterAdd); // Back to added state
      expect(notifier.canUndo, true);
      expect(notifier.canRedo, false);
    });

    test('multiple changes + undo/redo sequence', () async {
      final item1 = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );
      final item2 = DashboardItem(
        widgetType: DashboardWidgetType.taskList,
        position: {'x': 200, 'y': 0},
      );

      // Add first item
      await notifier.addItem(item1);
      expect(container.read(dashboardConfigProvider).length, 1);

      // Add second item
      await notifier.addItem(item2);
      expect(container.read(dashboardConfigProvider).length, 2);

      // Undo second add
      await notifier.undo();
      expect(container.read(dashboardConfigProvider).length, 1);
      expect(container.read(dashboardConfigProvider)[0].widgetType, DashboardWidgetType.metricCard);

      // Undo first add
      await notifier.undo();
      expect(container.read(dashboardConfigProvider).length, 0);

      // Redo first add
      await notifier.redo();
      expect(container.read(dashboardConfigProvider).length, 1);
      expect(container.read(dashboardConfigProvider)[0].widgetType, DashboardWidgetType.metricCard);

      // Redo second add
      await notifier.redo();
      expect(container.read(dashboardConfigProvider).length, 2);
      expect(container.read(dashboardConfigProvider)[1].widgetType, DashboardWidgetType.taskList);
    });

    test('history limit trims old entries', () async {
      // Add 51 items to exceed limit
      for (int i = 0; i < 51; i++) {
        final item = DashboardItem(
          widgetType: DashboardWidgetType.metricCard,
          position: {'x': i * 10, 'y': 0},
        );
        await notifier.addItem(item);
      }

      // History should be trimmed to 50 entries
      // Current index should be adjusted
      expect(notifier.canUndo, true);

      // Undo should work
      await notifier.undo();
      expect(container.read(dashboardConfigProvider).length, 50);
    });

    test('canUndo/canRedo edge cases', () async {
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0},
      );

      // Initially false
      expect(notifier.canUndo, false);
      expect(notifier.canRedo, false);

      // After add
      await notifier.addItem(item);
      expect(notifier.canUndo, true);
      expect(notifier.canRedo, false);

      // After undo (at start)
      await notifier.undo();
      expect(notifier.canUndo, false);
      expect(notifier.canRedo, true);

      // After redo (at end)
      await notifier.redo();
      expect(notifier.canUndo, true);
      expect(notifier.canRedo, false);
    });
  });

  group('Dashboard Templates', () {
    late DashboardConfigNotifier notifier;

    setUp(() {
      notifier = container.read(dashboardConfigProvider.notifier);
    });

    test('built-in presets are always available', () async {
      final templates = await notifier.getAllTemplates();
      expect(templates.length, greaterThanOrEqualTo(4)); // At least the 4 presets
      expect(templates.where((t) => t.isPreset).length, 4);
      expect(templates.any((t) => t.id == 'project-overview'), true);
      expect(templates.any((t) => t.id == 'task-management'), true);
      expect(templates.any((t) => t.id == 'analytics'), true);
      expect(templates.any((t) => t.id == 'notifications'), true);
    });

    test('saveAsTemplate creates new template', () async {
      // Set up some dashboard items
      final item = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0, 'width': 200, 'height': 150},
      );
      await notifier.addItem(item);

      // Save as template
      await notifier.saveAsTemplate('Test Template');

      // Verify template was saved
      final templates = await notifier.getAllTemplates();
      final userTemplates = templates.where((t) => !t.isPreset).toList();
      expect(userTemplates.length, 1);
      expect(userTemplates[0].name, 'Test Template');
      expect(userTemplates[0].items.length, 1);
      expect(userTemplates[0].items[0].widgetType, DashboardWidgetType.metricCard);
      expect(userTemplates[0].isPreset, false);
    });

    test('loadTemplate replaces current dashboard state', () async {
      // First save a template
      final item1 = DashboardItem(
        widgetType: DashboardWidgetType.metricCard,
        position: {'x': 0, 'y': 0, 'width': 200, 'height': 150},
      );
      await notifier.addItem(item1);
      await notifier.saveAsTemplate('Load Test');

      // Add another item to current state
      final item2 = DashboardItem(
        widgetType: DashboardWidgetType.taskList,
        position: {'x': 200, 'y': 0, 'width': 200, 'height': 150},
      );
      await notifier.addItem(item2);

      // Load the template
      final templates = await notifier.getAllTemplates();
      final userTemplate = templates.firstWhere((t) => t.name == 'Load Test');
      await notifier.loadTemplate(userTemplate.id);

      // Verify state was replaced
      final state = container.read(dashboardConfigProvider);
      expect(state.length, 1);
      expect(state[0].widgetType, DashboardWidgetType.metricCard);
    });

    test('deleteTemplate removes correctly', () async {
      // Save a template
      await notifier.saveAsTemplate('Delete Test');

      // Verify it exists
      var templates = await notifier.getAllTemplates();
      var userTemplates = templates.where((t) => !t.isPreset).toList();
      expect(userTemplates.length, 1);

      // Delete it
      await notifier.deleteTemplate(userTemplates[0].id);

      // Verify it's gone
      templates = await notifier.getAllTemplates();
      userTemplates = templates.where((t) => !t.isPreset).toList();
      expect(userTemplates.length, 0);
    });

    test('getAllTemplates returns presets + user templates', () async {
      // Initially only presets
      var templates = await notifier.getAllTemplates();
      expect(templates.where((t) => t.isPreset).length, 4);
      expect(templates.where((t) => !t.isPreset).length, 0);

      // Add user template
      await notifier.saveAsTemplate('User Template');

      // Now presets + 1 user
      templates = await notifier.getAllTemplates();
      expect(templates.where((t) => t.isPreset).length, 4);
      expect(templates.where((t) => !t.isPreset).length, 1);
    });

    test('saveAsTemplate with empty name still saves', () async {
      await notifier.saveAsTemplate('');

      final templates = await notifier.getAllTemplates();
      final userTemplates = templates.where((t) => !t.isPreset).toList();
      expect(userTemplates.length, 1);
      expect(userTemplates[0].name, '');
    });

    test('saveAsTemplate allows duplicate names', () async {
      await notifier.saveAsTemplate('Duplicate');
      await notifier.saveAsTemplate('Duplicate');

      final templates = await notifier.getAllTemplates();
      final userTemplates = templates.where((t) => !t.isPreset && t.name == 'Duplicate').toList();
      expect(userTemplates.length, 2);
    });

    test('loadTemplate with invalid id throws', () async {
      await expectLater(
        notifier.loadTemplate('invalid-id'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}