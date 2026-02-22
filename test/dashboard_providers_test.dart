import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/models/project_requirements.dart';

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
        'welcome',
        'projectList',
        'taskChart',
        'aiUsage',
        'progressChart',
        'kanbanBoard',
        'calendar',
        'notificationFeed',
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
          'welcome',
          'projectList',
          'taskChart',
          'aiUsage',
          'progressChart',
          'kanbanBoard',
          'calendar',
          'notificationFeed',
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
        'widgetType': 'welcome',
        'position': {'x': 0, 'y': 0},
      };

      final item = DashboardItem.fromJson(json);
      expect(item.widgetType, 'welcome');
      expect(item.position, {'x': 0, 'y': 0});
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
        widgetType: 'welcome',
        position: {'x': 0, 'y': 0},
      );

      final notifier = container.read(dashboardConfigProvider.notifier);
      await notifier.addItem(item);

      final state = container.read(dashboardConfigProvider);
      expect(state.length, 1);
      expect(state[0].widgetType, 'welcome');
    });

    test('invalid widgetType throws InvalidWidgetTypeException', () async {
      final item = DashboardItem(
        widgetType: 'invalidType',
        position: {'x': 0, 'y': 0},
      );

      final notifier = container.read(dashboardConfigProvider.notifier);

      expect(
        () => notifier.addItem(item),
        throwsA(isA<InvalidWidgetTypeException>()),
      );
    });
  });
}