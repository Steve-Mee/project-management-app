import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';
import 'package:my_project_management_app/core/repository/auth_repository.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
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

    final repoAsync = ref.watch(authRepositoryProvider);
    return repoAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.adminPanelTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.adminPanelTitle)),
        body: Center(child: Text(error.toString())),
      ),
      data: (repo) {
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
            ],
          ),
        );
      },
    );
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

    final repo = await ref.read(authRepositoryProvider.future);
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

    final repo = await ref.read(authRepositoryProvider.future);
    await repo.upsertRole(role.copyWith(permissions: selected.toList()));
    setState(() {});
  }

  Future<void> _promptCreateGroup(
    BuildContext context,
    List<RoleDefinition> roles,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    String selectedRole = roles.isNotEmpty
        ? roles.first.id
        : AuthRepository.defaultUserRoleId;

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
    final repo = await ref.read(authRepositoryProvider.future);
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

    final repo = await ref.read(authRepositoryProvider.future);
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
                                await ref.read(authRepositoryProvider.future);
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
 }
