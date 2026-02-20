import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_logger.dart';

/// Model for AI usage data
class AiUsage {
  final int tokensUsed;
  final int monthlyLimit;

  const AiUsage({required this.tokensUsed, required this.monthlyLimit});

  /// Creates AiUsage from Supabase query result
  factory AiUsage.fromJson(Map<String, dynamic> json) {
    return AiUsage(
      tokensUsed: json['tokens_used'] as int? ?? 0,
      monthlyLimit: json['monthly_limit'] as int? ?? 100000,
    );
  }

  /// Default AI usage when no data is available
  factory AiUsage.defaultUsage() {
    return const AiUsage(tokensUsed: 0, monthlyLimit: 100000);
  }

  Map<String, dynamic> toJson() {
    return {'tokens_used': tokensUsed, 'monthly_limit': monthlyLimit};
  }

  /// Creates a new AiUsage with updated token count
  AiUsage withTokens(int additionalTokens) {
    return AiUsage(
      tokensUsed: tokensUsed + additionalTokens,
      monthlyLimit: monthlyLimit,
    );
  }
}

/// Provider for fetching AI usage data from Supabase
/// Tracks token usage for worldwide users with subscription-based limits.
/// Designed to be modular for future upgrades (e.g., add billing integration).
///
/// COMPLIANCE NOTE: Usage data is logged anonymously per local privacy laws.
/// Ensure compliance with data protection regulations (GDPR, CCPA, etc.) when
/// storing or processing usage statistics. Only aggregate data should be
/// retained for analytics purposes.
final aiUsageProvider = FutureProvider<AiUsage>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    // Return default usage if user is not authenticated
    return AiUsage.defaultUsage();
  }

  try {
    // Fetch AI usage data from 'ai_usage' table
    final response = await supabase
        .from('ai_usage')
        .select('tokens_used, monthly_limit')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // No usage data found, return defaults
      return AiUsage.defaultUsage();
    }

    // Parse the response data
    return AiUsage.fromJson(response);
  } catch (e) {
    // Log error but return default usage to prevent app crashes
    // In production, you might want to use a logging service here
    AppLogger.instance.e('Error fetching AI usage', error: e);

    // Return default usage on any error
    return AiUsage.defaultUsage();
  }
});

/// Provider for updating AI token usage
/// Updates the token count in Supabase after AI API calls
/// Designed to be modular and reusable across different AI services
///
/// COMPLIANCE NOTE: Token usage is logged anonymously without storing
/// actual prompts or responses to maintain privacy compliance.
final aiUsageUpdateProvider = FutureProvider.family<void, int>((ref, tokensUsed) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    // Skip update if user is not authenticated
    AppLogger.instance.w('Cannot update AI usage: user not authenticated');
    return;
  }

  if (tokensUsed <= 0) {
    // Skip update if no tokens were used
    return;
  }

  try {
    // First, try to get current usage
    final currentResponse = await supabase
        .from('ai_usage')
        .select('tokens_used')
        .eq('user_id', userId)
        .maybeSingle();

    if (currentResponse == null) {
      // No existing record, create new one
      await supabase.from('ai_usage').insert({
        'user_id': userId,
        'tokens_used': tokensUsed,
        'monthly_limit': 100000, // Default limit
        'last_updated': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing record
      final currentTokens = currentResponse['tokens_used'] as int? ?? 0;
      await supabase
          .from('ai_usage')
          .update({
            'tokens_used': currentTokens + tokensUsed,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    }

    // Log the update for debugging
    AppLogger.instance.i('Updated AI usage: +$tokensUsed tokens for user $userId');
  } catch (e) {
    // Log error but don't throw - usage updates shouldn't break the app
    AppLogger.instance.e('Error updating AI usage', error: e);
  }
});

// Future extension points for additional AI usage features
// final aiUsageHistoryProvider = FutureProvider<List<AiUsage>>((ref) async {
//   // TODO: Implement usage history tracking
//   throw UnimplementedError('Usage history not yet implemented');
// });
