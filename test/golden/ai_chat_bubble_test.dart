import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/auth/permissions.dart';
import 'package:project_management_app/core/providers/ai_providers.dart';
import 'package:project_management_app/core/providers/auth_providers.dart';
import 'package:project_management_app/features/ai_chat/ai_chat_screen.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/models/chat_message_model.dart';

const _surfaceSize = Size(1280, 800);
const _screenKey = Key('ai_chat_bubble_golden');

class _FakeAiChatNotifier extends AiChatNotifier {
  _FakeAiChatNotifier(this._state);

  final AiChatState _state;

  @override
  Future<AiChatState> build() async {
    return _state;
  }
}

AiChatState _chatStateFixture() {
  final now = DateTime(2026, 3, 5, 10, 0);
  return AiChatState(
    messages: [
      ChatMessage(
        id: 'u-short',
        content: 'Can you summarize today\'s sprint status?',
        isUser: true,
        timestamp: now,
      ),
      ChatMessage(
        id: 'ai-short',
        content: 'Done. You have 7 tasks completed and 2 blockers.',
        isUser: false,
        timestamp: now.add(const Duration(minutes: 1)),
      ),
      ChatMessage(
        id: 'u-long',
        content:
            'Please propose a step-by-step mitigation plan for the delayed API integration and include quick wins we can implement before tomorrow\'s stakeholder review.',
        isUser: true,
        timestamp: now.add(const Duration(minutes: 2)),
      ),
      ChatMessage(
        id: 'ai-long',
        content:
            'Mitigation plan: 1) Freeze non-critical scope. 2) Pair backend and frontend owners for a two-hour bug bash. 3) Ship a fallback mock response path behind a feature flag. 4) Publish a concise status note with risks, owners, and ETA. Quick wins: add retry logic, tighten API error logging, and update the demo script to avoid unstable flows.',
        isUser: false,
        timestamp: now.add(const Duration(minutes: 3)),
      ),
    ],
    isLoading: false,
  );
}

Future<void> _pumpAiChatScreen(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiChatProvider.overrideWith(() => _FakeAiChatNotifier(_chatStateFixture())),
        hasPermissionProvider(AppPermissions.useAi).overrideWith((ref) => true),
      ],
      child: ScreenUtilInit(
        designSize: _surfaceSize,
        builder: (context, child) {
          return MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: RepaintBoundary(
                key: _screenKey,
                child: AIChatScreen(),
              ),
            ),
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AI chat bubbles golden - light theme', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpAiChatScreen(tester, theme: ThemeData.light(useMaterial3: true));

    await expectLater(
      find.byKey(_screenKey),
      matchesGoldenFile('goldens/ai_chat_bubble_light.png'),
    );
  });

  testWidgets('AI chat bubbles golden - dark theme', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpAiChatScreen(tester, theme: ThemeData.dark(useMaterial3: true));

    await expectLater(
      find.byKey(_screenKey),
      matchesGoldenFile('goldens/ai_chat_bubble_dark.png'),
    );
  });
}
