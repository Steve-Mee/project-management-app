import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_sort.dart';
import 'package:my_project_management_app/models/project_model.dart';

class FiltersSortWidget extends ConsumerStatefulWidget {
  const FiltersSortWidget({
    super.key,
    required this.selectedStatus,
    required this.sortBy,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.projects,
  });

  final String selectedStatus;
  final ProjectSort sortBy;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<ProjectSort> onSortChanged;
  final List<ProjectModel> projects;

  @override
  ConsumerState<FiltersSortWidget> createState() => _FiltersSortWidgetState();
}

class _FiltersSortWidgetState extends ConsumerState<FiltersSortWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final statuses = <String>{'All'};
    for (final project in widget.projects) {
      statuses.add(project.status);
    }

    final items = statuses.toList()..sort();
    if (items.first != 'All') {
      items.remove('All');
      items.insert(0, 'All');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((status) {
              final isSelected = widget.selectedStatus == status;
              return Padding(
                padding: EdgeInsets.only(right: isCompact ? 4.w : 8.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 120.w,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      status == 'All' ? l10n.allLabel : status,
                      style: TextStyle(fontSize: isCompact ? 12.sp : 14.sp),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    selected: isSelected,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8.w : 12.w,
                      vertical: isCompact ? 4.h : 8.h,
                    ),
                    onSelected: (_) {
                      widget.onStatusChanged(status);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8.h),
        isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sortByLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 4.h),
                  DropdownButton<ProjectSort>(
                    value: widget.sortBy,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      widget.onSortChanged(value);
                    },
                    items: ProjectSort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(_projectSortLabel(sort, l10n)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            : Row(
                children: [
                  Text(
                    l10n.sortByLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(width: 12.w),
                  DropdownButton<ProjectSort>(
                    value: widget.sortBy,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      widget.onSortChanged(value);
                    },
                    items: ProjectSort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(_projectSortLabel(sort, l10n)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
        SizedBox(height: 16.h),
      ],
    );
  }

  String _projectSortLabel(ProjectSort sort, AppLocalizations l10n) {
    switch (sort) {
      case ProjectSort.name:
        return l10n.projectSortName;
      case ProjectSort.progress:
        return l10n.projectSortProgress;
      case ProjectSort.priority:
        return l10n.projectSortPriority;
      case ProjectSort.createdDate:
        return l10n.projectSortCreatedDate;
      case ProjectSort.status:
        return l10n.projectSortStatus;
    }
  }
}