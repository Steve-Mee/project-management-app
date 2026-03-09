import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/mirror_editor_screen.dart';

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

  testWidgets('run to apply end-to-end updates session and calls orchestrator stages',
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
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MirrorEditorScreen(
            projectId: 'project-e2e',
            taskId: 'task-e2e',
            debugRealtimeRecords: Stream<Map<String, dynamic>>.empty(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Apply wijzigingen'), findsOneWidget);

    await tester.tap(find.text('Ik begrijp het risico van direct toepassen'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ja, toepassen'));
    await tester.pumpAndSettle();

    final session = container.read(
      mirrorSessionProvider('project-e2e::task-e2e'),
    );

    expect(session.files['lib/main.dart'], contains('print("applied")'));
    expect(
      session.terminalLog.any((line) => line.contains('Mirror run completed successfully.')),
      isTrue,
    );
    expect(backend.callOrder, <String>['generate', 'compile', 'apply']);
  });
}
