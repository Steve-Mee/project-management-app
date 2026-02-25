import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/repository/hive_initializer.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/core/providers/ai/index.dart'
    show useProjectFilesProvider, aiChatProvider;
import '../../core/providers/auth_providers.dart';
import '../../core/providers/theme_providers.dart';
import '../../core/providers/payment_providers.dart';
import '../../core/services/project_transfer_service.dart';
import '../../features/dashboard/customize_dashboard_screen.dart';
import '../../core/config/ai_config.dart' as ai_config;
import '../../core/models/ai_rate_limits_config.dart';

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
    final consentEnabled = ref
        .watch(privacyConsentProvider)
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);
    final notificationsEnabled = ref
        .watch(notificationsProvider)
        .maybeWhen(data: (enabled) => enabled, orElse: () => true);
    final themeModeAsync = ref.watch(themeModeProvider);
    final colorSchemeSeedAsync = ref.watch(colorSchemeSeedProvider);
    final useProjectFiles = ref.watch(useProjectFilesProvider);
    final localeAsync = ref.watch(localeProvider);
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    final authState = ref.watch(authProvider).maybeWhen(
      data: (auth) => auth,
      orElse: () => const AuthState(isAuthenticated: false),
    );
    final usersAsync = ref.watch(authUsersProvider);

    final canManageUsers = ref.watch(
      hasPermissionProvider(AppPermissions.manageUsers),
    );
    final canManageRoles = ref.watch(
      hasPermissionProvider(AppPermissions.manageRoles),
    );
    final canExportImport = ref.watch(
      hasPermissionProvider(AppPermissions.exportImport),
    );
    final canViewSettings = ref.watch(
      hasPermissionProvider(AppPermissions.viewSettings),
    );

    final enableRealPaymentBackendAsync = ref.watch(enableRealPaymentBackendProvider);

    final isDarkMode = themeModeAsync.maybeWhen(
      data: (mode) => mode == ThemeMode.dark,
      orElse: () => false,
    );
    final isSystemMode = themeModeAsync.maybeWhen(
      data: (mode) => mode == ThemeMode.system,
      orElse: () => false,
    );
    final lastBackupTime = settingsAsync.maybeWhen(
      data: (settings) => settings.getLastBackupTime(),
      orElse: () => null,
    );
    final lastBackupPath = settingsAsync.maybeWhen(
      data: (settings) => settings.getLastBackupPath(),
      orElse: () => null,
    );
    final lastBackupLabel =
        (lastBackupTime == null
            ? null
            : _formatBackupTimestamp(lastBackupTime)) ??
        l10n.backupNeverMessage;
    final lastBackupPathLabel = lastBackupPath ?? l10n.backupNoFileMessage;

    if (!canViewSettings) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: Center(
          child: Text(
            l10n.accessDeniedMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
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

          // Color Scheme Section
          ListTile(
            leading: Icon(
              Icons.color_lens,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.settingsColorSchemeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(l10n.settingsColorSchemeSubtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ChoiceChip(
                  label: Text(l10n.settingsColorSchemeDefault),
                  selected: colorSchemeSeedAsync.maybeWhen(
                    data: (seed) => seed == Colors.green.toARGB32(),
                    orElse: () => false,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(colorSchemeSeedProvider.notifier).setColorSchemeSeed(Colors.green.toARGB32());
                    }
                  },
                  avatar: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 8,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.settingsColorSchemeBlue),
                  selected: colorSchemeSeedAsync.maybeWhen(
                    data: (seed) => seed == Colors.blue.toARGB32(),
                    orElse: () => false,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(colorSchemeSeedProvider.notifier).setColorSchemeSeed(Colors.blue.toARGB32());
                    }
                  },
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 8,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.settingsColorSchemePurple),
                  selected: colorSchemeSeedAsync.maybeWhen(
                    data: (seed) => seed == Colors.purple.toARGB32(),
                    orElse: () => false,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(colorSchemeSeedProvider.notifier).setColorSchemeSeed(Colors.purple.toARGB32());
                    }
                  },
                  avatar: CircleAvatar(
                    backgroundColor: Colors.purple,
                    radius: 8,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.settingsColorSchemeOrange),
                  selected: colorSchemeSeedAsync.maybeWhen(
                    data: (seed) => seed == Colors.orange.toARGB32(),
                    orElse: () => false,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(colorSchemeSeedProvider.notifier).setColorSchemeSeed(Colors.orange.toARGB32());
                    }
                  },
                  avatar: CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 8,
                  ),
                ),
              ],
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
                value: localeAsync.maybeWhen(
                  data: (loc) => loc?.languageCode,
                  orElse: () => null,
                ),
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
              ref.read(notificationsProvider.notifier).setEnabled(value);
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
              ref.read(privacyConsentProvider.notifier).setEnabled(value);
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
              ref.read(useProjectFilesProvider.notifier).setEnabled(value);
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
              final settings = await ref.read(
                settingsRepositoryProvider.future,
              );
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
            value: ref
                .watch(biometricLoginProvider)
                .maybeWhen(data: (enabled) => enabled, orElse: () => false),
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

          // Subscription Section
          ListTile(
            leading: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Subscription',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final paymentState = ref.watch(paymentProvider);
              final authState = ref.watch(authProvider).maybeWhen(
                data: (auth) => auth,
                orElse: () => const AuthState(isAuthenticated: false),
              );

              return paymentState.when(
                data: (status) {
                  final isPremium = authState.subscriptionLevel == 'Premium' || authState.subscriptionLevel == 'PremiumPlus';

                  if (isPremium) {
                    return ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text('Premium ${authState.subscriptionLevel}'),
                      subtitle: const Text('You have an active premium subscription'),
                    );
                  }

                  // Show upgrade button or error/retry state
                  return ListTile(
                    leading: Icon(
                      status.status == 'error' ? Icons.error : Icons.upgrade,
                      color: status.status == 'error' ? Colors.red : Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(status.status == 'error' ? 'Payment Failed' : 'Upgrade to Premium'),
                    subtitle: Text(status.status == 'error' ? status.message ?? 'Unknown error' : 'Unlock advanced features'),
                    trailing: status.status == 'processing'
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: status.status == 'processing'
                        ? null
                        : () async {
                            if (status.status == 'error') {
                              // Retry payment
                              await ref.read(paymentProvider.notifier).retryPayment(
                                amount: 999, // $9.99
                                currency: 'usd',
                                product: 'Premium',
                              );
                            } else {
                              // Start new payment
                              await ref.read(paymentProvider.notifier).createCheckoutSession(
                                amount: 999, // $9.99
                                currency: 'usd',
                                product: 'Premium',
                              );
                            }
                          },
                  );
                },
                loading: () => const ListTile(
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Loading...'),
                ),
                error: (error, stack) => ListTile(
                  leading: Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                  title: const Text('Error loading payment status'),
                  subtitle: Text(error.toString()),
                ),
              );
            },
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
                  : '${authState.username!} (${authState.roleName ?? l10n.settingsLocalUserLabel})',
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
                return ListTile(title: Text(l10n.settingsNoUsersFound));
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
          if (canManageRoles)
            SwitchListTile(
              value: enableRealPaymentBackendAsync.maybeWhen(
                data: (enabled) => enabled,
                orElse: () => false,
              ),
              onChanged: (value) {
                ref
                    .read(enableRealPaymentBackendProvider.notifier)
                    .setEnableRealPaymentBackend(value);
              },
              title: Text(l10n.enable_real_payment_backend),
              subtitle: enableRealPaymentBackendAsync.maybeWhen(
                data: (enabled) => enabled ? Text(l10n.real_backend_warning) : null,
                orElse: () => null,
              ),
              secondary: Icon(
                Icons.payment,
                color: Theme.of(context).colorScheme.secondary,
              ),
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.loggedOutMessage)));
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
            l10n.exportCompleteMessage(result.projectsPath, result.tasksPath),
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
                    decoration: InputDecoration(labelText: l10n.passwordLabel),
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
                    if (password.isEmpty ||
                        repeat.isEmpty ||
                        password != repeat) {
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
            l10n.importCompleteMessage(result.projectsPath, result.tasksPath),
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
                decoration: InputDecoration(labelText: l10n.usernameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
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
        content: Text(added ? l10n.userAddedMessage : l10n.invalidUserMessage),
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
    final aiConsentEnabled = ref
        .watch(aiConsentProvider)
        .maybeWhen(data: (enabled) => enabled, orElse: () => false);

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
          subtitle: const Text(
            'Allow AI features while ensuring compliance with privacy laws',
          ),
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
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
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
        // Subscription Section
        ListTile(
          leading: Icon(
            Icons.star,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'Subscription',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final paymentState = ref.watch(paymentProvider);
            return ListTile(
              leading: const Icon(Icons.upgrade),
              title: const Text('Upgrade Subscription'),
              subtitle: const Text('Get premium features and higher limits'),
              trailing: paymentState.maybeWhen(
                data: (status) {
                  switch (status.status) {
                    case 'processing':
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    case 'success':
                      return Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      );
                    case 'error':
                      return Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      );
                    default:
                      return const Icon(Icons.arrow_forward_ios);
                  }
                },
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stack) => Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                orElse: () => const Icon(Icons.arrow_forward_ios),
              ),
              onTap: paymentState.maybeWhen(
                data: (status) {
                  if (status.status == 'processing') return null;
                  
                  // If there's an error, show retry option
                  if (status.status == 'error') {
                    return () async {
                      try {
                        await ref.read(paymentProvider.notifier).retryPayment(
                          amount: 999,
                          currency: 'usd',
                          product: 'Premium Subscription',
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Retry failed: $e')),
                          );
                        }
                      }
                    };
                  }
                  
                  // Normal upgrade flow
                  return () async {
                    try {
                      final sessionId = await ref.read(paymentProvider.notifier).createCheckoutSession(
                        amount: 999, // $9.99
                        currency: 'usd',
                        product: 'Premium Subscription',
                      );
                      if (context.mounted) {
                        // Show success dialog with session info
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Checkout Created'),
                            content: Text('Session ID: $sessionId\n\nIn production, this would open Stripe Checkout.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: Text('Failed to create checkout: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  };
                },
                orElse: () => null,
              ),
            );
          },
        ),
        // Help Level Dropdown
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help Level'),
          subtitle: const Text('Choose how detailed task help should be'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ref
                  .watch(helpLevelProvider)
                  .maybeWhen(
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
                DropdownMenuItem(value: 'basis', child: Text('Basis')),
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
        // AI Per-Operation Rate Limits Section
        ListTile(
          leading: Icon(
            Icons.speed,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'AI Per-Operation Rate Limits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ..._buildPerOperationLimitControls(context, ref),
        // AI Backoff Settings Section
        ListTile(
          leading: Icon(
            Icons.timer,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            'AI Backoff Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ..._buildBackoffSettingsControls(context, ref),
      ],
    );
  }

  /// Build dynamic list of operation-specific rate limit controls
  List<Widget> _buildPerOperationLimitControls(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rateLimitsAsync = ref.watch(aiRateLimitsConfigProvider);
    
    return rateLimitsAsync.maybeWhen(
      data: (config) {
        final operations = config.perOperationLimits.keys.toList()..sort();
        
        return operations.map((operation) {
          final currentLimit = config.perOperationLimits[operation] ?? config.maxRequestsPerWindow;
          final displayName = _getOperationDisplayName(operation, l10n);
          
          return Consumer(
            builder: (context, ref, child) {
              final liveConfig = ref.watch(aiRateLimitsConfigProvider).maybeWhen(
                data: (config) => config,
                orElse: () => AiRateLimitsConfig.defaults(),
              );
              final liveLimit = liveConfig.perOperationLimits[operation] ?? liveConfig.maxRequestsPerWindow;
              
              return ListTile(
                title: Text(displayName),
                subtitle: Text('Current limit: $liveLimit requests per window'),
                trailing: SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: currentLimit.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) => _updateOperationLimit(ref, operation, value, context, l10n),
                  ),
                ),
              );
            },
          );
        }).toList();
      },
      orElse: () => [const SizedBox.shrink()],
    );
  }

  /// Get localized display name for operation
  String _getOperationDisplayName(String operation, AppLocalizations l10n) {
    switch (operation) {
      case 'chat':
        return l10n.limit_for_chat;
      case 'summarize':
        return l10n.limit_for_summarize;
      case 'generate_questions':
        return l10n.limit_for_generate_questions;
      case 'generate_proposals':
        return l10n.limit_for_generate_proposals;
      case 'generate_plan':
        return l10n.limit_for_generate_plan;
      case 'parse_filter':
        return l10n.limit_for_parse_filter;
      default:
        return operation.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Update per-operation limit
  void _updateOperationLimit(WidgetRef ref, String operation, String value, BuildContext context, AppLocalizations l10n) {
    final limit = int.tryParse(value);
    if (limit == null || limit < 1) return;
    
    ref.read(aiRateLimitsConfigProvider.notifier).setAiRateLimitsConfig(
      ref.read(aiRateLimitsConfigProvider).maybeWhen(
        data: (currentConfig) {
          final updatedLimits = Map<String, int>.from(currentConfig.perOperationLimits);
          updatedLimits[operation] = limit;
          return currentConfig.copyWith(perOperationLimits: updatedLimits);
        },
        orElse: () => AiRateLimitsConfig.defaults(),
      ),
    ).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.per_op_limit_saved)),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save limit: $error')),
        );
      }
    });
  }

  /// Build backoff settings controls
  List<Widget> _buildBackoffSettingsControls(BuildContext context, WidgetRef ref) {
    final rateLimitsAsync = ref.watch(aiRateLimitsConfigProvider);
    
    return rateLimitsAsync.maybeWhen(
      data: (config) {
        return [
          // Base Delay Slider
          Consumer(
            builder: (context, ref, child) {
              final liveConfig = ref.watch(aiRateLimitsConfigProvider).maybeWhen(
                data: (config) => config,
                orElse: () => AiRateLimitsConfig.defaults(),
              );
              final currentValue = liveConfig.backoffBaseDelay.inMilliseconds.toDouble();
              
              return ListTile(
                title: Text('Base Delay'),
                subtitle: Text('${currentValue.toInt()}ms'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: currentValue,
                    min: 100,
                    max: 10000,
                    divisions: 99,
                    onChanged: (value) => _updateBackoffBaseDelay(ref, value.toInt(), context),
                  ),
                ),
              );
            },
          ),
          // Max Delay Slider
          Consumer(
            builder: (context, ref, child) {
              final liveConfig = ref.watch(aiRateLimitsConfigProvider).maybeWhen(
                data: (config) => config,
                orElse: () => AiRateLimitsConfig.defaults(),
              );
              final currentValue = liveConfig.backoffMaxDelay.inSeconds.toDouble();
              
              return ListTile(
                title: Text('Max Delay'),
                subtitle: Text('${currentValue.toInt()}s'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: currentValue,
                    min: 5,
                    max: 300,
                    divisions: 59,
                    onChanged: (value) => _updateBackoffMaxDelay(ref, value.toInt(), context),
                  ),
                ),
              );
            },
          ),
          // Max Retry Attempts Slider
          Consumer(
            builder: (context, ref, child) {
              final liveConfig = ref.watch(aiRateLimitsConfigProvider).maybeWhen(
                data: (config) => config,
                orElse: () => AiRateLimitsConfig.defaults(),
              );
              final currentValue = liveConfig.maxRetryAttempts.toDouble();
              
              return ListTile(
                title: Text('Max Retries'),
                subtitle: Text('${currentValue.toInt()} attempts'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: currentValue,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (value) => _updateMaxRetryAttempts(ref, value.toInt(), context),
                  ),
                ),
              );
            },
          ),
          // Queue Status Display
          Consumer(
            builder: (context, ref, child) {
              final chatStateAsync = ref.watch(aiChatProvider);
              return chatStateAsync.maybeWhen(
                data: (chatState) {
                  return ListTile(
                    title: Text('Queued requests'),
                    subtitle: Text('${chatState.queueLength} pending'),
                    leading: Icon(
                      Icons.queue,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
                orElse: () => ListTile(
                  title: Text('Queued requests'),
                  subtitle: Text('Loading...'),
                  leading: Icon(
                    Icons.queue,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              );
            },
          ),
          // Queue Enabled Toggle
          Consumer(
            builder: (context, ref, child) {
              final liveConfig = ref.watch(aiRateLimitsConfigProvider).maybeWhen(
                data: (config) => config,
                orElse: () => AiRateLimitsConfig.defaults(),
              );
              
              return SwitchListTile(
                value: liveConfig.queueEnabled,
                onChanged: (value) => _updateQueueEnabled(ref, value, context),
                title: Text('Enable Request Queuing'),
                subtitle: Text('Queue requests when rate limits are exceeded'),
                secondary: Icon(
                  Icons.queue_play_next,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              );
            },
          ),
          // Clear Queue Button
          Consumer(
            builder: (context, ref, child) {
              final chatStateAsync = ref.watch(aiChatProvider);
              final queueLength = chatStateAsync.maybeWhen(
                data: (chatState) => chatState.queueLength,
                orElse: () => 0,
              );
              
              return ListTile(
                title: Text('Clear Queue'),
                subtitle: Text('Cancel all queued requests'),
                leading: Icon(
                  Icons.clear_all,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                trailing: ElevatedButton(
                  onPressed: queueLength > 0 ? () => _clearQueue(ref, context) : null,
                  child: Text('Clear'),
                ),
              );
            },
          ),
        ];
      },
      orElse: () => [const SizedBox.shrink()],
    );
  }

  /// Update backoff base delay
  void _updateBackoffBaseDelay(WidgetRef ref, int milliseconds, BuildContext context) {
    ref.read(aiRateLimitsConfigProvider.notifier).setAiRateLimitsConfig(
      ref.read(aiRateLimitsConfigProvider).maybeWhen(
        data: (currentConfig) {
          return currentConfig.copyWith(
            backoffBaseDelay: Duration(milliseconds: milliseconds),
          );
        },
        orElse: () => AiRateLimitsConfig.defaults(),
      ),
    ).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base delay updated')),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save backoff settings: $error')),
        );
      }
    });
  }

  /// Update backoff max delay
  void _updateBackoffMaxDelay(WidgetRef ref, int seconds, BuildContext context) {
    ref.read(aiRateLimitsConfigProvider.notifier).setAiRateLimitsConfig(
      ref.read(aiRateLimitsConfigProvider).maybeWhen(
        data: (currentConfig) {
          return currentConfig.copyWith(
            backoffMaxDelay: Duration(seconds: seconds),
          );
        },
        orElse: () => AiRateLimitsConfig.defaults(),
      ),
    ).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max delay updated')),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save backoff settings: $error')),
        );
      }
    });
  }

  /// Update max retry attempts
  void _updateMaxRetryAttempts(WidgetRef ref, int attempts, BuildContext context) {
    ref.read(aiRateLimitsConfigProvider.notifier).setAiRateLimitsConfig(
      ref.read(aiRateLimitsConfigProvider).maybeWhen(
        data: (currentConfig) {
          return currentConfig.copyWith(
            maxRetryAttempts: attempts,
          );
        },
        orElse: () => AiRateLimitsConfig.defaults(),
      ),
    ).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max retry attempts updated')),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save backoff settings: $error')),
        );
      }
    });
  }

  /// Update queue enabled setting
  void _updateQueueEnabled(WidgetRef ref, bool enabled, BuildContext context) {
    ref.read(aiRateLimitsConfigProvider.notifier).setAiRateLimitsConfig(
      ref.read(aiRateLimitsConfigProvider).maybeWhen(
        data: (currentConfig) {
          return currentConfig.copyWith(
            queueEnabled: enabled,
          );
        },
        orElse: () => AiRateLimitsConfig.defaults(),
      ),
    ).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queue ${enabled ? 'enabled' : 'disabled'}')),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update queue setting: $error')),
        );
      }
    });
  }

  /// Clear the AI request queue
  void _clearQueue(WidgetRef ref, BuildContext context) {
    ref.read(aiChatProvider.notifier).clearQueue();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue cleared')),
      );
    }
  }
}
