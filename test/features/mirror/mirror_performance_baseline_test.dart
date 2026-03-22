import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_apply_flow_coordinator.dart';
import 'package:project_management_app/features/mirror/services/mirror_service_boundaries.dart';

class _FakeTaskNotifier extends TaskNotifier {
  @override
  Future<List<Task>> build() async => const <Task>[];

  @override
  Future<void> loadTasks(String projectId) async {
    state = const AsyncValue.data(<Task>[]);
  }
}

class _FastOrchestrator implements MirrorExecutionOrchestrator {
  @override
  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(success: true, code: null);
  }

  @override
  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: true,
      output: 'void main() { print("ok"); }',
      serverVersionToken: 'v-bench',
    );
  }

  @override
  Future<ApplyResult> apply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    return const ApplyResult(
      success: true,
      appliedFiles: <String>['lib/main.dart'],
    );
  }
}

ProjectContext _benchmarkContext() {
  return const ProjectContext(
    projectId: '11111111-1111-4111-8111-111111111111',
    taskId: '22222222-2222-4222-8222-222222222222',
    files: <String, String>{'lib/main.dart': 'void main() {}'},
    metadata: ProjectContextMetadata(selectedFile: 'lib/main.dart'),
  );
}

double _percentile(List<int> sortedValues, double p) {
  if (sortedValues.isEmpty) return 0;
  final rank = ((p / 100) * (sortedValues.length - 1)).round();
  final index = max(0, min(rank, sortedValues.length - 1));
  return sortedValues[index].toDouble();
}

Map<String, double> _summarize(List<int> valuesMs) {
  final sorted = List<int>.from(valuesMs)..sort();
  return <String, double>{
    'p50': _percentile(sorted, 50),
    'p95': _percentile(sorted, 95),
    'p99': _percentile(sorted, 99),
    'avg': sorted.isEmpty
        ? 0
        : sorted.reduce((a, b) => a + b) / sorted.length,
  };
}

Future<WidgetRef> _captureRef(WidgetTester tester) async {
  WidgetRef? ref;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[tasksProvider.overrideWith(_FakeTaskNotifier.new)],
      child: Consumer(
        builder: (_, widgetRef, __) {
          ref = widgetRef;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return ref!;
}

void main() {
  group('Mirror performance baseline', () {
    testWidgets('apply flow coordinator baseline (compile+preview+validate+apply)',
        (WidgetTester tester) async {
      final ref = await _captureRef(tester);
      final coordinator = MirrorApplyFlowCoordinator();
      final orchestrator = _FastOrchestrator();
      final context = _benchmarkContext();
      final samples = <int>[];
      const iterations = 40;

      for (var i = 0; i < iterations; i += 1) {
        final sw = Stopwatch()..start();
        final result = await coordinator.executeApplyFlow(
          orchestrator: orchestrator,
          ref: ref,
          sessionKey: '${context.projectId}::${context.taskId}',
          prompt: 'void main() {}',
          context: context,
          mode: 'private',
          onStateChange: (_) {},
          onApprovalRequired: (_) async => true,
        );
        sw.stop();
        expect(result.success, isTrue);
        samples.add(sw.elapsedMilliseconds);
      }

      final summary = _summarize(samples);
      // Keep the assertion broad to avoid machine-specific flakiness.
      expect(summary['p95']!, lessThan(4000));
      // Emitted for Task 4.5.4 baseline capture.
      // ignore: avoid_print
      print('PERF_BASELINE coordinator_apply_ms p50=${summary['p50']} p95=${summary['p95']} p99=${summary['p99']} avg=${summary['avg']} n=$iterations');
    });

    test('gateway backend baseline (compile/apply transport path)', () async {
      final mockClient = MockClient((http.Request request) async {
        if (request.url.path.endsWith('/compile')) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return http.Response(
            '{"success":true,"output":"void main() { print(\\"ok\\"); }"}',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 35));
        return http.Response(
          '{"success":true,"files":{"lib/main.dart":"void main() { print(\\"ok\\"); }"}}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        httpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/compile',
        applyHttpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/apply',
        useSecureApply: false,
      );

      final context = _benchmarkContext();
      final compileSamples = <int>[];
      final applySamples = <int>[];
      const iterations = 30;

      for (var i = 0; i < iterations; i += 1) {
        final swCompile = Stopwatch()..start();
        final compile = await backend.compile(
          prompt: 'compile prompt',
          context: context,
          mode: 'private',
        );
        swCompile.stop();
        expect(compile.success, isTrue);
        compileSamples.add(swCompile.elapsedMilliseconds);

        final swApply = Stopwatch()..start();
        final apply = await backend.apply(
          prompt: 'apply prompt',
          context: context,
          mode: 'private',
        );
        swApply.stop();
        expect(apply.success, isTrue);
        applySamples.add(swApply.elapsedMilliseconds);
      }

      final compileSummary = _summarize(compileSamples);
      final applySummary = _summarize(applySamples);
      expect(compileSummary['p95']!, lessThan(4000));
      expect(applySummary['p95']!, lessThan(5000));
      // ignore: avoid_print
      print('PERF_BASELINE gateway_compile_ms p50=${compileSummary['p50']} p95=${compileSummary['p95']} p99=${compileSummary['p99']} avg=${compileSummary['avg']} n=$iterations');
      // ignore: avoid_print
      print('PERF_BASELINE gateway_apply_ms p50=${applySummary['p50']} p95=${applySummary['p95']} p99=${applySummary['p99']} avg=${applySummary['avg']} n=$iterations');
    });
  });
}
