import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';

class MirrorDraftCacheSnapshot {
  const MirrorDraftCacheSnapshot({
    required this.sessionKey,
    required this.files,
    required this.selectedFile,
    required this.savedAt,
  });

  final String sessionKey;
  final Map<String, String> files;
  final String selectedFile;
  final DateTime savedAt;
}

class MirrorDraftCacheService {
  const MirrorDraftCacheService();

  static const String _boxName = 'mirror_editor_drafts';
  static const String _encryptionKeyName =
      'hive_encryption_key_mirror_editor_drafts';
  static const int _maxSessions = 40;
  static const int _maxFilesPerSession = 80;
  static const int _maxCharsPerSession = 300000;
  static const int _maxCharsPerFile = 25000;

  Future<MirrorDraftCacheSnapshot?> readDraft(String sessionKey) async {
    if (sessionKey.trim().isEmpty) {
      return null;
    }

    final box = await _openBox();
    final raw = box.get(sessionKey);
    if (raw is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(raw);
    final filesRaw = map['files'];
    if (filesRaw is! Map) {
      return null;
    }

    final files = <String, String>{};
    for (final entry in filesRaw.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value;
      if (key.isEmpty || value is! String) {
        continue;
      }
      files[key] = value;
    }

    if (files.isEmpty) {
      return null;
    }

    final selectedFileRaw = map['selectedFile']?.toString().trim() ?? '';
    final selectedFile = files.containsKey(selectedFileRaw)
        ? selectedFileRaw
        : files.keys.first;

    final savedAtRaw = map['savedAt']?.toString();
    final savedAt = DateTime.tryParse(savedAtRaw ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return MirrorDraftCacheSnapshot(
      sessionKey: sessionKey,
      files: files,
      selectedFile: selectedFile,
      savedAt: savedAt,
    );
  }

  Future<void> writeDraft({
    required String sessionKey,
    required Map<String, String> files,
    required String selectedFile,
  }) async {
    if (sessionKey.trim().isEmpty || files.isEmpty) {
      return;
    }

    final box = await _openBox();
    final cappedFiles = _capFiles(files, selectedFile: selectedFile);
    if (cappedFiles.isEmpty) {
      await box.delete(sessionKey);
      return;
    }

    final normalizedSelected = cappedFiles.containsKey(selectedFile)
        ? selectedFile
        : cappedFiles.keys.first;

    await box.put(sessionKey, {
      'sessionKey': sessionKey,
      'selectedFile': normalizedSelected,
      'files': cappedFiles,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'version': 1,
    });

    await _enforceSessionCap(box);
  }

  Future<void> clearDraft(String sessionKey) async {
    if (sessionKey.trim().isEmpty) {
      return;
    }
    final box = await _openBox();
    await box.delete(sessionKey);
  }

  Map<String, String> _capFiles(
    Map<String, String> inputFiles, {
    required String selectedFile,
  }) {
    final normalizedEntries = inputFiles.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .map((entry) => MapEntry(entry.key.trim(), entry.value))
        .toList(growable: false);

    normalizedEntries.sort((a, b) {
      final aPriority = a.key == selectedFile ? 0 : 1;
      final bPriority = b.key == selectedFile ? 0 : 1;
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return a.key.compareTo(b.key);
    });

    final capped = <String, String>{};
    var usedChars = 0;

    for (final entry in normalizedEntries) {
      if (capped.length >= _maxFilesPerSession) {
        break;
      }

      final path = entry.key;
      if (path.length >= _maxCharsPerSession) {
        continue;
      }

      final remainingChars = _maxCharsPerSession - usedChars;
      if (remainingChars <= path.length + 1) {
        break;
      }

      final fileBudget = min(_maxCharsPerFile, remainingChars - path.length);
      if (fileBudget <= 0) {
        break;
      }

      final fullContent = entry.value;
      final content = fullContent.length <= fileBudget
          ? fullContent
          : fullContent.substring(0, fileBudget);

      capped[path] = content;
      usedChars += path.length + content.length;
    }

    return capped;
  }

  Future<void> _enforceSessionCap(Box<dynamic> box) async {
    final records = <MapEntry<String, DateTime>>[];

    for (final key in box.keys) {
      final sessionKey = key.toString();
      final raw = box.get(key);
      if (raw is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(raw);
      final savedAt =
          DateTime.tryParse(map['savedAt']?.toString() ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      records.add(MapEntry(sessionKey, savedAt));
    }

    if (records.length <= _maxSessions) {
      return;
    }

    records.sort((a, b) => a.value.compareTo(b.value));
    final overflow = records.length - _maxSessions;

    for (var i = 0; i < overflow; i += 1) {
      await box.delete(records[i].key);
    }
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }

    try {
      return EncryptedHiveBox<dynamic>(
        boxName: _boxName,
        encryptionKey: _encryptionKeyName,
      ).open();
    } catch (error) {
      if (_failClosedOnEncryptionError) {
        throw StateError(
          'Encrypted Mirror draft cache is unavailable in production: $error',
        );
      }
      return Hive.openBox<dynamic>(_boxName);
    }
  }
}

const bool _failClosedOnEncryptionError = bool.fromEnvironment(
  'MIRROR_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
  defaultValue: bool.fromEnvironment('dart.vm.product'),
);
