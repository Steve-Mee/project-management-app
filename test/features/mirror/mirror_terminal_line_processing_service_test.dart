import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_structured_error_parser.dart';
import 'package:project_management_app/features/mirror/services/mirror_terminal_line_processing_service.dart';
import 'package:project_management_app/generated/app_localizations_en.dart';

void main() {
  const service = MirrorTerminalLineProcessingService();
  const parser = MirrorStructuredErrorParser();

  group('MirrorTerminalLineProcessingService', () {
    test('keeps plain line unchanged when no structured payload is present', () {
      final l10n = AppLocalizationsEn();
      const line = 'build started';

      final result = service.process(
        rawLine: line,
        l10n: l10n,
        parser: parser,
      );

      expect(result.displayLine, line);
      expect(result.structuredError, isNull);
    });

    test('maps structured error line to localized terminal crash text', () {
      final l10n = AppLocalizationsEn();
      const line =
          '{"error_family":"timeout","retryable":true,"message":"request timed out"}';

      final result = service.process(
        rawLine: line,
        l10n: l10n,
        parser: parser,
      );

      expect(result.structuredError, isNotNull);
      expect(result.structuredError!.errorFamily, 'timeout');
      expect(
        result.displayLine,
        l10n.mirrorRunCrashedTerminal('request timed out'),
      );
    });
  });
}