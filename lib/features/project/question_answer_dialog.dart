import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for collecting answers to selected questions
class QuestionAnswerDialog extends ConsumerStatefulWidget {
  final List<String> questions;

  const QuestionAnswerDialog({
    super.key,
    required this.questions,
  });

  @override
  ConsumerState<QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends ConsumerState<QuestionAnswerDialog> {
  late List<TextEditingController> controllers;
  late List<String> answers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.questions.length, (_) => TextEditingController());
    answers = List.filled(widget.questions.length, '');
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Answer AI Questions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. $question',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    hintText: 'Your answer...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    answers[index] = value;
                  },
                ),
                const SizedBox(height: 16),
              ],
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
            // Check if at least some answers are provided
            final hasAnswers = answers.any((answer) => answer.trim().isNotEmpty);
            if (!hasAnswers) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide at least one answer')),
              );
              return;
            }
            Navigator.of(context).pop(answers);
          },
          child: const Text('Submit Answers'),
        ),
      ],
    );
  }
}

/// Function to show the question answer dialog
Future<List<String>?> showQuestionAnswerDialog(
  BuildContext context,
  List<String> questions,
) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => QuestionAnswerDialog(questions: questions),
  );
}