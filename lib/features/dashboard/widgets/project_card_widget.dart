import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_model.dart';

class _ChartColors {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color neutral;
  final Color grid;
  final Color surface;

  const _ChartColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.neutral,
    required this.grid,
    required this.surface,
  });
}

class ProjectCardWidget extends StatelessWidget {
  const ProjectCardWidget({super.key, required this.project, required this.onTap});

  final ProjectModel project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _chartColors(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    switch (project.status) {
      case 'In Progress':
        statusColor = colorScheme.primary;
        break;
      case 'In Review':
        statusColor = colorScheme.secondary;
        break;
      case 'Planning':
        statusColor = colorScheme.tertiary;
        break;
      default:
        statusColor = colorScheme.surfaceContainerHighest;
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400.w,
            minWidth: 200.w,
          ),
          child: Card(
            elevation: 4,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 200;
                  final completedTasks = (project.progress * 100).round();
                  final pendingTasks = 100 - completedTasks;

                  // Detecteer unbounded height en val terug op screen-based max
                  final double effectiveMaxHeight = constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height * 0.35;

                  // Dynamische sizes, nu clamped op effectiveMaxHeight
                  final chartSize =
                      min(constraints.maxWidth * 0.4, effectiveMaxHeight * 0.5)
                          .clamp(50.0, 150.0);
                  final chartRadius = chartSize * 0.4;
                  final centerRadius = chartSize * 0.2;
                  final fontSize = (chartSize * 0.11).clamp(8.0, 11.0);

                  final pieChart = TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Semantics(
                        label: l10n.projectProgressChartSemantics(
                          project.name,
                          completedTasks,
                          pendingTasks,
                        ),
                        child: SizedBox(
                          width: chartSize,
                          height: chartSize,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: completedTasks.toDouble(),
                                  color: colors.primary,
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.primary,
                                      colors.primary.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  radius: chartRadius * value,
                                  title: '$completedTasks%',
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline,
                                    width: 1,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: pendingTasks.toDouble(),
                                  color: colors.neutral,
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.neutral,
                                      colors.neutral.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  radius: chartRadius * value,
                                  title: '$pendingTasks%',
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline,
                                    width: 1,
                                  ),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: centerRadius,
                            ),
                          ),
                        ),
                      );
                    },
                  );

                  final progressInfo = LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AutoSizeText(
                            l10n.progressLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            minFontSize: 6,
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 6.w,
                                          height: 6.h,
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius:
                                                BorderRadius.circular(2.r),
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: AutoSizeText(
                                            l10n.completedPercentLabel(
                                              completedTasks,
                                            ),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 8.5.sp,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            minFontSize: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6.w,
                                          height: 6.h,
                                          decoration: BoxDecoration(
                                            color: colors.neutral,
                                            borderRadius:
                                                BorderRadius.circular(2.r),
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: AutoSizeText(
                                            l10n.pendingPercentLabel(
                                              pendingTasks,
                                            ),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 8.5.sp,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            minFontSize: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Project title and status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              project.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 12.sp,
                                height: 1.1,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            constraints: BoxConstraints(maxWidth: 80.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              project.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      // Progress section: Gebruik ConstrainedBox met effectiveMaxHeight
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: effectiveMaxHeight * 0.82,
                        ),
                        child: isNarrow
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  progressInfo,
                                  SizedBox(height: 4.h),
                                  SizedBox(
                                    width: chartSize,
                                    height: chartSize,
                                    child: pieChart,
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth * 0.6,
                                      ),
                                      child: progressInfo,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: SizedBox(
                                      width: chartSize,
                                      height: chartSize,
                                      child: pieChart,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (project.description != null) ...[
                        SizedBox(height: 4.h),
                        AutoSizeText(
                          project.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.sp,
                            height: 1.2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          minFontSize: 7,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ChartColors _chartColors(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color tone(Color color, double amount) {
      if (!isDark) {
        return color;
      }
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }

    return _ChartColors(
      primary: tone(scheme.primary, 0.12),
      secondary: tone(scheme.secondary, 0.12),
      success: tone(scheme.tertiary, 0.12),
      neutral: isDark ? scheme.surfaceContainerHighest : scheme.outlineVariant,
      grid: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
      surface: scheme.surface,
    );
  }
}