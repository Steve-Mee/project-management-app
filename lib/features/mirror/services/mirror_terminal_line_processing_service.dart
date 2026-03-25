import '../../../generated/app_localizations.dart';
import '../models/mirror_structured_error.dart';
import 'mirror_structured_error_parser.dart';

class MirrorTerminalLineProcessingResult {
  const MirrorTerminalLineProcessingResult({
    required this.displayLine,
    this.structuredError,
  });

  final String displayLine;
  final MirrorStructuredError? structuredError;
}

class MirrorTerminalLineProcessingService {
  const MirrorTerminalLineProcessingService();

  MirrorTerminalLineProcessingResult process({
    required String rawLine,
    required AppLocalizations l10n,
    required MirrorStructuredErrorParser parser,
  }) {
    final structured = parser.tryParse(rawLine);
    final displayLine = structured == null
        ? rawLine
        : l10n.mirrorRunCrashedTerminal(
            structured.message ?? structured.errorFamily,
          );

    return MirrorTerminalLineProcessingResult(
      displayLine: displayLine,
      structuredError: structured,
    );
  }
}