import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:animate_do/animate_do.dart';

/// Widget that displays a saved view as a card with stats and quick access
class SavedViewWidget extends ConsumerWidget {
  final ProjectFilter savedFilter;

  const SavedViewWidget({
    super.key,
    required this.savedFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Get projects that match this filter
    final filteredProjectsAsync = ref.watch(filteredProjectsProvider(savedFilter));

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          onTap: () => _navigateToProjects(context, ref),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and star icon
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        savedFilter.viewName ?? l10n.unnamedFilterLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Project count and stats
                filteredProjectsAsync.when(
                  data: (projects) => _buildStats(context, projects, l10n),
                  loading: () => _buildLoadingStats(context),
                  error: (error, stack) => _buildErrorStats(context, l10n),
                ),

                SizedBox(height: 12.h),

                // Quick filters preview
                _buildFilterPreview(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List projects, AppLocalizations l10n) {
    final totalCount = projects.length;
    final overdueCount = projects.where((p) {
      final project = p as dynamic;
      final dueDate = project.dueDate as DateTime?;
      return dueDate != null && dueDate.isBefore(DateTime.now());
    }).length;

    // Calculate on-time percentage
    final completedCount = projects.where((p) {
      final project = p as dynamic;
      return project.status == 'Completed';
    }).length;

    final onTimePercentage = totalCount > 0
        ? ((completedCount / totalCount) * 100).round()
        : 0;

    return Row(
      children: [
        // Project count
        _buildStatItem(
          context,
          icon: Icons.folder,
          value: totalCount.toString(),
          label: l10n.projectListLabel.toLowerCase(),
          color: Theme.of(context).colorScheme.primary,
        ),

        SizedBox(width: 16.w),

        // Overdue count
        if (overdueCount > 0)
          _buildStatItem(
            context,
            icon: Icons.warning,
            value: overdueCount.toString(),
            label: 'overdue',
            color: Theme.of(context).colorScheme.error,
          ),

        SizedBox(width: 16.w),

        // Progress indicator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$onTimePercentage% on-time',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(height: 2.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16.sp,
          height: 16.sp,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'Loading stats...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStats(BuildContext context, AppLocalizations l10n) {
    return Text(
      'Unable to load stats',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildFilterPreview(BuildContext context, AppLocalizations l10n) {
    final filters = <String>[];

    if (savedFilter.status != null) {
      filters.add('Status: ${savedFilter.status}');
    }
    if (savedFilter.priority != null) {
      filters.add('Priority: ${savedFilter.priority}');
    }
    if (savedFilter.searchQuery?.isNotEmpty == true) {
      filters.add('Search: "${savedFilter.searchQuery}"');
    }
    if (savedFilter.tags?.isNotEmpty == true) {
      filters.add('Tags: ${savedFilter.tags!.length}');
    }

    if (filters.isEmpty) {
      return Text(
        'All projects',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Text(
      filters.take(2).join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _navigateToProjects(BuildContext context, WidgetRef ref) {
    // Update the current filter to this saved view
    ref.read(persistentProjectFilterProvider.notifier).loadView(savedFilter);

    // Navigate to projects screen
    context.go('/projects');
  }
}