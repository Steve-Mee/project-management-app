/// Core provider barrel.
///
/// Issue #071: exports the feature flag provider so core-level imports can use
/// a single entry point.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/analytics_service.dart';

export 'providers/feature_flag_provider.dart';
export 'services/analytics_service.dart';

/// Issue #073: central analytics provider.
///
/// Defaults to [SupabaseAnalyticsService] while keeping call sites typed to
/// [AnalyticsService] for future backend swaps (for example Firebase).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return SupabaseAnalyticsService(Supabase.instance.client);
});
