import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gantt_chart/gantt_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:share_plus/share_plus.dart';

/// Callback used when a task is dragged horizontally to a new date range.
typedef TaskRescheduleCallback = void Function(
  Task task,
  DateTime newStartDate,
  DateTime newEndDate,
);

/// Called during drag while the task is being moved.
typedef TaskReschedulePreviewCallback = void Function(
  Task task,
  DateTime previewStartDate,
  DateTime previewEndDate,
);

/// Optional progress resolver for task rows.
///
/// Return value is clamped to 0..1.
typedef TaskProgressResolver = double Function(Task task);

/// Optional export callback for CSV data.
typedef GanttCsvExportCallback = Future<void> Function(String csvContent);

/// Optional export callback for generated PDF bytes.
typedef GanttPdfExportCallback = Future<void> Function(Uint8List pdfBytes);

/// Modern, reusable wrapper around `gantt_chart` for project task timelines.
///
/// Why `gantt_chart` over Syncfusion for this issue:
/// - Free and lightweight dependency for open-source/community use.
/// - Smaller API surface and lower integration complexity for this app.
/// - Pure Flutter/Dart package that can be themed with Material 3 colors.
///
/// Riverpod-ready: this is a `ConsumerStatefulWidget`, so callers can plug in
/// provider-driven callbacks/resolvers without refactoring this component later.
class ModernGanttChart extends ConsumerStatefulWidget {
  const ModernGanttChart({
    super.key,
    required this.project,
    required this.tasks,
    this.startDate,
    this.endDate,
    this.dayWidth = 28,
    this.eventHeight = 32,
    this.stickyAreaWidth = 220,
    this.showDays = true,
    this.enableDragReschedule = true,
    this.onTaskRescheduled,
    this.onTaskReschedulePreview,
    this.onTaskRescheduleCommit,
    this.taskProgressResolver,
    this.showControls = true,
    this.onExportCsv,
    this.onExportPdf,
    this.emptyState,
  });

  final ProjectModel project;
  final List<Task> tasks;

  /// Optional custom visible range start. Defaults to project start or now.
  final DateTime? startDate;

  /// Optional custom visible range end. Defaults to project due date or +90 days.
  final DateTime? endDate;

  final double dayWidth;
  final double eventHeight;
  final double stickyAreaWidth;
  final bool showDays;

  /// Enables drag gestures to suggest date changes for tasks.
  ///
  /// The `gantt_chart` package does not expose built-in task drag state, so
  /// this wrapper implements drag handling via custom event-cell builders.
  final bool enableDragReschedule;

  /// Called whenever dragging crosses day boundaries.
  ///
  /// Kept for backwards compatibility. Prefer [onTaskRescheduleCommit].
  final TaskRescheduleCallback? onTaskRescheduled;

  /// Called while dragging for live UI preview scenarios.
  final TaskReschedulePreviewCallback? onTaskReschedulePreview;

  /// Called once when drag ends and a day shift occurred.
  final TaskRescheduleCallback? onTaskRescheduleCommit;

  /// Optional resolver for per-task progress (0..1).
  /// If omitted, progress is inferred from [Task.status].
  final TaskProgressResolver? taskProgressResolver;

  /// Shows zoom/pan/export controls above the chart.
  final bool showControls;

  /// Optional external CSV export handler.
  ///
  /// If omitted, the widget shares CSV text using the platform share sheet.
  final GanttCsvExportCallback? onExportCsv;

  /// Optional external PDF export handler.
  ///
  /// If omitted, the widget shares generated PDF bytes.
  final GanttPdfExportCallback? onExportPdf;

  /// Optional custom empty state.
  final Widget? emptyState;

  @override
  ConsumerState<ModernGanttChart> createState() => _ModernGanttChartState();
}

class _ModernGanttChartState extends ConsumerState<ModernGanttChart> {
  final Map<String, double> _dragDxAccumulator = <String, double>{};
  final Map<String, int> _dragDayShiftAccumulator = <String, int>{};
  late final ScrollController _scrollController;
  late double _currentDayWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentDayWidth = widget.dayWidth;
  }

  @override
  void didUpdateWidget(covariant ModernGanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayWidth != widget.dayWidth &&
        oldWidget.dayWidth == _currentDayWidth) {
      _currentDayWidth = widget.dayWidth;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Always normalize tasks so Gantt can render items with missing/invalid dates.
    final normalizedTasks = widget.tasks
      .map((task) => task.withGanttDefaults())
      .toList(growable: false);

    if (normalizedTasks.isEmpty) {
      return widget.emptyState ??
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              'No dated tasks available for this timeline.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
    }

    final effectiveStartDate =
      DateUtils.dateOnly(widget.startDate ?? widget.project.startDate ?? _minTaskStart(normalizedTasks));
    final effectiveEndDate =
      DateUtils.dateOnly(widget.endDate ?? widget.project.dueDate ?? _maxTaskEnd(normalizedTasks));
    final safeDuration = _safeDurationInclusive(effectiveStartDate, effectiveEndDate);

    final events = normalizedTasks
        .map((task) {
          final start = _taskStart(task);
          final end = _taskEnd(task);
          final progress = _taskProgress(task);
          return GanttAbsoluteEvent(
            startDate: start,
            endDate: end,
            displayName: task.title,
            suggestedColor: task.status.toThemeColor(colorScheme),
            extra: _ModernTaskEvent(task: task, progress: progress),
          );
        })
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showControls)
            _buildControlBar(
              context,
              normalizedTasks,
              colorScheme,
            ),
          GanttChartView(
            startDate: effectiveStartDate,
            maxDuration: safeDuration,
            dayWidth: _currentDayWidth,
            eventHeight: widget.eventHeight,
            stickyAreaWidth: widget.stickyAreaWidth,
            showStickyArea: true,
            showDays: widget.showDays,
            startOfTheWeek: WeekDay.monday,
            weekEnds: const {WeekDay.saturday, WeekDay.sunday},
            scrollController: _scrollController,
            holidayColor: isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            dayHeaderBuilder: (context, date, isHoliday) {
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHoliday
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surfaceContainerLow,
                  border: Border(
                    right: BorderSide(color: colorScheme.outlineVariant),
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Text(
                  '${date.day}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isHoliday
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            weekHeaderBuilder: (context, weekDate) {
              final weekEnd = weekDate.add(const Duration(days: 6));
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  border: Border(
                    right: BorderSide(color: colorScheme.outlineVariant),
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Text(
                  '${weekDate.month}/${weekDate.day} - ${weekEnd.month}/${weekEnd.day}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            stickyAreaEventBuilder: (context, eventIndex, event, eventColor) {
              final taskEvent = event.extra is _ModernTaskEvent
                  ? event.extra as _ModernTaskEvent
                  : null;
              final task = taskEvent?.task;
              final progress = taskEvent?.progress ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(
                    right: BorderSide(color: colorScheme.outlineVariant),
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactRow = constraints.maxHeight < 26;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task?.title ?? event.getDisplayName(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!isCompactRow) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                task == null
                                    ? eventColor
                                    : task.status.toThemeColor(colorScheme),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              );
            },
            eventCellPerDayBuilder: (context, eventStart, eventEnd, isHoliday,
                event, day, eventColor) {
              final taskEvent = event.extra is _ModernTaskEvent
                  ? event.extra as _ModernTaskEvent
                  : null;
              final task = taskEvent?.task;
              final progress = taskEvent?.progress ?? 0;

              final inRange = !DateUtils.isSameDay(eventStart, eventEnd) &&
                  (DateUtils.isSameDay(eventStart, day) ||
                      (day.isAfter(eventStart) && day.isBefore(eventEnd)));

              final barColor = task == null
                  ? eventColor
                  : task.status.toThemeColor(colorScheme);

              final bar = Container(
                decoration: BoxDecoration(
                  color: inRange
                      ? barColor.withValues(alpha: isDark ? 0.75 : 0.65)
                      : (isHoliday
                          ? colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.45)
                          : Colors.transparent),
                  border: Border(
                    right: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: inRange && DateUtils.isSameDay(eventStart, day)
                    ? Text(
                        '${(progress * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );

              if (!widget.enableDragReschedule || task == null || !inRange) {
                return bar;
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  _handleDrag(task, details.delta.dx);
                },
                onHorizontalDragEnd: (_) {
                  _handleDragEnd(task);
                  _dragDxAccumulator.remove(task.id);
                  _dragDayShiftAccumulator.remove(task.id);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: bar,
                ),
              );
            },
            events: events,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    List<Task> tasks,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Pan left',
            onPressed: () => _panByDays(-3),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Pan right',
            onPressed: () => _panByDays(3),
            icon: const Icon(Icons.chevron_right),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Export',
            icon: const Icon(Icons.download_outlined),
            onSelected: (value) async {
              if (value == 'csv') {
                await _exportCsv(tasks);
              }
              if (value == 'pdf') {
                await _exportPdf(tasks);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'csv',
                child: Text('Export CSV'),
              ),
              PopupMenuItem<String>(
                value: 'pdf',
                child: Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _currentDayWidth = (_currentDayWidth * 1.2).clamp(14.0, 72.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentDayWidth = (_currentDayWidth / 1.2).clamp(14.0, 72.0);
    });
  }

  Future<void> _panByDays(int days) async {
    if (!_scrollController.hasClients) {
      return;
    }
    final target = (_scrollController.offset + (days * _currentDayWidth))
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _exportCsv(List<Task> tasks) async {
    final rows = <List<dynamic>>[
      ['Project', 'Task ID', 'Title', 'Status', 'Start', 'End', 'Progress'],
      ...tasks.map((task) {
        final progress = (_taskProgress(task) * 100).round();
        return [
          widget.project.name,
          task.id,
          task.title,
          task.status.name,
          _taskStart(task).toIso8601String(),
          _taskEnd(task).toIso8601String(),
          '$progress%',
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    if (widget.onExportCsv != null) {
      await widget.onExportCsv!(csv);
      return;
    }

    final bytes = Uint8List.fromList(csv.codeUnits);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: 'gantt_export.csv',
        ),
      ],
      subject: 'Gantt CSV - ${widget.project.name}',
      text: 'Project timeline CSV export for ${widget.project.name}',
    );
  }

  Future<void> _exportPdf(List<Task> tasks) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return [
            pw.Text('Gantt Export: ${widget.project.name}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Task',
                'Status',
                'Start',
                'End',
                'Progress',
              ],
              data: tasks
                  .map((task) => [
                        task.title,
                        task.status.name,
                        _taskStart(task).toIso8601String().split('T').first,
                        _taskEnd(task).toIso8601String().split('T').first,
                        '${(_taskProgress(task) * 100).round()}%',
                      ])
                  .toList(growable: false),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (widget.onExportPdf != null) {
      await widget.onExportPdf!(bytes);
      return;
    }

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: 'gantt_export.pdf')],
      subject: 'Gantt PDF - ${widget.project.name}',
      text: 'Project timeline export for ${widget.project.name}',
    );
  }

  DateTime _taskStart(Task task) {
    return task.ganttStartDate;
  }

  DateTime _taskEnd(Task task) {
    return task.ganttEndDate;
  }

  DateTime _minTaskStart(List<Task> tasks) {
    var current = _taskStart(tasks.first);
    for (final task in tasks.skip(1)) {
      final start = _taskStart(task);
      if (start.isBefore(current)) {
        current = start;
      }
    }
    return current;
  }

  DateTime _maxTaskEnd(List<Task> tasks) {
    var current = _taskEnd(tasks.first);
    for (final task in tasks.skip(1)) {
      final end = _taskEnd(task);
      if (end.isAfter(current)) {
        current = end;
      }
    }
    return current;
  }

  Duration _safeDurationInclusive(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return Duration(days: days <= 0 ? 1 : days + 1);
  }

  double _taskProgress(Task task) {
    final raw = widget.taskProgressResolver?.call(task) ?? _defaultProgress(task);
    return raw.clamp(0.0, 1.0);
  }

  double _defaultProgress(Task task) {
    switch (task.status) {
      case TaskStatus.todo:
        return 0.15;
      case TaskStatus.inProgress:
        return 0.55;
      case TaskStatus.review:
        return 0.85;
      case TaskStatus.done:
        return 1.0;
    }
  }

  void _handleDrag(Task task, double deltaDx) {
    if (!widget.enableDragReschedule) {
      return;
    }

    final accumulated = (_dragDxAccumulator[task.id] ?? 0) + deltaDx;
    _dragDxAccumulator[task.id] = accumulated;

    final crossedDays = accumulated / _currentDayWidth;
    if (crossedDays.abs() < 1) {
      return;
    }

    final dayShift = crossedDays.truncate();
    _dragDxAccumulator[task.id] = accumulated - (dayShift * _currentDayWidth);
    final totalShift = (_dragDayShiftAccumulator[task.id] ?? 0) + dayShift;
    _dragDayShiftAccumulator[task.id] = totalShift;

    if (widget.onTaskReschedulePreview != null) {
      final baseStart = _taskStart(task);
      final baseEnd = _taskEnd(task);
      widget.onTaskReschedulePreview!.call(
        task,
        baseStart.add(Duration(days: totalShift)),
        baseEnd.add(Duration(days: totalShift)),
      );
    }
  }

  void _handleDragEnd(Task task) {
    final shift = _dragDayShiftAccumulator[task.id] ?? 0;
    if (shift == 0) {
      return;
    }

    final baseStart = _taskStart(task);
    final baseEnd = _taskEnd(task);
    final newStart = baseStart.add(Duration(days: shift));
    final newEnd = baseEnd.add(Duration(days: shift));

    // New callback.
    widget.onTaskRescheduleCommit?.call(task, newStart, newEnd);
    // Backwards compatible callback.
    widget.onTaskRescheduled?.call(task, newStart, newEnd);
  }
}

class _ModernTaskEvent {
  const _ModernTaskEvent({
    required this.task,
    required this.progress,
  });

  final Task task;
  final double progress;
}
