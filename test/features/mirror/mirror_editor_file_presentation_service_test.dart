import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_editor_file_presentation_service.dart';
import 'package:project_management_app/generated/app_localizations_en.dart';

void main() {
  const service = MirrorEditorFilePresentationService();

  group('MirrorEditorFilePresentationService', () {
    test('maps status line through localization', () {
      final l10n = AppLocalizationsEn();
      final label = service.statusLineLabel(l10n: l10n, status: 'ready');

      expect(label, l10n.mirrorStatusLine('ready'));
    });

    test('maps icon by file type', () {
      expect(service.iconForFile('lib/main.dart'), Icons.code);
      expect(
        service.iconForFile('README.md'),
        Icons.description_outlined,
      );
      expect(
        service.iconForFile('config.yml'),
        Icons.insert_drive_file_outlined,
      );
    });

    test('maps language by file extension', () {
      expect(service.languageForFile('lib/main.dart'), 'dart');
      expect(service.languageForFile('README.md'), 'markdown');
      expect(service.languageForFile('payload.json'), 'json');
      expect(service.languageForFile('notes.txt'), 'plaintext');
    });
  });
}