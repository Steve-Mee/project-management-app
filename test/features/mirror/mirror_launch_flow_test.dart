import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror launch flow contract', () {
    test('project and task entry points use the same launch coordinator path', () {
      final projectDetailSource = _readRepoFile(
        'lib/features/project/project_detail_screen.dart',
      );
      final taskCardSource = _readRepoFile(
        'lib/features/project/expandable_task_card.dart',
      );

      expect(projectDetailSource, contains('openMirrorFromTask('));
      expect(taskCardSource, contains('openMirrorFromTask('));

      expect(projectDetailSource, contains("preferredMode: 'private'"));
      expect(taskCardSource, contains("preferredMode: 'private'"));

      expect(
        projectDetailSource,
        contains('AppRoutes.mirrorEditorPath(payload.projectId, payload.taskId)'),
      );
      expect(
        taskCardSource,
        contains('AppRoutes.mirrorEditorPath(payload.projectId, payload.taskId)'),
      );

      expect(projectDetailSource, contains('mirrorLaunchFailureMessage('));
      expect(taskCardSource, contains('mirrorLaunchFailureMessage('));
      expect(
        projectDetailSource,
        contains('package:project_management_app/features/mirror/mirror_launch_feedback.dart'),
      );
      expect(
        taskCardSource,
        contains('package:project_management_app/features/mirror/mirror_launch_feedback.dart'),
      );
    });

    test('ai bridge routes through the same launch coordinator', () {
      final aiBridgeSource = _readRepoFile('lib/core/providers/ai_chat_provider.dart');
      final launchCoordinatorSource = _readRepoFile(
        'lib/features/mirror/services/mirror_launch_coordinator.dart',
      );

      expect(aiBridgeSource, contains('mirrorLaunchCoordinatorProvider'));
      expect(aiBridgeSource, contains('openMirrorFromTask('));
      expect(aiBridgeSource, contains('Future<MirrorLaunchResult> openMirrorFromTask'));
      expect(aiBridgeSource, contains('state = result.payload;'));

      expect(launchCoordinatorSource, contains('resolveMirrorFeatureEnabled'));
      expect(launchCoordinatorSource, contains('hasPermissionProvider(AppPermissions.useMirror)'));
      expect(launchCoordinatorSource, contains('setMode(safeMode)'));
      expect(launchCoordinatorSource, contains('MirrorLaunchResult.featureDisabled'));
      expect(launchCoordinatorSource, contains('MirrorLaunchResult.launchedWithDowngrade'));
    });

    test('launch guard sequencing is feature flag first then permission', () {
      final guardSource = _readRepoFile(
        'lib/features/mirror/providers/mirror_route_guard_provider.dart',
      );

      final featureCheckIndex = guardSource.indexOf('resolveMirrorFeatureEnabled');
      final featureReturnIndex = guardSource.indexOf('return MirrorRouteGuardResult.featureDisabled');
      final permissionCheckIndex = guardSource.indexOf('hasPermissionProvider(AppPermissions.useMirror)');
      final permissionReturnIndex = guardSource.indexOf('return MirrorRouteGuardResult.permissionDenied');

      expect(featureCheckIndex, isNonNegative);
      expect(permissionCheckIndex, isNonNegative);
      expect(featureReturnIndex, greaterThan(featureCheckIndex));
      expect(permissionCheckIndex, greaterThan(featureReturnIndex));
      expect(permissionReturnIndex, greaterThan(permissionCheckIndex));
    });

    test('route builder enforces guard outcomes before opening editor', () {
      final routesSource = _readRepoFile('lib/core/routes.dart');

      expect(routesSource, contains('switch (guard)'));
      expect(routesSource, contains('case MirrorRouteGuardResult.featureDisabled:'));
      expect(routesSource, contains('l10n.mirrorFeatureDisabled'));
      expect(routesSource, contains('case MirrorRouteGuardResult.permissionDenied:'));
      expect(routesSource, contains('l10n.mirrorPermissionDenied'));
      expect(routesSource, contains('l10n.mirrorUnavailableForAccount'));
      expect(routesSource, contains('case MirrorRouteGuardResult.allowed:'));
      expect(routesSource, contains('return MirrorEditorScreen('));
    });

    test('deeplink path validates project and task ids as UUIDs', () {
      final intentSource = _readRepoFile('lib/core/mirror_route_intent.dart');
      final routesSource = _readRepoFile('lib/core/routes.dart');

      expect(intentSource, contains('_uuidV4LikePattern'));
      expect(intentSource, contains('isValidMirrorContextId(projectId)'));
      expect(intentSource, contains('isValidMirrorContextId(taskId)'));

      expect(routesSource, contains('!isValidMirrorContextId(projectId)'));
      expect(routesSource, contains('!isValidMirrorContextId(taskId)'));
      expect(
        routesSource,
        contains('Invalid Mirror link: project and task IDs must be valid UUIDs.'),
      );
    });
  });
}

String _readRepoFile(String relativePath) {
  final direct = File(relativePath);
  if (direct.existsSync()) {
    return direct.readAsStringSync();
  }

  final fromTestDir = File('test/$relativePath');
  if (fromTestDir.existsSync()) {
    return fromTestDir.readAsStringSync();
  }

  final fromParent = File('../$relativePath');
  if (fromParent.existsSync()) {
    return fromParent.readAsStringSync();
  }

  throw StateError('Unable to locate file for contract test: $relativePath');
}