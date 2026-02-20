import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/ai/index.dart';
import 'package:my_project_management_app/core/providers/task_provider.dart';
import 'package:my_project_management_app/features/ai_chat/ai_chat_modal.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/chat_message_model.dart';
import 'package:my_project_management_app/models/task_model.dart';

class FakeTaskNotifier extends TaskNotifier {
  final List<Task> _tasks = [];
  String? _activeProjectId;

  @override
  Future<List<Task>> build() async => _tasks;

  @override
  Future<void> loadTasks(String projectId) async {
    _activeProjectId = projectId;
    state = AsyncValue.data(_tasks.where((t) => t.projectId == projectId).toList());
  }

  @override
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    if (_activeProjectId == task.projectId) {
      state = AsyncValue.data(
        _tasks.where((t) => t.projectId == _activeProjectId).toList(),
      );
    }
  }
}

class FakeAiChatNotifier extends AiChatNotifier {
  @override
  AiChatState build() => const AiChatState();

  @override
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    const taskTitle = 'New task';
    if (projectId != null && projectId.isNotEmpty) {
      await ref.read(tasksProvider.notifier).loadTasks(projectId);
      final task = Task(
        id: '${projectId}_test_${DateTime.now().millisecondsSinceEpoch}',
        projectId: projectId,
        title: taskTitle,
        description: 'Created by test AI',
        status: TaskStatus.todo,
        assignee: '',
        createdAt: DateTime.now(),
        priority: 0.5,
      );
      await ref.read(tasksProvider.notifier).addTask(task);
    }

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Taak aangemaakt: $taskTitle',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
    );
  }
}

class FakeUseProjectFilesNotifier extends UseProjectFilesNotifier {
  @override
  bool build() => false;
}

void main() {
  testWidgets('AI creates task', (tester) async {
    final container = ProviderContainer(
      overrides: [
        tasksProvider.overrideWith(FakeTaskNotifier.new),
        aiChatProvider.overrideWith(FakeAiChatNotifier.new),
        useProjectFilesProvider.overrideWith(FakeUseProjectFilesNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) {
            return MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: AiChatModal(projectId: 'project_1'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Create a task');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    final tasks = container.read(tasksProvider).value ?? [];
    expect(tasks.any((task) => task.title == 'New task'), true);
    final chatState = container.read(aiChatProvider);
    expect(
      chatState.messages.any(
        (message) => message.content == 'Taak aangemaakt: New task',
      ),
      true,
    );
  });
}
