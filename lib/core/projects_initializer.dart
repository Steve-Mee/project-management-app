import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/repository/hive_initializer.dart' as core_hive;

import 'providers/mirror_feature_flag_provider.dart';

final mirrorDeeplinkEnabledProvider = FutureProvider<bool>((ref) {
  return resolveMirrorFeatureEnabled(ref, useWatch: true);
});

class ProjectsInitializer extends ConsumerWidget {
  const ProjectsInitializer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canUseMirror = ref.watch(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    final mirrorEnabledAsync = ref.watch(mirrorDeeplinkEnabledProvider);
    final initialRoute = WidgetsBinding
        .instance.platformDispatcher.defaultRouteName
        .toLowerCase();
    final mirrorRequested = initialRoute.contains('mirror');

    if (mirrorRequested) {
      return mirrorEnabledAsync.when(
        data: (mirrorEnabled) {
          if (!mirrorEnabled) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text(
                    l10n?.mirrorUnavailableForAccount ??
                        'Mirror is currently disabled.',
                  ),
                ),
              ),
            );
          }

          if (!canUseMirror) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Geen toegang tot Mirror voor deze gebruiker.'),
                ),
              ),
            );
          }

          return core_hive.ProjectsInitializer(child: child);
        },
        loading: () => const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (_, __) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                l10n?.mirrorUnavailableForAccount ??
                    'Mirror is currently disabled.',
              ),
            ),
          ),
        ),
      );
    }

    return core_hive.ProjectsInitializer(child: child);
  }
}
