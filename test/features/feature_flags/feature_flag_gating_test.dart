import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:project_management_app/core/widgets/onboarding_wizard.dart';
import 'package:project_management_app/features/projects/views/project_gantt_view.dart';
import 'package:project_management_app/generated/app_localizations.dart';

class _FixedFeatureFlagNotifier extends FeatureFlagNotifier {
  _FixedFeatureFlagNotifier(this._flags);

  final Map<String, dynamic> _flags;

  @override
  Future<Map<String, dynamic>> build() async {
    return _flags;
  }
}

class _EmptyProjectsNotifier extends ProjectsNotifier {
  @override
  Future<List<ProjectModel>> build() async {
    return const <ProjectModel>[];
  }
}

Widget _wrapWithApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(1280, 940),
      builder: (context, _) {
        return MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    ),
  );
}

void main() {
  testWidgets('ProjectGanttView shows localized fallback when gantt flag is disabled',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        const ProjectGanttView(),
        overrides: [
          projectsProvider.overrideWith(_EmptyProjectsNotifier.new),
          featureFlagProvider.overrideWith(
            () => _FixedFeatureFlagNotifier(
              const <String, dynamic>{
                'gantt_chart_enabled': <String, dynamic>{'enabled': false},
              },
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gantt chart is currently disabled by admin'), findsOneWidget);
  });

  testWidgets('OnboardingWizard shows fallback and triggers completion callback when disabled',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        const OnboardingWizard(),
        overrides: [
          featureFlagProvider.overrideWith(
            () => _FixedFeatureFlagNotifier(
              const <String, dynamic>{
                'onboarding_enabled': <String, dynamic>{'enabled': false},
              },
            ),
          ),
        ],
      ),
    );

    // First frame renders fallback UI.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Onboarding is currently disabled by admin'), findsOneWidget);
    expect(find.text('Opening your dashboard...'), findsOneWidget);
  });
}
