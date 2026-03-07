import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/repository/i_auth_repository.dart';
import 'package:pma_core/repository/impl/hive_auth_repository.dart';

void main() {
  group('Auth repository interface split', () {
    test('HiveAuthRepository satisfies all auth sub-contracts', () {
      final repository = HiveAuthRepository();

      expect(repository, isA<IAuthSessionRepository>());
      expect(repository, isA<IAuthDirectoryRepository>());
      expect(repository, isA<IAuthRateLimitRepository>());
      expect(repository, isA<IAuthRepository>());
    });
  });
}
