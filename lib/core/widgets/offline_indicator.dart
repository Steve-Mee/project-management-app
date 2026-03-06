import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_management_app/core/providers/offline_status_providers.dart';

/// Global app bar wrapper that renders a slim offline/sync indicator above [appBar].
///
/// This widget is intended for top-level scaffolds so the indicator appears
/// consistently across screens.
class OfflineIndicatorAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const OfflineIndicatorAppBar({
    required this.appBar,
    this.onIndicatorTap,
    super.key,
  });

  /// The regular app bar shown below the indicator.
  final PreferredSizeWidget appBar;

  /// Optional tap callback. In the next step this will open a status dialog.
  final VoidCallback? onIndicatorTap;

  static const double _indicatorHeight = 28;

  @override
  Size get preferredSize => Size.fromHeight(
        _indicatorHeight + appBar.preferredSize.height,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineStatusProvider);
    final effectiveTapHandler =
        onIndicatorTap ?? () => _showStatusSheet(context, ref);

    return PreferredSize(
      preferredSize: preferredSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SafeArea keeps the slim status bar clear of notches/status bar.
          SafeArea(
            bottom: false,
            child: _OfflineIndicatorBar(
              state: state,
              height: _indicatorHeight,
              onTap: effectiveTapHandler,
            ),
          ),
          appBar,
        ],
      ),
    );
  }

  Future<void> _showStatusSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(offlineStatusProvider);
            final theme = Theme.of(context);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Current status',
                    value: '${state.connectivityLabel} | ${state.statusLabel}',
                    valueColor: state.statusColor,
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: 'Last sync',
                    value: _formatLastSync(context, state.lastSyncTime),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isSyncing
                          ? null
                          : () async {
                              await ref
                                  .read(offlineStatusProvider.notifier)
                                  .manualSync();
                            },
                      icon: state.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        state.isSyncing ? 'Syncing...' : 'Manual Sync Now',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatLastSync(BuildContext context, DateTime? lastSyncTime) {
    if (lastSyncTime == null) {
      return 'No sync yet';
    }

    final localizations = MaterialLocalizations.of(context);
    final dateText = localizations.formatMediumDate(lastSyncTime);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(lastSyncTime),
    );
    return '$dateText, $timeText';
  }
}

class _OfflineIndicatorBar extends StatelessWidget {
  const _OfflineIndicatorBar({
    required this.state,
    required this.height,
    this.onTap,
  });

  final OfflineStatusState state;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color barColor = state.statusColor;
    final _IndicatorPresentation presentation = _presentationForState(state);

    return Material(
      color: barColor,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  presentation.icon,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildStatusText(
                      context,
                      state,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_up,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _IndicatorPresentation _presentationForState(OfflineStatusState state) {
    switch (state.status) {
      case OfflineSyncStatus.synced:
        // Green: all changes are synced.
        return const _IndicatorPresentation(
          label: 'Synced',
          icon: Icons.cloud_done_rounded,
        );
      case OfflineSyncStatus.syncing:
        // Orange: sync operation is in progress.
        return const _IndicatorPresentation(
          label: 'Syncing',
          icon: Icons.sync_rounded,
        );
      case OfflineSyncStatus.offline:
        // Red: no connectivity, remote sync unavailable.
        return const _IndicatorPresentation(
          label: 'Offline',
          icon: Icons.cloud_off_rounded,
        );
    }
  }

  String _buildStatusText(
    BuildContext context,
    OfflineStatusState state,
  ) {
    final lastSyncTime = state.lastSyncTime;
    if (lastSyncTime == null) {
      return '${state.connectivityLabel} | ${state.statusLabel} | no sync yet';
    }

    final formatted = TimeOfDay.fromDateTime(lastSyncTime).format(context);
    return '${state.connectivityLabel} | ${state.statusLabel} | last sync $formatted';
  }
}

class _IndicatorPresentation {
  const _IndicatorPresentation({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
