import 'package:flutter/material.dart';
import 'package:my_project_management_app/models/project_requirements.dart';

/// Widget to display project requirements in an icon list view
class RequirementsIconListView extends StatelessWidget {
  final ProjectRequirements requirements;

  const RequirementsIconListView({
    super.key,
    required this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    if (requirements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Software requirements section
        if (requirements.software.isNotEmpty) ...[
          _buildSectionHeader(context, 'Software Requirements', Icons.computer),
          ...requirements.software.map((item) => _buildRequirementItem(
            context,
            item,
            Icons.code,
            Colors.blue,
          )),
          const SizedBox(height: 16),
        ],

        // Hardware requirements section
        if (requirements.hardware.isNotEmpty) ...[
          _buildSectionHeader(context, 'Hardware Requirements', Icons.hardware),
          ...requirements.hardware.map((item) => _buildRequirementItem(
            context,
            item,
            Icons.build,
            Colors.orange,
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    String requirement,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(requirement),
        dense: true,
      ),
    );
  }
}