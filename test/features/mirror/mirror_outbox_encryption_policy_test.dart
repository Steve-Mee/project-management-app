// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_management_app/core/services/mirror_premium_service.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/services/mirror_outbox_replay_service.dart';

class _FakeRef implements Ref {
  _FakeRef(this._container);

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
      'mirror_outbox_encryption_policy_test_',
    );
    Hive.init(hiveDir.path);
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

  group('MirrorPremiumService outbox encryption policy', () {
    test('defaults fail-closed in production mode', () {
      final service = MirrorPremiumService(productionMode: true);

      expect(service.shouldFailClosedOnOutboxEncryptionError(), isTrue);
    });

    test('defaults fail-open outside production mode', () {
      final service = MirrorPremiumService(productionMode: false);

      expect(service.shouldFailClosedOnOutboxEncryptionError(), isFalse);
    });

    test('explicit override can force fail-closed outside production', () {
      final service = MirrorPremiumService(
        productionMode: false,
        outboxFailClosedOnEncryptionError: true,
      );

      expect(service.shouldFailClosedOnOutboxEncryptionError(), isTrue);
    });

    test('explicit override can force fail-open in production', () {
      final service = MirrorPremiumService(
        productionMode: true,
        outboxFailClosedOnEncryptionError: false,
      );

      expect(service.shouldFailClosedOnOutboxEncryptionError(), isFalse);
    });
  });

  group('MirrorOutboxReplayService encryption policy matrix', () {
    test('fail-closed throws when encrypted box open fails', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = _FakeRef(container);

      var fallbackCalled = false;
      final service = MirrorOutboxReplayService(
        ref: ref,
        failClosedOnEncryptionError: true,
        encryptedBoxOpener: () async {
          throw StateError('encryption unavailable');
        },
        unencryptedBoxOpener: () async {
          fallbackCalled = true;
          return Hive.openBox<Map<dynamic, dynamic>>('mirror_outbox');
        },
      );

      await expectLater(
        () => service.enqueue(
          operation: 'generate',
          sessionKey: 'project::task',
          prompt: 'Secure replay',
          context: _context(),
          mode: 'private',
        ),
        throwsA(isA<MirrorOutboxEncryptionException>()),
      );

      expect(fallbackCalled, isFalse);
    });

    test('fail-open falls back to unencrypted box when encryption fails',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = _FakeRef(container);

      var fallbackCalled = false;
      final service = MirrorOutboxReplayService(
        ref: ref,
        failClosedOnEncryptionError: false,
        encryptedBoxOpener: () async {
          throw StateError('encryption unavailable');
        },
        unencryptedBoxOpener: () async {
          fallbackCalled = true;
          return Hive.openBox<Map<dynamic, dynamic>>('mirror_outbox');
        },
      );

      await service.enqueue(
        operation: 'generate',
        sessionKey: 'project::task',
        prompt: 'Fallback replay',
        context: _context(),
        mode: 'private',
      );

      expect(fallbackCalled, isTrue);
      expect(service.queuedEntries, hasLength(1));
    });
  });
}

ProjectContext _context() {
  return const ProjectContext(
    projectId: 'project',
    taskId: 'task',
    files: <String, String>{'lib/main.dart': 'void main() {}'},
    metadata: ProjectContextMetadata(branch: 'security-test'),
  );
}
