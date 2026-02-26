// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_rate_limits_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiRateLimitsConfig _$AiRateLimitsConfigFromJson(Map<String, dynamic> json) =>
    _AiRateLimitsConfig(
      maxRequestsPerMinute:
          (json['maxRequestsPerMinute'] as num?)?.toInt() ?? 10,
      maxRequestsPerHour: (json['maxRequestsPerHour'] as num?)?.toInt() ?? 100,
      maxRequestsPerDay: (json['maxRequestsPerDay'] as num?)?.toInt() ?? 500,
      maxTokensPerRequest:
          (json['maxTokensPerRequest'] as num?)?.toInt() ?? 4000,
      maxTotalTokensPerDay:
          (json['maxTotalTokensPerDay'] as num?)?.toInt() ?? 100000,
      maxRequestsPerWindow:
          (json['maxRequestsPerWindow'] as num?)?.toInt() ?? 10,
      timeWindowDuration: json['timeWindowDurationSeconds'] == null
          ? const Duration(minutes: 1)
          : _durationSecondsFromJson(json['timeWindowDurationSeconds']),
      backoffBaseDelay: json['backoffBaseDelayMs'] == null
          ? const Duration(milliseconds: 500)
          : _durationMsFromJson(json['backoffBaseDelayMs']),
      backoffMaxDelay: json['backoffMaxDelaySeconds'] == null
          ? const Duration(seconds: 30)
          : _durationSecondsFromJson(json['backoffMaxDelaySeconds']),
      maxRetryAttempts: (json['maxRetryAttempts'] as num?)?.toInt() ?? 3,
      queueEnabled: json['queueEnabled'] as bool? ?? true,
      perOperationLimits: json['perOperationLimits'] == null
          ? const <String, int>{
              'chat': 15,
              'generate_questions': 8,
              'generate_proposals': 6,
              'generate_plan': 4,
              'parse_filter': 10,
              'summarize': 5
            }
          : _perOperationLimitsFromJson(json['perOperationLimits']),
    );

Map<String, dynamic> _$AiRateLimitsConfigToJson(_AiRateLimitsConfig instance) =>
    <String, dynamic>{
      'maxRequestsPerMinute': instance.maxRequestsPerMinute,
      'maxRequestsPerHour': instance.maxRequestsPerHour,
      'maxRequestsPerDay': instance.maxRequestsPerDay,
      'maxTokensPerRequest': instance.maxTokensPerRequest,
      'maxTotalTokensPerDay': instance.maxTotalTokensPerDay,
      'maxRequestsPerWindow': instance.maxRequestsPerWindow,
      'timeWindowDurationSeconds':
          _durationSecondsToJson(instance.timeWindowDuration),
      'backoffBaseDelayMs': _durationMsToJson(instance.backoffBaseDelay),
      'backoffMaxDelaySeconds':
          _durationSecondsToJson(instance.backoffMaxDelay),
      'maxRetryAttempts': instance.maxRetryAttempts,
      'queueEnabled': instance.queueEnabled,
      'perOperationLimits':
          _perOperationLimitsToJson(instance.perOperationLimits),
    };
