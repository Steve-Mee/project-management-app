import '../../config/ai_config.dart' as ai_config;
import '../../../models/project_plan.dart';
import '../../providers/project_providers.dart' show ProjectFilter;

/// AI service abstraction for provider-agnostic AI integrations.
///
/// Issue reference: .github/issues/057-aiservice-abstraction.md
/// This interface defines the shared contract used by AI chat and project
/// planning flows so providers (Grok/Gemini/Claude/OpenAI) can be swapped
/// without changing feature or provider code.
abstract class AiService {
  Future<String> generate(String prompt, {String? projectId});

  /// Generates a project-plan-oriented response for the given project idea.
  Future<String> generateProjectPlan(String projectIdea, {String? projectId});

  /// Generates clarifying planning questions for project setup flows.
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    String? projectId,
  });

  /// Generates project proposals based on project data and optional answers.
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
    String? projectId,
  });

  /// Generates a structured final project plan.
  Future<ProjectPlan> generateFinalPlan(
    Map<String, dynamic> projectData, {
    String? projectId,
  });

  /// Parses natural language into a structured project filter.
  Future<ProjectFilter?> parseFilterRequest(
    String userRequest, {
    String? projectId,
  });

  Future<void> dispose();
}
