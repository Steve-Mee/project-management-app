import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for selecting which AI-generated questions to ask
class QuestionSelectionDialog extends ConsumerStatefulWidget {
  final List<String> questions;

  const QuestionSelectionDialog({
    super.key,
    required this.questions,
  });

  @override
  ConsumerState<QuestionSelectionDialog> createState() => _QuestionSelectionDialogState();
}

class _QuestionSelectionDialogState extends ConsumerState<QuestionSelectionDialog> {
  late List<bool> selectedQuestions;

  @override
  void initState() {
    super.initState();
    selectedQuestions = List.filled(widget.questions.length, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Questions to Ask AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return CheckboxListTile(
              title: Text(question),
              value: selectedQuestions[index],
              onChanged: (value) {
                setState(() {
                  selectedQuestions[index] = value ?? false;
                });
              },
              secondary: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    selectedQuestions[index] = false;
                  });
                },
                tooltip: 'Skip this question',
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final selected = widget.questions
                .asMap()
                .entries
                .where((entry) => selectedQuestions[entry.key])
                .map((entry) => entry.value)
                .toList();
            Navigator.of(context).pop(selected);
          },
          child: const Text('Ask Selected Questions'),
        ),
      ],
    );
  }
}

/// Function to show the question selection dialog
Future<List<String>?> showQuestionSelectionDialog(
  BuildContext context,
  List<String> questions,
) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => QuestionSelectionDialog(questions: questions),
  );
}