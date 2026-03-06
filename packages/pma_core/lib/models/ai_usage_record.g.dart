// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_usage_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiUsageRecord _$AiUsageRecordFromJson(Map<String, dynamic> json) =>
    _AiUsageRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      operation: json['operation'] as String,
      inputTokens: (json['inputTokens'] as num).toInt(),
      outputTokens: (json['outputTokens'] as num).toInt(),
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      userId: json['userId'] as String?,
      projectId: json['projectId'] as String?,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$AiUsageRecordToJson(_AiUsageRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'operation': instance.operation,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
      'estimatedCost': instance.estimatedCost,
      'userId': instance.userId,
      'projectId': instance.projectId,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
    };
