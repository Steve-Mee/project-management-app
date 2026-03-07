// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/auth/role_models.dart';
import 'package:project_management_app/features/admin/providers/index.dart';
import 'package:pma_core/core/services/analytics_events.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/routes.dart';
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}
class _AdminScreenState extends ConsumerState<AdminScreen> {
  String _userFilter = '';
  late Future<List<Map<String, dynamic>>> _featureFlagAuditFuture;

  @override
  void initState() {
    super.initState();
    _featureFlagAuditFuture = _loadFeatureFlagAuditEvents();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManageRoles =
        ref.watch(hasPermissionProvider(AppPermissions.manageRoles));
    if (!canManageRoles) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminPanelTitle)),
        body: Center(
          child: Text(
            l10n.accessDeniedMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final repo = ref.watch(authRepositoryProvider);
    final roles = repo.getRoles();
    final groups = repo.getGroups();
    final roleNames = {for (final role in roles) role.id: role.name};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPanelTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            context,
            'Feature Flags',
            onAdd: () {},
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Feature Flags (Admin)'),
              subtitle: const Text(
                'Toggle feature flags with Supabase RLS-protected writes',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.featureFlagsAdmin),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureFlagAuditSection(context),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            l10n.rolesTitle,
            onAdd: () => _promptCreateRole(context, roles),
          ),
          const SizedBox(height: 8),
          if (roles.isEmpty)
            Text(l10n.noRolesFound)
          else
            for (final role in roles)
              ListTile(
                title: Text(role.name),
                subtitle: Text(
                  l10n.permissionsCount(role.permissions.length),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.editPermissionsTooltip,
                      onPressed: () => _promptEditPermissions(context, role),
                    ),
                  ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                l10n.groupsTitle,
                onAdd: () => _promptCreateGroup(context, roles),
              ),
              const SizedBox(height: 8),
              if (groups.isEmpty)
                Text(l10n.noGroupsFound)
              else
                for (final group in groups)
                  Card(
                    child: ListTile(
                      title: Text(group.name),
                      subtitle: Text(
                        '${l10n.roleLabel}: ${roleNames[group.roleId] ?? group.roleId}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_alt_1),
                        tooltip: l10n.addGroupMemberTooltip,
                        onPressed: () => _promptAddGroupMember(
                          context,
                          group,
                        ),
                      ),
                      onTap: () => _showGroupMembers(context, group),
                    ),
                  ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                'AI Usage Analytics',
                onAdd: () {},
              ),
              const SizedBox(height: 8),
              _buildAIUsageAnalyticsSection(context),
            ],
          ),
        );
  }

  Widget _buildFeatureFlagAuditSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Feature Flag Audit (last 20)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh audit logs',
                  onPressed: () {
                    setState(() {
                      _featureFlagAuditFuture = _loadFeatureFlagAuditEvents();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _featureFlagAuditFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Could not load audit logs: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                if (rows.isEmpty) {
                  return const Text('No feature flag audit events found.');
                }

                return Column(
                  children: rows
                      .map((row) => _buildFeatureFlagAuditTile(context, row))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlagAuditTile(
    BuildContext context,
    Map<String, dynamic> row,
  ) {
    final parameters = row['parameters'] is Map
      ? Map<String, dynamic>.from(row['parameters'] as Map)
      : row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : const <String, dynamic>{};

    final flagKey = parameters['flag_key']?.toString() ?? 'unknown_flag';
    final previousEnabled = parameters['previous_enabled'];
    final nextEnabled = parameters['next_enabled'];
    final previousValue = parameters['previous_value'];
    final nextValue = parameters['next_value'];
    final userId = row['user_id']?.toString() ?? 'unknown_user';
    final timestamp = _formatAuditTimestamp(row['timestamp']);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history),
      title: Text(
        '$flagKey: ${_boolToLabel(previousEnabled)} -> ${_boolToLabel(nextEnabled)}',
      ),
      subtitle: Text('$timestamp | user: $userId'),
      onTap: () => _showFeatureFlagAuditDetails(
        context,
        flagKey: flagKey,
        userId: userId,
        timestamp: timestamp,
        previousEnabled: previousEnabled,
        nextEnabled: nextEnabled,
        previousValue: previousValue,
        nextValue: nextValue,
      ),
    );
  }

  Future<void> _showFeatureFlagAuditDetails(
    BuildContext context, {
    required String flagKey,
    required String userId,
    required String timestamp,
    required Object? previousEnabled,
    required Object? nextEnabled,
    required Object? previousValue,
    required Object? nextValue,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Feature Flag Change Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Flag: $flagKey'),
                Text('User: $userId'),
                Text('Time: $timestamp'),
                const SizedBox(height: 12),
                Text('Previous enabled: ${_boolToLabel(previousEnabled)}'),
                Text('Next enabled: ${_boolToLabel(nextEnabled)}'),
                const SizedBox(height: 12),
                Text('Previous value: ${_valueToPreview(previousValue)}'),
                const SizedBox(height: 8),
                Text('Next value: ${_valueToPreview(nextValue)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadFeatureFlagAuditEvents() async {
    final client = Supabase.instance.client;
    final response = await client
      .from('analytics_events')
      .select('event, user_id, timestamp, parameters')
        .eq('event', AnalyticsEventName.featureFlagChanged)
        .order('timestamp', ascending: false)
        .limit(20);

    final rows = response as List;
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  String _formatAuditTimestamp(Object? raw) {
    if (raw == null) {
      return 'unknown time';
    }

    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) {
      return raw.toString();
    }

    return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
  }

  String _boolToLabel(Object? value) {
    if (value is bool) {
      return value ? 'enabled' : 'disabled';
    }
    return 'unknown';
  }

  String _valueToPreview(Object? value) {
    if (value == null) {
      return 'null';
    }
    return value.toString();
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: title,
          onPressed: onAdd,
        ),
      ],
    );
  }
  Future<void> _promptCreateRole(
    BuildContext context,
    List<RoleDefinition> roles,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.roleCreateTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.roleNameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    final roleIdBase = name.toLowerCase().replaceAll(' ', '_');
    final roleId = roles.any((role) => role.id == 'role_$roleIdBase')
        ? 'role_${roleIdBase}_${DateTime.now().millisecondsSinceEpoch}'
        : 'role_$roleIdBase';
    final repo = ref.read(authRepositoryProvider);
    await repo.upsertRole(
      RoleDefinition(id: roleId, name: name, permissions: const []),
    );
    setState(() {});
  }
  Future<void> _promptEditPermissions(
    BuildContext context,
    RoleDefinition role,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = role.permissions.toSet();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.permissionsTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final permission in AppPermissions.all)
                  CheckboxListTile(
                    value: selected.contains(permission),
                    onChanged: (value) {
                      if (value == true) {
                        selected.add(permission);
                      } else {
                        selected.remove(permission);
                      }
                      setState(() {});
                    },
                    title: Text(permission),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    final repo = ref.read(authRepositoryProvider);
    await repo.upsertRole(role.copyWith(permissions: selected.toList()));
    setState(() {});
  }
  Future<void> _promptCreateGroup(
    BuildContext context,
    List<RoleDefinition> roles,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final repo = ref.read(authRepositoryProvider);
    String selectedRole = roles.isNotEmpty
        ? roles.first.id
        : repo.defaultUserRoleId;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.groupAddTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.groupNameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    items: roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role.id,
                            child: Text(role.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() {
                        selectedRole = value;
                      });
                    },
                    decoration: InputDecoration(labelText: l10n.roleLabel),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.saveButton),
                ),
              ],
            );
          },
        );
      },
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if (result != true || name.isEmpty) {
      return;
    }
    final groupId = name.toLowerCase().replaceAll(' ', '_');
    await repo.upsertGroup(
      GroupDefinition(
        id: groupId,
        name: name,
        roleId: selectedRole,
        members: const [],
      ),
    );
    setState(() {});
  }
  Future<void> _promptAddGroupMember(
    BuildContext context,
    GroupDefinition group,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addGroupMemberTitle(group.name)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.usernameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (username == null || username.isEmpty) {
      return;
    }
    final repo = ref.read(authRepositoryProvider);
    await repo.addUserToGroup(group.id, username);
    setState(() {});
  }
  Future<void> _showGroupMembers(
    BuildContext context,
    GroupDefinition group,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.groupMembersTitle(group.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: group.members.isEmpty
                ? [Text(l10n.noGroupMembers)]
                : [
                    for (final member in group.members)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(member),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: l10n.removeGroupMemberTooltip,
                          onPressed: () async {
                            final repo =
                                ref.read(authRepositoryProvider);
                            await repo.removeUserFromGroup(group.id, member);
                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ),
                  ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.closeButton),
            ),
          ],
        );
      },
    );
   }

  Widget _buildAIUsageAnalyticsSection(BuildContext context) {
    final usersAsync = ref.watch(authUsersProvider);

    return usersAsync.when(
      data: (users) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Usage Analytics', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Filter users'),
                onChanged: (value) => setState(() => _userFilter = value),
              ),
              const SizedBox(height: 16),
              ...users.where((u) => u.username.contains(_userFilter)).map((user) => _buildUserUsageTile(user)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _exportAllUsage,
                child: const Text('Export All Usage'),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error loading users: $e'))),
    );
  }

  Widget _buildUserUsageTile(AppUser user) {
    final usageAsync = ref.watch(aiUsageUserProvider(user.username));
    return usageAsync.when(
      data: (usage) => ListTile(
        title: Text(user.username),
        subtitle: Text('Total Cost: \$${usage['totalCost']?.toStringAsFixed(2) ?? '0.00'}'),
      ),
      loading: () => ListTile(
        title: Text(user.username),
        subtitle: const Text('Loading...'),
      ),
      error: (e, _) => ListTile(
        title: Text(user.username),
        subtitle: Text('Error: $e'),
      ),
    );
  }

  Future<void> _exportAllUsage() async {
    try {
      final data = await ref.read(aiUsageHistoryProvider.notifier).exportUsageHistory(format: 'csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${data.length} characters')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
