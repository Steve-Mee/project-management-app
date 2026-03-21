library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for Supabase client in pma_core provider graph.
final pmaSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
