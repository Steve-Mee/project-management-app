import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for obtaining explicit consent for AI data sharing
class AiConsentDialog extends ConsumerStatefulWidget {
  const AiConsentDialog({super.key});

  @override
  ConsumerState<AiConsentDialog> createState() => _AiConsentDialogState();
}

class _AiConsentDialogState extends ConsumerState<AiConsentDialog> {
  bool _consentGiven = false;
  bool _understandCompliance = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Data Sharing Consent'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before proceeding with AI-assisted project planning, please review and consent to the following:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Privacy & Compliance:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Your project data will be anonymized before sharing with AI services\n'
              '• No personal information (PII) will be transmitted\n'
              '• Data is processed in compliance with worldwide privacy laws including:\n'
              '  - GDPR (European Union)\n'
              '  - CCPA/CPRA (California, USA)\n'
              '  - PIPEDA (Canada)\n'
              '  - LGPD (Brazil)\n'
              '  - PDPA (Singapore)\n'
              '  - And other applicable regional regulations',
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Usage:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Anonymized data is used only for generating project planning assistance\n'
              '• Data is not stored permanently or used for training AI models\n'
              '• Session data is discarded after the planning process completes',
            ),
            const SizedBox(height: 16),
            const Text(
              'Legal Compliance:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              '• All AI suggestions comply with applicable laws and regulations\n'
              '• Content respects intellectual property rights\n'
              '• No assistance is provided for restricted or illegal activities',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('I consent to share anonymized project data with AI services for planning assistance'),
              value: _consentGiven,
              onChanged: (value) => setState(() => _consentGiven = value ?? false),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('I understand the privacy and compliance measures in place'),
              value: _understandCompliance,
              onChanged: (value) => setState(() => _understandCompliance = value ?? false),
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_consentGiven && _understandCompliance)
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Proceed with AI Discussion'),
        ),
      ],
    );
  }
}

/// Function to show the AI consent dialog
Future<bool?> showAiConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const AiConsentDialog(),
  );
}