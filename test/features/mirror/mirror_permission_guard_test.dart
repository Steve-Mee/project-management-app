import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/sub_task_model.dart';
import 'package:pma_core/models/task_model.dart';

class _TestMirrorNotifier extends MirrorNotifier {
  _TestMirrorNotifier(this._initialState);

  final MirrorState _initialState;

  @override
  MirrorState build() => _initialState;
}

Widget _buildHarness({
  required MirrorNotifier notifier,
}) {
  return ProviderScope(
    overrides: <Override>[
      mirrorProvider.overrideWith(() => notifier),
      hasPermissionProvider(AppPermissions.useMirror)
          .overrideWith((ref) => false),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MirrorEditorScreen(
        projectId: 'project-1',
        taskId: 'task-1',
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp(
      'mirror_permission_guard_test_',
    );
    Hive.init(hiveDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter<ProjectModel>(ProjectModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter<TaskStatus>(TaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter<Task>(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter<CommentModel>(CommentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter<SubTask>(SubTaskAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets('blocks direct mirror screen opening without use_mirror permission',
      (WidgetTester tester) async {
    final notifier = _TestMirrorNotifier(
      const MirrorState(
        mode: 'private',
        isPremium: true,
        teamModeVariant: 'solo',
        offlineWarning: null,
      ),
    );

    await tester.pumpWidget(_buildHarness(notifier: notifier));
    await tester.pumpAndSettle();

    expect(
      find.text('Mirror is not available for your account.'),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsOneWidget);
  });
}
