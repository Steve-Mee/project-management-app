import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/widgets/error_boundary.dart';

void main() {
  testWidgets('ErrorBoundary shows child when no error occurs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ErrorBoundary(
        child: MaterialApp(
          home: Scaffold(
            body: Text('Healthy child'),
          ),
        ),
      ),
    );

    expect(find.text('Healthy child'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('ErrorBoundary.restartApp triggers restart callback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _RestartableHarness());
    expect(find.text('Restart count: 0'), findsOneWidget);

    await tester.tap(find.text('Trigger restart'));
    await tester.pump();

    expect(find.text('Restart count: 1'), findsOneWidget);
  });

  testWidgets('ErrorBoundary handles FlutterError and recovers on restart', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _RecoverableCrashHarness());

    // Consume the thrown FlutterError from the crashing child build.
    expect(tester.takeException(), isA<FlutterError>());
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('Error ID:'), findsOneWidget);
    expect(find.text('Restart App'), findsOneWidget);

    await tester.tap(find.text('Restart App'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered. Restart count: 1'), findsOneWidget);
  });
}

class _RestartableHarness extends StatefulWidget {
  const _RestartableHarness();

  @override
  State<_RestartableHarness> createState() => _RestartableHarnessState();
}

class _RestartableHarnessState extends State<_RestartableHarness> {
  int _restartCount = 0;

  Future<void> _onRestart() async {
    setState(() {
      _restartCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onRestart: _onRestart,
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              Text('Restart count: $_restartCount'),
              Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () => ErrorBoundary.restartApp(context),
                    child: const Text('Trigger restart'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoverableCrashHarness extends StatefulWidget {
  const _RecoverableCrashHarness();

  @override
  State<_RecoverableCrashHarness> createState() => _RecoverableCrashHarnessState();
}

class _RecoverableCrashHarnessState extends State<_RecoverableCrashHarness> {
  bool _shouldCrash = true;
  int _restartCount = 0;

  Future<void> _onRestart() async {
    setState(() {
      _shouldCrash = false;
      _restartCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onRestart: _onRestart,
      child: MaterialApp(
        home: Scaffold(
          body: _shouldCrash
              ? const _CrashOnBuild()
              : Text('Recovered. Restart count: $_restartCount'),
        ),
      ),
    );
  }
}

class _CrashOnBuild extends StatelessWidget {
  const _CrashOnBuild();

  @override
  Widget build(BuildContext context) {
    throw FlutterError('Intentional test crash from _CrashOnBuild');
  }
}
