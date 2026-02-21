import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';

/// PDF export utility for project reports
class PdfExporter {

  /// Export filtered projects to PDF
  static Future<void> exportProjectsToPdf({
    required BuildContext context,
    required List<ProjectModel> projects,
    required ProjectFilter filter,
    required String searchQuery,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Show loading indicator
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportingPdfMessage)),
      );

      // Generate PDF
      final pdf = pw.Document();

      // Load logo (placeholder - you can replace with actual logo)
      final logoData = await _loadLogo();

      // Add main page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(logoData, l10n),
          build: (context) => [
            _buildTitle(l10n),
            pw.SizedBox(height: 20),
            _buildFiltersSection(filter, searchQuery, l10n),
            pw.SizedBox(height: 20),
            _buildSummarySection(projects, l10n),
            pw.SizedBox(height: 20),
            _buildChartsSection(projects, l10n),
            pw.SizedBox(height: 20),
            _buildProjectsList(projects, l10n),
          ],
        ),
      );

      // Save and share PDF
      // ignore: use_build_context_synchronously
      await _saveAndSharePdf(pdf, l10n, context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.pdfExportErrorMessage}: $e')),
      );
    }
  }

  static Future<Uint8List?> _loadLogo() async {
    try {
      // Load a default Flutter logo as placeholder
      // In a real app, you'd load your actual logo
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      // Return null if logo not found
      return null;
    }
  }

  static pw.Widget _buildHeader(Uint8List? logoData, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logoData != null)
                pw.Image(
                  pw.MemoryImage(logoData),
                  width: 40,
                  height: 40,
                ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Project Management App',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                l10n.projectsReportTitle,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${l10n.generatedOnLabel}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle(AppLocalizations l10n) {
    return pw.Text(
      l10n.projectsReportTitle,
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue,
      ),
    );
  }

  static pw.Widget _buildFiltersSection(
    ProjectFilter filter,
    String searchQuery,
    AppLocalizations l10n,
  ) {
    final filters = <String>[];

    if (searchQuery.isNotEmpty) {
      filters.add('Search: "$searchQuery"');
    }

    if (filter.status != null) {
      filters.add('Status: ${filter.status}');
    }

    if (filter.priority != null) {
      filters.add('Priority: ${filter.priority}');
    }

    if (filter.tags != null && filter.tags!.isNotEmpty) {
      filters.add('Optional Tags: ${filter.tags!.join(", ")}');
    }

    if (filter.requiredTags != null && filter.requiredTags!.isNotEmpty) {
      filters.add('Required Tags: ${filter.requiredTags!.join(", ")}');
    }

    if (filter.startDate != null) {
      filters.add('Start Date: ${DateFormat('yyyy-MM-dd').format(filter.startDate!)}');
    }

    if (filter.dueDateStart != null) {
      filters.add('Due Date Start: ${DateFormat('yyyy-MM-dd').format(filter.dueDateStart!)}');
    }

    if (filter.dueDateEnd != null) {
      filters.add('Due Date End: ${DateFormat('yyyy-MM-dd').format(filter.dueDateEnd!)}');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.activeFiltersLabel,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          if (filters.isEmpty)
            pw.Text('No active filters', style: const pw.TextStyle(fontSize: 10))
          else
            ...filters.map((filter) => pw.Text(
              '• $filter',
              style: const pw.TextStyle(fontSize: 10),
            )),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(List<ProjectModel> projects, AppLocalizations l10n) {
    final totalProjects = projects.length;
    final completedProjects = projects.where((p) => p.status == 'Completed').length;
    final inProgressProjects = projects.where((p) => p.status == 'In Progress').length;
    final inReviewProjects = projects.where((p) => p.status == 'In Review').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.summaryLabel,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('${l10n.totalProjectsLabel}:', totalProjects.toString()),
              _buildSummaryItem('Completed:', completedProjects.toString()),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('In Progress:', inProgressProjects.toString()),
              _buildSummaryItem('In Review:', inReviewProjects.toString()),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildChartsSection(List<ProjectModel> projects, AppLocalizations l10n) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Charts & Analytics',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildPriorityChart(projects, l10n),
        pw.SizedBox(height: 20),
        _buildDueDatesChart(projects, l10n),
      ],
    );
  }

  static pw.Widget _buildPriorityChart(List<ProjectModel> projects, AppLocalizations l10n) {
    final priorityCounts = <String, int>{};
    for (final project in projects) {
      final priority = project.priority ?? 'Not Set';
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.priorityDistributionLabel,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          // Visual representation with colored bars
          ...priorityCounts.entries.map((entry) {
            final percentage = projects.isEmpty ? 0.0 : entry.value / projects.length;
            final color = _getPriorityColor(entry.key);
            return pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${entry.key}: ${entry.value} (${(percentage * 100).round()}%)',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 8,
                  width: 200 * percentage,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  static PdfColor _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return PdfColors.red;
      case 'medium':
        return PdfColors.orange;
      case 'low':
        return PdfColors.green;
      default:
        return PdfColors.grey;
    }
  }

  static pw.Widget _buildDueDatesChart(List<ProjectModel> projects, AppLocalizations l10n) {
    final dueDates = projects.where((p) => p.dueDate != null).toList();
    dueDates.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    if (dueDates.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(
          'No due dates set',
          style: const pw.TextStyle(fontSize: 12),
        ),
      );
    }

    // Group by weeks
    final now = DateTime.now();
    final weekLabels = <String>[];
    final weekCounts = <int>[];

    for (int i = 0; i < 4; i++) {
      final weekStart = now.add(Duration(days: i * 7));
      final count = dueDates.where((p) {
        final daysDiff = p.dueDate!.difference(weekStart).inDays;
        return daysDiff >= 0 && daysDiff <= 6;
      }).length;

      weekLabels.add('Week ${i + 1}');
      weekCounts.add(count);
    }

    final maxCount = weekCounts.isEmpty ? 1 : weekCounts.reduce((a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Due Dates by Week',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          // Bar chart representation
          ...List.generate(weekLabels.length, (index) {
            final count = weekCounts[index];
            final percentage = maxCount == 0 ? 0.0 : count / maxCount;
            return pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 80,
                      child: pw.Text(
                        weekLabels[index],
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      height: 12,
                      width: 150 * percentage,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      count.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
              ],
            );
          }),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total projects with due dates: ${dueDates.length}',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectsList(List<ProjectModel> projects, AppLocalizations l10n) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.projectListLabel,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Name', isHeader: true),
                _buildTableCell('Status', isHeader: true),
                _buildTableCell('Priority', isHeader: true),
                _buildTableCell('Progress', isHeader: true),
                _buildTableCell('Due Date', isHeader: true),
              ],
            ),
            // Data rows
            ...projects.map((project) => pw.TableRow(
              children: [
                _buildTableCell(project.name),
                _buildTableCell(project.status),
                _buildTableCell(project.priority ?? 'Not Set'),
                _buildTableCell('${project.progress.round()}%'),
                _buildTableCell(
                  project.dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(project.dueDate!)
                      : 'Not Set',
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static Future<void> _saveAndSharePdf(
    pw.Document pdf,
    AppLocalizations l10n,
    BuildContext context,
  ) async {
    try {
      // Get the PDF bytes
      final bytes = await pdf.save();

      // Get the downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'projects_report_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: l10n.projectsReportTitle,
      );

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfExportedMessage)),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.pdfExportErrorMessage}: $e')),
      );
    }
  }
}