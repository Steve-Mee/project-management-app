import '../../config/ai_config.dart' as ai_config;
import '../../services/ai_planning_helpers.dart';
import '../../services/app_logger.dart';
import '../../../models/project_plan.dart';
import '../../providers/project_providers.dart' show ProjectFilter;
import 'ai_service.dart';

/// Backend selector for future model-provider routing.
///
/// Current implementation keeps existing Grok-backed behavior by routing all
/// calls through [AiPlanningHelpers]. The enum is intentionally included now so
/// feature flags can switch to Gemini/Claude/OpenAI implementations later
/// without changing service consumers.
enum AiProviderBackend {
  openAiLangchain,
  grok,
  gemini,
  claude,
}

/// AiService implementation for issue 057 abstraction.
///
/// Issue reference: .github/issues/057-aiservice-abstraction.md
///
/// Notes:
/// - Preserves existing behavior by delegating to AiPlanningHelpers.
/// - Keeps existing tool-call/memory/error pipeline from current helper stack.
/// - Adds backend selection hook for future feature-flag provider swaps.
class OpenAiLangchainService implements AiService {
  OpenAiLangchainService({
    this.backend = AiProviderBackend.grok,
  });

  final AiProviderBackend backend;

  /// Factory for feature-flag driven backend selection.
  ///
  /// Expected values: `openai_langchain`, `grok`, `gemini`, `claude`.
  factory OpenAiLangchainService.fromFeatureFlag(String? backendFlag) {
    final normalized = (backendFlag ?? '').trim().toLowerCase();
    final selected = switch (normalized) {
      'openai_langchain' => AiProviderBackend.openAiLangchain,
      'gemini' => AiProviderBackend.gemini,
      'claude' => AiProviderBackend.claude,
      _ => AiProviderBackend.grok,
    };

    return OpenAiLangchainService(backend: selected);
  }

  @override
  Future<String> generate(String prompt, {String? projectId}) async {
    try {
      final result = await AiPlanningHelpers.sendChatMessage(prompt);
      return result.content;
    } catch (e, st) {
      AppLogger.instance.e(
        'AiService.generate failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<String> generateProjectPlan(String projectIdea, {String? projectId}) {
    final prompt = 'Genereer stappenplan voor project: $projectIdea';
    return generate(prompt, projectId: projectId);
  }

  @override
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    String? projectId,
  }) async {
    try {
      final result = await AiPlanningHelpers.generatePlanningQuestions(
        projectData,
        helpLevel,
      );
      return result.content;
    } catch (e, st) {
      AppLogger.instance.e(
        'AiService.generatePlanningQuestions failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
    String? projectId,
  }) async {
    try {
      final result = await AiPlanningHelpers.generateProposals(
        projectData,
        helpLevel,
        answers: answers,
      );
      return result.content;
    } catch (e, st) {
      AppLogger.instance.e(
        'AiService.generateProposals failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<ProjectPlan> generateFinalPlan(
    Map<String, dynamic> projectData, {
    String? projectId,
  }) async {
    try {
      final result = await AiPlanningHelpers.generateFinalPlan(projectData);
      return result.content;
    } catch (e, st) {
      AppLogger.instance.e(
        'AiService.generateFinalPlan failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<ProjectFilter?> parseFilterRequest(
    String userRequest, {
    String? projectId,
  }) async {
    try {
      final result = await AiPlanningHelpers.parseFilterRequest(userRequest);
      return result.content;
    } catch (e, st) {
      AppLogger.instance.e(
        'AiService.parseFilterRequest failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    // No active resources to release yet.
  }
}

/// Grok-backed AiService implementation.
///
/// Kept as a separate type so provider switching remains explicit and
/// future provider-specific behavior can diverge without changing call sites.
class GrokAiService extends OpenAiLangchainService {
  GrokAiService() : super(backend: AiProviderBackend.grok);
}
