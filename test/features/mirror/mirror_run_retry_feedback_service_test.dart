import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_retry_feedback_service.dart';
import 'package:project_management_app/generated/app_localizations.dart';

void main() {
  const service = MirrorRunRetryFeedbackService();

  testWidgets('shows snackbar for retryable error and triggers retry action', (
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
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    service.showRetryFeedback(
                      context: context,
                      l10n: l10n,
                      error: const MirrorStructuredError(
                        errorFamily: 'timeout',
                        retryable: true,
                        message: 'request timed out',
                      ),
                      onRetry: () => retryCount++,
                    );
                  },
                  child: const Text('show'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.textContaining('request timed out'), findsOneWidget);
    expect(find.text(l10n.mirrorRetryButton), findsOneWidget);

    await tester.tap(find.text(l10n.mirrorRetryButton));
    await tester.pumpAndSettle();

    expect(retryCount, 1);
  });

  testWidgets('does not show snackbar for non-retryable error', (
    WidgetTester tester,
  ) async {
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
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    service.showRetryFeedback(
                      context: context,
                      l10n: l10n,
                      error: const MirrorStructuredError(
                        errorFamily: 'validation',
                        retryable: false,
                        message: 'invalid request',
                      ),
                      onRetry: () {},
                    );
                  },
                  child: const Text('show'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid request'), findsNothing);
    expect(find.text(l10n.mirrorRetryButton), findsNothing);
  });
}