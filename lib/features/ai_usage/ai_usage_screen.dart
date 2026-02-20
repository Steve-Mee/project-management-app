import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ai/index.dart';

/// AI Usage Overview Screen
/// Displays detailed AI token usage information and analytics
/// Modular design for future expansion with additional usage metrics
class AIUsageScreen extends ConsumerWidget {
  const AIUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiUsageAsync = ref.watch(aiUsageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Usage Overview'),
      ),
      body: aiUsageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading AI usage: $error'),
        ),
        data: (aiUsage) => _AIUsageContent(aiUsage: aiUsage),
      ),
    );
  }
}

class _AIUsageContent extends StatelessWidget {
  final AiUsage aiUsage;

  const _AIUsageContent({required this.aiUsage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usagePercentage = aiUsage.tokensUsed / aiUsage.monthlyLimit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'AI Usage Overview',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          // Current usage card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Usage',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tokens Used: ${aiUsage.tokensUsed.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Monthly Limit: ${aiUsage.monthlyLimit.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Usage: ${(usagePercentage * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: usagePercentage > 0.8
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: usagePercentage.clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usagePercentage > 0.8
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Compliance note
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'AI usage is monitored for compliance with worldwide privacy regulations (GDPR, CCPA, etc.). Only aggregate usage data is stored.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Future expansion area for additional metrics
          const SizedBox(height: 24),
          Text(
            'Future Features',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This screen is designed to be modular and can be extended with:\n'
            '• Detailed usage history\n'
            '• Cost analysis\n'
            '• Usage by feature\n'
            '• Export functionality',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}