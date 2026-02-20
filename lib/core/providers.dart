import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/core/repository/project_meta_repository.dart';
import 'package:my_project_management_app/core/repository/task_repository.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/repository/auth_repository.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';
import 'package:my_project_management_app/core/services/cloud_sync_service.dart';
import 'package:my_project_management_app/core/services/ab_testing_service.dart';
import 'package:my_project_management_app/core/services/notification_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/services/requirements_service.dart';
import 'package:my_project_management_app/models/project_meta.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;

class DashboardItem {
  final String widgetType;
  final Map<String, dynamic> position;

  const DashboardItem({
    required this.widgetType,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'position': position,
      };

  factory DashboardItem.fromJson(Map<String, dynamic> json) => DashboardItem(
        widgetType: json['widgetType'],
        position: json['position'],
      );
}

class DashboardConfigNotifier extends Notifier<List<DashboardItem>> {
  @override
  List<DashboardItem> build() {
    loadConfig();
    return [];
  }

  Future<void> loadConfig() async {
    final box = await Hive.openBox<List>('dashboard_config');
    final data = box.get('config', defaultValue: []);
    if (data != null) {
      state = data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
    }
  }

  Future<void> saveConfig(List<DashboardItem> items) async {
    final box = await Hive.openBox<List>('dashboard_config');
    final data = items.map((item) => item.toJson()).toList();
    await box.put('config', data);
    state = items;
  }
}

final dashboardConfigProvider = NotifierProvider<DashboardConfigNotifier, List<DashboardItem>>(() => DashboardConfigNotifier());

/// Provider for requirements service
final requirementsServiceProvider = Provider<RequirementsService>((ref) {
  return RequirementsService();
});

/// Provider for project requirements by project ID
final projectRequirementsProvider = FutureProvider.family<ProjectRequirements, String>((ref, projectId) async {
  final projectsAsync = ref.watch(projectsProvider);
  return projectsAsync.maybeWhen(
    data: (projects) {
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      );

      final service = ref.read(requirementsServiceProvider);

      // If project has a category, try to fetch from API
      if (project.category != null && project.category!.isNotEmpty) {
        return service.fetchRequirements(project.category!);
      }

      // Otherwise return empty requirements
      return const ProjectRequirements();
    },
    orElse: () => const ProjectRequirements(),
  );
});

/// Notifier for managing theme mode state
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.getThemeMode() ?? ThemeMode.system,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setThemeMode(mode));
  }
}

/// Provider for managing theme mode across the application
/// Supports: ThemeMode.system (default), ThemeMode.dark, ThemeMode.light
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Notifier for managing locale selection.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) {
        final code = settings.getLocaleCode();
        return code == null ? null : Locale(code);
      },
      orElse: () => null,
    );
  }

  void setLocaleCode(String? localeCode) {
    state = localeCode == null ? null : Locale(localeCode);
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setLocaleCode(localeCode));
  }
}

/// Provider for locale selection (null = system locale).
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Provider for checking if dark mode is currently active
/// Returns true if the app is in dark mode (either system dark or explicitly set to dark)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  if (themeMode == ThemeMode.dark) {
    return true;
  } else if (themeMode == ThemeMode.light) {
    return false;
  } else {
    return true; // Default to dark for system mode
  }
});

/// Notifier for managing navigation state
/// Tracks current selected navigation item for responsive navigation
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0; // Default to first item (Home)

  void setSelectedIndex(int index) {
    state = index;
  }
}

/// Provider for managing navigation state
/// Returns the index of the currently selected navigation item
final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);

/// Notifier for global search query.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

/// Provider for global search query.
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Notifier for app-wide notifications toggle.
class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.getNotificationsEnabled() ?? true,
      orElse: () => true,
    );
  }

  void setEnabled(bool value) {
    state = value;
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setNotificationsEnabled(value));

    final notificationService = ref.read(notificationServiceProvider);
    if (!value) {
      notificationService.cancelAll();
      return;
    }

    ref.read(taskRepositoryProvider.future).then((repository) {
      final tasks = repository.getAllTasks();
      notificationService.scheduleTasks(tasks);
    });
  }
}

/// Whether notifications are enabled.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsNotifier, bool>(
  NotificationsNotifier.new,
);

/// Notifier for privacy consent when reading local project files.
class PrivacyConsentNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) {
    state = value;
  }
}

/// Notifier for AI consent setting.
class AiConsentNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.getAiConsentEnabled(),
      orElse: () => false,
    );
  }

  Future<void> setEnabled(bool value) async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setAiConsentEnabled(value);
    state = value;
  }
}

/// Whether the user has opted in to local file access for AI prompts.
final privacyConsentProvider =
    NotifierProvider<PrivacyConsentNotifier, bool>(
  PrivacyConsentNotifier.new,
);

/// Whether the user has consented to AI usage with compliance.
final aiConsentProvider = NotifierProvider<AiConsentNotifier, bool>(
  AiConsentNotifier.new,
);

/// Help level enum for task descriptions
// Using ai_config.HelpLevel for consistency
// enum HelpLevel {
//   basic,
//   detailed,
// }

/// Notifier for help level setting.
class HelpLevelNotifier extends Notifier<ai_config.HelpLevel> {
  @override
  ai_config.HelpLevel build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) {
        final level = settings.getHelpLevel();
        switch (level) {
          case 'gedetailleerd':
            return ai_config.HelpLevel.gedetailleerd;
          case 'stapVoorStap':
            return ai_config.HelpLevel.stapVoorStap;
          default:
            return ai_config.HelpLevel.basis;
        }
      },
      orElse: () => ai_config.HelpLevel.basis,
    );
  }

  void setHelpLevel(ai_config.HelpLevel level) {
    state = level;
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setHelpLevel(level.name));
  }
}

/// Provider for help level setting (basic/detailed).
final helpLevelProvider = NotifierProvider<HelpLevelNotifier, ai_config.HelpLevel>(
  HelpLevelNotifier.new,
);

/// Provider for SettingsRepository
final settingsRepositoryProvider = FutureProvider<SettingsRepository>((ref) async {
  final repository = SettingsRepository();
  await repository.initialize();
  return repository;
});

/// Provider for ProjectRepository
/// Initializes the repository on first access
final projectRepositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final repository = ProjectRepository();
  await repository.initialize();
  return repository;
});

/// Provider for TaskRepository
/// Initializes the repository on first access
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final repository = TaskRepository();
  await repository.initialize();
  return repository;
});

/// Provider for ProjectMetaRepository
/// Stores urgency and tracked time per project
final projectMetaRepositoryProvider =
    FutureProvider<ProjectMetaRepository>((ref) async {
  final repository = ProjectMetaRepository();
  await repository.initialize();
  return repository;
});

/// Provider for local notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Provider for A/B testing service.
final abTestingServiceProvider = Provider<ABTestingService>((ref) {
  return ABTestingService.instance;
});

/// Current user's A/B test group (if assigned).
final abTestGroupProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authProvider);
  final username = authState.username;
  if (username == null || username.isEmpty) {
    return null;
  }
  final service = ref.read(abTestingServiceProvider);
  await service.initialize();
  return service.assignGroupForUser(username);
});

/// Provider for AuthRepository
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final repository = AuthRepository();
  await repository.initialize();
  return repository;
});

/// Notifier for managing projects list state
class ProjectsNotifier extends Notifier<AsyncValue<List<ProjectModel>>> {
  late ProjectRepository _repository;

  @override
  AsyncValue<List<ProjectModel>> build() {
    // Load projects from Hive on initialization (offline-first approach)
    return const AsyncValue.loading();
  }

  /// Initialize the notifier with the repository
  Future<void> initialize(ProjectRepository repository) async {
    _repository = repository;
    // Load all projects from Hive
    final projects = _repository.getAllProjects();
    state = AsyncValue.data(projects);
  }

  /// Add a new project and update state
  Future<void> addProject(ProjectModel project) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.addProject(
        project,
        userId: userId,
        metadata: {
          'name': project.name,
          'status': project.status,
        },
      );
      AppLogger.event(
        'project_created',
        details: {
          'id': project.id,
          'name': project.name,
          'status': project.status,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update project progress and refresh state
  Future<void> updateProgress(String projectId, double newProgress) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.updateProgress(
        projectId,
        newProgress,
        userId: userId,
        metadata: {'progress': newProgress},
      );
      AppLogger.event(
        'project_progress_updated',
        details: {
          'id': projectId,
          'progress': newProgress,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update project tasks and refresh state
  Future<void> updateTasks(String projectId, List<String> tasks) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.updateTasks(
        projectId,
        tasks,
        userId: userId,
        metadata: {'task_count': tasks.length},
      );
      AppLogger.event(
        'project_tasks_updated',
        details: {
          'id': projectId,
          'count': tasks.length,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a project and update state
  Future<void> deleteProject(String projectId) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.deleteProject(projectId, userId: userId);
      AppLogger.event(
        'project_deleted',
        details: {
          'id': projectId,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update project directory path and refresh state
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath,
  ) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.updateDirectoryPath(
        projectId,
        directoryPath,
        userId: userId,
        metadata: {'has_path': directoryPath != null && directoryPath.isNotEmpty},
      );
      AppLogger.event(
        'project_directory_updated',
        details: {
          'id': projectId,
          'hasPath': directoryPath != null && directoryPath.isNotEmpty,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update project plan JSON and refresh state
  Future<void> updatePlanJson(String projectId, String? planJson) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.updatePlanJson(
        projectId,
        planJson,
        userId: userId,
        metadata: {'hasPlan': planJson != null && planJson.isNotEmpty},
      );
      AppLogger.event(
        'project_plan_updated',
        details: {
          'id': projectId,
          'hasPlan': planJson != null && planJson.isNotEmpty,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// General update project method with change history logging
  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? changeDescription,
  }) async {
    try {
      final userId = ref.read(authProvider).username;
      await _repository.updateProject(
        projectId,
        updatedProject,
        userId: userId,
        changeDescription: changeDescription,
        metadata: {
          'updated_fields': ['general_update'],
          'change_type': 'ai_suggestion_applied',
        },
      );
      AppLogger.event(
        'project_updated_with_history',
        details: {
          'id': projectId,
          'change_description': changeDescription,
        },
      );
      final projects = _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh projects from Hive (useful for syncing after offline changes)
  void refresh() {
    final projects = _repository.getAllProjects();
    state = AsyncValue.data(projects);
  }
}

/// Provider for managing projects with Hive persistence
/// Handles offline-first functionality by loading from local storage
final projectsProvider =
    NotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>(
  ProjectsNotifier.new,
);

/// Auth state for basic login flow.
class AuthState {
  final bool isAuthenticated;
  final String? username;
  final String? roleId;
  final String? roleName;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.roleId,
    this.roleName,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
    String? roleId,
    String? roleName,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      error: error,
    );
  }
}

/// Notifier for basic authentication with mock users.
class AuthNotifier extends Notifier<AuthState> {
  final CloudSyncService _cloudSync = CloudSyncService();
  final ABTestingService _abTesting = ABTestingService.instance;
  bool _listening = false;

  @override
  AuthState build() {
    if (!_listening) {
      _listening = true;
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        final user = event.session?.user;
        if (user != null) {
          // User is authenticated with Supabase
          final email = user.email ?? user.id;
          final localUser = await ref.read(authRepositoryProvider.future).then((repo) => repo.getUserByUsername(email));
          final role = localUser != null ? await ref.read(authRepositoryProvider.future).then((repo) => repo.getRoleById(localUser.roleId)) : null;
          state = AuthState(
            isAuthenticated: true,
            username: email,
            roleId: role?.id ?? AuthRepository.defaultUserRoleId,
            roleName: role?.name ?? 'Member',
          );
        } else {
          // User is not authenticated
          state = const AuthState(isAuthenticated: false);
        }
      });
    }

    // Check initial auth state
    final current = Supabase.instance.client.auth.currentUser;
    if (current != null) {
      // User has a valid session, check if auto-login should be enabled
      final settingsRepo = ref.read(settingsRepositoryProvider.future);
      settingsRepo.then((settings) async {
        final autoLoginEnabled = settings.getAutoLoginEnabled();
        if (autoLoginEnabled) {
          // Keep the session active
          final email = current.email ?? current.id;
          final localUser = await ref.read(authRepositoryProvider.future).then((repo) => repo.getUserByUsername(email));
          final role = localUser != null ? await ref.read(authRepositoryProvider.future).then((repo) => repo.getRoleById(localUser.roleId)) : null;
          state = AuthState(
            isAuthenticated: true,
            username: email,
            roleId: role?.id ?? AuthRepository.defaultUserRoleId,
            roleName: role?.name ?? 'Member',
          );
        } else {
          // Auto-login disabled, but user just logged in manually - keep session for this run
          // Only sign out if this is app startup and no manual login just happened
          final lastLoginTime = settings.getLastLoginTime();
          final timeSinceLastLogin = lastLoginTime != null ? DateTime.now().difference(lastLoginTime) : null;
          
          // If last login was more than 5 minutes ago, sign out (app restart scenario)
          if (timeSinceLastLogin == null || timeSinceLastLogin.inMinutes > 5) {
            await Supabase.instance.client.auth.signOut();
            state = const AuthState(isAuthenticated: false);
          } else {
            // Recent login, keep session active
            final email = current.email ?? current.id;
            final localUser = await ref.read(authRepositoryProvider.future).then((repo) => repo.getUserByUsername(email));
            final role = localUser != null ? await ref.read(authRepositoryProvider.future).then((repo) => repo.getRoleById(localUser.roleId)) : null;
            state = AuthState(
              isAuthenticated: true,
              username: email,
              roleId: role?.id ?? AuthRepository.defaultUserRoleId,
              roleName: role?.name ?? 'Member',
            );
          }
        }
      });
      // Return temporary state while async check completes
      return const AuthState(isAuthenticated: false);
    }
    return const AuthState(isAuthenticated: false);
  }

  Future<bool> login(String username, String password, {bool enableAutoLogin = false}) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: username.trim(),
        password: password,
      );

      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token != null) {
        try {
          final payloadBase64 = token.split('.')[1];
          final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(payloadBase64)));
          AppLogger.instance.d('JWT payload after login: $payloadJson');
        } catch (e) {
          AppLogger.instance.e('JWT decode failed', error: e);
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Gebruik email als username voor state
        final email = user.email ?? user.id;
        // Voor role, gebruik default voor nu (later integreren met Supabase)
        final repo = await ref.read(authRepositoryProvider.future);
        final localUser = repo.getUserByUsername(email);
        final role = localUser != null ? repo.getRoleById(localUser.roleId) : null;
        state = AuthState(
          isAuthenticated: true,
          username: email,
          roleId: role?.id ?? AuthRepository.defaultUserRoleId,
          roleName: role?.name ?? 'Member',
        );
        await _abTesting.initialize();
        await _abTesting.assignGroupForUser(email);
        AppLogger.event('auth_sign_in', details: {'id': user.id});
        await _cloudSync.authSignInPlaceholder(
          user.id,
          metadata: {'role': role?.name ?? 'Member'},
        );
        // Update auto-login settings
        final settingsRepo = await ref.read(settingsRepositoryProvider.future);
        if (enableAutoLogin || settingsRepo.getLastLoginTime() == null) {
          await settingsRepo.setAutoLoginEnabled(true);
        }
        await settingsRepo.setLastLoginTime(DateTime.now());
        // Eventueel syncAll() of andere calls
        return true;
      }
    } catch (e) {
      AppLogger.instance.w('Supabase login failed', error: e);
    }

    state = state.copyWith(error: 'Ongeldige gebruikersnaam of wachtwoord.');
    return false;
  }

  Future<void> logout() async {
    final userId = state.username;
    // Insert analytics before logout to ensure user is still authenticated
    AppLogger.event('auth_sign_out');
    // NOTE: Vervang door Supabase auth sign-out later; placeholder voor sessie.
    await _cloudSync.authSignOutPlaceholder(userId: userId);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      AppLogger.instance.w('Supabase logout failed', error: e);
    }
    // State is updated by the auth listener
  }

  Future<bool> addUser(
    String username,
    String password, {
    String roleId = AuthRepository.defaultUserRoleId,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return false;
    }

    final repo = await ref.read(authRepositoryProvider.future);
    await repo.addUser(
      AuthUser(
        username: username.trim(),
        password: password,
        roleId: roleId,
      ),
    );
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      AppLogger.instance.d('Signup attempt: email=$trimmedEmail, password length=${password.length}');

      final response = await Supabase.instance.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          // Optioneel: data voor user_metadata als je wilt
          'full_name': 'Test User',
        },
      );

      if (response.user != null) {
        AppLogger.instance.i('Signup success: user ID = ${response.user!.id}, email = ${response.user!.email}');
        // Auto-login als Confirm off
        final loginRes = await Supabase.instance.client.auth.signInWithPassword(
          email: trimmedEmail,
          password: password,
        );
        if (loginRes.session != null) {
          AppLogger.instance.d('Auto-login na signup gelukt');
        }
        return true;
      } else {
        AppLogger.instance.w('Signup response zonder user: session=${response.session}');
        return false;
      }
    } on AuthException catch (e) {
      AppLogger.instance.d('AuthException details: Message: ${e.message}, Status: ${e.statusCode}, Code: ${e.code}');

      AppLogger.instance.w('Supabase sign-up failed', error: e);
      state = state.copyWith(error: 'Registratie mislukt: ${e.message} (${e.code ?? 'geen code'})');
    } catch (e, stack) {
      AppLogger.instance.d('Unexpected signup error: $e, Stack: $stack');
      state = state.copyWith(error: 'Onverwachte fout bij registratie');
    }
    return false;
  }

  Future<void> deleteUser(String username) async {
    final repo = await ref.read(authRepositoryProvider.future);
    final roleId = state.roleId ?? AuthRepository.defaultUserRoleId;
    final role = repo.getRoleById(roleId);
    final canManageUsers = role?.permissions.contains(AppPermissions.manageUsers) ??
        false;
    if (!canManageUsers) {
      state = state.copyWith(
        error: 'Je hebt geen rechten om gebruikers te verwijderen.',
      );
      return;
    }
    await repo.deleteUser(username.trim());
    final current = repo.getCurrentUser();
    if (current == null) {
      state = const AuthState(isAuthenticated: false);
    }
  }
}

/// Provider for authentication state.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider for listing available users.
final authUsersProvider = FutureProvider<List<AuthUser>>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return repo.getUsers();
});

/// Provider for current authenticated user
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.username == null) {
    return null;
  }

  final repo = await ref.watch(authRepositoryProvider.future);
  return repo.getUserByUsername(authState.username!);
});

/// Provider for current role definition.
final currentRoleProvider = Provider<RoleDefinition?>((ref) {
  final authState = ref.watch(authProvider);
  final repoAsync = ref.watch(authRepositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) {
      final roleId = authState.roleId;
      if (roleId == null) {
        return null;
      }
      return repo.getRoleById(roleId);
    },
    orElse: () => null,
  );
});

/// Provider for current permission set.
final permissionsProvider = Provider<Set<String>>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role?.permissions.toSet() ?? <String>{};
});

/// Permission check provider.
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final permissions = ref.watch(permissionsProvider);
  return permissions.contains(permission);
});

/// Provider for project metadata (urgency + tracked time).
final projectMetaProvider = Provider<Map<String, ProjectMeta>>((ref) {
  final repoAsync = ref.watch(projectMetaRepositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getAllMeta(),
    orElse: () => const {},
  );
});

/// Provider for projects filtered by role permissions and group sharing.
final visibleProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final projectsState = ref.watch(projectsProvider);
  final authState = ref.watch(authProvider);
  final permissions = ref.watch(permissionsProvider);
  final repoAsync = ref.watch(authRepositoryProvider);

  return projectsState.when(
    data: (projects) {
      if (!permissions.contains(AppPermissions.viewProjects)) {
        return const AsyncValue.data(<ProjectModel>[]);
      }
      if (permissions.contains(AppPermissions.viewAllProjects)) {
        return AsyncValue.data(projects);
      }

      final username = authState.username ?? '';
      final groups = repoAsync.maybeWhen(
        data: (repo) => repo.getGroupsForUser(username),
        orElse: () => const <GroupDefinition>[],
      );
      final groupIds = groups.map((group) => group.id).toSet();

      final filtered = projects.where((project) {
        final isSharedUser = project.sharedUsers.any(
          (user) => user.toLowerCase() == username.toLowerCase(),
        );
        final isSharedGroup = project.sharedGroups.any(
          (groupId) => groupIds.contains(groupId),
        );
        return isSharedUser || isSharedGroup;
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for AI help level selection
/// Modular for user preferences (link to settings later)
final aiHelpLevelProvider = StateProvider<ai_config.HelpLevel>((ref) => ai_config.HelpLevel.basis);
