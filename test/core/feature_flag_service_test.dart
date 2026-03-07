import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/core/services/feature_flag_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveTempDir;

  setUpAll(() async {
    hiveTempDir = await Directory.systemTemp.createTemp('feature_flags_test_');
    Hive.init(hiveTempDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('feature_flags')) {
      await Hive.box('feature_flags').clear();
      await Hive.box('feature_flags').close();
    }
  });

  tearDownAll(() async {
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  test('getFlag returns cached value without remote fetch', () async {
    var remoteCalled = false;
    final service = FeatureFlagService(
      supabaseClient: _FakeSupabaseClient(),
      remoteFetchOverride: () async {
        remoteCalled = true;
        throw Exception('remote should not be called when cache contains key');
      },
      useFlutterHiveInit: false,
    );

    await service.initialize();
    final box = Hive.box('feature_flags');
    await box.put('flags', <Map>[
      <String, dynamic>{'key': 'onboarding_enabled', 'enabled': true},
    ]);

    final enabled = await service.getFlag('onboarding_enabled', defaultValue: false);

    expect(enabled, isTrue);
    expect(remoteCalled, isFalse);
  });

  test('getFlag returns default when cache is empty and remote fetch fails', () async {
    var remoteCalled = false;
    final service = FeatureFlagService(
      supabaseClient: _FakeSupabaseClient(),
      remoteFetchOverride: () async {
        remoteCalled = true;
        throw Exception('simulated remote outage');
      },
      useFlutterHiveInit: false,
    );

    await service.initialize();
    final box = Hive.box('feature_flags');
    await box.put('flags', <Map>[]);

    final enabled = await service.getFlag('missing_flag', defaultValue: true);

    expect(remoteCalled, isTrue);
    expect(enabled, isTrue);
  });
}
