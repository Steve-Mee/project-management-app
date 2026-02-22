import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Example dashboard toolbar with undo/redo buttons
/// Demonstrates usage of DashboardConfigNotifier undo/redo API
/// See .github/issues/022-dashboard-undo-redo.md for details
class DashboardToolbar extends ConsumerWidget {
  const DashboardToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardConfigProvider.notifier);
    final canUndo = ref.watch(dashboardConfigProvider.notifier).canUndo;
    final canRedo = ref.watch(dashboardConfigProvider.notifier).canRedo;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: canUndo ? () => notifier.undo() : null,
          icon: const Icon(Icons.undo),
          tooltip: l10n.undoTooltip,
        ),
        IconButton(
          onPressed: canRedo ? () => notifier.redo() : null,
          icon: const Icon(Icons.redo),
          tooltip: l10n.redoTooltip,
        ),
      ],
    );
  }
}