# 057-aiservice-abstraction

**Priority:** Medium

**Description:** Create AiService abstraction to make it easy to add different AI providers like Gemini/Claude.

**Acceptance Criteria:**
- [x] DONE: Create lib/core/services/ai/ai_service.dart (abstract class with Future<String> generate(...))
- [x] DONE: Implement OpenAiLangchainService in it
- [x] DONE: Update all calls in AI chat, task suggestions, etc.
- [x] DONE: Make it easy to add Gemini/Claude later via feature flag