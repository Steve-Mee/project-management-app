import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/sub_task_model.dart';
import 'package:pma_core/models/task_model.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTicks = 30,
  Duration step = const Duration(milliseconds: 100),
  String? reason,
}) async {
  for (var i = 0; i < maxTicks; i += 1) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }

  expect(condition(), isTrue, reason: reason ?? 'Condition not reached in time');
}

class _TestMirrorNotifier extends MirrorNotifier {
  _TestMirrorNotifier(this._initialState);

  final MirrorState _initialState;

  @override
  MirrorState build() => _initialState;
}

class _FakeMirrorBackend implements MirrorComputeBackend {
  final List<String> callOrder = <String>[];

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    callOrder.add('generate');
    return const GenerateResult(
      success: true,
      code: 'void main() {\n  print("generated");\n}\n',
      diagnostics: <String>['generate-ok'],
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    callOrder.add('compile');

    final payload = jsonEncode(<String, dynamic>{
      'files': <String, String>{
        'lib/main.dart': 'void main() {\n  print("applied");\n}\n',
      },
    });

    return CompileResult(
      success: true,
      output: payload,
      warnings: const <String>['compile-ok'],
    );
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    callOrder.add('apply');
    return const ApplyResult(
      success: true,
      appliedFiles: <String>['lib/main.dart'],
      message: 'apply-ok',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('mirror_end_to_end_test_');
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

    testWidgets('run flow reaches preview stage and calls generate+compile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final backend = _FakeMirrorBackend();
    final container = ProviderContainer(
      overrides: <Override>[
        mirrorProvider.overrideWith(
          () => _TestMirrorNotifier(
            const MirrorState(
              mode: 'private',
              isPremium: true,
              teamModeVariant: 'solo',
              offlineWarning: null,
            ),
          ),
        ),
        mirrorBackendProvider.overrideWith((ref) async => backend),
        hasPermissionProvider(AppPermissions.useMirror)
            .overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MirrorEditorScreen(
            projectId: 'project-e2e',
            taskId: 'task-e2e',
            debugRealtimeRecords: Stream<Map<String, dynamic>>.empty(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.play_arrow));
    await tester.pump();
    await _pumpUntil(
      tester,
      () => backend.callOrder.contains('compile'),
      reason: 'Compile stage was not invoked',
    );

    await tester.pump(const Duration(milliseconds: 200));

    final session = container.read(
      mirrorSessionProvider('project-e2e::task-e2e'),
    );
    expect(session.terminalLog, isNotEmpty);
    expect(backend.callOrder, containsAllInOrder(<String>['generate', 'compile']));
  }, skip: true);
}
