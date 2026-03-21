import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/repository/hive_initializer.dart' as core_hive;

import 'package:project_management_app/features/mirror/providers/mirror_route_guard_provider.dart';

class ProjectsInitializer extends ConsumerWidget {
  const ProjectsInitializer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialRoute = WidgetsBinding
        .instance.platformDispatcher.defaultRouteName
        .toLowerCase();
    final mirrorRequested = initialRoute.contains('mirror');

    if (mirrorRequested) {
      // Guard is enforced inside the GoRoute builder via mirrorRouteGuardProvider.
      // Here we only need Hive initialised before GoRouter renders the route.
      final guardAsync = ref.watch(mirrorRouteGuardProvider);
      return guardAsync.when(
        loading: () => const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (_, __) => const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Mirror is currently unavailable.')),
          ),
        ),
        data: (_) => core_hive.ProjectsInitializer(child: child),
      );
    }

    return core_hive.ProjectsInitializer(child: child);
  }
}
