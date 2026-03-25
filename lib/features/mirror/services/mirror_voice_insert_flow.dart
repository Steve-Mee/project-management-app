import 'package:flutter/material.dart';

class MirrorVoiceInsertFlow {
  const MirrorVoiceInsertFlow();

  Future<bool> confirmInsert({
    required BuildContext context,
    required String selectedFile,
    required String sanitizedText,
  }) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm voice insert'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Target file: $selectedFile'),
                const SizedBox(height: 6),
                Text('Characters: ${sanitizedText.length}'),
                const SizedBox(height: 10),
                const Text('Preview'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SelectableText(
                    sanitizedText,
                    maxLines: 8,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Insert into editor'),
            ),
          ],
        );
      },
    );

    return decision == true;
  }

  void showUndoSnackBar({
    required BuildContext context,
    required String selectedFile,
    required VoidCallback onUndo,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Voice draft inserted into $selectedFile'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: onUndo,
          ),
        ),
      );
  }
}
