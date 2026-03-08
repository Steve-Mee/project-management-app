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
      return const AuthVerdict.denied(
        code: AuthDenyCode.missingAuthorization,
        reason: 'Missing authorization metadata.',
      );
    }

    const bearerPrefix = 'bearer ';
    if (!authHeader.toLowerCase().startsWith(bearerPrefix)) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.invalidAuthorizationScheme,
        reason: 'Authorization must be a Bearer token.',
      );
    }

    final token = authHeader.substring(bearerPrefix.length).trim();
    if (token.isEmpty) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.emptyBearerToken,
        reason: 'Bearer token is empty.',
      );
    }

    return _verifyJwt(token);
  }

  AuthVerdict _verifyJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtMalformed,
        reason: 'Malformed JWT.',
      );
    }

    final headerPart = parts[0];
    final payloadPart = parts[1];
    final signaturePart = parts[2];
    final headerMap = _decodeJsonPart(headerPart);
    if (headerMap == null) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtHeaderInvalid,
        reason: 'Invalid JWT header.',
      );
    }

    final payloadMap = _decodeJsonPart(payloadPart);
    if (payloadMap == null) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtPayloadInvalid,
        reason: 'Invalid JWT payload.',
      );
    }

    final alg = (headerMap['alg'] ?? '').toString();
    if (alg != 'HS256') {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtUnsupportedAlg,
        reason: 'Unsupported JWT algorithm.',
      );
    }

    final kid = (headerMap['kid'] ?? '').toString().trim();
    final signingInput = '$headerPart.$payloadPart';
    final candidateSecrets = _candidateSecretsForKid(kid);
    if (candidateSecrets.isEmpty) {
      return kid.isNotEmpty
          ? const AuthVerdict.denied(
              code: AuthDenyCode.jwtUnknownKid,
              reason: 'Unknown JWT key id.',
            )
          : const AuthVerdict.denied(
              code: AuthDenyCode.jwtSecretsMissing,
              reason: 'No JWT signing secrets configured.',
            );
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
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtSignatureInvalid,
        reason: 'Invalid JWT signature.',
      );
    }

    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final exp = _asInt(payloadMap['exp']);
    if (exp != null && exp < nowSeconds) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtExpired,
        reason: 'JWT expired.',
      );
    }

    final nbf = _asInt(payloadMap['nbf']);
    if (nbf != null && nbf > nowSeconds) {
      return const AuthVerdict.denied(
        code: AuthDenyCode.jwtNotYetActive,
        reason: 'JWT not active yet.',
      );
    }

    if (requiredIssuer != null && requiredIssuer!.isNotEmpty) {
      final iss = (payloadMap['iss'] ?? '').toString();
      if (iss != requiredIssuer) {
        return const AuthVerdict.denied(
          code: AuthDenyCode.jwtIssuerMismatch,
          reason: 'JWT issuer mismatch.',
        );
      }
    }

    if (requiredAudience != null && requiredAudience!.isNotEmpty) {
      final audClaim = payloadMap['aud'];
      final hasAudience = _matchesAudience(audClaim, requiredAudience!);
      if (!hasAudience) {
        return const AuthVerdict.denied(
          code: AuthDenyCode.jwtAudienceMismatch,
          reason: 'JWT audience mismatch.',
        );
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
    final digest =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(input));
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

class AuthDenyCode {
  static const String missingAuthorization = 'missing_authorization';
  static const String invalidAuthorizationScheme =
      'invalid_authorization_scheme';
  static const String emptyBearerToken = 'empty_bearer_token';
  static const String jwtMalformed = 'jwt_malformed';
  static const String jwtHeaderInvalid = 'jwt_header_invalid';
  static const String jwtPayloadInvalid = 'jwt_payload_invalid';
  static const String jwtUnsupportedAlg = 'jwt_unsupported_alg';
  static const String jwtUnknownKid = 'jwt_unknown_kid';
  static const String jwtSecretsMissing = 'jwt_secrets_missing';
  static const String jwtSignatureInvalid = 'jwt_signature_invalid';
  static const String jwtExpired = 'jwt_expired';
  static const String jwtNotYetActive = 'jwt_not_yet_active';
  static const String jwtIssuerMismatch = 'jwt_issuer_mismatch';
  static const String jwtAudienceMismatch = 'jwt_audience_mismatch';

  const AuthDenyCode._();
}

class AuthVerdict {
  const AuthVerdict._({
    required this.authorized,
    required this.reasonCode,
    required this.reason,
    required this.method,
  });

  const AuthVerdict.authorized({required String method})
      : this._(
          authorized: true,
          reasonCode: '',
          reason: '',
          method: method,
        );

  const AuthVerdict.denied({required String code, required String reason})
      : this._(
          authorized: false,
          reasonCode: code,
          reason: reason,
          method: 'none',
        );

  final bool authorized;
  final String reasonCode;
  final String reason;
  final String method;
}
