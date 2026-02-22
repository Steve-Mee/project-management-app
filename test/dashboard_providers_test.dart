import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';

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

  setUp(() {
    fakeRepo = FakeDashboardRepository();
    container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
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
}