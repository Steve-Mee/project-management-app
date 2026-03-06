/// Abstract interface for AI usage repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:pma_core/models/ai_usage_record.dart';

/// Define abstract class `IAiUsageRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IAiUsageRepository {
  /// Logs an AI usage record to storage
  Future<void> logUsage(AiUsageRecord record);

  /// Retrieves usage history with optional filters
  Future<List<AiUsageRecord>> getUsageHistory({
    DateTime? from,
    DateTime? to,
    String? userId,
    String? projectId,
  });

  /// Calculates usage totals (tokens, cost, count) with optional filters
  Future<Map<String, dynamic>> getUsageTotals({
    String? userId,
    String? projectId,
  });

  /// Closes repository resources (e.g., Hive boxes)
  Future<void> close();
}
