import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Encrypted Hive box wrapper for sensitive local data.
///
/// Issue reference: .github/issues/062-hive-encryption.md
///
/// - `boxName` is the Hive box name to open.
/// - `encryptionKey` is the key name used in `FlutterSecureStorage`.
class EncryptedHiveBox<T> {
  EncryptedHiveBox({
    required this.boxName,
    required this.encryptionKey,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String boxName;
  final String encryptionKey;
  final FlutterSecureStorage _secureStorage;

  static const int _hiveAesKeyLength = 32;

  Future<Box<T>> open() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }

    final cipherKey = await _readOrCreateCipherKey();
    return Hive.openBox<T>(
      boxName,
      encryptionCipher: HiveAesCipher(cipherKey),
    );
  }

  Future<Uint8List> _readOrCreateCipherKey() async {
    final stored = await _secureStorage.read(key: encryptionKey);

    if (stored != null && stored.isNotEmpty) {
      final decoded = _decodeStoredKey(stored);
      if (decoded.length == _hiveAesKeyLength) {
        return decoded;
      }
    }

    final generated = encrypt.Key.fromSecureRandom(_hiveAesKeyLength);
    await _secureStorage.write(
      key: encryptionKey,
      value: base64UrlEncode(generated.bytes),
    );
    return Uint8List.fromList(generated.bytes);
  }

  Uint8List _decodeStoredKey(String value) {
    try {
      return Uint8List.fromList(base64Url.decode(value));
    } catch (_) {
      return Uint8List.fromList(base64.decode(value));
    }
  }
}
