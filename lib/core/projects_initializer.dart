import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/repository/hive_initializer.dart' as core_hive;

class ProjectsInitializer extends ConsumerWidget {
  const ProjectsInitializer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUseMirror = ref.watch(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    final mirrorEnabled = ref.watch(featureFlagProvider).maybeWhen(
      data: (flags) => FeatureFlagResolver.isEnabled(
        flags,
        'mirror_enabled',
        defaultValue: true,
      ),
      orElse: () => true,
    );
    final initialRoute = WidgetsBinding
        .instance.platformDispatcher.defaultRouteName
        .toLowerCase();
    final mirrorRequested = initialRoute.contains('mirror');

    if (mirrorRequested && !mirrorEnabled) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mirror is currently disabled.'),
          ),
        ),
      );
    }

    if (mirrorRequested && !canUseMirror) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Geen toegang tot Mirror voor deze gebruiker.'),
          ),
        ),
      );
    }

    return core_hive.ProjectsInitializer(child: child);
  }
}
