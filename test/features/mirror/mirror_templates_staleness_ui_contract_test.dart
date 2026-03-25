import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror templates staleness UI contract', () {
    test('editor screen delegates template modal content to the sheet widget', () {
      final source = _readRepoFile(
        'lib/features/mirror/mirror_editor_screen.dart',
      );

      expect(source, contains('MirrorTemplatesSheet('));
      expect(source, contains('MirrorTemplatesUiService'));
      expect(
        source,
        contains('formatStaleUpdatedAt: _templatesUiService.formatStaleUpdatedAt'),
      );
      expect(
        source,
        contains('formatTemplatesFallbackReason:'),
      );
      expect(
        source,
        contains('formatTemplatesCacheAge:'),
      );
      expect(
        source,
        contains('_templatesUiService.formatCacheAge'),
      );
      expect(
        source,
        contains('_templatesUiService.formatFallbackReason'),
      );
    });

    test('stale fallback warning includes reason label and refresh action', () {
      final source = _readRepoFile(
        'lib/features/mirror/widgets/mirror_templates_sheet.dart',
      );

      expect(source, contains('final staleFallbackNotice = result.isStaleFallback'));
      expect(source, contains('final staleFallbackDetails ='));
      expect(source, contains('final staleSourceMessage = result.staleFallbackSourceLabel'));
      expect(source, contains('final staleAgeMessage = formatTemplatesCacheAge(result.cacheAge);'));
      expect(source, contains(r'Fallback details: reason=$staleReasonMessage, source=$staleSourceMessage, age=$staleAgeMessage'));
      expect(source, contains('_buildTemplatesStaleFallbackNotice('));
      expect(source, contains('details: staleFallbackDetails'));
      expect(source, contains('TextButton.icon('));
      expect(source, contains('mirrorTemplatesInvalidationControllerProvider'));
      expect(source, contains('invalidateTemplatesCache(refresh: true)'));
      expect(source, contains('recordTemplateFallbackInteraction('));
      expect(source, contains("action: 'refresh'"));
      expect(source, contains("action: 'select_template'"));
      expect(source, contains('mirrorRetryButton'));
      expect(source, contains('staleWarningTooltip: staleFallbackNotice'));
    });

    test('stale fallback state is surfaced inside the gallery cards', () {
      final source = _readRepoFile(
        'lib/features/mirror/templates_gallery.dart',
      );

      expect(source, contains('staleWarningTooltip'));
      expect(source, contains('Tooltip('));
      expect(source, contains('Icons.cloud_off_outlined'));
    });

    test('fresh templates path does not render stale fallback branch', () {
      final source = _readRepoFile(
        'lib/features/mirror/widgets/mirror_templates_sheet.dart',
      );

      expect(source, contains('final staleWarningMessage = result.isStaleFallback'));
      expect(source, contains('Expanded('));
      expect(source, contains('TemplatesGallery('));
    });
  });
}

String _readRepoFile(String relativePath) {
  final direct = File(relativePath);
  if (direct.existsSync()) {
    return direct.readAsStringSync();
  }

  final fromTestDir = File('test/$relativePath');
  if (fromTestDir.existsSync()) {
    return fromTestDir.readAsStringSync();
  }

  final fromParent = File('../$relativePath');
  if (fromParent.existsSync()) {
    return fromParent.readAsStringSync();
  }

  throw StateError('Unable to locate file for contract test: $relativePath');
}
