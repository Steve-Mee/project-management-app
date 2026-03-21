class MirrorVoiceDraftSanitizationResult {
  const MirrorVoiceDraftSanitizationResult._({
    required this.isAccepted,
    this.sanitizedText,
    this.rejectionReason,
  });

  final bool isAccepted;
  final String? sanitizedText;
  final String? rejectionReason;

  factory MirrorVoiceDraftSanitizationResult.accepted(String text) {
    return MirrorVoiceDraftSanitizationResult._(
      isAccepted: true,
      sanitizedText: text,
    );
  }

  factory MirrorVoiceDraftSanitizationResult.rejected(String reason) {
    return MirrorVoiceDraftSanitizationResult._(
      isAccepted: false,
      rejectionReason: reason,
    );
  }
}

class MirrorVoiceDraftSanitizer {
  const MirrorVoiceDraftSanitizer();

  static const int defaultMaxChars = 2000;

  static final RegExp _controlChars =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
  static final RegExp _zeroWidthChars = RegExp(r'[\u200B-\u200D\uFEFF]');

  MirrorVoiceDraftSanitizationResult sanitize(
    String rawDraft, {
    int maxChars = defaultMaxChars,
  }) {
    final normalizedNewLines =
        rawDraft.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final withoutControlChars =
        normalizedNewLines.replaceAll(_controlChars, '');
    final withoutZeroWidthChars =
        withoutControlChars.replaceAll(_zeroWidthChars, '');
    final sanitized = withoutZeroWidthChars.trim();

    if (sanitized.isEmpty) {
      return MirrorVoiceDraftSanitizationResult.rejected(
        'Voice draft is empty after sanitization.',
      );
    }

    if (sanitized.length > maxChars) {
      return MirrorVoiceDraftSanitizationResult.rejected(
        'Voice draft exceeds the $maxChars character safety limit.',
      );
    }

    return MirrorVoiceDraftSanitizationResult.accepted(sanitized);
  }
}
