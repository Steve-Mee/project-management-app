import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/dashboard/widgets/project_card_widget.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/models/project_model.dart';

const _surfaceSize = Size(1280, 720);
const _cardKey = Key('dashboard_card_golden');

Future<void> _pumpDashboardCard(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);

  const project = ProjectModel(
    id: 'golden-p1',
    name: 'Dashboard Card Sample',
    progress: 0.67,
    status: 'In Progress',
    description: 'Golden test fixture for dashboard card UI.',
    tasks: ['Design', 'Build', 'Review'],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      builder: (context, child) {
        return MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: SizedBox(
                  width: 420,
                  child: ProjectCardWidget(
                    project: project,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  // Wait for widget animations (pie chart tween + fades) to reach stable state.
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  tearDown(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.clearAllTestValues();
  });

  testWidgets('Dashboard card golden - light theme', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDashboardCard(tester, theme: ThemeData.light(useMaterial3: true));

    await expectLater(
      find.byKey(_cardKey),
      matchesGoldenFile('goldens/dashboard_card_light.png'),
    );
  });

  testWidgets('Dashboard card golden - dark theme', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDashboardCard(tester, theme: ThemeData.dark(useMaterial3: true));

    await expectLater(
      find.byKey(_cardKey),
      matchesGoldenFile('goldens/dashboard_card_dark.png'),
    );
  });
}
