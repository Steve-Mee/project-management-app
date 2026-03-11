import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';

class MirrorAuditHistoryPatchEntry {
  const MirrorAuditHistoryPatchEntry({
    required this.path,
    required this.diff,
  });

  final String path;
  final String diff;
}

class MirrorAuditHistoryService {
  const MirrorAuditHistoryService();

  Future<void> persistApplyHistory({
    required String projectId,
    required String taskId,
    required String mode,
    required String prompt,
    required String backupId,
    required Map<String, String> signedInputUrls,
    required Map<String, String> backupSignedUrls,
    required List<MirrorAuditHistoryPatchEntry> patches,
    String backend = 'unknown',
    Map<String, String> updatedFiles = const <String, String>{},
  }) async {
    const maxUpdatedFiles = 50;
    const maxUpdatedFilesChars = 100000;

    final limitedUpdatedFiles = <String, String>{};
    var usedChars = 0;
    final sortedPaths = updatedFiles.keys.toList()..sort();
    for (final path in sortedPaths) {
      if (limitedUpdatedFiles.length >= maxUpdatedFiles) {
        break;
      }

      final remainingChars = maxUpdatedFilesChars - usedChars;
      if (remainingChars <= 0) {
        break;
      }

      final pathCost = path.length;
      if (pathCost >= remainingChars) {
        break;
      }

      final fullContent = updatedFiles[path] ?? '';
      final contentBudget = remainingChars - pathCost;
      final persistedContent = fullContent.length <= contentBudget
          ? fullContent
          : _truncate(fullContent, contentBudget);

      limitedUpdatedFiles[path] = persistedContent;
      usedChars += pathCost + persistedContent.length;
    }

    final box = await _openApplyHistoryBox();
    final key = '$projectId::$taskId';
    final existing = box.get(key);

    final history = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          history.add(Map<String, dynamic>.from(item));
        }
      }
    }

    history.add(<String, dynamic>{
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'projectId': projectId,
      'taskId': taskId,
      'mode': mode,
      'backend': backend,
      'prompt': _truncate(prompt, 1000),
      'backupId': backupId,
      'signedInputUrlFingerprints': _fingerprintSignedUrlMap(signedInputUrls),
      'backupSignedUrlFingerprints': _fingerprintSignedUrlMap(backupSignedUrls),
      'appliedFiles': patches.map((patch) => patch.path).toList(growable: false),
      'patches': patches
          .map(
            (patch) => <String, dynamic>{
              'path': patch.path,
              'diff': patch.diff,
            },
          )
          .toList(growable: false),
      'updatedFiles': limitedUpdatedFiles,
    });

    const maxHistoryEntries = 40;
    final trimmed = history.length <= maxHistoryEntries
        ? history
        : history.sublist(history.length - maxHistoryEntries);

    await box.put(key, trimmed);
  }

  Future<Box<dynamic>> _openApplyHistoryBox() async {
    const boxName = 'mirror_apply_history';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }

    try {
      return EncryptedHiveBox<dynamic>(
        boxName: boxName,
        encryptionKey: 'hive_encryption_key_mirror_apply_history',
      ).open();
    } catch (error) {
      if (_failClosedOnEncryptionError) {
        throw StateError(
          'Encrypted apply history storage is unavailable in production: $error',
        );
      }
      return Hive.openBox<dynamic>(boxName);
    }
  }

  Map<String, String> _fingerprintSignedUrlMap(Map<String, String> urls) {
    if (urls.isEmpty) {
      return const <String, String>{};
    }

    final sortedKeys = urls.keys.toList()..sort();
    final fingerprints = <String, String>{};
    for (final key in sortedKeys) {
      final value = urls[key] ?? '';
      final hash = sha256.convert(utf8.encode(value)).toString();
      fingerprints[key] = hash.substring(0, 16);
    }
    return fingerprints;
  }

  String _truncate(String input, int maxChars) {
    if (maxChars <= 0) {
      return '';
    }
    if (input.length <= maxChars) {
      return input;
    }
    return '${input.substring(0, maxChars)}\n...[truncated]';
  }
}

const bool _failClosedOnEncryptionError = bool.fromEnvironment(
  'MIRROR_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
  defaultValue: bool.fromEnvironment('dart.vm.product'),
);
