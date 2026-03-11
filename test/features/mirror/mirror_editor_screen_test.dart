import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/sub_task_model.dart';
import 'package:pma_core/models/task_model.dart';

class _TestMirrorNotifier extends MirrorNotifier {
  _TestMirrorNotifier(this._initialState);

  final MirrorState _initialState;
  final List<String> setModeCalls = <String>[];

  @override
  MirrorState build() => _initialState;

  @override
  Future<void> setMode(String mode) async {
    setModeCalls.add(mode);
    state = state.copyWith(mode: mode);
  }
}

Widget _buildHarness({
  required _TestMirrorNotifier notifier,
  Stream<Map<String, dynamic>>? realtimeRecords,
}) {
  return ProviderScope(
    overrides: <Override>[
      mirrorProvider.overrideWith(() => notifier),
      hasPermissionProvider(AppPermissions.useMirror)
          .overrideWith((ref) => true),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MirrorEditorScreen(
        projectId: 'project-1',
        taskId: 'task-1',
        debugRealtimeRecords:
            realtimeRecords ?? const Stream<Map<String, dynamic>>.empty(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('mirror_editor_screen_test_');
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

  group('MirrorEditorScreen widget tests', () {
    testWidgets('shows mode selector and mode options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      final element = tester.element(find.byType(MirrorEditorScreen));
      final l10n = AppLocalizations.of(element)!;

      expect(find.text(l10n.mirrorModeLabel), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mirrorPrivateMode), findsWidgets);
      expect(find.text(l10n.mirrorCloudMode), findsWidgets);
    });

    testWidgets('blocks cloud mode for non-premium users and shows snackbar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorNotifier(
        const MirrorState(
          mode: 'private',
          isPremium: false,
          teamModeVariant: 'solo',
          offlineWarning: null,
        ),
      );

      await tester.pumpWidget(_buildHarness(notifier: notifier));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(MirrorEditorScreen));
      final l10n = AppLocalizations.of(element)!;

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.mirrorCloudMode).last);
      await tester.pump();

      expect(
        find.text(l10n.mirrorCloudPremiumOnly),
        findsOneWidget,
      );
      expect(notifier.setModeCalls, isEmpty);
    });

    testWidgets('applies realtime output cap to latest 500 lines', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorNotifier(
        const MirrorState(
          mode: 'private',
          isPremium: true,
          teamModeVariant: 'solo',
          offlineWarning: null,
        ),
      );

      final records = StreamController<Map<String, dynamic>>();
      addTearDown(records.close);

      await tester.pumpWidget(
        _buildHarness(
          notifier: notifier,
          realtimeRecords: records.stream,
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 510; i++) {
        records.add(<String, dynamic>{
          'task_id': 'task-1',
          'versions': <Map<String, dynamic>>[
            <String, dynamic>{'output': 'line $i'},
          ],
        });
      }
      await tester.pumpAndSettle();

      final capped = mergeLiveOutputWithCap(
        currentLines: <String>[],
        incomingLines: List<String>.generate(510, (int i) => 'line $i'),
      );

      expect(capped.length, 500);
      expect(capped.first, 'line 10');
      expect(capped.last, 'line 509');
    });
  });
}
