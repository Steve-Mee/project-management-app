import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/providers/ai/ai_chat_provider.dart' show aiChatProvider, aiHelpLevelProvider;
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/services/ai_planning_service.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;
import 'package:my_project_management_app/features/project/question_selection_dialog.dart';
import 'package:my_project_management_app/features/project/question_answer_dialog.dart';
import 'package:my_project_management_app/features/project/proposal_selection_dialog.dart';
import 'package:my_project_management_app/features/project/ai_consent_dialog.dart';
import 'package:my_project_management_app/features/project/project_plan_display.dart';

/// Data model for new project form
class NewProjectData {
  final String name;
  final String category;
  final String? customCategory;
  final String description;
  final double budget;
  final DateTimeRange? timeline;
  final int teamSize;
  final List<String> platforms; // For software
  final List<String> regions; // For software
  final String materials; // For hardware
  final String themes; // For board game
  final String components; // For board game
  final String extras; // For custom
  final bool isLoading; // For dynamic UI loading state
  final bool privacyConsent; // For AI discussion
  final String? aiAssistant; // For software: 'copilot', 'cursor', or null

  const NewProjectData({
    this.name = '',
    this.category = 'software',
    this.customCategory,
    this.description = '',
    this.budget = 0.0,
    this.timeline,
    this.teamSize = 1,
    this.platforms = const [],
    this.regions = const [],
    this.materials = '',
    this.themes = '',
    this.components = '',
    this.extras = '',
    this.isLoading = false,
    this.privacyConsent = false,
    this.aiAssistant,
  });

  NewProjectData copyWith({
    String? name,
    String? category,
    String? customCategory,
    String? description,
    double? budget,
    DateTimeRange? timeline,
    int? teamSize,
    List<String>? platforms,
    List<String>? regions,
    String? materials,
    String? themes,
    String? components,
    String? extras,
    bool? isLoading,
    bool? privacyConsent,
    String? aiAssistant,
  }) {
    return NewProjectData(
      name: name ?? this.name,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      timeline: timeline ?? this.timeline,
      teamSize: teamSize ?? this.teamSize,
      platforms: platforms ?? this.platforms,
      regions: regions ?? this.regions,
      materials: materials ?? this.materials,
      themes: themes ?? this.themes,
      components: components ?? this.components,
      extras: extras ?? this.extras,
      isLoading: isLoading ?? this.isLoading,
      privacyConsent: privacyConsent ?? this.privacyConsent,
      aiAssistant: aiAssistant ?? this.aiAssistant,
    );
  }

  String get effectiveCategory => category == 'custom' ? (customCategory ?? '') : category;

  bool get isValid =>
      name.isNotEmpty &&
      effectiveCategory.isNotEmpty &&
      description.isNotEmpty &&
      budget >= 0 &&
      timeline != null &&
      teamSize >= 1 && teamSize <= 20;

  /// Anonymize data for privacy
  Map<String, dynamic> toAnonymizedJson() {
    return {
      'category': effectiveCategory,
      'description': description,
      'budget': budget,
      'timeline_days': timeline?.duration.inDays,
      'team_size': teamSize,
      'platforms': platforms,
      'regions': regions,
      'materials': materials,
      'themes': themes,
      'components': components,
      'extras': extras,
    };
  }
}

/// Notifier for new project form state
class NewProjectFormNotifier extends Notifier<NewProjectData> {
  @override
  NewProjectData build() => const NewProjectData();

  void updateName(String name) => state = state.copyWith(name: name);
  void updateCategory(String category) {
    state = state.copyWith(category: category, isLoading: true);
    // Simulate loading for dynamic UI
    Future.delayed(const Duration(milliseconds: 300), () {
      state = state.copyWith(isLoading: false);
    });
  }
  void updateCustomCategory(String? customCategory) => state = state.copyWith(customCategory: customCategory);
  void updateDescription(String description) => state = state.copyWith(description: description);
  void updateBudget(double budget) => state = state.copyWith(budget: budget);
  void updateTimeline(DateTimeRange? timeline) => state = state.copyWith(timeline: timeline);
  void updateTeamSize(int teamSize) => state = state.copyWith(teamSize: teamSize);
  void updatePlatforms(List<String> platforms) => state = state.copyWith(platforms: platforms);
  void updateRegions(List<String> regions) => state = state.copyWith(regions: regions);
  void updateMaterials(String materials) => state = state.copyWith(materials: materials);
  void updateThemes(String themes) => state = state.copyWith(themes: themes);
  void updateComponents(String components) => state = state.copyWith(components: components);
  void updateExtras(String extras) => state = state.copyWith(extras: extras);
  void updatePrivacyConsent(bool consent) => state = state.copyWith(privacyConsent: consent);
  void updateAiAssistant(String? aiAssistant) => state = state.copyWith(aiAssistant: aiAssistant);

  void reset() => state = const NewProjectData();
}

/// Provider for new project form state
final newProjectFormProvider = NotifierProvider<NewProjectFormNotifier, NewProjectData>(
  NewProjectFormNotifier.new,
);

/// Provider for AI help level selection (using global provider)
final helpLevelProvider = aiHelpLevelProvider;

/// AlertDialog for creating a new project
class NewProjectDialog extends ConsumerStatefulWidget {
  const NewProjectDialog({super.key});

  @override
  ConsumerState<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends ConsumerState<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();

  /// Modular method for handling the complete AI discussion flow
  /// This method can be easily upgraded or modified without affecting the rest of the dialog
  Future<void> _startAiDiscussion(NewProjectData formData) async {
    // Show consent dialog first
    final consent = await showAiConsentDialog(context);
    if (consent != true) return;

    // Show loading
    ref.read(newProjectFormProvider.notifier).updateCategory(formData.category);

    try {
      // Get selected help level
      final helpLevel = ref.read(helpLevelProvider);

      // Generate planning questions
      final aiData = formData.toAnonymizedJson();
      final questions = await AiPlanningService.generateQuestions(aiData, helpLevel);

      // Reset loading
      ref.read(newProjectFormProvider.notifier).updateCategory(formData.category);

      // Show question selection dialog
      if (!mounted) return;
      final selectedQuestions = await showQuestionSelectionDialog(context, questions);
      if (selectedQuestions == null || selectedQuestions.isEmpty) return;

      // Show answer collection dialog
      if (!mounted) return;
      final answers = await showQuestionAnswerDialog(context, selectedQuestions);
      if (answers == null) return;

      // Generate proposals with answers
      final proposals = await ref.read(aiChatProvider.notifier).generateProposals(aiData, helpLevel, answers: answers);

      // Show proposal selection dialog
      if (!mounted) return;
      final acceptedProposals = await showProposalSelectionDialog(context, proposals);
      if (acceptedProposals == null || acceptedProposals.isEmpty) return;

      // Generate final plan
      final plan = await ref.read(aiChatProvider.notifier).generateFinalPlan(aiData);

      // Create the project with the plan
      final project = ProjectModel.create(
        name: formData.name.trim(),
        progress: 0.0,
        description: formData.description.trim(),
        category: formData.effectiveCategory,
        aiAssistant: formData.aiAssistant,
        planJson: jsonEncode(plan.toJson()),
        helpLevel: helpLevel,
      );

      // Add to projects provider
      ref.read(projectsProvider.notifier).addProject(project);

      // Close dialog and show plan
      ref.read(newProjectFormProvider.notifier).reset();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProjectPlanDisplay(plan: plan, projectId: project.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error in AI discussion: $e')),
        );
      }
    } finally {
      ref.read(newProjectFormProvider.notifier).updateCategory(formData.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(newProjectFormProvider);

    return AlertDialog(
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                initialValue: formData.name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
                onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateName(value),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: formData.category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'software', child: Text('Software')),
                  DropdownMenuItem(value: 'hardware', child: Text('Hardware')),
                  DropdownMenuItem(value: 'board game', child: Text('Board Game')),
                  DropdownMenuItem(value: 'content creation', child: Text('Content Creation')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(newProjectFormProvider.notifier).updateCategory(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom category field (shown when 'custom' is selected)
              if (formData.category == 'custom')
                TextFormField(
                  initialValue: formData.customCategory,
                  decoration: const InputDecoration(
                    labelText: 'Custom Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (formData.category == 'custom' && (value == null || value.trim().isEmpty)) {
                      return 'Custom category is required';
                    }
                    return null;
                  },
                  onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateCustomCategory(value),
                ),
              if (formData.category == 'custom') const SizedBox(height: 16),

              // Conditional fields based on category
              if (formData.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildConditionalFields(formData),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formData.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
                onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateDescription(value),
              ),
              const SizedBox(height: 16),

              // Budget field
              TextFormField(
                initialValue: formData.budget == 0.0 ? '' : formData.budget.toString(),
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Budget is required';
                  }
                  final budget = double.tryParse(value);
                  if (budget == null || budget < 0) {
                    return 'Please enter a valid budget';
                  }
                  return null;
                },
                onChanged: (value) {
                  final budget = double.tryParse(value) ?? 0.0;
                  ref.read(newProjectFormProvider.notifier).updateBudget(budget);
                },
              ),
              const SizedBox(height: 16),

              // Timeline picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formData.timeline == null
                          ? 'Select Timeline'
                          : '${formData.timeline!.start.toLocal().toString().split(' ')[0]} - ${formData.timeline!.end.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        initialDateRange: formData.timeline,
                      );
                      if (range != null) {
                        ref.read(newProjectFormProvider.notifier).updateTimeline(range);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              if (formData.timeline == null)
                const Text(
                  'Timeline is required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 16),

              // Team size slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Size: ${formData.teamSize}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: formData.teamSize.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: formData.teamSize.toString(),
                    onChanged: (value) {
                      ref.read(newProjectFormProvider.notifier).updateTeamSize(value.toInt());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Privacy consent checkbox
              CheckboxListTile(
                title: const Text('I consent to share anonymized project data with AI for discussion purposes'),
                subtitle: const Text('Data will be anonymized and used only for this session'),
                value: formData.privacyConsent,
                onChanged: (value) => ref.read(newProjectFormProvider.notifier).updatePrivacyConsent(value ?? false),
              ),
              const SizedBox(height: 16),

              // Help level dropdown for AI discussion
              DropdownButtonFormField<ai_config.HelpLevel>(
                initialValue: ref.watch(helpLevelProvider),
                decoration: const InputDecoration(
                  labelText: 'AI Help Level',
                  border: OutlineInputBorder(),
                ),
                items: ai_config.HelpLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(helpLevelProvider.notifier).state = value;
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(newProjectFormProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && formData.timeline != null) {
              // Show loading
              ref.read(newProjectFormProvider.notifier).updateCategory(formData.category); // trigger loading

              try {
                // Create the project (anonymized data)
                final project = ProjectModel.create(
                  name: formData.name.trim(),
                  progress: 0.0,
                  description: formData.description.trim(),
                  category: formData.effectiveCategory,
                  aiAssistant: formData.aiAssistant,
                );

                // Add to projects provider
                ref.read(projectsProvider.notifier).addProject(project);

                // Reset form and close dialog
                ref.read(newProjectFormProvider.notifier).reset();
                Navigator.of(context).pop(project);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating project: $e')),
                );
              } finally {
                ref.read(newProjectFormProvider.notifier).updateCategory(formData.category); // reset loading
              }
            } else if (formData.timeline == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a timeline')),
              );
            }
          },
          child: const Text('Create'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!formData.privacyConsent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide privacy consent to start AI discussion')),
              );
              return;
            }

            if (_formKey.currentState!.validate() && formData.timeline != null) {
              await _startAiDiscussion(formData);
            } else if (formData.timeline == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a timeline')),
              );
            }
          },
          child: const Text('Start AI Bespreking'),
        ),
      ],
    );
  }

  Widget _buildConditionalFields(NewProjectData formData) {
    switch (formData.category) {
      case 'software':
        return _buildSoftwareFields(formData);
      case 'hardware':
        return _buildHardwareFields(formData);
      case 'board game':
        return _buildBoardGameFields(formData);
      case 'content creation':
        return _buildContentCreationFields(formData);
      case 'custom':
        return _buildCustomFields(formData);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSoftwareFields(NewProjectData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Platforms', style: TextStyle(fontWeight: FontWeight.bold)),
        ...['Android', 'iOS', 'Web', 'Desktop'].map((platform) => CheckboxListTile(
          title: Text(platform),
          value: formData.platforms.contains(platform),
          onChanged: (value) {
            final newPlatforms = List<String>.from(formData.platforms);
            if (value == true) {
              newPlatforms.add(platform);
            } else {
              newPlatforms.remove(platform);
            }
            ref.read(newProjectFormProvider.notifier).updatePlatforms(newPlatforms);
          },
        )),
        const SizedBox(height: 16),
        const Text('Regions', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          children: ['EU', 'US', 'Worldwide'].map((region) => FilterChip(
            label: Text(region),
            selected: formData.regions.contains(region),
            onSelected: (selected) {
              final newRegions = List<String>.from(formData.regions);
              if (selected) {
                newRegions.add(region);
              } else {
                newRegions.remove(region);
              }
              ref.read(newProjectFormProvider.notifier).updateRegions(newRegions);
            },
          )).toList(),
        ),
        if (formData.regions.contains('EU'))
          Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(top: 8.0),
            color: Colors.orange.shade100,
            child: const Text(
              '⚠️ GDPR Warning: Ensure compliance with EU data protection regulations.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        const SizedBox(height: 16),
        const Text('AI Coding Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended for Flutter/Dart development:',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment<String?>(
                    value: 'copilot',
                    label: Text('GitHub Copilot'),
                  ),
                  ButtonSegment<String?>(
                    value: 'cursor',
                    label: Text('Cursor'),
                  ),
                  ButtonSegment<String?>(
                    value: null,
                    label: Text('None'),
                  ),
                ],
                selected: {formData.aiAssistant},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    ref.read(newProjectFormProvider.notifier).updateAiAssistant(selected.first);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareFields(NewProjectData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: formData.materials,
          decoration: const InputDecoration(
            labelText: 'Materials List',
            border: OutlineInputBorder(),
            hintText: 'Enter required materials separated by commas',
          ),
          maxLines: 2,
          onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateMaterials(value),
        ),
      ],
    );
  }

  Widget _buildBoardGameFields(NewProjectData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: formData.themes,
          decoration: const InputDecoration(
            labelText: 'Themes',
            border: OutlineInputBorder(),
            hintText: 'Enter game themes separated by commas',
          ),
          onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateThemes(value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formData.components,
          decoration: const InputDecoration(
            labelText: 'Components',
            border: OutlineInputBorder(),
            hintText: 'Enter game components (cards, dice, etc.)',
          ),
          maxLines: 2,
          onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateComponents(value),
        ),
      ],
    );
  }

  Widget _buildContentCreationFields(NewProjectData formData) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Content creation project - no additional fields required.'),
      ],
    );
  }

  Widget _buildCustomFields(NewProjectData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: formData.extras,
          decoration: const InputDecoration(
            labelText: 'Extras',
            border: OutlineInputBorder(),
            hintText: 'Enter any additional information',
          ),
          maxLines: 3,
          onChanged: (value) => ref.read(newProjectFormProvider.notifier).updateExtras(value),
        ),
      ],
    );
  }
}

/// Function to show the new project dialog
Future<ProjectModel?> showNewProjectDialog(BuildContext context) {
  return showDialog<ProjectModel>(
    context: context,
    builder: (context) => const NewProjectDialog(),
  );
}