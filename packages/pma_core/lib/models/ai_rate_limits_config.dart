// ignore_for_file: invalid_annotation_target

// Configuration for AI rate limits
//
// This model defines configurable rate limits for AI operations.
// See .github/issues/030-ai-configurable-rate-limits.md for requirements.
// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/app_logger.dart';

part 'ai_rate_limits_config.freezed.dart';
part 'ai_rate_limits_config.g.dart';

@freezed
abstract class AiRateLimitsConfig with _$AiRateLimitsConfig {
  const factory AiRateLimitsConfig({
    @Default(10) int maxRequestsPerMinute,
    @Default(100) int maxRequestsPerHour,
    @Default(500) int maxRequestsPerDay,
    @Default(4000) int maxTokensPerRequest,
    @Default(100000) int maxTotalTokensPerDay,
    @Default(10) int maxRequestsPerWindow,
    @JsonKey(name: 'timeWindowDurationSeconds', fromJson: _durationSecondsFromJson, toJson: _durationSecondsToJson)
    @Default(Duration(minutes: 1)) Duration timeWindowDuration,
    @JsonKey(name: 'backoffBaseDelayMs', fromJson: _durationMsFromJson, toJson: _durationMsToJson)
    @Default(Duration(milliseconds: 500)) Duration backoffBaseDelay,
    @JsonKey(name: 'backoffMaxDelaySeconds', fromJson: _durationSecondsFromJson, toJson: _durationSecondsToJson)
    @Default(Duration(seconds: 30)) Duration backoffMaxDelay,
    @Default(3) int maxRetryAttempts,
    @Default(true) bool queueEnabled,
    @JsonKey(fromJson: _perOperationLimitsFromJson, toJson: _perOperationLimitsToJson)
    @Default(<String, int>{
      'chat': 15,
      'generate_questions': 8,
      'generate_proposals': 6,
      'generate_plan': 4,
      'parse_filter': 10,
      'summarize': 5,
    })
    Map<String, int> perOperationLimits,
  }) = _AiRateLimitsConfig;

  factory AiRateLimitsConfig.fromJson(Map<String, dynamic> json) =>
      _$AiRateLimitsConfigFromJson(json);

  /// Validates and clamps AI rate limits configuration to safe ranges.
  ///
  /// This method ensures that all rate limit values are within acceptable bounds
  /// to prevent abuse while allowing flexibility for legitimate use cases.
  /// Invalid values are clamped to safe defaults.
  ///
  /// Returns a new AiRateLimitsConfig with validated values.
  static AiRateLimitsConfig validateAiRateLimits(AiRateLimitsConfig config) {
    final maxRequestsPerWindow = config.maxRequestsPerWindow;
    if (maxRequestsPerWindow < 1) {
      AppLogger.warning('Invalid maxRequestsPerWindow', params: {'value': maxRequestsPerWindow, 'action': 'clamping to 1'});
    }
    final backoffBaseDelay = config.backoffBaseDelay;
    const minBaseDelay = Duration(milliseconds: 100);
    const maxBaseDelay = Duration(seconds: 10);
    if (backoffBaseDelay < minBaseDelay || backoffBaseDelay > maxBaseDelay) {
      AppLogger.warning('Invalid backoffBaseDelay', params: {'value': backoffBaseDelay.inMilliseconds, 'action': 'clamping to 100-10000ms'});
    }
    final backoffMaxDelay = config.backoffMaxDelay;
    const minMaxDelay = Duration(seconds: 5);
    const maxMaxDelay = Duration(minutes: 5);
    if (backoffMaxDelay < minMaxDelay || backoffMaxDelay > maxMaxDelay) {
      AppLogger.warning('Invalid backoffMaxDelay', params: {'value': backoffMaxDelay.inSeconds, 'action': 'clamping to 5-300s'});
    }
    final maxRetryAttempts = config.maxRetryAttempts;
    if (maxRetryAttempts < 0 || maxRetryAttempts > 10) {
      AppLogger.warning('Invalid maxRetryAttempts', params: {'value': maxRetryAttempts, 'action': 'clamping to 0-10 range'});
    }
    // Validate per-operation limits
    final validatedPerOperationLimits = <String, int>{};
    for (final entry in config.perOperationLimits.entries) {
      final clampedValue = entry.value.clamp(1, 1000);
      if (entry.value != clampedValue) {
        AppLogger.warning('Invalid perOperationLimit for ${entry.key}', params: {'value': entry.value, 'action': 'clamping to $clampedValue'});
      }
      validatedPerOperationLimits[entry.key] = clampedValue;
    }
    return AiRateLimitsConfig(
      maxRequestsPerMinute: config.maxRequestsPerMinute.clamp(1, 1000),
      maxRequestsPerHour: config.maxRequestsPerHour.clamp(1, 10000),
      maxRequestsPerDay: config.maxRequestsPerDay.clamp(1, 50000),
      maxTokensPerRequest: config.maxTokensPerRequest.clamp(100, 100000),
      maxTotalTokensPerDay: config.maxTotalTokensPerDay.clamp(1000, 10000000),
      maxRequestsPerWindow: maxRequestsPerWindow.clamp(1, 1000),
      timeWindowDuration: config.timeWindowDuration,
      backoffBaseDelay: backoffBaseDelay < minBaseDelay ? minBaseDelay : backoffBaseDelay > maxBaseDelay ? maxBaseDelay : backoffBaseDelay,
      backoffMaxDelay: backoffMaxDelay < minMaxDelay ? minMaxDelay : backoffMaxDelay > maxMaxDelay ? maxMaxDelay : backoffMaxDelay,
      maxRetryAttempts: maxRetryAttempts.clamp(0, 10),
      perOperationLimits: validatedPerOperationLimits,
    );
  }

}

Duration _durationSecondsFromJson(Object? value) =>
    Duration(seconds: (value as int?) ?? 60);

int _durationSecondsToJson(Duration value) => value.inSeconds;

Duration _durationMsFromJson(Object? value) =>
  Duration(milliseconds: (value as int?) ?? 500);

int _durationMsToJson(Duration value) => value.inMilliseconds;

Map<String, int> _perOperationLimitsFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.map((key, dynamic val) => MapEntry(key, val as int));
  }
  return const {
    'chat': 15,
    'generate_questions': 8,
    'generate_proposals': 6,
    'generate_plan': 4,
    'parse_filter': 10,
    'summarize': 5,
  };
}

Map<String, int> _perOperationLimitsToJson(Map<String, int> value) => value;
