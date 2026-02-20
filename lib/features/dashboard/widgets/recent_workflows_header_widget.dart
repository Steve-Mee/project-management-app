import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

class RecentWorkflowsHeaderWidget extends StatelessWidget {
  const RecentWorkflowsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          l10n.recentWorkflowsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}