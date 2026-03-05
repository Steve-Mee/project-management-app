import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/project_providers.dart';
import '../providers/onboarding_provider.dart';
import '../providers/ai/ai_chat_provider.dart';
import '../routes.dart';
import '../services/project_invitation_service.dart';
import '../../models/project_model.dart';

/// Issue #067: main onboarding wizard (4-step flow).
///
/// This widget:
/// - shows onboarding only on first launch via [onboardingProvider]
/// - uses a [PageView] with smooth animated step navigation
/// - provides top progress + bottom Skip/Continue/Finish controls
/// - marks onboarding completed and navigates to the main app on finish
class OnboardingWizard extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingWizard({
    super.key,
    this.onCompleted,
  });

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  static const int _totalSteps = 4;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _hasCreatedFirstProject = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_isSubmitting) {
      return;
    }

    if (!_canContinueCurrentStep) {
      return;
    }

    if (_currentStep == _totalSteps - 1) {
      await _finishOnboarding();
      return;
    }

    await _pageController.animateToPage(
      _currentStep + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipOnboarding() async {
    if (_isSubmitting) {
      return;
    }

    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(onboardingProvider.notifier).markOnboardingCompleted();
      if (!mounted) {
        return;
      }
      widget.onCompleted?.call();
      if (widget.onCompleted != null) {
        return;
      }
      _navigateToMainApp();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _navigateToMainApp() {
    // Main app landing route in the current router setup.
    context.go(AppRoutes.dashboard);
  }

  bool get _canContinueCurrentStep {
    // Step 1 uses an in-content "Get Started" CTA.
    if (_currentStep == 0) {
      return false;
    }
    // Step 2 can only continue after a successful project creation.
    if (_currentStep == 1) {
      return _hasCreatedFirstProject;
    }
    return true;
  }

  Future<void> _goToStep(int stepIndex) async {
    await _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (_currentStep + 1) / _totalSteps;
    final isLastStep = _currentStep == _totalSteps - 1;
    final continueEnabled = _isSubmitting ? false : _canContinueCurrentStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Setup'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _skipOnboarding,
            child: const Text('Skip all'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Issue #067: progress indicator at top.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _OnboardingWelcomeStep(
                    onGetStarted: () => _goToStep(1),
                  ),
                  _OnboardingCreateProjectStep(
                    onProjectCreated: () {
                      setState(() {
                        _hasCreatedFirstProject = true;
                      });
                    },
                  ),
                  const _OnboardingAiIntroStep(),
                  _OnboardingInviteTeamStep(
                    onSkipForNow: _finishOnboarding,
                  ),
                ],
              ),
            ),
            // Issue #067: bottom navigation with Skip and Continue/Finish.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: continueEnabled ? _nextStep : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isLastStep
                                ? 'Finish'
                                : (_currentStep == 1
                                    ? 'Continue'
                                    : 'Continue'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 3: short AI intro with a quick chat demo entry point.
class _OnboardingAiIntroStep extends StatelessWidget {
  const _OnboardingAiIntroStep();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '3. AI intro',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Your AI assistant can help you draft plans, break work into tasks, and explore ideas faster.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Try a quick demo prompt and see the assistant respond in this onboarding flow.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const _QuickAiDemoDialog(),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open AI Demo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small AI demo dialog that reuses [aiChatProvider] for sending/receiving.
class _QuickAiDemoDialog extends ConsumerStatefulWidget {
  const _QuickAiDemoDialog();

  @override
  ConsumerState<_QuickAiDemoDialog> createState() => _QuickAiDemoDialogState();
}

class _QuickAiDemoDialogState extends ConsumerState<_QuickAiDemoDialog> {
  final TextEditingController _messageController = TextEditingController(
    text: 'Give me a simple 3-step project kickoff plan.',
  );

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendDemoPrompt() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    await ref.read(aiChatProvider.notifier).sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(aiChatProvider);

    return AlertDialog(
      title: const Text('AI Demo'),
      content: SizedBox(
        width: 520,
        child: chatStateAsync.when(
          data: (chatState) {
            final lastAiMessage = chatState.messages
                .where((msg) => !msg.isUser)
                .cast<dynamic>()
                .lastOrNull;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (chatState.error != null)
                  Text(
                    chatState.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 90),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lastAiMessage?.content ??
                        'No AI response yet. Send a prompt to run the demo.',
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('AI demo failed to load: $error'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _sendDemoPrompt,
          child: const Text('Send'),
        ),
      ],
    );
  }
}

/// Step 4: simple invite form that reuses [ProjectInvitationService].
///
/// Includes an inline "Skip for now" action that immediately finishes onboarding.
class _OnboardingInviteTeamStep extends ConsumerStatefulWidget {
  final Future<void> Function() onSkipForNow;

  const _OnboardingInviteTeamStep({
    required this.onSkipForNow,
  });

  @override
  ConsumerState<_OnboardingInviteTeamStep> createState() =>
      _OnboardingInviteTeamStepState();
}

class _OnboardingInviteTeamStepState
    extends ConsumerState<_OnboardingInviteTeamStep> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSendingInvite = false;
  String? _inviteMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() {
        _inviteMessage = 'Please enter a valid email address.';
      });
      return;
    }

    final projects = ref.read(projectsProvider).valueOrNull ?? <ProjectModel>[];
    if (projects.isEmpty) {
      setState(() {
        _inviteMessage =
            'No project found. Create a project first, then invite teammates.';
      });
      return;
    }

    final projectId = projects.first.id;

    setState(() {
      _isSendingInvite = true;
      _inviteMessage = null;
    });

    try {
      final invitationService =
          ProjectInvitationService(Supabase.instance.client);
      await invitationService.sendInvitation(projectId, email, 'member');

      if (!mounted) {
        return;
      }

      setState(() {
        _inviteMessage = 'Invitation sent successfully.';
      });
      _emailController.clear();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _inviteMessage = 'Could not send invite: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInvite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.group_add_outlined,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '4. Invite team',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Invite one teammate by email to start collaborating.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'teammate@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_inviteMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _inviteMessage!,
                    style: TextStyle(
                      color: _inviteMessage!.startsWith('Invitation sent')
                          ? Colors.green
                          : colorScheme.error,
                    ),
                  ),
                ),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSendingInvite ? null : widget.onSkipForNow,
                    child: const Text('Skip for now'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isSendingInvite ? null : _sendInvite,
                    icon: _isSendingInvite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Send Invite'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 1: welcome screen with app branding and explicit "Get Started" CTA.
class _OnboardingWelcomeStep extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _OnboardingWelcomeStep({
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.dashboard_customize_rounded,
                      size: 28,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Project Management App',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '1. Welcome',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to your workspace. In four quick steps, you will create your first project, discover AI support, and get your team invited.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Estimated setup time: less than 1 minute.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onGetStarted,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2: adapted from AddProjectDialog flow for inline onboarding usage.
///
/// The user enters name/description and creates their first project directly.
/// Parent wizard unlocks "Continue" only after [onProjectCreated] is called.
class _OnboardingCreateProjectStep extends ConsumerStatefulWidget {
  final VoidCallback onProjectCreated;

  const _OnboardingCreateProjectStep({
    required this.onProjectCreated,
  });

  @override
  ConsumerState<_OnboardingCreateProjectStep> createState() =>
      _OnboardingCreateProjectStepState();
}

class _OnboardingCreateProjectStepState
    extends ConsumerState<_OnboardingCreateProjectStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isCreating = false;
  bool _projectCreated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final projectName = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (projectName.isEmpty || _isCreating || _projectCreated) {
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final project = ProjectModel.create(
        name: projectName,
        progress: 0,
        description: description.isEmpty ? null : description,
      );
      await ref.read(projectsProvider.notifier).addProject(project);

      if (!mounted) {
        return;
      }

      setState(() {
        _projectCreated = true;
      });
      widget.onProjectCreated();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not create project: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.add_task_rounded,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '2. Create first project',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your first project to unlock the next step in onboarding.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_projectCreated,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'Enter project name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                enabled: !_projectCreated,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter project description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],
              if (_projectCreated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Project created. You can now continue to the next step.',
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: (_isCreating || _projectCreated)
                      ? null
                      : _createProject,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

