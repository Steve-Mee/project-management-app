import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth providers do not persist plaintext biometric password', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content.contains('biometric_password'), isFalse);
    expect(content.contains('_biometricRefreshTokenKey'), isTrue);
  });

  test('auth providers use feature flag and single biometric toggle source', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    final content = await file.readAsString();

    expect(content.contains("_biometricFeatureFlagKey = 'auth_biometric'"), isTrue);
    expect(content.contains('final useBiometricsProvider = biometricLoginProvider;'), isTrue);
  });
}
