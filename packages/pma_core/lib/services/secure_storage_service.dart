import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pma_core/services/app_logger.dart';

/// Helper for securely managing encryption material in platform secure storage.
///
/// Issue reference: .github/issues/062-hive-encryption.md
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? secureStorage,
    this.encryptionKeyStorageName = 'hive_encryption_key',
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final String encryptionKeyStorageName;

  static const int _keyLengthBytes = 32;

  Future<String> getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: encryptionKeyStorageName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final key = encrypt.Key.fromSecureRandom(_keyLengthBytes);
    final encoded = base64UrlEncode(key.bytes);
    await _secureStorage.write(
      key: encryptionKeyStorageName,
      value: encoded,
    );

    AppLogger.event(
      'encryption_key_generated',
      params: {'storageKey': encryptionKeyStorageName},
    );

    return encoded;
  }
}
