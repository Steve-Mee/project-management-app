import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../models/mirror_structured_error.dart';

class MirrorRunRetryFeedbackService {
  const MirrorRunRetryFeedbackService();

  bool showRetryFeedback({
    required BuildContext context,
    required AppLocalizations l10n,
    required MirrorStructuredError error,
    required VoidCallback onRetry,
  }) {
    if (!error.retryable) {
      return false;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.mirrorRunCrashed(error.message ?? error.errorFamily),
        ),
        action: SnackBarAction(
          label: l10n.mirrorRetryButton,
          onPressed: onRetry,
        ),
      ),
    );
    return true;
  }
}