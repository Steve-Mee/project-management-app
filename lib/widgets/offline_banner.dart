import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_project_management_app/core/providers/connectivity_provider.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Offline Banner Widget
///
/// Displays a banner at the top of the screen when the app is offline.
/// Uses the connectivityProvider to monitor network status.
/// Automatically hides when connectivity is restored.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: Text('My App')),
///   body: Column(
///     children: [
///       OfflineBanner(), // Add this at the top of your body
///       Expanded(child: MyContent()),
///     ],
///   ),
/// )
/// ```
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (connectivity) {
        final isOffline = connectivity == ConnectivityResult.none;

        if (!isOffline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: Colors.orange.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.orange.shade800,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.offline_mode,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}