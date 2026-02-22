// Configuration for AI rate limits
//
// This model defines configurable rate limits for AI operations.
// See .github/issues/030-ai-configurable-rate-limits.md for requirements.
//
import '../services/app_logger.dart';

class AiRateLimitsConfig {
  final int maxRequestsPerMinute;
  final int maxRequestsPerHour;
  final int maxRequestsPerDay;
  final int maxTokensPerRequest;
  final int maxTotalTokensPerDay;
  final int maxRequestsPerWindow;
  final Duration timeWindowDuration;

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
      AppLogger.event('Invalid maxRequestsPerWindow', params: {'value': maxRequestsPerWindow, 'action': 'clamping to 1'});
    }
    return AiRateLimitsConfig(
      maxRequestsPerMinute: config.maxRequestsPerMinute.clamp(1, 1000),
      maxRequestsPerHour: config.maxRequestsPerHour.clamp(1, 10000),
      maxRequestsPerDay: config.maxRequestsPerDay.clamp(1, 50000),
      maxTokensPerRequest: config.maxTokensPerRequest.clamp(100, 100000),
      maxTotalTokensPerDay: config.maxTotalTokensPerDay.clamp(1000, 10000000),
      maxRequestsPerWindow: maxRequestsPerWindow.clamp(1, 1000),
      timeWindowDuration: config.timeWindowDuration,
    );
  }

  const AiRateLimitsConfig({
    required this.maxRequestsPerMinute,
    required this.maxRequestsPerHour,
    required this.maxRequestsPerDay,
    required this.maxTokensPerRequest,
    required this.maxTotalTokensPerDay,
    required this.maxRequestsPerWindow,
    required this.timeWindowDuration,
  });

  const AiRateLimitsConfig.defaults()
      : maxRequestsPerMinute = 10,
        maxRequestsPerHour = 100,
        maxRequestsPerDay = 500,
        maxTokensPerRequest = 4000,
        maxTotalTokensPerDay = 100000,
        maxRequestsPerWindow = 10,
        timeWindowDuration = const Duration(minutes: 1);

  AiRateLimitsConfig copyWith({
    int? maxRequestsPerMinute,
    int? maxRequestsPerHour,
    int? maxRequestsPerDay,
    int? maxTokensPerRequest,
    int? maxTotalTokensPerDay,
    int? maxRequestsPerWindow,
    Duration? timeWindowDuration,
  }) {
    return AiRateLimitsConfig(
      maxRequestsPerMinute: maxRequestsPerMinute ?? this.maxRequestsPerMinute,
      maxRequestsPerHour: maxRequestsPerHour ?? this.maxRequestsPerHour,
      maxRequestsPerDay: maxRequestsPerDay ?? this.maxRequestsPerDay,
      maxTokensPerRequest: maxTokensPerRequest ?? this.maxTokensPerRequest,
      maxTotalTokensPerDay: maxTotalTokensPerDay ?? this.maxTotalTokensPerDay,
      maxRequestsPerWindow: maxRequestsPerWindow ?? this.maxRequestsPerWindow,
      timeWindowDuration: timeWindowDuration ?? this.timeWindowDuration,
    );
  }

  factory AiRateLimitsConfig.fromJson(Map<String, dynamic> json) {
    return AiRateLimitsConfig(
      maxRequestsPerMinute: json['maxRequestsPerMinute'] as int? ?? 10,
      maxRequestsPerHour: json['maxRequestsPerHour'] as int? ?? 100,
      maxRequestsPerDay: json['maxRequestsPerDay'] as int? ?? 500,
      maxTokensPerRequest: json['maxTokensPerRequest'] as int? ?? 4000,
      maxTotalTokensPerDay: json['maxTotalTokensPerDay'] as int? ?? 100000,
      maxRequestsPerWindow: json['maxRequestsPerWindow'] as int? ?? 10,
      timeWindowDuration: Duration(seconds: json['timeWindowDurationSeconds'] as int? ?? 60),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'maxRequestsPerHour': maxRequestsPerHour,
      'maxRequestsPerDay': maxRequestsPerDay,
      'maxTokensPerRequest': maxTokensPerRequest,
      'maxTotalTokensPerDay': maxTotalTokensPerDay,
      'maxRequestsPerWindow': maxRequestsPerWindow,
      'timeWindowDurationSeconds': timeWindowDuration.inSeconds,
    };
  }

  @override
  String toString() {
    return 'AiRateLimitsConfig(maxRequestsPerMinute: $maxRequestsPerMinute, maxRequestsPerHour: $maxRequestsPerHour, maxRequestsPerDay: $maxRequestsPerDay, maxTokensPerRequest: $maxTokensPerRequest, maxTotalTokensPerDay: $maxTotalTokensPerDay, maxRequestsPerWindow: $maxRequestsPerWindow, timeWindowDuration: $timeWindowDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiRateLimitsConfig &&
        other.maxRequestsPerMinute == maxRequestsPerMinute &&
        other.maxRequestsPerHour == maxRequestsPerHour &&
        other.maxRequestsPerDay == maxRequestsPerDay &&
        other.maxTokensPerRequest == maxTokensPerRequest &&
        other.maxTotalTokensPerDay == maxTotalTokensPerDay &&
        other.maxRequestsPerWindow == maxRequestsPerWindow &&
        other.timeWindowDuration == timeWindowDuration;
  }

  @override
  int get hashCode {
    return maxRequestsPerMinute.hashCode ^
        maxRequestsPerHour.hashCode ^
        maxRequestsPerDay.hashCode ^
        maxTokensPerRequest.hashCode ^
        maxTotalTokensPerDay.hashCode ^
        maxRequestsPerWindow.hashCode ^
        timeWindowDuration.hashCode;
  }
}

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
import 'package:my_project_management_app/core/models/ai_rate_limits_config.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/l10n/app_localizations.dart';

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
