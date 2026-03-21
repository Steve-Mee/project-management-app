// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_management_app/main.dart';
import 'package:project_management_app/features/auth/login_screen.dart';

void main() {
  testWidgets('App shows initial auth gate', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Avoid indefinite settle when app has repeating animations/timers.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));

      final hasLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (hasLogin || hasLoading) {
        break;
      }
    }

    final hasLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasLogin || hasLoading, isTrue);
  });
}
