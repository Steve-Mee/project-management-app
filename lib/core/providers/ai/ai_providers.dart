import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ai/ai_service.dart';
import '../../services/ai/openai_langchain_service.dart';
import '../auth_providers.dart';

/// Lightweight settings view-model for AI service switching.
class AiSettings {
  const AiSettings({
    this.enableOpenAILangchain,
  });

  final bool? enableOpenAILangchain;
}

/// Settings provider used by AI service selection.
final settingsProvider = Provider<AiSettings>((ref) {
  final settings = ref.watch(settingsRepositoryProvider).maybeWhen(
        data: (repo) => repo,
        orElse: () => null,
      );

  return AiSettings(
    enableOpenAILangchain: settings?.getEnableOpenAILangchain(),
  );
});

/// AI service switch for issue 057 abstraction.
final aiServiceProvider = Provider<AiService>((ref) {
  final useOpenAI = ref.watch(settingsProvider).enableOpenAILangchain ?? false;
  return useOpenAI ? OpenAiLangchainService() : GrokAiService();
});
