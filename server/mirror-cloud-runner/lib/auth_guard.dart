import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuthGuard {
  AuthGuard({
    required this.serviceToken,
    required this.jwtSecret,
    this.requiredAudience,
    this.requiredIssuer,
  });

  final String serviceToken;
  final String jwtSecret;
  final String? requiredAudience;
  final String? requiredIssuer;

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

    final payloadMap = _decodeJsonPart(payloadPart);
    if (payloadMap == null) {
      return const AuthVerdict.denied('Invalid JWT payload.');
    }

    final alg = (_decodeJsonPart(headerPart)?['alg'] ?? '').toString();
    if (alg != 'HS256') {
      return AuthVerdict.denied('Unsupported JWT alg: $alg');
    }

    final expectedSignature = _signHs256('$headerPart.$payloadPart', jwtSecret);
    if (!_constantTimeEquals(signaturePart, expectedSignature)) {
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
