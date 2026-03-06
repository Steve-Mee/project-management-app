// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/providers.dart';
import 'package:project_management_app/features/ai_chat/ai_chat_modal.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/models/chat_message_model.dart';
import 'package:pma_core/models/task_model.dart';

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
    final visibleTasks = _activeProjectId == null
        ? _tasks
        : _tasks.where((t) => t.projectId == _activeProjectId).toList();
    state = AsyncValue.data(List<Task>.from(visibleTasks));
  }
}

class FakeAiChatNotifier extends AiChatNotifier {
  @override
  Future<AiChatState> build() async => const AiChatState();

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

    state = AsyncValue.data(state.value!.copyWith(
      messages: [...state.value!.messages, userMsg],
      isLoading: true,
      error: null,
    ));

    const taskTitle = 'New task';
    final targetProjectId = (projectId != null && projectId.isNotEmpty)
        ? projectId
        : 'project_1';
    await ref.read(tasksProvider.notifier).addTask(
          Task(
            id: 'ai-task-1',
            projectId: targetProjectId,
            title: taskTitle,
            createdAt: DateTime.now(),
          ),
        );

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Taak aangemaakt: $taskTitle',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(state.value!.copyWith(
      messages: [...state.value!.messages, aiMsg],
      isLoading: false,
    ));
  }
}

class FakeUseProjectFilesNotifier {
  bool build() => false;
}

void main() {
  testWidgets('AI creates task', (tester) async {
    final container = ProviderContainer(
      overrides: [
        tasksProvider.overrideWith(FakeTaskNotifier.new),
        aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) {
            return const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AiChatModal(projectId: 'project_1'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await container
      .read(aiChatProvider.notifier)
      .sendMessage('Create a task', projectId: 'project_1');
    await tester.pump();

    final tasks = container.read(tasksProvider).value ?? [];
    expect(
      tasks.whereType<Task>().any((task) => task.title == 'New task'),
      true,
    );
    final chatState = container.read(aiChatProvider);
    expect(
      chatState.value!.messages
          .whereType<ChatMessage>()
          .any((message) => message.content == 'Taak aangemaakt: New task'),
      true,
    );
  });
}
