import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for [SupabaseClient] inside the Riverpod graph.
///
/// All Mirror providers and services should read this provider instead of
/// calling [Supabase.instance.client] directly — this makes every consumer
/// testable by overriding this provider with a mock client in tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
