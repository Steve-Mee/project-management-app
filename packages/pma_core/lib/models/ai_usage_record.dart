import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_usage_record.freezed.dart';
part 'ai_usage_record.g.dart';

/// Immutable model for AI usage records
/// Tracks individual AI operations for billing, monitoring, and analytics
/// Stored locally in Hive for privacy and performance
@freezed
abstract class AiUsageRecord with _$AiUsageRecord {
  const factory AiUsageRecord({
    required String id,
    required DateTime timestamp,
    required String operation,
    required int inputTokens,
    required int outputTokens,
    required double estimatedCost,
    String? userId,
    String? projectId,
    required bool success,
    String? errorMessage,
  }) = _AiUsageRecord;

  factory AiUsageRecord.fromJson(Map<String, dynamic> json) =>
      _$AiUsageRecordFromJson(json);
}
