import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/core/feature_flags/feature_flag.dart';

void main() {
  group('FeatureFlag model', () {
    test('parses row with direct enabled field', () {
      final row = <String, dynamic>{
        'id': '1',
        'key': 'ai_assistant_enabled',
        'enabled': true,
        'value': <String, dynamic>{'rollout': 100},
        'description': 'AI assistant gate',
        'updated_at': '2026-03-07T12:00:00.000Z',
      };

      final model = FeatureFlag.tryParse(row);

      expect(model, isNotNull);
      expect(model!.key, 'ai_assistant_enabled');
      expect(model.enabled, isTrue);
      expect(model.description, 'AI assistant gate');
      expect(model.updatedAt, isNotNull);
      expect(model.toMap()['key'], 'ai_assistant_enabled');
    });

    test('resolves enabled from nested value map', () {
      final row = <String, dynamic>{
        'key': 'onboarding_enabled',
        'value': <String, dynamic>{'enabled': false},
      };

      final model = FeatureFlag.tryParse(row);

      expect(model, isNotNull);
      expect(model!.enabled, isFalse);
    });

    test('returns null for invalid row without key', () {
      final row = <String, dynamic>{'enabled': true};
      expect(FeatureFlag.tryParse(row), isNull);
    });
  });
}
