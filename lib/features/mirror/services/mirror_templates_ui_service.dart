import '../../../generated/app_localizations.dart';
import '../models/mirror_template.dart';

class MirrorTemplateApplyPresentation {
  const MirrorTemplateApplyPresentation({
    required this.updatedContent,
    required this.terminalMessage,
  });

  final String updatedContent;
  final String terminalMessage;
}

class MirrorTemplatesUiService {
  const MirrorTemplatesUiService();

  String formatStaleUpdatedAt(DateTime timestampUtc) {
    final local = timestampUtc.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String formatFallbackReason(String? reasonCode) {
    switch (reasonCode) {
      case 'timeout':
        return 'timeout';
      case 'version_mismatch':
        return 'version mismatch';
      case 'network_error':
        return 'network error';
      default:
        return 'unknown reason';
    }
  }

  String formatCacheAge(Duration? cacheAge) {
    if (cacheAge == null) {
      return 'unknown age';
    }
    if (cacheAge.inSeconds < 60) {
      return '${cacheAge.inSeconds}s';
    }
    if (cacheAge.inMinutes < 60) {
      return '${cacheAge.inMinutes}m';
    }
    return '${cacheAge.inHours}h';
  }

  MirrorTemplateApplyPresentation buildTemplateApplyPresentation({
    required String selectedFile,
    required MirrorTemplate template,
    required AppLocalizations l10n,
  }) {
    return MirrorTemplateApplyPresentation(
      updatedContent: template.seedContent,
      terminalMessage: l10n.mirrorTemplateAppliedTerminal(
        selectedFile,
        template.title,
      ),
    );
  }
}