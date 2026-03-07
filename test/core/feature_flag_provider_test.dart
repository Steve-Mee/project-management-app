import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/core/services/feature_flag_service.dart';

class _FakeFeatureFlagService implements FeatureFlagServiceBase {
  _FakeFeatureFlagService({
    required this.cached,
    required this.remoteRows,
    required this.stale,
  });

  final Map<String, dynamic> cached;
  final List<Map> remoteRows;
  final bool stale;

  @override
  Future<List<Map>> fetchFeatureFlags() async => remoteRows;

  @override
  Future<bool> getFlag(String key, {bool defaultValue = false}) async {
    final value = cached[key];
    if (value is Map<String, dynamic> && value['enabled'] is bool) {
      return value['enabled'] as bool;
    }
    return defaultValue;
  }

  @override
  Future<List<Map>> getCachedFeatureFlags() async => cached.values.whereType<Map>().toList();

  @override
  Future<Map<String, dynamic>> getCachedFeatureFlagsByKey() async => cached;

  @override
  Future<bool> isCacheStale({Duration ttl = FeatureFlagService.defaultCacheTtl}) async => stale;

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> setFeatureEnabled(String key, bool enabled) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build returns cached state first when cache exists', () async {
    final fakeService = _FakeFeatureFlagService(
      cached: const <String, dynamic>{
        'gantt_chart_enabled': <String, dynamic>{'key': 'gantt_chart_enabled', 'enabled': false},
      },
      remoteRows: const <Map>[
        <String, dynamic>{'key': 'gantt_chart_enabled', 'enabled': true},
      ],
      stale: true,
    );

    final container = ProviderContainer(
      overrides: [
        featureFlagServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final flags = await container.read(featureFlagProvider.future);

    expect(flags['gantt_chart_enabled'], isNotNull);
    expect(
      (flags['gantt_chart_enabled'] as Map<String, dynamic>)['enabled'],
      isFalse,
    );
  });

  test('refresh updates state from remote rows', () async {
    final fakeService = _FakeFeatureFlagService(
      cached: const <String, dynamic>{
        'ai_assistant_enabled': <String, dynamic>{'key': 'ai_assistant_enabled', 'enabled': false},
      },
      remoteRows: const <Map>[
        <String, dynamic>{'key': 'ai_assistant_enabled', 'enabled': true},
      ],
      stale: false,
    );

    final container = ProviderContainer(
      overrides: [
        featureFlagServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(featureFlagProvider.future);
    await container.read(featureFlagProvider.notifier).refresh();

    final next = container.read(featureFlagProvider).valueOrNull;
    expect(next, isNotNull);
    expect(
      (next!['ai_assistant_enabled'] as Map<String, dynamic>)['enabled'],
      isTrue,
    );
  });

  test('didChangeAppLifecycleState(resumed) triggers refresh', () async {
    final fakeService = _FakeFeatureFlagService(
      cached: const <String, dynamic>{
        'ai_assistant_enabled': <String, dynamic>{'key': 'ai_assistant_enabled', 'enabled': false},
      },
      remoteRows: const <Map>[
        <String, dynamic>{'key': 'ai_assistant_enabled', 'enabled': true},
      ],
      stale: false,
    );

    final container = ProviderContainer(
      overrides: [
        featureFlagServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(featureFlagProvider.future);

    final notifier = container.read(featureFlagProvider.notifier);
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final next = container.read(featureFlagProvider).valueOrNull;
    expect(next, isNotNull);
    expect(
      (next!['ai_assistant_enabled'] as Map<String, dynamic>)['enabled'],
      isTrue,
    );
  });
}
