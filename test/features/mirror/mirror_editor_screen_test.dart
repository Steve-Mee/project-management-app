import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';

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
    ],
    child: MaterialApp(
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

      expect(find.text('Mode:'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsWidgets);
      expect(find.text('Cloud'), findsWidgets);
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

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cloud').last);
      await tester.pump();

      expect(
        find.text('Cloud mode is beschikbaar voor premium gebruikers.'),
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
      expect(find.text('Waiting for realtime output...'), findsNothing);
    });
  });
}
