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

/*
UI Example Code for Settings Screen
====================================

Add this section to your settings screen (e.g., in lib/screens/settings_screen.dart).
Only show this section for admins or when a feature flag is enabled.

Required imports:
import 'package:flutter/material.dart';
import '../services/app_logger.dart';
import '../services/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_management_app/core/models/ai_rate_limits_config.dart';
import 'package:project_management_app/core/providers/auth_providers.dart';
import 'package:project_management_app/l10n/app_localizations.dart';

Example implementation:

/// AI Rate Limits Settings Section
/// Only visible for admin users or when feature flag is enabled
class AiRateLimitsSection extends ConsumerStatefulWidget {
  const AiRateLimitsSection({super.key});

  @override
  ConsumerState<AiRateLimitsSection> createState() => _AiRateLimitsSectionState();
}

class _AiRateLimitsSectionState extends ConsumerState<AiRateLimitsSection> {
  late AiRateLimitsConfig _config;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    setState(() {
      _config = settings.getAiRateLimitsConfig();
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.setAiRateLimitsConfig(_config);
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.ai_config_saved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save AI configuration: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ai_rate_limits_title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Max Requests Per Minute
            _buildNumericInput(
              label: l10n.max_requests_per_minute,
              value: _config.maxRequestsPerMinute,
              min: 1,
              max: 1000,
              onChanged: (value) => setState(() {
                _config = _config.copyWith(maxRequestsPerMinute: value);
                _hasChanges = true;
              }),
            ),

            const SizedBox(height: 16),

            // Max Requests Per Hour
            _buildNumericInput(
              label: 'Max requests per hour',
              value: _config.maxRequestsPerHour,
              min: 1,
              max: 10000,
              onChanged: (value) => setState(() {
                _config = _config.copyWith(maxRequestsPerHour: value);
                _hasChanges = true;
              }),
            ),

            const SizedBox(height: 16),

            // Max Tokens Per Day
            _buildNumericInput(
              label: 'Max tokens per day',
              value: _config.maxTokensPerDay,
              min: 100,
              max: 1000000,
              onChanged: (value) => setState(() {
                _config = _config.copyWith(maxTokensPerDay: value);
                _hasChanges = true;
              }),
            ),

            const SizedBox(height: 16),

            // Cooldown After Limit
            _buildNumericInput(
              label: l10n.cooldown_seconds,
              value: _config.cooldownAfterLimit.inSeconds,
              min: 10,
              max: 3600,
              onChanged: (value) => setState(() {
                _config = _config.copyWith(cooldownAfterLimit: Duration(seconds: value));
                _hasChanges = true;
              }),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveConfig : null,
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save AI Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ 10,
                onChanged: (newValue) => onChanged(newValue.toInt()),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: TextEditingController(text: value.toString()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (text) {
                  final newValue = int.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max) {
                    onChanged(newValue);
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        Text(
          'Range: $min - $max',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Usage in Settings Screen:
///
/// class SettingsScreen extends ConsumerWidget {
///   const SettingsScreen({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final isAdmin = ref.watch(isAdminProvider); // Your admin check
///     final featureFlag = ref.watch(aiRateLimitsFeatureFlagProvider); // Your feature flag
///
///     return Scaffold(
///       appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
///       body: ListView(
///         children: [
///           // Other settings sections...
///
///           if (isAdmin || featureFlag) const AiRateLimitsSection(),
///         ],
///       ),
///     );
///   }
/// }
///
/// // Example: Max Requests Per Window Setting Widget
/// // Add to your settings screen AI section
/// class AiMaxRequestsSetting extends ConsumerWidget {
///   const AiMaxRequestsSetting({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final settings = ref.watch(settingsRepositoryProvider);
///     final rateLimits = settings.getAiRateLimitsConfig();
///
///     return Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         Text(
///           AppLocalizations.of(context)!.ai_max_requests_label,
///           style: Theme.of(context).textTheme.titleMedium,
///         ),
///         const SizedBox(height: 8),
///         Row(
///           children: [
///             Expanded(
///               child: Slider(
///                 value: rateLimits.maxRequestsPerWindow.toDouble(),
///                 min: 1,
///                 max: 50,
///                 divisions: 49,
///                 label: rateLimits.maxRequestsPerWindow.toString(),
///                 onChanged: (value) {
///                   final newConfig = rateLimits.copyWith(
///                     maxRequestsPerWindow: value.toInt(),
///                   );
///                   ref.read(settingsRepositoryProvider).setAiRateLimitsConfig(newConfig);
///                 },
///               ),
///             ),
///             const SizedBox(width: 16),
///             Text(
///               '${rateLimits.maxRequestsPerWindow} ${AppLocalizations.of(context)!.ai_requests_per_minute}',
///               style: Theme.of(context).textTheme.bodyMedium,
///             ),
///           ],
///         ),
///         Text(
///           AppLocalizations.of(context)!.max_requests_per_window,
///           style: Theme.of(context).textTheme.bodySmall?.copyWith(
///             color: Theme.of(context).colorScheme.onSurfaceVariant,
///           ),
///         ),
///       ],
///     );
///   }
/// }
///
/// // Example: Settings Screen AI Section
/// class AiRateLimitsSection extends ConsumerWidget {
///   const AiRateLimitsSection({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return Card(
///       margin: const EdgeInsets.all(16),
///       child: Padding(
///         padding: const EdgeInsets.all(16),
///         child: Column(
///           crossAxisAlignment: CrossAxisAlignment.start,
///           children: [
///             Text(
///               AppLocalizations.of(context)!.ai_rate_limits_title,
///               style: Theme.of(context).textTheme.titleLarge,
///             ),
///             const SizedBox(height: 16),
///             const AiMaxRequestsSetting(),
///             // Add other AI settings here...
///           ],
///         ),
///       ),
///     );
///   }
/// }
///
*/
