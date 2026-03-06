import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/core/config/ai_config.dart' as ai_config;
import 'package:pma_core/providers/ai/ai_providers.dart';
import 'package:pma_core/services/ai/ai_service.dart';
import 'package:pma_core/services/ai/openai_langchain_service.dart';
import 'package:pma_core/providers/project/project_providers.dart' show ProjectFilter;
import 'package:pma_core/models/project_plan.dart';

class MockAiService implements AiService {
  int generateCallCount = 0;
  int generateProjectPlanCallCount = 0;
  int generateProposalsCallCount = 0;

  @override
  Future<String> generate(String prompt, {String? projectId}) async {
    generateCallCount++;
    return 'mock-generate:$prompt:${projectId ?? 'none'}';
  }

  @override
  Future<String> generateProjectPlan(String projectIdea, {String? projectId}) async {
    generateProjectPlanCallCount++;
    return 'mock-plan:$projectIdea:${projectId ?? 'none'}';
  }

  @override
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
    String? projectId,
  }) async {
    generateProposalsCallCount++;
    return ['mock-proposal-1', 'mock-proposal-2'];
  }

  @override
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    String? projectId,
  }) async {
    return ['mock-question'];
  }

  @override
  Future<ProjectPlan> generateFinalPlan(
    Map<String, dynamic> projectData, {
    String? projectId,
  }) async {
    return const ProjectPlan(
      overview: 'mock-overview',
      chapters: [],
    );
  }

  @override
  Future<ProjectFilter?> parseFilterRequest(
    String userRequest, {
    String? projectId,
  }) async {
    return const ProjectFilter(priority: 'High');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AiService abstraction tests', () {
    test('MockAiService generate works', () async {
      final service = MockAiService();

      final result = await service.generate('hello', projectId: 'p1');

      expect(result, 'mock-generate:hello:p1');
      expect(service.generateCallCount, 1);
    });

    test('MockAiService generateProjectPlan works', () async {
      final service = MockAiService();

      final result = await service.generateProjectPlan('Build app', projectId: 'p2');

      expect(result, 'mock-plan:Build app:p2');
      expect(service.generateProjectPlanCallCount, 1);
    });

    test('MockAiService generateProposals works', () async {
      final service = MockAiService();

      final result = await service.generateProposals(
        {'name': 'project'},
        ai_config.HelpLevel.basis,
        answers: const ['a1'],
        projectId: 'p3',
      );

      expect(result, ['mock-proposal-1', 'mock-proposal-2']);
      expect(service.generateProposalsCallCount, 1);
    });

    test('abstraction works via aiServiceProvider override', () async {
      final mock = MockAiService();
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(aiServiceProvider);
      final result = await service.generate('provider-call');

      expect(result, 'mock-generate:provider-call:none');
      expect(mock.generateCallCount, 1);
    });
  });

  group('AiService feature flag switching', () {
    test('uses OpenAiLangchainService when feature flag is enabled', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWithValue(
            const AiSettings(enableOpenAILangchain: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(aiServiceProvider);

      expect(service, isA<OpenAiLangchainService>());
      expect((service as OpenAiLangchainService).backend, AiProviderBackend.grok);
    });

    test('uses GrokAiService when feature flag is disabled', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWithValue(
            const AiSettings(enableOpenAILangchain: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(aiServiceProvider);

      expect(service, isA<GrokAiService>());
    });
  });
}
