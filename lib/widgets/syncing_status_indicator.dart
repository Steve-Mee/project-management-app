import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Syncing Status Widget
///
/// Displays a status indicator when the app is syncing offline changes.
/// Shows "Syncing requirements..." text with a loading spinner.
/// Automatically hides when sync completes.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppBar(
///     title: Text('My App'),
///     actions: [
///       SyncingStatusIndicator(),
///     ],
///   ),
///   body: MyContent(),
/// )
/// ```
///
/// Or as a floating overlay:
/// ```dart
/// Stack(
///   children: [
///     MyContent(),
///     Positioned(
///       top: 10,
///       right: 10,
///       child: SyncingStatusIndicator(),
///     ),
///   ],
/// )
/// ```
class SyncingStatusIndicator extends ConsumerWidget {
  const SyncingStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(offlineSyncStatusProvider);

    if (!isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.syncing_requirements,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}