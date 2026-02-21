import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

class LoadingMoreWidget extends StatelessWidget {
  const LoadingMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Center(
        child: Column(
          children: [
            Pulse(
              infinite: true,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.loadingMoreProjects,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}