import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_voice_draft_sanitizer.dart';

void main() {
  group('MirrorVoiceDraftSanitizer', () {
    const sanitizer = MirrorVoiceDraftSanitizer();

    test('accepts normal draft and trims whitespace', () {
      final result = sanitizer.sanitize('  hello voice draft  ');

      expect(result.isAccepted, isTrue);
      expect(result.sanitizedText, equals('hello voice draft'));
      expect(result.rejectionReason, isNull);
    });

    test('rejects empty draft after sanitization', () {
      final result = sanitizer.sanitize('\u200B\u200C\n\r\t  ');

      expect(result.isAccepted, isFalse);
      expect(result.sanitizedText, isNull);
      expect(result.rejectionReason, isNotNull);
    });

    test('removes control characters and normalizes newlines', () {
      final result = sanitizer.sanitize('line1\r\nline2\x07\rline3');

      expect(result.isAccepted, isTrue);
      expect(result.sanitizedText, equals('line1\nline2\nline3'));
    });

    test('rejects drafts over max length', () {
      final result = sanitizer.sanitize('abcd', maxChars: 3);

      expect(result.isAccepted, isFalse);
      expect(result.sanitizedText, isNull);
      expect(result.rejectionReason, contains('3'));
    });
  });
}
