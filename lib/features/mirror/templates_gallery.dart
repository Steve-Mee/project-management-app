import 'package:flutter/material.dart';

class MirrorTemplate {
  const MirrorTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.seedContent,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String seedContent;
  final List<String> tags;
}

class TemplatesGallery extends StatelessWidget {
  const TemplatesGallery({
    super.key,
    required this.onTemplateSelected,
    this.templates = defaultTemplates,
    this.crossAxisCount = 2,
  });

  final ValueChanged<MirrorTemplate> onTemplateSelected;
  final List<MirrorTemplate> templates;
  final int crossAxisCount;

  static const List<MirrorTemplate> defaultTemplates = <MirrorTemplate>[
    MirrorTemplate(
      id: 'flutter-feature',
      title: 'Flutter Feature Module',
      description: 'Scaffold a complete feature with state, UI, and tests.',
      icon: Icons.widgets_outlined,
      tags: <String>['flutter', 'feature', 'riverpod'],
      seedContent: """Create a Flutter feature module with:
- state management via Riverpod
- screen, view model, and repository layers
- unit and widget tests
- clear file structure and TODO markers""",
    ),
    MirrorTemplate(
      id: 'api-integration',
      title: 'API Integration',
      description: 'Generate robust API client, models, and retry handling.',
      icon: Icons.cloud_outlined,
      tags: <String>['api', 'http', 'models'],
      seedContent: """Implement API integration with:
- typed request/response models
- error mapping and retry strategy
- logging hooks and parsing guards
- a short integration test checklist""",
    ),
    MirrorTemplate(
      id: 'bugfix-patch',
      title: 'Bugfix Patch',
      description: 'Focused fix with minimal risk and verification steps.',
      icon: Icons.bug_report_outlined,
      tags: <String>['bugfix', 'safe-change'],
      seedContent: """Apply a minimal bugfix patch:
- keep behavior unchanged outside the fix scope
- include guard clauses and null safety checks
- add regression tests if possible
- summarize potential risks""",
    ),
    MirrorTemplate(
      id: 'performance-pass',
      title: 'Performance Pass',
      description: 'Optimize hotspots and reduce UI jank where possible.',
      icon: Icons.speed_outlined,
      tags: <String>['performance', 'profiling'],
      seedContent: """Perform a performance pass:
- identify hot paths and rebuild bottlenecks
- reduce expensive operations in build methods
- memoize or cache safely where useful
- report expected perf impact""",
    ),
    MirrorTemplate(
      id: 'test-suite',
      title: 'Test Suite Booster',
      description: 'Expand coverage for core flows and failure cases.',
      icon: Icons.rule_folder_outlined,
      tags: <String>['tests', 'coverage', 'quality'],
      seedContent: """Create an expanded test suite:
- happy path and edge case tests
- async failure and timeout scenarios
- concise fixtures and reusable helpers
- coverage notes for remaining gaps""",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final computedCount = width < 640 ? 1 : crossAxisCount;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: computedCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: templates.length,
      itemBuilder: (BuildContext context, int index) {
        final template = templates[index];

        return _TemplateCard(
          template: template,
          onTap: () => onTemplateSelected(template),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  final MirrorTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      template.icon,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: template.tags
                    .take(3)
                    .map(
                      (String tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
