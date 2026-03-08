import 'dart:convert';

import 'package:crypto/crypto.dart';

class ABTestingService {
  ABTestingService._();

  static final ABTestingService instance = ABTestingService._();

  final Map<String, String> _assignedVariants = <String, String>{};

  Future<String> assignVariant({
    required String experimentKey,
    required String userId,
    List<String> variants = const <String>['A', 'B'],
  }) async {
    if (variants.isEmpty) {
      return 'A';
    }

    final cacheKey = '$experimentKey::$userId';
    final existing = _assignedVariants[cacheKey];
    if (existing != null) {
      return existing;
    }

    final normalizedUserId = userId.trim().isEmpty ? 'anonymous' : userId.trim();
    final input = utf8.encode('$experimentKey::$normalizedUserId');
    final digest = sha256.convert(input).bytes;
    final bucket = digest.first;
    final index = bucket % variants.length;
    final assigned = variants[index];

    _assignedVariants[cacheKey] = assigned;
    return assigned;
  }

  String? getAssignedVariant({
    required String experimentKey,
    required String userId,
  }) {
    final cacheKey = '$experimentKey::$userId';
    return _assignedVariants[cacheKey];
  }
}
