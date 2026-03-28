library;

/// Centralized runtime feature flag keys used by the app.
class AppFeatureFlags {
  const AppFeatureFlags._();

  static const String mirrorEnabled = 'mirror_enabled';
  static const String ganttChartEnabled = 'gantt_chart_enabled';
  static const String onboardingEnabled = 'onboarding_enabled';
  static const String threeDVisualizationEnabled =
      'three_d_visualization_enabled';
}
