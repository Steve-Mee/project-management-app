@Tags(['golden'])
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/generated/app_localizations.dart';

const _surfaceSize = Size(900, 700);
const _switcherKey = Key('theme_switcher_golden');

class _ThemeSwitcherSection extends StatelessWidget {
  const _ThemeSwitcherSection({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = mode == ThemeMode.dark;
    final isSystemMode = mode == ThemeMode.system;

    return ListView(
      children: [
        ListTile(
          leading: Icon(
            Icons.palette,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            l10n.settingsDisplaySection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          value: isDarkMode,
          onChanged: (_) {},
          title: Text(l10n.settingsDarkModeTitle),
          subtitle: Text(l10n.settingsDarkModeSubtitle),
          secondary: Icon(
            Icons.brightness_6,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SwitchListTile(
          value: isSystemMode,
          onChanged: (_) {},
          title: Text(l10n.settingsFollowSystemTitle),
          subtitle: Text(l10n.settingsFollowSystemSubtitle),
          secondary: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

Future<void> _pumpThemeSwitcher(
  WidgetTester tester, {
  required ThemeMode mode,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RepaintBoundary(
              key: _switcherKey,
              child: _ThemeSwitcherSection(mode: mode),
            ),
          ),
        );
      },
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Theme switcher golden - light mode', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpThemeSwitcher(tester, mode: ThemeMode.light);

    await expectLater(
      find.byKey(_switcherKey),
      matchesGoldenFile('goldens/theme_switcher_light_mode.png'),
    );
  });

  testWidgets('Theme switcher golden - dark mode', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpThemeSwitcher(tester, mode: ThemeMode.dark);

    await expectLater(
      find.byKey(_switcherKey),
      matchesGoldenFile('goldens/theme_switcher_dark_mode.png'),
    );
  });

  testWidgets('Theme switcher golden - system mode', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpThemeSwitcher(tester, mode: ThemeMode.system);

    await expectLater(
      find.byKey(_switcherKey),
      matchesGoldenFile('goldens/theme_switcher_system_mode.png'),
    );
  });
}
