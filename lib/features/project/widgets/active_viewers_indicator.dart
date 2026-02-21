import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/active_viewers_provider.dart';

/// Widget that displays active viewers in the projects list
class ActiveViewersIndicator extends ConsumerWidget {
  const ActiveViewersIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewers = ref.watch(activeViewersProvider);
    final isOnline = ref.watch(isOnlineProvider);

    // Only show if online and there are other viewers
    if (!isOnline || viewers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _buildTooltipMessage(viewers),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show up to 3 avatars
          ...viewers.take(3).map((viewer) => Padding(
            padding: const EdgeInsets.only(left: 2),
            child: CircleAvatar(
              radius: 10,
              backgroundImage: viewer.avatarUrl != null
                  ? NetworkImage(viewer.avatarUrl!)
                  : null,
              backgroundColor: viewer.avatarUrl == null
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: viewer.avatarUrl == null
                  ? Text(
                      (viewer.displayName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
          )),
          // Show count if more than 3 viewers
          if (viewers.length > 3) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${viewers.length - 3}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Icon(
            Icons.visibility,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _buildTooltipMessage(List<ActiveViewer> viewers) {
    if (viewers.isEmpty) return '';

    final names = viewers.map((v) => v.displayName ?? 'Unknown User').toList();
    final count = viewers.length;

    if (count == 1) {
      return '${names[0]} is viewing this page';
    } else if (count == 2) {
      return '${names[0]} and ${names[1]} are viewing this page';
    } else {
      final others = names.sublist(2);
      return '${names[0]}, ${names[1]}, and ${others.length} other${others.length == 1 ? '' : 's'} are viewing this page';
    }
  }
}