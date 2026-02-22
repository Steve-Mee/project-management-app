import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:async';
import 'package:my_project_management_app/models/project_plan.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:my_project_management_app/core/services/payment_service.dart';

enum HelpLevel { basis, gedetailleerd, stapVoorStap }
enum Complexity { simpel, middel, complex }

/// Widget to display a structured project plan
class ProjectPlanDisplay extends ConsumerStatefulWidget {
  final ProjectPlan plan;
  final String? projectId;

  const ProjectPlanDisplay({
    super.key,
    required this.plan,
    this.projectId,
  });

  @override
  ConsumerState<ProjectPlanDisplay> createState() => _ProjectPlanDisplayState();
}

class _ProjectPlanDisplayState extends ConsumerState<ProjectPlanDisplay> {
  late ProjectPlan currentPlan;
  late Map<int, String> questionResponses;
  late Set<int> selectedProposals;
  late List<Widget> dynamicFields;
  late bool iosSelected;
  late bool androidSelected;
  late bool webSelected;
  late String? selectedRegion;
  late String? selectedAIAgent;
  late HelpLevel selectedHelpLevel;
  late Complexity selectedComplexity;
  late bool isLoading;
  late String? selectedCategory;
  late String? customCategory;
  late List<Map<String, dynamic>> messages;
  late TextEditingController chatController;
  late List<Map<String, dynamic>> history;
  late String? projectName;
  late String? projectDescription;
  bool liteMode = false;
  bool gdprConsent = false;
  bool voting = false;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _projectSubscription;

  Future<void> _loadLiteMode() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final data = await supabase
            .from('users')
            .select('lite_mode')
            .eq('id', userId)
            .single();
        setState(() {
          liteMode = data['lite_mode'] as bool? ?? false;
        });
      } catch (e) {
        debugPrint('Error loading lite mode: $e');
      }
    }
  }

  bool isLiteMode() {
    return liteMode;
  }

  Future<void> toggleLite(bool value) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await supabase
            .from('users')
            .update({'lite_mode': value})
            .eq('id', userId);
      } catch (e) {
        debugPrint('Error updating lite mode: $e');
      }
    }
    setState(() {
      liteMode = value;
    });
  }

  Future<void> rollbackToVersion(String projectId, int versionIndex) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await supabase
        .from('projects')
        .select('history')
        .eq('id', projectId)
        .single();

    List<dynamic> history = List.from(response['history'] ?? []);
    if (versionIndex < 0 || versionIndex >= history.length) {
      throw Exception('Invalid version index');
    }

    final snapshot = history[versionIndex] as Map<String, dynamic>;
    final plan = snapshot['plan'] as Map<String, dynamic>;

    // Update the current plan
    await supabase
        .from('projects')
        .update({'plan': plan})
        .eq('id', projectId);

    // Update local state if needed
    setState(() {
      currentPlan = ProjectPlan.fromJson(plan);
    });
  }

  Widget buildGDPRConsent(String region) {
    if (region == 'EU' && selectedCategory == 'Software') {
      return CheckboxListTile(
        title: const Text('I consent to processing my data for this AI request under GDPR'),
        subtitle: const Text('Your data will be anonymized and not stored for logging purposes'),
        value: gdprConsent,
        onChanged: (value) {
          setState(() {
            gdprConsent = value ?? false;
          });
        },
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> voteCustom(String cat) async {
    if (voting) return;
    voting = true;
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get current count
      final existing = await supabase
          .from('categories')
          .select('count')
          .eq('name', cat)
          .maybeSingle();

      int count = (existing?['count'] as int? ?? 0) + 1;

      // Upsert the category
      await supabase
          .from('categories')
          .upsert({'name': cat, 'count': count});

      // Check threshold for promotion
      if (count > 10) { // Assume threshold of 10 votes
        // Promote category - could add to predefined list or notify admin
        debugPrint('Category "$cat" promoted with $count votes');
        // Optionally, show a snackbar or dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "$cat" has been promoted!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error voting for category: $e');
    } finally {
      voting = false;
    }
  }

  @override
  void initState() {
    super.initState();
    currentPlan = widget.plan;
    questionResponses = {};
    selectedProposals = {};
    dynamicFields = [];
    iosSelected = false;
    androidSelected = false;
    webSelected = false;
    selectedRegion = null;
    selectedAIAgent = null;
    selectedHelpLevel = HelpLevel.basis;
    selectedComplexity = Complexity.simpel;
    isLoading = false;
    selectedCategory = null;
    customCategory = null;
    projectName = null;
    projectDescription = null;
    messages = [];
    chatController = TextEditingController();
    history = [];
    _loadLiteMode();
    checkSubscription();
    if (widget.projectId != null) {
      setupRealtime(widget.projectId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(authUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Plan'),
        actions: [
          IconButton(
            icon: Icon(liteMode ? Icons.lightbulb_outline : Icons.lightbulb),
            tooltip: 'Lite Mode: ${liteMode ? 'On' : 'Off'}',
            onPressed: () => toggleLite(!liteMode),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (widget.projectId != null) {
                try {
                  // Convert plan to JSON and save to project
                  final planJson = jsonEncode(currentPlan.toJson());
                  await ref.read(projectsProvider.notifier).updatePlanJson(widget.projectId!, planJson);
                  await saveVersion(currentPlan.toJson(), widget.projectId!);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plan saved successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save plan: $e')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No project selected to save plan')),
                  );
                }
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: buildRequirements({
          'hardware': ['CPU', 'RAM', 'GPU'],
          'software': ['Flutter', 'Dart', 'VS Code'],
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPlan.overview,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chapters with ExpansionTiles
            ...currentPlan.chapters.map((chapter) => Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ExpansionTile(
                title: Text(
                  chapter.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(chapter.overview),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        usersAsync.when(
                          data: (users) => _buildTasksList(chapter, users),
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => Text('Error loading users: $error'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(PlanChapter chapter, List<dynamic> users) {
    return Column(
      children: chapter.tasks.map((task) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Assigned to:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: task.assignedUserId,
                          hint: const Text('Select user'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ...users.map((user) => DropdownMenuItem<String>(
                              value: user.username,
                              child: Text(user.username, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              final updatedTasks = List<PlanTask>.from(chapter.tasks);
                              final taskIndex = chapter.tasks.indexOf(task);
                              updatedTasks[taskIndex] = task.copyWith(
                                assignedUserId: value,
                                assignedUserName: value,
                              );
                              final updatedChapters = List<PlanChapter>.from(currentPlan.chapters);
                              updatedChapters[currentPlan.chapters.indexOf(chapter)] = 
                                PlanChapter(
                                  title: chapter.title,
                                  overview: chapter.overview,
                                  tasks: updatedTasks,
                                );
                              currentPlan = ProjectPlan(
                                overview: currentPlan.overview,
                                chapters: updatedChapters,
                              );
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Done';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'In Progress';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Future<Map<String, dynamic>> _parseJson(String jsonResponse) async {
    try {
      return jsonDecode(jsonResponse) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid JSON: $e');
    }
  }

  Widget buildQuestions(String jsonResponse) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _parseJson(jsonResponse),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error parsing JSON: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        final questions = List<String>.from(data['questions'] ?? []);
        final proposals = List<String>.from(data['proposals'] ?? []);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (questions.isNotEmpty) ...[
                const Text('Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (ctx, i) {
                    final response = questionResponses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(questions[i]),
                        subtitle: response != null ? Text('Response: $response') : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: response == 'accept' ? null : () {
                                setState(() {
                                  questionResponses[i] = 'accept';
                                });
                              },
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: response == 'refuse' ? null : () {
                                setState(() {
                                  questionResponses[i] = 'refuse';
                                });
                              },
                              child: const Text('Refuse'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (proposals.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Proposals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: proposals.length,
                  itemBuilder: (ctx, i) => CheckboxListTile(
                    title: Text(proposals[i]),
                    value: selectedProposals.contains(i),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedProposals.add(i);
                        } else {
                          selectedProposals.remove(i);
                        }
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void updateFields(String category) {
    List<Widget> fields = [];
    try {
      switch (category) {
        case 'Software':
          fields = [
            const Text('Platforms:', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('iOS'),
              value: iosSelected,
              onChanged: (bool? value) {
                setState(() {
                  iosSelected = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Android'),
              value: androidSelected,
              onChanged: (bool? value) {
                setState(() {
                  androidSelected = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Web'),
              value: webSelected,
              onChanged: (bool? value) {
                setState(() {
                  webSelected = value ?? false;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Regions:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: selectedRegion,
              items: ['EU', 'US', 'Wereldwijd'].map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              )).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedRegion = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Regio'),
            ),
            const SizedBox(height: 16),
            const Text('AI-agent keuze:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: selectedAIAgent,
              items: ['Grok', 'ChatGPT', 'Claude', 'Other'].map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              )).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedAIAgent = value;
                });
              },
              decoration: const InputDecoration(labelText: 'AI Agent'),
            ),
          ];
          break;
        default:
          fields = [];
      }
    } catch (e) {
      fields = [Text('Error loading fields: $e')];
    }
    setState(() {
      dynamicFields = fields;
    });
  }

  Widget buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (questionResponses.length < 3)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: const Text(
              'Warning: Add at least 3 questions for better project planning results.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        if (selectedCategory == null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: const Text(
              'Warning: Please select a category.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        const Text('Hulpniveau', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: Radio<HelpLevel>(
            value: HelpLevel.basis,
            // ignore: deprecated_member_use
            groupValue: selectedHelpLevel,
            // ignore: deprecated_member_use
            onChanged: (HelpLevel? value) {
              if (value != null) {
                setState(() {
                  selectedHelpLevel = value;
                });
              }
            },
          ),
          title: const Text('Basis'),
        ),
        ListTile(
          leading: Radio<HelpLevel>(
            value: HelpLevel.gedetailleerd,
            // ignore: deprecated_member_use
            groupValue: selectedHelpLevel,
            // ignore: deprecated_member_use
            onChanged: (HelpLevel? value) {
              if (value != null) {
                setState(() {
                  selectedHelpLevel = value;
                });
              }
            },
          ),
          title: const Text('Gedetailleerd'),
        ),
        ListTile(
          leading: Radio<HelpLevel>(
            value: HelpLevel.stapVoorStap,
            // ignore: deprecated_member_use
            groupValue: selectedHelpLevel,
            // ignore: deprecated_member_use
            onChanged: (HelpLevel? value) {
              if (value != null) {
                setState(() {
                  selectedHelpLevel = value;
                });
              }
            },
          ),
          title: const Text('Stap-voor-stap'),
        ),
        const SizedBox(height: 16),
        const Text('Complexiteit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: Radio<Complexity>(
            value: Complexity.simpel,
            // ignore: deprecated_member_use
            groupValue: selectedComplexity,
            // ignore: deprecated_member_use
            onChanged: (Complexity? value) {
              if (value != null) {
                setState(() {
                  selectedComplexity = value;
                });
              }
            },
          ),
          title: const Text('Simpel'),
        ),
        ListTile(
          leading: Radio<Complexity>(
            value: Complexity.middel,
            // ignore: deprecated_member_use
            groupValue: selectedComplexity,
            // ignore: deprecated_member_use
            onChanged: (Complexity? value) {
              if (value != null) {
                setState(() {
                  selectedComplexity = value;
                });
              }
            },
          ),
          title: const Text('Middel'),
        ),
        ListTile(
          leading: Radio<Complexity>(
            value: Complexity.complex,
            // ignore: deprecated_member_use
            groupValue: selectedComplexity,
            // ignore: deprecated_member_use
            onChanged: (Complexity? value) {
              if (value != null) {
                setState(() {
                  selectedComplexity = value;
                });
              }
            },
          ),
          title: const Text('Complex'),
        ),
      ],
    );
  }

  void onDiscuss() async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiKey = dotenv.env['GROK_API_KEY'];
      final endpoint = dotenv.env['GROK_ENDPOINT'] ?? 'https://api.x.ai/v1/chat/completions';
      if (apiKey == null) {
        throw Exception('GROK_API_KEY not found in .env');
      }
      // Collect project data
      Map<String, dynamic> data = {
        'name': projectName ?? 'Unnamed Project',
        'category': selectedCategory == 'Custom' ? (customCategory ?? 'Custom') : selectedCategory,
        'description': projectDescription ?? 'No description',
        'extras': {
          'helpLevel': selectedHelpLevel.name,
          'complexity': selectedComplexity.name,
          'platforms': {
            'ios': iosSelected,
            'android': androidSelected,
            'web': webSelected,
          },
          'region': selectedRegion,
          'aiAgent': selectedAIAgent,
        },
      };
      String jsonString = jsonEncode(data);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonString,
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Grok Response'),
              content: Text(responseData.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to send data to Grok: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildPlan(Map<String, dynamic> plan) {
    final text = plan['text'] as String? ?? '';
    final chapters = plan['chapters'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chapters with ExpansionTile
          ...chapters.map((chapter) {
            final chapterMap = chapter as Map<String, dynamic>;
            final name = chapterMap['name'] as String? ?? '';
            final tasks = chapterMap['tasks'] as List<dynamic>? ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ExpansionTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: tasks.map((task) {
                  final taskMap = task as Map<String, dynamic>;
                  final id = taskMap['id'] as String? ?? '';
                  final desc = taskMap['desc'] as String? ?? '';
                  return ListTile(
                    title: Text('Task $id'),
                    subtitle: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: buildTaskActions(selectedCategory ?? '', text),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Task $id'),
                          content: Text(desc),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildTaskActions(String category, String projectSummary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            _showChatDialog(projectSummary);
          },
          child: const Text('Chat'),
        ),
        if (category == 'Software')
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                await _makeApiCall('Maak Code', projectSummary);
              },
              child: const Text('Maak Code'),
            ),
          ),
        if (category == 'Board Game')
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                await _makeApiCall('Maak Afbeelding', projectSummary);
              },
              child: const Text('Maak Afbeelding'),
            ),
          ),
        // Add more conditional buttons as needed
      ],
    );
  }

  void _showChatDialog(String projectSummary) {
    final TextEditingController chatController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat with Grok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: chatController,
              decoration: const InputDecoration(hintText: 'Enter your message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          if (customCategory != null)
            IconButton(
              icon: const Icon(Icons.thumb_up),
              tooltip: 'Vote for custom category',
              onPressed: () => voteCustom(customCategory!),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = chatController.text;
              if (message.isNotEmpty) {
                Navigator.of(context).pop();
                if (isLiteMode()) {
                  setState(() {
                    messages.add({
                      'text': message,
                      'isUser': true,
                      'timestamp': DateTime.now().toString(),
                    });
                  });
                } else {
                  await _makeApiCall('Chat: $message', projectSummary);
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _makeApiCall(String action, String projectSummary) async {
    setState(() {
      isLoading = true;
    });
    try {
      final prompt = await buildPrompt({'action': action, 'projectSummary': projectSummary}, 'software');
      if (!await estimateTokens(prompt)) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // GDPR check for EU region and Software category
      if (selectedRegion == 'EU' && selectedCategory == 'Software' && !gdprConsent) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('GDPR Consent Required'),
              content: const Text('Please provide consent for data processing in the settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final apiKey = dotenv.env['GROK_API_KEY'];
      final endpoint = dotenv.env['GROK_ENDPOINT'] ?? 'https://api.x.ai/v1/chat/completions';
      if (apiKey == null) {
        throw Exception('GROK_API_KEY not found in .env');
      }
      final data = {
        'message': prompt,
      };
      String jsonString = jsonEncode(data);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonString,
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Grok Response'),
              content: Text(responseData.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to send data to Grok: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildRequirements(Map<String, dynamic> req) {
    final hardware = req['hardware'] as List<dynamic>? ?? [];
    final software = req['software'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        const ListTile(
          title: Text(
            'Hardware Requirements',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...hardware.map((item) => ListTile(
          leading: const Icon(Icons.hardware),
          title: Text(item.toString()),
        )),
        const Divider(),
        const ListTile(
          title: Text(
            'Software Requirements',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...software.map((item) => ListTile(
          leading: const Icon(Icons.computer),
          title: Text(item.toString()),
        )),
      ],
    );
  }

  Widget buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return ListTile(
                title: Text(msg['text']),
                subtitle: Text(msg['timestamp']),
                leading: Icon(msg['isUser'] ? Icons.person : Icons.android),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  decoration: const InputDecoration(hintText: 'Enter message'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = chatController.text;
                  if (text.isNotEmpty) {
                    setState(() {
                      messages.add({
                        'text': text,
                        'isUser': true,
                        'timestamp': DateTime.now().toString(),
                      });
                    });
                    chatController.clear();
                    _sendToGrok(text);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _applyChanges();
                },
                child: const Text('Pas Toe'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendToGrok(String message) async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiKey = dotenv.env['GROK_API_KEY'];
      final endpoint = dotenv.env['GROK_ENDPOINT'] ?? 'https://api.x.ai/v1/chat/completions';
      if (apiKey == null) {
        throw Exception('GROK_API_KEY not found in .env');
      }
      final data = {
        'message': message,
        'projectSummary': currentPlan.overview, // or something
      };
      String jsonString = jsonEncode(data);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonString,
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          messages.add({
            'text': responseData.toString(),
            'isUser': false,
            'timestamp': DateTime.now().toString(),
          });
        });
        await _updateTokens(100); // Assume 100 tokens used
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        messages.add({
          'text': 'Error: $e',
          'isUser': false,
          'timestamp': DateTime.now().toString(),
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyChanges() {
    // Collect changes from messages or something
    final changes = messages.where((msg) => msg['isUser']).map((msg) => msg['text']).join('\n');
    // Send to Grok for update
    _sendToGrok('Apply changes: $changes');
    // Add to history
    setState(() {
      history.add({
        'timestamp': DateTime.now().toString(),
        'user_id': 'current_user', // assume
        'change': changes,
      });
    });
  }

  Future<void> _updateTokens(int tokensUsed) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final current = await supabase
          .from('user_tokens')
          .select('total_tokens, monthly_tokens')
          .eq('user_id', userId)
          .maybeSingle();

      int total = (current?['total_tokens'] ?? 0) + tokensUsed;
      int monthly = (current?['monthly_tokens'] ?? 0) + tokensUsed;

      await supabase.from('user_tokens').upsert({
        'user_id': userId,
        'total_tokens': total,
        'monthly_tokens': monthly,
      });
    } catch (e) {
      debugPrint('Error updating tokens: $e');
    }
  }

  Widget buildTokenDashboard() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Text('Not logged in');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('user_tokens')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final data = snapshot.data?.firstOrNull ?? {'total_tokens': 0, 'monthly_tokens': 0};
        int total = data['total_tokens'] ?? 0;
        int monthly = data['monthly_tokens'] ?? 0;
        const maxTotal = 100000; // Example max
        const maxMonthly = 10000; // Example max

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Token Usage', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Total Tokens: $total / $maxTotal'),
                LinearProgressIndicator(value: total / maxTotal),
                const SizedBox(height: 16),
                Text('Monthly Tokens: $monthly / $maxMonthly'),
                LinearProgressIndicator(value: monthly / maxMonthly),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveVersion(Map<String, dynamic> plan, String projectId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final timestamp = DateTime.now().toIso8601String();
    final snapshot = {
      'plan': plan,
      'timestamp': timestamp,
      'user_id': userId,
      'change': 'version_saved',
    };
    try {
      final response = await supabase
          .from('projects')
          .select('history')
          .eq('id', projectId)
          .single();

      List<dynamic> history = List.from(response['history'] ?? []);

      // Add new snapshot
      history.add(snapshot);

      // Limit to 10 versions
      if (history.length > 10) {
        history = history.sublist(history.length - 10);
      }

      // Update the project
      await supabase
          .from('projects')
          .update({'history': history})
          .eq('id', projectId);

      // Send notification to the current user (project owner) if not EU region
      final currentUser = supabase.auth.currentUser;
      if (selectedRegion != 'EU' && currentUser != null && currentUser.email != null) {
        await sendNotification('Plan version saved', [currentUser.email!]);
      }
    } catch (e) {
      debugPrint('Error saving version: $e');
      rethrow;
    }
  }

  Future<bool> estimateTokens(String prompt) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Estimate tokens using simple formula: tokens ≈ words / 0.75
    final words = prompt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final estimatedTokens = (words / 0.75).round();

    try {
      // Get user token data
      final userData = await supabase
          .from('users')
          .select('token_limit, current_usage')
          .eq('id', userId)
          .single();

      final limit = userData['token_limit'] as int? ?? 100000;
      final current = userData['current_usage'] as int? ?? 0;
      final projected = current + estimatedTokens;

      if (projected / limit > 0.8) {
        if (!mounted) return false;
        // Show confirmation dialog
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Token Limit Warning'),
            content: Text(
              'Estimated tokens for this request: $estimatedTokens\n'
              'Current usage: $current / $limit (${((current / limit) * 100).round()}%)\n'
              'Projected usage after this request: $projected (${((projected / limit) * 100).round()}%)\n\n'
              'Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        );
        return result ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error estimating tokens: $e');
      return true; // Proceed on error
    }
  }

  Future<void> sendNotification(String change, List<String> userEmails) async {
    // Send email notifications
    final smtpServer = gmail(dotenv.env['EMAIL_USERNAME']!, dotenv.env['EMAIL_PASSWORD']!);
    
    for (String email in userEmails) {
      final message = Message()
        ..from = Address(dotenv.env['EMAIL_FROM']!)
        ..recipients.add(email)
        ..subject = 'Project Change Notification'
        ..text = 'A change occurred in the project: $change';
      
      try {
        await send(message, smtpServer);
        debugPrint('Email sent to $email');
      } catch (e) {
        debugPrint('Failed to send email to $email: $e');
      }
    }

    // Send Slack notification if webhook is configured
    final slackWebhook = dotenv.env['SLACK_WEBHOOK'];
    if (slackWebhook != null && slackWebhook.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(slackWebhook),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': 'Project change notification: $change\nAffected users: ${userEmails.join(', ')}'
          }),
        );
        if (response.statusCode == 200) {
          debugPrint('Slack notification sent');
        } else {
          debugPrint('Failed to send Slack notification: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error sending Slack notification: $e');
      }
    }
  }

  Widget buildAssignDropdown(String taskId) {
    final usersAsync = ref.watch(authUsersProvider);

    return usersAsync.when(
      data: (users) {
        // Find the current assigned user
        String? assignedTo;
        final json = currentPlan.toJson();
        for (final chapter in json['chapters'] as List) {
          for (final task in chapter['tasks'] as List) {
            if (task['id'] == taskId) {
              assignedTo = task['assignedUserName'] as String?;
              break;
            }
          }
        }

        return DropdownButtonFormField<String?>(
          initialValue: assignedTo,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Unassigned'),
            ),
            ...users.map((user) {
              return DropdownMenuItem<String?>(
                value: user.username,
                child: Text(user.username),
              );
            }),
          ],
          onChanged: (String? value) {
            // Update the JSON
            final json = currentPlan.toJson();
            for (final chapter in json['chapters'] as List) {
              for (final task in chapter['tasks'] as List) {
                if (task['id'] == taskId) {
                  task['assignedUserName'] = value;
                  break;
                }
              }
            }
            setState(() {
              currentPlan = ProjectPlan.fromJson(json);
            });
            // Save to Supabase
            ref.read(projectsProvider.notifier).updatePlanJson(widget.projectId!, jsonEncode(json));
          },
          decoration: const InputDecoration(labelText: 'Assigned to'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading users: $error'),
    );
  }

  Widget buildHistoryTimeline(List history) {
    // Sort descending by timestamp
    history.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index] as Map<String, dynamic>;
        final timestamp = DateTime.parse(item['timestamp']);
        final userId = item['user_id'] as String?;
        final change = item['change'] as String? ?? 'unknown';

        Icon icon;
        switch (change) {
          case 'version_saved':
            icon = const Icon(Icons.save, color: Colors.blue);
            break;
          case 'rollback':
            icon = const Icon(Icons.undo, color: Colors.orange);
            break;
          default:
            icon = const Icon(Icons.history, color: Colors.grey);
        }

        return ListTile(
          leading: icon,
          title: Text(change.replaceAll('_', ' ').toUpperCase()),
          subtitle: Text('User: $userId\n${timestamp.toLocal()}'),
          isThreeLine: true,
        );
      },
    );
  }

  String handleEdgeCases(Map<String, dynamic> data) {
    String instructions = '';

    // Simple projects: max 3 questions
    final questions = data['questions'] as List<dynamic>? ?? [];
    if (questions.length <= 3) {
      instructions += '\n- This is a simple project with few requirements. Keep the plan concise and focused on the core essentials.\n';
    }

    // Incomplete input: check for missing fields
    final requiredFields = ['overview', 'category', 'questions'];
    final missing = requiredFields.where((field) => data[field] == null || (data[field] is String && (data[field] as String).isEmpty) || (data[field] is List && (data[field] as List).isEmpty));
    if (missing.isNotEmpty) {
      instructions += '\n- Some input is incomplete (${missing.join(', ')}). Ask for clarification if needed, but provide the best possible plan based on available information.\n';
    }

    // Hybrid tasks: check if multiple categories
    final category = data['category'] as String?;
    if (category != null && category.contains(' ') || category == 'overig') {
      instructions += '\n- This appears to be a hybrid or multi-disciplinary project. Integrate elements from multiple domains appropriately.\n';
    }

    return instructions;
  }

  String getModel(String category, String task) {
    const Map<String, String> modelMap = {
      'software': 'code_model',
      'board game': 'design_model',
      'hardware': 'engineering_model',
      'kunst': 'creative_model',
      'marketing': 'business_model',
      'architectuur': 'architecture_model',
      'onderwijs': 'education_model',
      'bedrijfsontwikkeling': 'business_model',
      'wetenschap': 'science_model',
      'overig': 'general_model',
      'finance': 'business_model',
      'healthcare': 'science_model',
      'entertainment': 'creative_model',
      'research': 'science_model',
      'consulting': 'business_model',
      'e-commerce': 'business_model',
      'gaming': 'design_model',
      'ai': 'science_model',
      'blockchain': 'engineering_model',
      'mobile': 'code_model',
      'web': 'code_model',
    };

    final model = modelMap[category.toLowerCase()] ?? 'general';
    debugPrint('Selected model for category "$category" and task "$task": $model');
    return model;
  }

  Future<String> buildPrompt(Map<String, dynamic> data, String category) async {
    final model = getModel(category, category);

    // Generate history summary
    final historySummary = await summarizeHistory(history);

    final systemInstructions = '''
You are Grok, a helpful and maximally truthful AI built by xAI.
Always respond in valid JSON format.
Provide structured, accurate responses based on the user's query.
${handleEdgeCases(data)}

Project History Summary: $historySummary
''';

    final userMessage = '''
Project Data: ${jsonEncode(data)}
Category: $category
Model: $model

Please provide a detailed response in JSON format.
''';

    // For API, this would be part of the messages array
    // But returning the user message as the prompt
    return '$systemInstructions\n\n$userMessage';
  }

  Future<String> summarizeHistory(List history) async {
    if (history.isEmpty) return 'No history available.';

    final apiKey = dotenv.env['GROK_API_KEY'];
    final endpoint = dotenv.env['GROK_ENDPOINT'] ?? 'https://api.x.ai/v1/chat/completions';
    if (apiKey == null) {
      throw Exception('GROK_API_KEY not found in .env');
    }

    final historyText = history.map((entry) {
      final timestamp = entry['timestamp'] ?? 'Unknown';
      final change = entry['change'] ?? 'Unknown change';
      final userId = entry['user_id'] ?? 'Unknown user';
      return '$timestamp: $change by $userId';
    }).join('\n');

    final prompt = '''
Summarize the following project history in a concise manner, limited to 200 tokens.
Focus on key changes, versions, and user activities.

History:
$historyText

Provide a brief summary:
''';

    final data = {
      'message': prompt,
      'model': 'grok-1', // or use getModel
      'max_tokens': 200,
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final summary = responseData['choices']?[0]?['message']?['content'] ?? 'Summary not available';

      // Save to DB
      final supabase = Supabase.instance.client;
      if (widget.projectId != null) {
        await supabase
            .from('projects')
            .update({'history_summary': summary})
            .eq('id', widget.projectId!);
      }

      // Update tokens (assume 50 tokens for summary)
      await _updateTokens(50);

      return summary;
    } else {
      throw Exception('Failed to summarize history: HTTP ${response.statusCode}');
    }
  }

  void setupRealtime(String projectId) {
    final supabase = Supabase.instance.client;

    // Clean up existing
    _realtimeChannel?.unsubscribe();
    _projectSubscription?.cancel();

    // Use stream for projects
    _projectSubscription = supabase
        .from('projects')
        .stream(primaryKey: ['id'])
        .eq('id', projectId)
        .listen((data) {
          if (data.isNotEmpty) {
            final project = data.first;
            final planJson = project['plan'];
            final historyData = List<Map<String, dynamic>>.from(project['history'] ?? []);
            final conversations = List<Map<String, dynamic>>.from(project['conversations'] ?? []);
            if (planJson != null) {
              setState(() {
                currentPlan = ProjectPlan.fromJson(planJson);
                history = historyData;
                messages = conversations;
              });
            }
          }
        });

    // For user_tokens, it's already handled by StreamBuilder in build
    // For conversations, it's included in projects stream
  }

  Future<void> checkSubscription() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Check user's subscription level from Supabase
      final subData = await supabase
          .from('subscriptions')
          .select('subscription_level, stripe_customer_id, status')
          .eq('user_id', userId)
          .maybeSingle();

      final level = subData?['subscription_level'] as String? ?? 'free';
      // final stripeCustomerId = subData?['stripe_customer_id'] as String?; // For future Stripe integration
      final status = subData?['status'] as String? ?? 'inactive';

      if (level == 'PremiumPlus' && status == 'active') {
        // Higher token limit for PremiumPlus
        const premiumLimit = 100000;
        await supabase.from('user_tokens').upsert({
          'user_id': userId,
          'total_tokens': premiumLimit,
          'monthly_tokens': premiumLimit,
        });
        debugPrint('PremiumPlus subscription active: token limit set to $premiumLimit');
      } else {
        // Default limits
        const defaultLimit = 10000;
        await supabase.from('user_tokens').upsert({
          'user_id': userId,
          'total_tokens': defaultLimit,
          'monthly_tokens': defaultLimit,
        });
      }

      // Handle monthly reset (this would be done server-side ideally)
      // For now, check if last_reset is more than a month ago
      final tokenData = await supabase
          .from('user_tokens')
          .select('last_reset')
          .eq('user_id', userId)
          .maybeSingle();

      if (tokenData != null) {
        final lastReset = DateTime.parse(tokenData['last_reset']);
        final now = DateTime.now();
        if (now.difference(lastReset).inDays >= 30) {
          // Reset monthly tokens
          await supabase.from('user_tokens').update({
            'monthly_tokens': level == 'PremiumPlus' ? 100000 : 10000,
            'last_reset': now.toIso8601String(),
          }).eq('user_id', userId);
          debugPrint('Monthly token reset performed');
        }
      }

      // Handle payments - integrated with PaymentService
      final paymentService = PaymentService();
      await paymentService.initialize();

      // Check if user has an active subscription that needs payment
      final subscriptionData = await supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'pending_payment')
          .maybeSingle();

      if (subscriptionData != null) {
        // Process pending payment using PaymentService
        try {
          debugPrint('Processing pending subscription payment for user $userId');

          // Use PaymentService to handle the subscription upgrade
          final result = await paymentService.processSubscriptionUpgrade(
            userId: userId,
            targetLevel: subscriptionData['level'] as String,
          );

          if (result['success'] == true) {
            debugPrint('Subscription payment processed successfully');
          } else {
            debugPrint('Error processing subscription payment: ${result['error']}');
          }
        } catch (e) {
          debugPrint('Error processing subscription payment: $e');
        }
      }

    } catch (e) {
      debugPrint('Error checking subscription: $e');
    }
  }

  Future<void> initDb() async {
    final createTableSQL = '''
    CREATE TABLE IF NOT EXISTS projects (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT,
      plan JSONB,
      history JSONB[] DEFAULT '[]'::jsonb[],
      history_summary TEXT,
      conversations JSONB[] DEFAULT '[]'::jsonb[],
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      version INTEGER DEFAULT 1,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_tokens (
      user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      total_tokens INTEGER DEFAULT 0,
      monthly_tokens INTEGER DEFAULT 0,
      last_reset TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS subscriptions (
      user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      subscription_level TEXT DEFAULT 'free',
      stripe_customer_id TEXT,
      stripe_subscription_id TEXT,
      status TEXT DEFAULT 'inactive',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ''';

    final rlsSQL = '''
    ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can insert their own projects" ON projects
      FOR INSERT WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can view their own projects" ON projects
      FOR SELECT USING (auth.uid() = user_id);

    CREATE POLICY "Users can update their own projects" ON projects
      FOR UPDATE USING (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own projects" ON projects
      FOR DELETE USING (auth.uid() = user_id);

    ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;

    ALTER TABLE user_tokens ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can view their own tokens" ON user_tokens
      FOR SELECT USING (auth.uid() = user_id);

    CREATE POLICY "Users can update their own tokens" ON user_tokens
      FOR UPDATE USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own membership" ON project_members
      FOR INSERT WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can view project memberships" ON project_members
      FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
          SELECT 1 FROM project_members pm
          WHERE pm.project_id = project_members.project_id
          AND pm.user_id = auth.uid()
        )
      );

    CREATE POLICY "Users can update memberships if they have permission" ON project_members
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM project_members pm
          WHERE pm.project_id = project_members.project_id
          AND pm.user_id = auth.uid()
          AND pm.role IN ('owner', 'admin')
        )
      );

    CREATE POLICY "Users can delete memberships if they have permission" ON project_members
      FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (
          SELECT 1 FROM project_members pm
          WHERE pm.project_id = project_members.project_id
          AND pm.user_id = auth.uid()
          AND pm.role IN ('owner', 'admin')
        )
      );

    ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can view their own subscriptions" ON subscriptions
      FOR SELECT USING (auth.uid() = user_id);

    CREATE POLICY "Users can update their own subscriptions" ON subscriptions
      FOR UPDATE USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own subscriptions" ON subscriptions
      FOR INSERT WITH CHECK (auth.uid() = user_id);
    ''';

    final versionControlSQL = '''
    CREATE OR REPLACE FUNCTION increment_version()
    RETURNS TRIGGER AS \$\$
    BEGIN
      NEW.version = OLD.version + 1;
      RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql;

    CREATE TRIGGER version_trigger
      BEFORE UPDATE ON projects
      FOR EACH ROW
      EXECUTE FUNCTION increment_version();
    ''';
    
    // Note: Execute this SQL in Supabase dashboard or via custom RPC function
    // For client-side initialization, this is not directly executable
    // Supabase tables should be created server-side for security
    debugPrint('Supabase Schema SQL:');
    debugPrint(createTableSQL);
    debugPrint(rlsSQL);
    debugPrint(versionControlSQL);
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _projectSubscription?.cancel();
    chatController.dispose();
    super.dispose();
  }
}