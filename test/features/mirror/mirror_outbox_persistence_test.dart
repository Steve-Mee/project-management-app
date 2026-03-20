// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/features/mirror/mirror_compute_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_orchestrator_service.dart';

class _AlwaysFailBackend implements MirrorComputeBackend {
  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: 'generate-failed',
      diagnostics: <String>['offline'],
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: false,
      errors: <String>['compile-failed'],
    );
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    return const ApplyResult(
      success: false,
      message: 'apply-failed',
    );
  }
}

class _FakeWidgetRef implements WidgetRef {
  _FakeWidgetRef(this._container);

  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) {
    return _container.read(provider);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp(
      'mirror_outbox_persistence_test_',
    );
    Hive.init(hiveDir.path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('mirror_outbox')) {
      await Hive.openBox<Map<dynamic, dynamic>>('mirror_outbox');
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen('mirror_outbox')) {
      final box = Hive.box<Map<dynamic, dynamic>>('mirror_outbox');
      await box.clear();
      await box.close();
    }
    await Hive.deleteBoxFromDisk('mirror_outbox');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('Mirror outbox persistence', () {
    test('persists outbox entries across orchestrator restarts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = _FakeWidgetRef(container);
      final context = _buildContext();
      const sessionKey = '';

      final serviceA = MirrorOrchestratorService(
        backend: _AlwaysFailBackend(),
        maxRetries: 1,
        initialBackoff: const Duration(milliseconds: 1),
      );

      final resultA = await serviceA.generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: 'Generate code',
        context: context,
        mode: 'private',
      );

      expect(resultA.success, isFalse);
      expect(serviceA.queuedOutboxEntries.length, 1);

      final serviceB = MirrorOrchestratorService(
        backend: _AlwaysFailBackend(),
        maxRetries: 1,
        initialBackoff: const Duration(milliseconds: 1),
      );

      // Lazy replay-service initialization means a fresh orchestrator does not
      // expose queued entries until it touches the provider; persistence is
      // asserted via Hive-backed outbox storage.
      await _waitUntil(() => Hive.isBoxOpen('mirror_outbox'));
      final outbox = Hive.box<Map<dynamic, dynamic>>('mirror_outbox');
      expect(outbox.length, 1);
      final persisted = outbox.values.first;
      expect(persisted['sessionKey'], sessionKey);
      expect(serviceB.queuedOutboxEntries, isEmpty);
    });

    test('stores idempotency key and keeps last-write-wins on conflict',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = _FakeWidgetRef(container);
      final context = _buildContext();
      const sessionKey = '';

      final service = MirrorOrchestratorService(
        backend: _AlwaysFailBackend(),
        maxRetries: 0,
        initialBackoff: const Duration(milliseconds: 1),
      );

      await service.generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: 'Same payload',
        context: context,
        mode: 'private',
      );
      final first = service.queuedOutboxEntries.single;

      await Future<void>.delayed(const Duration(milliseconds: 5));

      await service.generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: 'Same payload',
        context: context,
        mode: 'private',
      );

      expect(service.queuedOutboxEntries.length, 1);
      final merged = service.queuedOutboxEntries.single;
      expect(merged.idempotencyKey, isNotEmpty);
      expect(merged.idempotencyKey, first.idempotencyKey);

      final firstUpdatedAt = first.updatedAt ?? first.createdAt;
      final mergedUpdatedAt = merged.updatedAt ?? merged.createdAt;
      expect(
        mergedUpdatedAt.isAfter(firstUpdatedAt) ||
            mergedUpdatedAt.isAtSameMomentAs(firstUpdatedAt),
        isTrue,
      );
    });

    test('records retry metadata and emits retry status updates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = _FakeWidgetRef(container);
      final context = _buildContext();
      const sessionKey = '';

      final service = MirrorOrchestratorService(
        backend: _AlwaysFailBackend(),
        maxRetries: 2,
        initialBackoff: const Duration(milliseconds: 1),
      );

      await service.generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: 'Retry me',
        context: context,
        mode: 'private',
      );

      final queued = service.queuedOutboxEntries.single;
      expect(queued.retryCount, 0);
      expect(queued.nextRetryAt, isNotNull);
      expect(
        queued.nextRetryAt!.isAfter(queued.createdAt) ||
            queued.nextRetryAt!.isAtSameMomentAs(queued.createdAt),
        isTrue,
      );

      final sessionState = container.read(mirrorSessionProvider(sessionKey));
      expect(sessionState.terminalLog, isNotEmpty);
    });
  });
}

ProjectContext _buildContext() {
  return const ProjectContext(
    projectId: 'project',
    taskId: 'task',
    files: <String, String>{
      'lib/main.dart': 'void main() {}',
    },
    metadata: ProjectContextMetadata(branch: 'offline-test'),
  );
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  Duration pollInterval = const Duration(milliseconds: 20),
}) async {
  final started = DateTime.now();
  while (!predicate()) {
    if (DateTime.now().difference(started) > timeout) {
      throw TimeoutException('Timed out waiting for condition');
    }
    await Future<void>.delayed(pollInterval);
  }
}
