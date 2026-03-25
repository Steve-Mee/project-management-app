import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/widgets/mirror_retry_feedback_card.dart';
import 'package:project_management_app/generated/app_localizations.dart';

void main() {
  testWidgets('renders retry text and triggers callback', (
    WidgetTester tester,
  ) async {
    var retryCount = 0;
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: MirrorRetryFeedbackCard(
                l10n: l10n,
                error: const MirrorStructuredError(
                  errorFamily: 'timeout',
                  retryable: true,
                  message: 'request timed out',
                ),
                isRunInProgress: false,
                onRetry: () => retryCount++,
              ),
            );
          },
        ),
      ),
    );

    expect(find.textContaining('request timed out'), findsOneWidget);
    expect(find.text(l10n.mirrorRetryButton), findsOneWidget);

    await tester.tap(find.text(l10n.mirrorRetryButton));
    await tester.pump();
    expect(retryCount, 1);
  });
}