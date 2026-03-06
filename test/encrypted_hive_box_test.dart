import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:pma_core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const storage = FlutterSecureStorage();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('encrypted_hive_box_test_');
    Hive.init(tempDir.path);
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('EncryptedHiveBox', () {
    test('sensitive box data is not stored as plaintext on disk', () async {
      final encryptedBox = EncryptedHiveBox<String>(
        boxName: 'auth',
        encryptionKey: 'hive_encryption_key_auth',
      );
      final box = await encryptedBox.open();
      await box.put('token', 'secret-token');
      await box.close();

      final hiveFiles = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().contains('auth'))
          .toList();
      expect(hiveFiles, isNotEmpty);

      final bytes = await hiveFiles.first.readAsBytes();
      expect(
        _containsSequence(bytes, utf8.encode('secret-token')),
        isFalse,
      );
    });

    test('encrypted box still supports read and write', () async {
      final encryptedBox = EncryptedHiveBox<String>(
        boxName: 'settings',
        encryptionKey: 'hive_encryption_key_settings',
      );

      final box = await encryptedBox.open();
      await box.put('theme', 'dark');
      await box.close();

      final reopened = await encryptedBox.open();
      expect(reopened.get('theme'), 'dark');
    });

    test('encryption key is stored securely and not exposed in box data', () async {
      final encryptedBox = EncryptedHiveBox<String>(
        boxName: 'ai_usage',
        encryptionKey: 'hive_encryption_key_ai_usage',
      );

      final box = await encryptedBox.open();
      await box.put('entry', 'usage-data');

      final storedKey = await storage.read(key: 'hive_encryption_key_ai_usage');
      expect(storedKey, isNotNull);
      expect(storedKey, isNotEmpty);
      expect(base64Url.decode(storedKey!).length, 32);

      // The encryption key alias itself should not be persisted as box content.
      expect(box.containsKey('hive_encryption_key_ai_usage'), isFalse);
      expect(box.values.contains(storedKey), isFalse);
    });
  });

  group('SecureStorageService', () {
    test('getOrCreateEncryptionKey creates and reuses the same key', () async {
      final service = SecureStorageService(
        secureStorage: storage,
        encryptionKeyStorageName: 'hive_encryption_key_local_tokens',
      );

      final first = await service.getOrCreateEncryptionKey();
      final second = await service.getOrCreateEncryptionKey();

      expect(first, isNotEmpty);
      expect(second, first);
      expect(base64Url.decode(first).length, 32);
    });
  });
}

bool _containsSequence(List<int> source, List<int> sequence) {
  if (sequence.isEmpty || source.length < sequence.length) {
    return false;
  }
  for (var i = 0; i <= source.length - sequence.length; i++) {
    var match = true;
    for (var j = 0; j < sequence.length; j++) {
      if (source[i + j] != sequence[j]) {
        match = false;
        break;
      }
    }
    if (match) {
      return true;
    }
  }
  return false;
}
