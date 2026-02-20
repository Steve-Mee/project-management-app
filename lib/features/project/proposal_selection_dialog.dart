import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for selecting which AI-generated proposals to accept
class ProposalSelectionDialog extends ConsumerStatefulWidget {
  final List<String> proposals;

  const ProposalSelectionDialog({
    super.key,
    required this.proposals,
  });

  @override
  ConsumerState<ProposalSelectionDialog> createState() => _ProposalSelectionDialogState();
}

class _ProposalSelectionDialogState extends ConsumerState<ProposalSelectionDialog> {
  late List<bool> acceptedProposals;

  @override
  void initState() {
    super.initState();
    acceptedProposals = List.filled(widget.proposals.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final acceptedCount = acceptedProposals.where((accepted) => accepted).length;

    return AlertDialog(
      title: const Text('Review AI Proposals'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Accept or reject the following improvement proposals ($acceptedCount accepted):',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...widget.proposals.asMap().entries.map((entry) {
              final index = entry.key;
              final proposal = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: CheckboxListTile(
                  title: Text(proposal),
                  subtitle: acceptedProposals[index] ? const Text('Accepted', style: TextStyle(color: Colors.green)) : const Text('Rejected', style: TextStyle(color: Colors.red)),
                  value: acceptedProposals[index],
                  onChanged: (value) {
                    setState(() {
                      acceptedProposals[index] = value ?? false;
                    });
                  },
                  secondary: Icon(
                    acceptedProposals[index] ? Icons.check_circle : Icons.cancel,
                    color: acceptedProposals[index] ? Colors.green : Colors.red,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: acceptedCount == 0
              ? null
              : () {
                  final accepted = widget.proposals
                      .asMap()
                      .entries
                      .where((entry) => acceptedProposals[entry.key])
                      .map((entry) => entry.value)
                      .toList();
                  Navigator.of(context).pop(accepted);
                },
          child: Text('Create Final Plan ($acceptedCount)'),
        ),
      ],
    );
  }
}

/// Function to show the proposal selection dialog
Future<List<String>?> showProposalSelectionDialog(
  BuildContext context,
  List<String> proposals,
) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => ProposalSelectionDialog(proposals: proposals),
  );
}