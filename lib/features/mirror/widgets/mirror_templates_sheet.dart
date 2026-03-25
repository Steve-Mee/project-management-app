import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../models/mirror_template.dart';
import '../providers/mirror_templates_provider.dart';
import '../templates_gallery.dart';

class MirrorTemplatesSheet extends ConsumerWidget {
  const MirrorTemplatesSheet({
    super.key,
    required this.onTemplateSelected,
    required this.formatStaleUpdatedAt,
    required this.formatTemplatesFallbackReason,
    required this.formatTemplatesCacheAge,
  });

  final ValueChanged<MirrorTemplate> onTemplateSelected;
  final String Function(DateTime timestampUtc) formatStaleUpdatedAt;
  final String Function(String? reasonCode) formatTemplatesFallbackReason;
  final String Function(Duration? cacheAge) formatTemplatesCacheAge;

  void _refreshTemplates(
    WidgetRef ref, {
    MirrorTemplatesLoadResult? staleResult,
  }) {
    if (staleResult != null && staleResult.isStaleFallback) {
      _recordFallbackInteraction(
        ref,
        action: 'refresh',
        result: staleResult,
      );
    }

    final _ = ref
        .read(mirrorTemplatesInvalidationControllerProvider)
        .invalidateTemplatesCache(refresh: true);
  }

  void _recordFallbackInteraction(
    WidgetRef ref, {
    required String action,
    required MirrorTemplatesLoadResult result,
    String? templateId,
  }) {
    final reason = result.reasonCode ?? MirrorTemplatesLoadReasonCodes.networkError;
    ref.read(mirrorTemplatesObservabilityProvider).recordTemplateFallbackInteraction(
          action: action,
          source: result.source,
          reason: reason,
          stalenessAgeMs: result.cacheAge?.inMilliseconds,
          templateId: templateId,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(mirrorTemplatesProvider);

    return templatesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.mirrorTemplatesLoadFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _refreshTemplates(ref),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.mirrorRetryButton),
              ),
            ],
          ),
        ),
      ),
      data: (MirrorTemplatesLoadResult result) {
        final templates = result.templates;
        final staleWarningMessage = result.isStaleFallback
            ? result.fetchedAtUtc == null
                ? l10n.mirrorTemplatesStaleFallbackWarning
                : l10n.mirrorTemplatesStaleFallbackWarningWithTime(
                    formatStaleUpdatedAt(result.fetchedAtUtc!),
                  )
            : null;
        final staleReasonMessage =
            formatTemplatesFallbackReason(result.reasonCode);
        final staleSourceMessage = result.staleFallbackSourceLabel;
        final staleAgeMessage = formatTemplatesCacheAge(result.cacheAge);
        final staleFallbackDetails =
            'Fallback details: reason=$staleReasonMessage, source=$staleSourceMessage, age=$staleAgeMessage';
        final staleFallbackNotice = result.isStaleFallback
            ? (staleWarningMessage ?? l10n.mirrorTemplatesStaleFallbackWarning)
            : null;

        if (templates.isEmpty) {
          return _buildTemplatesEmptyState(
            context,
            ref,
            staleFallbackNotice: staleFallbackNotice,
            staleFallbackDetails: staleFallbackDetails,
            staleResult: result,
          );
        }

        return Column(
          children: <Widget>[
            if (staleFallbackNotice != null)
              _buildTemplatesStaleFallbackNotice(
                context,
                ref,
                notice: staleFallbackNotice,
                details: staleFallbackDetails,
                staleResult: result,
              ),
            Expanded(
              child: TemplatesGallery(
                templates: templates,
                staleWarningTooltip: staleFallbackNotice,
                onTemplateSelected: (MirrorTemplate template) {
                  if (result.isStaleFallback) {
                    _recordFallbackInteraction(
                      ref,
                      action: 'select_template',
                      result: result,
                      templateId: template.id,
                    );
                  }
                  onTemplateSelected(template);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplatesEmptyState(
    BuildContext context,
    WidgetRef ref, {
    String? staleFallbackNotice,
    String? staleFallbackDetails,
    MirrorTemplatesLoadResult? staleResult,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (staleFallbackNotice != null) ...<Widget>[
              _buildTemplatesStaleFallbackNotice(
                context,
                ref,
                notice: staleFallbackNotice,
                details: staleFallbackDetails,
                staleResult: staleResult,
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ],
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.mirrorNoActiveTemplates,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _refreshTemplates(ref),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.mirrorRetryButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesStaleFallbackNotice(
    BuildContext context,
    WidgetRef ref, {
    required String notice,
    String? details,
    MirrorTemplatesLoadResult? staleResult,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(12, 8, 12, 0),
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (details != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _refreshTemplates(ref, staleResult: staleResult),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.mirrorRetryButton),
            ),
          ),
        ],
      ),
    );
  }
}