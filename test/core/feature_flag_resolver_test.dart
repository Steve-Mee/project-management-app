import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';

void main() {
  group('FeatureFlagResolver', () {
    test('resolves direct bool values', () {
      expect(
        FeatureFlagResolver.resolveEnabled(true, defaultValue: false),
        isTrue,
      );
      expect(
        FeatureFlagResolver.resolveEnabled(false, defaultValue: true),
        isFalse,
      );
    });

    test('resolves row.enabled', () {
      final row = <String, dynamic>{'key': 'x', 'enabled': true};
      expect(FeatureFlagResolver.resolveEnabled(row, defaultValue: false), isTrue);
    });

    test('resolves row.value bool', () {
      final row = <String, dynamic>{'key': 'x', 'value': false};
      expect(FeatureFlagResolver.resolveEnabled(row, defaultValue: true), isFalse);
    });

    test('resolves row.value.enabled', () {
      final row = <String, dynamic>{
        'key': 'x',
        'value': <String, dynamic>{'enabled': true},
      };
      expect(FeatureFlagResolver.resolveEnabled(row, defaultValue: false), isTrue);
    });

    test('falls back to default when malformed', () {
      final row = <String, dynamic>{'key': 'x', 'value': <String, dynamic>{'foo': 'bar'}};
      expect(FeatureFlagResolver.resolveEnabled(row, defaultValue: false), isFalse);
      expect(FeatureFlagResolver.resolveEnabled(row, defaultValue: true), isTrue);
    });

    test('isEnabled reads map by key', () {
      final flags = <String, dynamic>{
        'a': <String, dynamic>{'enabled': true},
        'b': <String, dynamic>{'value': false},
      };

      expect(FeatureFlagResolver.isEnabled(flags, 'a', defaultValue: false), isTrue);
      expect(FeatureFlagResolver.isEnabled(flags, 'b', defaultValue: true), isFalse);
      expect(FeatureFlagResolver.isEnabled(flags, 'missing', defaultValue: true), isTrue);
    });
  });
}
