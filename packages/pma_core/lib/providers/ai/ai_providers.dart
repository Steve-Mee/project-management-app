import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/feature_flag_provider.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ai/openai_langchain_service.dart';
import '../auth_providers.dart';

/// Lightweight settings view-model for AI service switching.
class AiSettings {
  const AiSettings({
    this.enableOpenAILangchain,
    this.aiBackend,
  });

  final bool? enableOpenAILangchain;
  final String? aiBackend;
}

/// Settings provider used by AI service selection.
final settingsProvider = Provider<AiSettings>((ref) {
  final featureFlags = ref.watch(featureFlagProvider).maybeWhen(
        data: (flags) => flags,
        orElse: () => null,
      );

  final settings = ref.watch(settingsRepositoryProvider).maybeWhen(
        data: (repo) => repo,
        orElse: () => null,
      );

  return AiSettings(
    enableOpenAILangchain: settings?.getEnableOpenAILangchain(),
    aiBackend: _resolveAiBackendFlag(featureFlags),
  );
});

/// AI service switch for issue 057 abstraction.
final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsProvider);
  final backendFlag = settings.aiBackend;

  if (backendFlag != null) {
    final normalized = backendFlag.trim().toLowerCase();
    if (_isSupportedBackendFlag(normalized)) {
      return OpenAiLangchainService.fromFeatureFlag(normalized);
    }
  }

  final useOpenAI = settings.enableOpenAILangchain ?? false;
  return useOpenAI ? OpenAiLangchainService() : GrokAiService();
});

String? _resolveAiBackendFlag(Map<String, dynamic>? featureFlags) {
  if (featureFlags == null || featureFlags.isEmpty) {
    return null;
  }

  final raw = featureFlags['ai_backend'];
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    return _isSupportedBackendFlag(normalized) ? normalized : null;
  }

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final directValue = map['value'];
    if (directValue is String) {
      final normalized = directValue.trim().toLowerCase();
      return _isSupportedBackendFlag(normalized) ? normalized : null;
    }

    if (directValue is Map) {
      final nested = Map<String, dynamic>.from(directValue);
      final nestedBackend = nested['backend'];
      if (nestedBackend is String) {
        final normalized = nestedBackend.trim().toLowerCase();
        return _isSupportedBackendFlag(normalized) ? normalized : null;
      }
    }
  }

  return null;
}

bool _isSupportedBackendFlag(String value) {
  switch (value) {
    case 'openai_langchain':
    case 'grok':
    case 'gemini':
    case 'claude':
      return true;
    default:
      return false;
  }
}
