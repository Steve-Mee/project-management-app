import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';

import '../providers.dart';

/// Issue #071: admin UI for viewing/toggling feature flags.
///
/// Security notes:
/// - Writes require JWT `app_metadata.role == 'admin'` per Supabase RLS.
/// - Without that claim, writes are denied by design (safe default).
/// - The UI surfaces save errors and does not mutate persisted data on failure.
class FeatureFlagsAdminWidget extends ConsumerStatefulWidget {
  const FeatureFlagsAdminWidget({super.key});

  @override
  ConsumerState<FeatureFlagsAdminWidget> createState() =>
      _FeatureFlagsAdminWidgetState();
}

class _FeatureFlagsAdminWidgetState
    extends ConsumerState<FeatureFlagsAdminWidget> {
  final Set<String> _savingKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(featureFlagProvider);
    final canManageFlags = ref.watch(hasPermissionProvider(AppPermissions.manageRoles)) ||
        ref.watch(hasPermissionProvider(AppPermissions.manageUsers));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags (Admin)'),
        actions: [
          IconButton(
            tooltip: 'Refresh flags',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(featureFlagProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: !canManageFlags
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Access denied: only admins can manage feature flags.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load feature flags: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (flags) {
          if (flags.isEmpty) {
            return const Center(
              child: Text('No feature flags found.'),
            );
          }

          final keys = flags.keys.toList()..sort();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final key = keys[index];
              final enabled = ref.read(featureFlagProvider.notifier).isEnabled(key);
              final isSaving = _savingKeys.contains(key);

              return SwitchListTile.adaptive(
                title: Text(key),
                subtitle: const Text('Persisted in Supabase feature_flags'),
                value: enabled,
                onChanged: isSaving
                    ? null
                    : (value) async {
                  final messenger = ScaffoldMessenger.maybeOf(this.context);

                  setState(() {
                    _savingKeys.add(key);
                  });

                  final ok = await ref
                      .read(featureFlagProvider.notifier)
                      .setFlagEnabled(key, value);

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _savingKeys.remove(key);
                  });

                  if (!mounted) {
                    return;
                  }

                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                          ? '$key set to ${value ? 'enabled' : 'disabled'}'
                          : 'Failed to save $key. JWT app_metadata.role must be admin for writes.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
