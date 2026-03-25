import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_template.dart';
import 'package:project_management_app/features/mirror/services/mirror_templates_ui_service.dart';
import 'package:project_management_app/generated/app_localizations_en.dart';

void main() {
  const service = MirrorTemplatesUiService();

  group('MirrorTemplatesUiService', () {
    test('formats stale timestamp for display', () {
      final timestamp = DateTime.utc(2026, 3, 22, 14, 5);
      final local = timestamp.toLocal();
      final expected =
          '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      final formatted = service.formatStaleUpdatedAt(timestamp);

      expect(formatted, expected);
    });

    test('maps fallback reasons to user-facing labels', () {
      expect(service.formatFallbackReason('timeout'), 'timeout');
      expect(
        service.formatFallbackReason('version_mismatch'),
        'version mismatch',
      );
      expect(service.formatFallbackReason('network_error'), 'network error');
      expect(service.formatFallbackReason('other'), 'unknown reason');
    });

    test('formats cache age for stale fallback metadata', () {
      expect(service.formatCacheAge(null), 'unknown age');
      expect(service.formatCacheAge(const Duration(seconds: 42)), '42s');
      expect(service.formatCacheAge(const Duration(minutes: 7)), '7m');
      expect(service.formatCacheAge(const Duration(hours: 3)), '3h');
    });

    test('builds template apply presentation payload', () {
      final l10n = AppLocalizationsEn();
      final presentation = service.buildTemplateApplyPresentation(
        selectedFile: 'lib/main.dart',
        template: const MirrorTemplate(
          id: 'tpl-1',
          title: 'Starter',
          description: 'Template',
          seedContent: 'void main() {}',
          iconName: 'bolt',
        ),
        l10n: l10n,
      );

      expect(presentation.updatedContent, 'void main() {}');
      expect(
        presentation.terminalMessage,
        l10n.mirrorTemplateAppliedTerminal('lib/main.dart', 'Starter'),
      );
    });
  });
}