import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuthGuard {
  AuthGuard({
    required this.serviceToken,
    required this.jwtSecret,
    this.jwtSecretsByKid = const <String, String>{},
    this.requiredAudience,
    this.requiredIssuer,
  });

  final String serviceToken;
  final String jwtSecret;
  final Map<String, String> jwtSecretsByKid;
  final String? requiredAudience;
  final String? requiredIssuer;

  static Map<String, String> parseKidSecretMapping(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <String, String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, String>{};
      }

      final mapping = <String, String>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isEmpty || value.isEmpty) {
          continue;
        }
        mapping[key] = value;
      }
      return mapping;
    } catch (_) {
      return const <String, String>{};
    }
  }

  AuthVerdict verify(Map<String, String> metadata) {
    final normalized = <String, String>{};
    for (final entry in metadata.entries) {
      normalized[entry.key.toLowerCase()] = entry.value;
    }

    final serviceHeader =
        normalized['x-service-token'] ?? normalized['service-token'];
    if (serviceHeader != null &&
        _constantTimeEquals(serviceHeader.trim(), serviceToken)) {
      return const AuthVerdict.authorized(method: 'service-token');
    }

    final authHeader = normalized['authorization'];
    if (authHeader == null || authHeader.isEmpty) {
      return const AuthVerdict.denied('Missing authorization metadata.');
    }

    const bearerPrefix = 'bearer ';
    if (!authHeader.toLowerCase().startsWith(bearerPrefix)) {
      return const AuthVerdict.denied('Authorization must be a Bearer token.');
    }

    final token = authHeader.substring(bearerPrefix.length).trim();
    if (token.isEmpty) {
      return const AuthVerdict.denied('Bearer token is empty.');
    }

    return _verifyJwt(token);
  }

  AuthVerdict _verifyJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return const AuthVerdict.denied('Malformed JWT.');
    }

    final headerPart = parts[0];
    final payloadPart = parts[1];
    final signaturePart = parts[2];
    final headerMap = _decodeJsonPart(headerPart);
    if (headerMap == null) {
      return const AuthVerdict.denied('Invalid JWT header.');
    }

    final payloadMap = _decodeJsonPart(payloadPart);
    if (payloadMap == null) {
      return const AuthVerdict.denied('Invalid JWT payload.');
    }

    final alg = (headerMap['alg'] ?? '').toString();
    if (alg != 'HS256') {
      return AuthVerdict.denied('Unsupported JWT alg: $alg');
    }

    final kid = (headerMap['kid'] ?? '').toString().trim();
    final signingInput = '$headerPart.$payloadPart';
    final candidateSecrets = _candidateSecretsForKid(kid);
    if (candidateSecrets.isEmpty) {
      return kid.isNotEmpty
          ? AuthVerdict.denied('Unknown JWT kid: $kid')
          : const AuthVerdict.denied('No JWT signing secrets configured.');
    }

    var signatureValid = false;
    for (final secret in candidateSecrets) {
      final expectedSignature = _signHs256(signingInput, secret);
      if (_constantTimeEquals(signaturePart, expectedSignature)) {
        signatureValid = true;
        break;
      }
    }

    if (!signatureValid) {
      return const AuthVerdict.denied('Invalid JWT signature.');
    }

    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final exp = _asInt(payloadMap['exp']);
    if (exp != null && exp < nowSeconds) {
      return const AuthVerdict.denied('JWT expired.');
    }

    final nbf = _asInt(payloadMap['nbf']);
    if (nbf != null && nbf > nowSeconds) {
      return const AuthVerdict.denied('JWT not active yet.');
    }

    if (requiredIssuer != null && requiredIssuer!.isNotEmpty) {
      final iss = (payloadMap['iss'] ?? '').toString();
      if (iss != requiredIssuer) {
        return const AuthVerdict.denied('JWT issuer mismatch.');
      }
    }

    if (requiredAudience != null && requiredAudience!.isNotEmpty) {
      final audClaim = payloadMap['aud'];
      final hasAudience = _matchesAudience(audClaim, requiredAudience!);
      if (!hasAudience) {
        return const AuthVerdict.denied('JWT audience mismatch.');
      }
    }

    return const AuthVerdict.authorized(method: 'jwt');
  }

  List<String> _candidateSecretsForKid(String kid) {
    if (kid.isNotEmpty) {
      final mapped = jwtSecretsByKid[kid];
      if (mapped != null && mapped.isNotEmpty) {
        return <String>[mapped];
      }
      return const <String>[];
    }

    final set = <String>{};
    if (jwtSecret.isNotEmpty) {
      set.add(jwtSecret);
    }
    set.addAll(jwtSecretsByKid.values.where((value) => value.isNotEmpty));
    return set.toList(growable: false);
  }

  bool _matchesAudience(dynamic claim, String required) {
    if (claim is String) {
      return claim == required;
    }

    if (claim is List) {
      for (final item in claim) {
        if (item?.toString() == required) {
          return true;
        }
      }
      return false;
    }

    return false;
  }

  Map<String, dynamic>? _decodeJsonPart(String part) {
    try {
      final normalized = base64Url.normalize(part);
      final bytes = base64Url.decode(normalized);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _signHs256(String input, String secret) {
    final digest = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(input));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < aBytes.length; i++) {
      result |= aBytes[i] ^ bBytes[i];
    }
    return result == 0;
  }
}

class AuthVerdict {
  const AuthVerdict._({
    required this.authorized,
    required this.reason,
    required this.method,
  });

  const AuthVerdict.authorized({required String method})
    : this._(authorized: true, reason: '', method: method);

  const AuthVerdict.denied(String reason)
    : this._(authorized: false, reason: reason, method: 'none');

  final bool authorized;
  final String reason;
  final String method;
}

class RunnerMetrics {
  int _authDeniedCount = 0;
  int _compileCount = 0;
  int _compileFailureCount = 0;
  int _compileTotalLatencyMs = 0;
  int _compileMaxLatencyMs = 0;
  final Map<String, int> _authDeniedByReason = <String, int>{};

  void recordAuthDenied(String reason) {
    _authDeniedCount += 1;
    _authDeniedByReason.update(reason, (value) => value + 1, ifAbsent: () => 1);
  }

  void recordCompile({required Duration latency, required bool success}) {
    _compileCount += 1;
    if (!success) {
      _compileFailureCount += 1;
    }

    final latencyMs = latency.inMilliseconds;
    _compileTotalLatencyMs += latencyMs;
    if (latencyMs > _compileMaxLatencyMs) {
      _compileMaxLatencyMs = latencyMs;
    }
  }

  Map<String, Object> snapshot() {
    final avgLatencyMs = _compileCount == 0
        ? 0
        : (_compileTotalLatencyMs ~/ _compileCount);
    return <String, Object>{
      'authDeniedCount': _authDeniedCount,
      'authDeniedByReason': Map<String, int>.from(_authDeniedByReason),
      'compileCount': _compileCount,
      'compileFailureCount': _compileFailureCount,
      'compileAvgLatencyMs': avgLatencyMs,
      'compileMaxLatencyMs': _compileMaxLatencyMs,
    };
  }
}
