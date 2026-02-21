import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Widget that shows a dropdown menu with recent filter history
class RecentFiltersMenu extends ConsumerWidget {
  const RecentFiltersMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFilters = ref.watch(persistentProjectFilterProvider.notifier).recentFilters;
    final l10n = AppLocalizations.of(context)!;

    if (recentFilters.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.history),
        tooltip: l10n.recentFiltersTooltip,
        onPressed: null, // Disabled when no recent filters
      );
    }

    return PopupMenuButton<ProjectFilter>(
      icon: const Icon(Icons.history),
      tooltip: l10n.recentFiltersTooltip,
      onSelected: (filter) {
        ref.read(persistentProjectFilterProvider.notifier).updateFilter(filter);
      },
      itemBuilder: (context) => recentFilters.map((filter) {
        return PopupMenuItem<ProjectFilter>(
          value: filter,
          child: _buildFilterPreview(filter, l10n),
        );
      }).toList(),
    );
  }

  Widget _buildFilterPreview(ProjectFilter filter, AppLocalizations l10n) {
    final parts = <String>[];

    if (filter.status != null) {
      parts.add('${l10n.statusLabel}: ${filter.status}');
    }
    if (filter.priority != null) {
      parts.add('${l10n.priorityLabel}: ${filter.priority}');
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      parts.add('"${filter.searchQuery}"');
    }
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      parts.add('${l10n.tagsLabel}: ${filter.tags!.join(", ")}');
    }
    if (filter.ownerId != null) {
      parts.add('${l10n.ownerLabel}: ${filter.ownerId}');
    }
    if (filter.sortBy != null) {
      final sortDirection = filter.sortAscending ? l10n.ascendingLabel : l10n.descendingLabel;
      parts.add('${l10n.sortByLabel}: ${filter.sortBy} ($sortDirection)');
    }

    final preview = parts.isEmpty ? l10n.allProjectsLabel : parts.join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.viewName ?? l10n.unnamedFilterLabel,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          preview,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}