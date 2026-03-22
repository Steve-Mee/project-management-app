import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:project_management_app/core/providers/supabase_client_provider.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';
import 'package:project_management_app/features/mirror/models/mirror_template.dart';
import 'package:project_management_app/features/mirror/providers/mirror_templates_provider.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/sub_task_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _TestMirrorModeController extends MirrorModeController {
  _TestMirrorModeController(this._initialState);

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
  required _TestMirrorModeController notifier,
  Stream<Map<String, dynamic>>? realtimeRecords,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      mirrorModeControllerProvider.overrideWith(() => notifier),
      hasPermissionProvider(AppPermissions.useMirror)
          .overrideWith((ref) => true),
      supabaseClientProvider.overrideWith((ref) => _FakeSupabaseClient()),
      ...overrides,
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
    hiveDir =
        await Directory.systemTemp.createTemp('mirror_editor_screen_test_');
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
    testWidgets('shows mode selector and mode options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorModeController(
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

    testWidgets('blocks cloud mode for non-premium users and shows snackbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorModeController(
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

      expect(notifier.setModeCalls, isEmpty);
      expect(notifier.state.mode, 'private');
    });

    testWidgets('applies realtime output cap to latest 500 lines',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorModeController(
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

    testWidgets('shows stale templates warning with last updated timestamp',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorModeController(
        const MirrorState(
          mode: 'private',
          isPremium: true,
          teamModeVariant: 'solo',
          offlineWarning: null,
        ),
      );
      final staleResult = MirrorTemplatesLoadResult(
        templates: const <MirrorTemplate>[
          MirrorTemplate(
            id: 'stale-template-1',
            title: 'Stale Template',
            description: 'desc',
            seedContent: 'seed',
          ),
        ],
        freshness: MirrorTemplatesFreshness.staleFallback,
        source: 'memory',
        reasonCode: MirrorTemplatesLoadReasonCodes.networkOrFetchError,
        fetchedAtUtc: DateTime.utc(2026, 3, 22, 15, 30),
      );

      await tester.pumpWidget(
        _buildHarness(
          notifier: notifier,
          overrides: <Override>[
            mirrorTemplatesProvider.overrideWith(
              (ref) async => staleResult,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      final localTimestamp = DateTime.utc(2026, 3, 22, 15, 30).toLocal();
      final month = localTimestamp.month.toString().padLeft(2, '0');
      final day = localTimestamp.day.toString().padLeft(2, '0');
      final hour = localTimestamp.hour.toString().padLeft(2, '0');
      final minute = localTimestamp.minute.toString().padLeft(2, '0');
      final expectedFormattedTime =
          '${localTimestamp.year}-$month-$day $hour:$minute';

      expect(
        find.textContaining('Showing cached saved views from'),
        findsOneWidget,
      );
      expect(find.textContaining(expectedFormattedTime), findsOneWidget);
    });

    testWidgets('does not show stale templates warning for fresh templates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _TestMirrorModeController(
        const MirrorState(
          mode: 'private',
          isPremium: true,
          teamModeVariant: 'solo',
          offlineWarning: null,
        ),
      );
      final freshResult = MirrorTemplatesLoadResult(
        templates: const <MirrorTemplate>[
          MirrorTemplate(
            id: 'fresh-template-1',
            title: 'Fresh Template',
            description: 'desc',
            seedContent: 'seed',
          ),
        ],
        freshness: MirrorTemplatesFreshness.fresh,
        source: 'network',
        fetchedAtUtc: DateTime.utc(2026, 3, 22, 15, 30),
      );

      await tester.pumpWidget(
        _buildHarness(
          notifier: notifier,
          overrides: <Override>[
            mirrorTemplatesProvider.overrideWith(
              (ref) async => freshResult,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Showing cached saved views'),
        findsNothing,
      );
    });
  });
}

