import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_logger.dart';
import '../../models/ai_usage_record.dart';
import '../../repository/i_ai_usage_repository.dart';
import '../../repository/ai_usage_repository.dart';

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

/// Calculates total cost from a list of usage records
double calculateTotalCost(List<AiUsageRecord> records) {
  final total = records.fold<double>(0.0, (sum, record) => sum + record.estimatedCost);
  AppLogger.debug('Calculated total cost: \$${total.toStringAsFixed(4)} from ${records.length} records');
  return total;
}

/// Gets usage count by operation from records
Map<String, int> getUsageByOperation(List<AiUsageRecord> records) {
  final usage = <String, int>{};
  for (final record in records) {
    usage[record.operation] = (usage[record.operation] ?? 0) + 1;
  }
  AppLogger.debug('Usage by operation: $usage');
  return usage;
}

/// Gets per-user aggregation from records
Map<String, Map<String, dynamic>> getPerUserAggregation(List<AiUsageRecord> records) {
  final aggregation = <String, Map<String, dynamic>>{};
  for (final record in records) {
    if (record.userId != null) {
      final userAgg = aggregation[record.userId!] ?? {
        'totalTokens': 0,
        'totalCost': 0.0,
        'requestCount': 0,
        'successfulRequests': 0,
      };
      userAgg['totalTokens'] += record.inputTokens + record.outputTokens;
      userAgg['totalCost'] += record.estimatedCost;
      userAgg['requestCount'] += 1;
      if (record.success) userAgg['successfulRequests'] += 1;
      aggregation[record.userId!] = userAgg;
    }
  }
  AppLogger.debug('Per-user aggregation: ${aggregation.length} users');
  return aggregation;
}

/// Gets per-project aggregation from records
Map<String, Map<String, dynamic>> getPerProjectAggregation(List<AiUsageRecord> records) {
  final aggregation = <String, Map<String, dynamic>>{};
  for (final record in records) {
    if (record.projectId != null) {
      final projectAgg = aggregation[record.projectId!] ?? {
        'totalTokens': 0,
        'totalCost': 0.0,
        'requestCount': 0,
        'successfulRequests': 0,
      };
      projectAgg['totalTokens'] += record.inputTokens + record.outputTokens;
      projectAgg['totalCost'] += record.estimatedCost;
      projectAgg['requestCount'] += 1;
      if (record.success) projectAgg['successfulRequests'] += 1;
      aggregation[record.projectId!] = projectAgg;
    }
  }
  AppLogger.debug('Per-project aggregation: ${aggregation.length} projects');
  return aggregation;
}

/// Notifier for AI usage history
class AiUsageNotifier extends StateNotifier<AsyncValue<List<AiUsageRecord>>> {
  final IAiUsageRepository _repository;

  AiUsageNotifier(this._repository) : super(const AsyncValue.data([]));

  /// Logs a new usage record and updates the state
  Future<void> logUsage(AiUsageRecord record) async {
    await _repository.logUsage(record);
    state = state.maybeWhen(
      data: (records) => AsyncValue.data([...records, record]),
      orElse: () => state,
    );
  }

  /// Fetches usage history with optional filters
  Future<void> fetchHistory({
    DateTime? from,
    DateTime? to,
    String? userId,
    String? projectId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getUsageHistory(
        from: from,
        to: to,
        userId: userId,
        projectId: projectId,
      );
      state = AsyncValue.data(records);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Gets usage totals with optional filters
  Future<Map<String, dynamic>> getTotals({
    String? userId,
    String? projectId,
  }) async {
    return await _repository.getUsageTotals(userId: userId, projectId: projectId);
  }
}

/// Provider for AI usage repository
final aiUsageRepositoryProvider = Provider<IAiUsageRepository>((ref) {
  return AiUsageRepository();
});

/// Provider for AI usage history
final aiUsageHistoryProvider = StateNotifierProvider<AiUsageNotifier, AsyncValue<List<AiUsageRecord>>>((ref) {
  final repository = ref.watch(aiUsageRepositoryProvider);
  return AiUsageNotifier(repository);
});

/// Computed provider for total cost from current history
final aiUsageTotalCostProvider = Provider<double>((ref) {
  final history = ref.watch(aiUsageHistoryProvider);
  return history.maybeWhen(
    data: calculateTotalCost,
    orElse: () => 0.0,
  );
});

/// Computed provider for usage by operation from current history
final aiUsageByOperationProvider = Provider<Map<String, int>>((ref) {
  final history = ref.watch(aiUsageHistoryProvider);
  return history.maybeWhen(
    data: getUsageByOperation,
    orElse: () => {},
  );
});

/// Computed provider for per-user aggregation from current history
final aiUsagePerUserProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
  final history = ref.watch(aiUsageHistoryProvider);
  return history.maybeWhen(
    data: getPerUserAggregation,
    orElse: () => {},
  );
});

/// Computed provider for per-project aggregation from current history
final aiUsagePerProjectProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
  final history = ref.watch(aiUsageHistoryProvider);
  return history.maybeWhen(
    data: getPerProjectAggregation,
    orElse: () => {},
  );
});

/*
REUSABLE UI EXAMPLE CODE FOR AI USAGE DASHBOARD
Add this to a settings screen or dedicated AI dashboard widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/ai/ai_usage_provider.dart';
import '../../../generated/l10n.dart';

class AiUsageDashboard extends ConsumerWidget {
  const AiUsageDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aiUsageHistoryProvider);
    final totalCost = ref.watch(aiUsageTotalCostProvider);
    final usageByOperation = ref.watch(aiUsageByOperationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).ai_usage_history),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (records) => _buildDashboard(context, ref, records, totalCost, usageByOperation),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    List<AiUsageRecord> records,
    double totalCost,
    Map<String, int> usageByOperation,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _SummaryCard(
                title: S.of(context).total_tokens,
                value: records.fold<int>(0, (sum, r) => sum + r.inputTokens + r.outputTokens).toString(),
                icon: Icons.token,
              ),
              const SizedBox(width: 16),
              _SummaryCard(
                title: S.of(context).estimated_cost,
                value: '\$${totalCost.toStringAsFixed(2)}',
                icon: Icons.attach_money,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Usage by Operation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requests per Operation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...usageByOperation.entries.map((entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text(entry.value.toString()),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Filter by operation',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO: Implement filtering
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement CSV export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV export not implemented yet')),
                  );
                },
                icon: const Icon(Icons.download),
                label: Text(S.of(context).ai_usage_export),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Usage History List
          Text('Recent Usage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                title: Text('${record.operation} - ${record.inputTokens + record.outputTokens} tokens'),
                subtitle: Text(
                  '${DateFormat.yMd().format(record.timestamp)} - \$${record.estimatedCost.toStringAsFixed(4)}',
                ),
                trailing: record.success
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
*/
