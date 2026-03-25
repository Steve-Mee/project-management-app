import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/widgets/mirror_permission_revoked_view.dart';
import 'package:project_management_app/generated/app_localizations.dart';

void main() {
  testWidgets('renders denied messaging and close action', (
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
            return MirrorPermissionRevokedView(l10n: l10n);
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text(l10n.mirrorPermissionDenied), findsOneWidget);
    expect(find.text(l10n.mirrorPermissionRevokedSessionDisabled), findsOneWidget);
    expect(find.text(l10n.closeButton), findsOneWidget);
  });
}