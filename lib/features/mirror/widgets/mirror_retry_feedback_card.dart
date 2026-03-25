import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../models/mirror_structured_error.dart';

class MirrorRetryFeedbackCard extends StatelessWidget {
  const MirrorRetryFeedbackCard({
    super.key,
    required this.l10n,
    required this.error,
    required this.isRunInProgress,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final MirrorStructuredError error;
  final bool isRunInProgress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.refresh, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.mirrorRunCrashed(error.message ?? error.errorFamily),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isRunInProgress ? null : onRetry,
            child: Text(l10n.mirrorRetryButton),
          ),
        ],
      ),
    );
  }
}