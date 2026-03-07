import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/providers/settings/settings_providers.dart';
import 'package:pma_core/repository/impl/hive_settings_repository.dart';

class _FakeSettingsRepository extends HiveSettingsRepository {
  _FakeSettingsRepository({
    required AiRateLimitsConfig initialConfig,
  }) : _aiRateLimitsConfig = initialConfig,
       super();

  AiRateLimitsConfig _aiRateLimitsConfig;

  @override
  Future<void> initialize({String? testPath}) async {}

  @override
  AiRateLimitsConfig getAiRateLimitsConfig() => _aiRateLimitsConfig;

  @override
  Future<void> setAiRateLimitsConfig(AiRateLimitsConfig config) async {
    _aiRateLimitsConfig = config;
  }

  @override
  String? getSubscriptionLevel() => 'free';
}

void main() {
  late Directory hiveDir;

  setUpAll(() {
    hiveDir = Directory.systemTemp.createTempSync('ai_rate_limits_sync_test_');
    Hive.init(hiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  test('aiChatProvider runtime config updates when settings config changes', () async {
    final repository = _FakeSettingsRepository(
      initialConfig: const AiRateLimitsConfig(
        maxRequestsPerWindow: 10,
        perOperationLimits: {'chat': 1},
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWith((ref) => Future.value(repository)),
      ],
    );
    addTearDown(container.dispose);

    final initialState = await container.read(aiChatProvider.future);
    expect(initialState.rateLimitsConfig.perOperationLimits['chat'], 1);

    const updatedConfig = AiRateLimitsConfig(
      maxRequestsPerWindow: 7,
      backoffBaseDelay: Duration(milliseconds: 250),
      perOperationLimits: {'chat': 5},
    );

    await container
        .read(aiRateLimitsConfigProvider.notifier)
        .setAiRateLimitsConfig(updatedConfig);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final updatedState = container.read(aiChatProvider).maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    expect(updatedState, isNotNull);
    expect(updatedState!.rateLimitsConfig.perOperationLimits['chat'], 5);
    expect(updatedState.rateLimitsConfig.maxRequestsPerWindow, 7);
    expect(updatedState.rateLimitsConfig.backoffBaseDelay, const Duration(milliseconds: 250));

    final notifier = container.read(aiChatProvider.notifier);
    for (var i = 0; i < 5; i++) {
      notifier.recordOperationForTest('chat');
    }

    expect(notifier.isOperationRateLimitedForTest('chat'), isTrue);
  });
}
