import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/repository/hive_initializer.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/core/providers/ai/ai_chat_provider.dart' show useProjectFilesProvider;
import '../../core/providers/auth_providers.dart';
import '../../core/providers/theme_providers.dart';
import '../../core/services/project_transfer_service.dart';
import '../../features/dashboard/customize_dashboard_screen.dart';
import '../../core/config/ai_config.dart' as ai_config;

/// Settings screen - placeholder for application settings
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final consentEnabled = ref.watch(privacyConsentProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );
    final notificationsEnabled = ref.watch(notificationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final useProjectFiles = ref.watch(useProjectFilesProvider);
    final locale = ref.watch(localeProvider);
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final authState = ref.watch(authProvider).value!;
    final usersAsync = ref.watch(authUsersProvider);
    
    final canManageUsers =
      ref.watch(hasPermissionProvider(AppPermissions.manageUsers));
    final canManageRoles =
      ref.watch(hasPermissionProvider(AppPermissions.manageRoles));
    final canExportImport =
      ref.watch(hasPermissionProvider(AppPermissions.exportImport));
    final canViewSettings =
      ref.watch(hasPermissionProvider(AppPermissions.viewSettings));

    final isDarkMode = themeMode == ThemeMode.dark;
    final isSystemMode = themeMode == ThemeMode.system;
    final lastBackupTime = settingsAsync.maybeWhen(
      data: (settings) => settings.getLastBackupTime(),
      orElse: () => null,
    );
    final lastBackupPath = settingsAsync.maybeWhen(
      data: (settings) => settings.getLastBackupPath(),
      orElse: () => null,
    );
    final lastBackupLabel =
      (lastBackupTime == null ? null : _formatBackupTimestamp(lastBackupTime)) ??
        l10n.backupNeverMessage;
    final lastBackupPathLabel = lastBackupPath ?? l10n.backupNoFileMessage;

    if (!canViewSettings) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
        ),
        body: Center(
          child: Text(
            l10n.accessDeniedMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // Theme Section
          ListTile(
            leading: Icon(
              Icons.palette,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsDisplaySection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            value: isDarkMode,
            onChanged: (value) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            title: Text(l10n.settingsDarkModeTitle),
            subtitle: Text(l10n.settingsDarkModeSubtitle),
            secondary: Icon(
              Icons.brightness_6,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          SwitchListTile(
            value: isSystemMode,
            onChanged: (value) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(value ? ThemeMode.system : ThemeMode.light);
            },
            title: Text(l10n.settingsFollowSystemTitle),
            subtitle: Text(l10n.settingsFollowSystemSubtitle),
            secondary: Icon(
              Icons.phone_android,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Divider(),

          // Language Section
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsLanguageTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(l10n.settingsLanguageSubtitle),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: locale?.languageCode,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).setLocaleCode(value);
                  ref.invalidate(localeProvider);
                  setState(() {});
                },
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.languageSystem),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(l10n.languageEnglish),
                  ),
                  DropdownMenuItem(
                    value: 'nl',
                    child: Text(l10n.languageDutch),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Text(l10n.languageSpanish),
                  ),
                  DropdownMenuItem(
                    value: 'fr',
                    child: Text(l10n.languageFrench),
                  ),
                  DropdownMenuItem(
                    value: 'de',
                    child: Text(l10n.languageGerman),
                  ),
                  DropdownMenuItem(
                    value: 'pt',
                    child: Text(l10n.languagePortuguese),
                  ),
                  DropdownMenuItem(
                    value: 'it',
                    child: Text(l10n.languageItalian),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(l10n.languageArabic),
                  ),
                  DropdownMenuItem(
                    value: 'zh',
                    child: Text(l10n.languageChinese),
                  ),
                  DropdownMenuItem(
                    value: 'ja',
                    child: Text(l10n.languageJapanese),
                  ),
                  DropdownMenuItem(
                    value: 'ko',
                    child: Text(l10n.languageKorean),
                  ),
                  DropdownMenuItem(
                    value: 'ru',
                    child: Text(l10n.languageRussian),
                  ),
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text(l10n.languageHindi),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // Notifications Section
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsNotificationsSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(notificationsProvider.notifier)
                  .setEnabled(value);
            },
            title: Text(l10n.settingsNotificationsTitle),
            subtitle: Text(l10n.settingsNotificationsSubtitle),
            secondary: Icon(
              Icons.notifications_active,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Divider(),

          // Privacy Section
          ListTile(
            leading: Icon(
              Icons.security,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsPrivacySection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            value: consentEnabled,
            onChanged: (value) {
              ref
                  .read(privacyConsentProvider.notifier)
                  .setEnabled(value);
            },
            title: Text(l10n.settingsLocalFilesConsentTitle),
            subtitle: Text(l10n.settingsLocalFilesConsentSubtitle),
            secondary: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          SwitchListTile(
            value: useProjectFiles,
            onChanged: (value) {
              ref
                  .read(useProjectFilesProvider.notifier)
                  .setEnabled(value);
            },
            title: Text(l10n.settingsUseProjectFilesTitle),
            subtitle: Text(l10n.settingsUseProjectFilesSubtitle),
            secondary: Icon(
              Icons.folder_shared,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Divider(),

          // AI Settings Section (Modular)
          const _AiSettingsSection(),
          const Divider(),

          // Account Section
          ListTile(
            leading: Icon(
              Icons.account_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SwitchListTile(
            value: settingsAsync.maybeWhen(
              data: (settings) => settings.getAutoLoginEnabled(),
              orElse: () => false,
            ),
            onChanged: (value) async {
              final settings = await ref.read(settingsRepositoryProvider.future);
              await settings.setAutoLoginEnabled(value);
              setState(() {});
            },
            title: const Text('Auto-login inschakelen'),
            subtitle: const Text('Automatisch inloggen bij app start'),
            secondary: Icon(
              Icons.login,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          SwitchListTile(
            value: ref.watch(biometricLoginProvider).maybeWhen(
              data: (enabled) => enabled,
              orElse: () => false,
            ),
            onChanged: (value) async {
              await ref.read(biometricLoginProvider.notifier).setEnabled(value);
            },
            title: Text(l10n.settingsBiometricLoginTitle),
            subtitle: Text(l10n.settingsBiometricLoginSubtitle),
            secondary: Icon(
              Icons.fingerprint,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Divider(),

          // Projects Section
          ListTile(
            leading: Icon(
              Icons.folder,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsProjectsSection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(l10n.settingsLogoutTitle),
            subtitle: Text(l10n.settingsLogoutSubtitle),
            onTap: () {
              _confirmLogout(context, ref);
            },
          ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.upload_file,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsExportTitle),
              subtitle: Text(l10n.settingsExportSubtitle),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isExporting
                  ? null
                  : () {
                      _exportProjects(context, ref);
                    },
            ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsImportTitle),
              subtitle: Text(l10n.settingsImportSubtitle),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isImporting
                  ? null
                  : () {
                      _importProjects(context, ref);
                    },
            ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.backup,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsBackupTitle),
              subtitle: Text(l10n.settingsBackupSubtitle),
              trailing: _isBackingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isBackingUp
                  ? null
                  : () {
                      _backupHive(context);
                    },
            ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.restore,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsRestoreTitle),
              subtitle: Text(l10n.settingsRestoreSubtitle),
              trailing: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isRestoring
                  ? null
                  : () {
                      _restoreHive(context);
                    },
            ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsBackupLastRunLabel),
              subtitle: Text(lastBackupLabel),
              trailing: TextButton(
                onPressed: _isBackingUp ? null : () => _backupHive(context),
                child: Text(l10n.backupNowButton),
              ),
            ),
          if (canExportImport)
            ListTile(
              leading: Icon(
                Icons.folder_open,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsBackupPathLabel),
              subtitle: Text(lastBackupPathLabel),
            ),
          const Divider(),

          // Users Section
          ListTile(
            leading: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsUsersSection,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(l10n.settingsCurrentUserTitle),
            subtitle: Text(
              authState.username == null
                  ? l10n.settingsNotLoggedIn
                  : '${authState.username} (${authState.roleName ?? l10n.settingsLocalUserLabel})',
            ),
          ),
          usersAsync.when(
            data: (users) {
              // authRepositoryProvider is synchronous so treat it directly
              final authRepo = ref.read(authRepositoryProvider);
              final roleNames = {
                for (final role in authRepo.getRoles()) role.id: role.name,
              };
              if (users.isEmpty) {
                return ListTile(
                  title: Text(l10n.settingsNoUsersFound),
                );
              }

              return Column(
                children: [
                  for (final user in users)
                    ListTile(
                      leading: Icon(
                        Icons.account_circle_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: Text(user.username),
                      subtitle: Text(
                        '${l10n.settingsLocalUserLabel} (${roleNames[user.roleId] ?? user.roleId})',
                      ),
                      trailing: canManageUsers
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: l10n.settingsDeleteTooltip,
                              onPressed: () => _confirmDeleteUser(
                                context,
                                ref,
                                user.username,
                              ),
                            )
                          : null,
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.settingsLoadUsersFailed),
              subtitle: Text(error.toString()),
            ),
          ),
          if (canManageUsers)
            ListTile(
              leading: Icon(
                Icons.person_add_alt_1,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.settingsAddUserTitle),
              subtitle: Text(l10n.settingsAddUserSubtitle),
              onTap: () => _showAddUserDialog(context, ref),
            ),
          if (canManageRoles)
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(l10n.adminPanelTitle),
              subtitle: Text(l10n.adminPanelSubtitle),
              onTap: () => _openAdminPanel(context),
            ),
          const Divider(),

          // Dashboard Customization
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomizeDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard_customize),
              label: const Text('Customize Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.logoutDialogTitle),
          content: Text(l10n.logoutDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.logoutButton),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loggedOutMessage)),
      );
    }
  }

  void _openAdminPanel(BuildContext context) {
    context.go('/admin');
  }

  Future<void> _exportProjects(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final password = await _promptExportPassword(context);
    if (password == null) {
      return;
    }
    setState(() {
      _isExporting = true;
    });
    final projectRepository = ref.read(projectRepositoryProvider);
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final service = ProjectTransferService();

    try {
      final result = await service.exportData(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        password: password,
      );
      if (result == null) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.exportCompleteMessage(
              result.projectsPath,
              result.tasksPath,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        setState(() {
          _isExporting = false;
        });
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.exportFailedMessage(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<String?> _promptExportPassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final repeatController = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.exportPasswordTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.exportPasswordSubtitle),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repeatController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.repeatPasswordLabel,
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: () {
                    final password = passwordController.text;
                    final repeat = repeatController.text;
                    if (password.isEmpty || repeat.isEmpty || password != repeat) {
                      setDialogState(() {
                        errorText = l10n.exportPasswordMismatch;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(password);
                  },
                  child: Text(l10n.continueButton),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    repeatController.dispose();
    return result;
  }

  Future<void> _importProjects(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isImporting = true;
    });
    final projectRepository = ref.read(projectRepositoryProvider);
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final service = ProjectTransferService();

    try {
      final result = await service.importData(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
      );
      if (result == null) {
        if (!context.mounted) {
          setState(() {
            _isImporting = false;
          });
          return;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.importSelectFilesMessage)),
        );
        return;
      }

      ref.read(projectsProvider.notifier).refresh();
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.importCompleteMessage(
              result.projectsPath,
              result.tasksPath,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        setState(() {
          _isImporting = false;
        });
        return;
      }
      await _showImportErrorDialog(
        context,
        l10n.importFailedMessage(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _backupHive(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBackingUp = true;
    });

    try {
      final file = await HiveInitializer.backupHive();
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupSuccessMessage(file.path))),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupFailedMessage(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _restoreHive(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.restoreConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      await HiveInitializer.restoreHive(File(path));
      ref.read(projectsProvider.notifier).refresh();
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.restoreSuccessMessage)),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.restoreFailedMessage(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  String _formatBackupTimestamp(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _showImportErrorDialog(
    BuildContext context,
    String message,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.importFailedTitle),
          content: Text(message),
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

  Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addUserDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: l10n.usernameLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );

    if (result != true) {
      usernameController.dispose();
      passwordController.dispose();
      return;
    }

    final added = await ref
        .read(authProvider.notifier)
        .addUser(usernameController.text, passwordController.text);
    ref.invalidate(authUsersProvider);

    if (!context.mounted) {
      usernameController.dispose();
      passwordController.dispose();
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          added ? l10n.userAddedMessage : l10n.invalidUserMessage,
        ),
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteUserDialogTitle),
          content: Text(l10n.deleteUserDialogContent(username)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await ref.read(authProvider.notifier).deleteUser(username);
    ref.invalidate(authUsersProvider);

    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.userDeletedMessage(username))),
    );
  }
}

/// Modular AI settings section widget
class _AiSettingsSection extends ConsumerWidget {
  const _AiSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConsentEnabled = ref.watch(aiConsentProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );

    return Column(
      children: [
        // Help & AI Section Header
        ListTile(
          leading: Icon(
            Icons.smart_toy,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text(
            'Help & AI',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        // AI Consent Switch
        SwitchListTile(
          value: aiConsentEnabled,
          onChanged: (value) {
            ref.read(aiConsentProvider.notifier).setEnabled(value);
          },
          title: const Text('Enable AI with compliance consent'),
          subtitle: const Text('Allow AI features while ensuring compliance with privacy laws'),
          secondary: Icon(
            Icons.verified_user,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        // Compliance Warning
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI use must comply with your local laws worldwide.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Help Level Dropdown
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help Level'),
          subtitle: const Text('Choose how detailed task help should be'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ref.watch(helpLevelProvider).maybeWhen(
                data: (level) => level.name,
                orElse: () => ai_config.HelpLevel.basis.name,
              ),
              onChanged: (value) {
                if (value != null) {
                  ai_config.HelpLevel level;
                  switch (value) {
                    case 'gedetailleerd':
                      level = ai_config.HelpLevel.gedetailleerd;
                      break;
                    case 'stapVoorStap':
                      level = ai_config.HelpLevel.stapVoorStap;
                      break;
                    default:
                      level = ai_config.HelpLevel.basis;
                  }
                  ref.read(helpLevelProvider.notifier).setHelpLevel(level);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'basis',
                  child: Text('Basis'),
                ),
                DropdownMenuItem(
                  value: 'gedetailleerd',
                  child: Text('Gedetailleerd'),
                ),
                DropdownMenuItem(
                  value: 'stapVoorStap',
                  child: Text('Stap voor Stap'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
