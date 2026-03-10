import 'package:flutter/material.dart';
import 'models/mirror_template.dart';

class TemplatesGallery extends StatelessWidget {
  const TemplatesGallery({
    super.key,
    required this.onTemplateSelected,
    this.templates = const <MirrorTemplate>[],
    this.crossAxisCount = 2,
  });

  final ValueChanged<MirrorTemplate> onTemplateSelected;
  final List<MirrorTemplate> templates;
  final int crossAxisCount;

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
                      _iconForTemplate(template),
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

IconData _iconForTemplate(MirrorTemplate template) {
  final normalizedIcon = template.iconName.trim().toLowerCase();
  switch (normalizedIcon) {
    case 'widgets':
      return Icons.widgets;
    case 'settings':
    case 'build':
      return Icons.settings;
    case 'description':
    case 'article':
      return Icons.description;
    case 'code':
      return Icons.code;
    case 'bug_report':
      return Icons.bug_report;
    case 'terminal':
      return Icons.terminal;
    case 'rocket_launch':
      return Icons.rocket_launch;
    case 'bolt':
      return Icons.bolt;
    case 'palette':
      return Icons.palette;
    case 'data_object':
      return Icons.data_object;
    case 'storage':
      return Icons.storage;
  }

  final normalizedKey = template.id.toLowerCase();
  if (normalizedKey.contains('widget') || normalizedKey.contains('ui')) {
    return Icons.widgets;
  }
  if (normalizedKey.contains('service') || normalizedKey.contains('backend')) {
    return Icons.settings;
  }
  if (normalizedKey.contains('doc') || normalizedKey.contains('markdown')) {
    return Icons.description;
  }

  return Icons.auto_awesome;
}
