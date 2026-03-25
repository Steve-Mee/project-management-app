import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';

class MirrorEditorFilePresentationService {
  const MirrorEditorFilePresentationService();

  String statusLineLabel({
    required AppLocalizations l10n,
    required String status,
  }) {
    return l10n.mirrorStatusLine(status);
  }

  IconData iconForFile(String path) {
    if (path.endsWith('.dart')) {
      return Icons.code;
    }
    if (path.endsWith('.md')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String languageForFile(String path) {
    if (path.endsWith('.dart')) {
      return 'dart';
    }
    if (path.endsWith('.md')) {
      return 'markdown';
    }
    if (path.endsWith('.json')) {
      return 'json';
    }
    return 'plaintext';
  }
}