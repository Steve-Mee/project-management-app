import 'package:equatable/equatable.dart';

/// Immutable model for AI usage records
/// Tracks individual AI operations for billing, monitoring, and analytics
/// Stored locally in Hive for privacy and performance
class AiUsageRecord extends Equatable {
  final String id;
  final DateTime timestamp;
  final String operation; // "chat", "summarize", etc.
  final int inputTokens;
  final int outputTokens;
  final double estimatedCost;
  final String? userId;
  final String? projectId;
  final bool success;
  final String? errorMessage;

  const AiUsageRecord({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCost,
    this.userId,
    this.projectId,
    required this.success,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        operation,
        inputTokens,
        outputTokens,
        estimatedCost,
        userId,
        projectId,
        success,
        errorMessage,
      ];

  AiUsageRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? operation,
    int? inputTokens,
    int? outputTokens,
    double? estimatedCost,
    String? userId,
    String? projectId,
    bool? success,
    String? errorMessage,
  }) {
    return AiUsageRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      operation: operation ?? this.operation,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AiUsageRecord.fromJson(Map<String, dynamic> json) {
    return AiUsageRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      operation: json['operation'] as String,
      inputTokens: json['inputTokens'] as int,
      outputTokens: json['outputTokens'] as int,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      userId: json['userId'] as String?,
      projectId: json['projectId'] as String?,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'estimatedCost': estimatedCost,
      'userId': userId,
      'projectId': projectId,
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}