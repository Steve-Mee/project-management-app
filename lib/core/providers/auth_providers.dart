import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:my_project_management_app/core/repository/auth_repository.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/services/cloud_sync_service.dart';
import 'package:my_project_management_app/core/services/ab_testing_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;

/// Provider for auth repository
/// TODO: Consider using an abstract interface for easy testing/swapping
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for SettingsRepository
/// Initializes the repository on first access
final settingsRepositoryProvider = FutureProvider<SettingsRepository>((ref) async {
  final repository = SettingsRepository();
  await repository.initialize();
  return repository;
});

/// Auth state for basic login flow with error handling
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

/// Notifier for authentication with robust error handling
/// TODO: Add rate limiting for login attempts
/// TODO: Add biometric authentication support
class AuthNotifier extends Notifier<AuthState> {
  final CloudSyncService _cloudSync = CloudSyncService();
  final ABTestingService _abTesting = ABTestingService.instance;
  bool _listening = false;

  @override
  AuthState build() {
    if (!_listening) {
      _listening = true;
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        await _handleAuthStateChange(event);
      });
    }

    // Check initial auth state with error handling
    return _checkInitialAuthState();
  }

  AuthState _checkInitialAuthState() {
    final current = Supabase.instance.client.auth.currentUser;
    if (current != null) {
      // TODO: Implement proper async checking with settings
      return _createAuthenticatedState(current);
    }
    return const AuthState(isAuthenticated: false);
  }

  AuthState _createAuthenticatedState(dynamic user) {
    final email = user.email ?? user.id;
    final repo = ref.read(authRepositoryProvider);
    final localUser = repo.getUserByUsername(email);
    final role = localUser != null ? repo.getRoleById(localUser.roleId) : null;

    return AuthState(
      isAuthenticated: true,
      username: email,
      roleId: role?.id ?? AuthRepository.defaultUserRoleId,
      roleName: role?.name ?? 'Member',
    );
  }

  Future<void> _handleAuthStateChange(dynamic event) async {
    final user = event.session?.user;
    if (user != null) {
      state = _createAuthenticatedState(user);
    } else {
      state = const AuthState(isAuthenticated: false);
    }
  }

  /// Login with error handling and rate limiting considerations
  /// TODO: Implement rate limiting (max 5 attempts per minute)
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
        final email = user.email ?? user.id;
        final repo = ref.read(authRepositoryProvider);
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
        // TODO: Access settings repository properly
        // final settingsRepo = await ref.read(settingsRepositoryProvider.future);
        // if (enableAutoLogin || settingsRepo.getLastLoginTime() == null) {
        //   await settingsRepo.setAutoLoginEnabled(true);
        // }
        // await settingsRepo.setLastLoginTime(DateTime.now());

        return true;
      }
    } catch (e) {
      AppLogger.instance.w('Supabase login failed', error: e);
    }

    state = state.copyWith(error: 'Invalid username or password.');
    return false;
  }

  /// Logout with proper cleanup
  Future<void> logout() async {
    final userId = state.username;
    AppLogger.event('auth_sign_out');
    await _cloudSync.authSignOutPlaceholder(userId: userId);

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      AppLogger.instance.w('Supabase logout failed', error: e);
    }
    // State is updated by the auth listener
  }

  /// Add user with validation
  Future<bool> addUser(
    String username,
    String password, {
    String roleId = AuthRepository.defaultUserRoleId,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Username and password are required.');
      return false;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.addUser(
        AuthUser(
          username: username.trim(),
          password: password,
          roleId: roleId,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add user: $e');
      return false;
    }
  }

  /// Sign up with comprehensive error handling
  Future<bool> signUp(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      AppLogger.instance.d('Signup attempt: email=$trimmedEmail, password length=${password.length}');

      final response = await Supabase.instance.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'full_name': 'Test User'},
      );

      if (response.user != null) {
        AppLogger.instance.i('Signup success: user ID = ${response.user!.id}, email = ${response.user!.email}');

        // Auto-login if email confirmation is off
        final loginRes = await Supabase.instance.client.auth.signInWithPassword(
          email: trimmedEmail,
          password: password,
        );
        if (loginRes.session != null) {
          AppLogger.instance.d('Auto-login after signup successful');
        }
        return true;
      } else {
        AppLogger.instance.w('Signup response without user: session=${response.session}');
        return false;
      }
    } on AuthException catch (e) {
      AppLogger.instance.w('Supabase sign-up failed', error: e);
      state = state.copyWith(error: 'Registration failed: ${e.message} (${e.code ?? 'no code'})');
    } catch (e, stack) {
      AppLogger.instance.e('Unexpected signup error', error: e, stackTrace: stack);
      state = state.copyWith(error: 'Unexpected error during registration');
    }
    return false;
  }

  /// Delete user with permission checking
  Future<void> deleteUser(String username) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final roleId = state.roleId ?? AuthRepository.defaultUserRoleId;
      final role = repo.getRoleById(roleId);
      final canManageUsers = role?.permissions.contains(AppPermissions.manageUsers) ?? false;

      if (!canManageUsers) {
        state = state.copyWith(error: 'You do not have permission to delete users.');
        return;
      }

      await repo.deleteUser(username.trim());
      final current = repo.getCurrentUser();
      if (current == null) {
        state = const AuthState(isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete user: $e');
    }
  }
}

/// Provider for authentication state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider exposing current user's permission set based on their role
final permissionsProvider = Provider<Set<String>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.roleId == null) {
    return <String>{};
  }
  final repo = ref.read(authRepositoryProvider);
  final role = repo.getRoleById(auth.roleId!);
  return role?.permissions.toSet() ?? <String>{};
});

/// Convenience family provider for checking a single permission
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final perms = ref.watch(permissionsProvider);
  return perms.contains(permission);
});

/// Notifier for user consent to upload project files for AI prompts
class PrivacyConsentNotifier extends Notifier<bool> {
  @override
  bool build() {
    // stored in settings repository
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (s) => s.getAiConsentEnabled() ?? false,
      orElse: () => false,
    );
  }

  /// legacy name used by UI
  Future<void> setEnabled(bool enabled) => setConsent(enabled);

  Future<void> setConsent(bool enabled) async {
    state = enabled;
    try {
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.setAiConsentEnabled(enabled);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for privacy/AI consent toggle
final privacyConsentProvider = NotifierProvider<PrivacyConsentNotifier, bool>(
  PrivacyConsentNotifier.new,
);

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

/// Whether the user has consented to AI usage with compliance.
final aiConsentProvider = NotifierProvider<AiConsentNotifier, bool>(
  AiConsentNotifier.new,
);

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

/// TODO: Add search/filtering capabilities
final authUsersProvider = FutureProvider<List<AuthUser>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUsers();
});

/// Provider for current authenticated user
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.username == null) {
    return null;
  }

  final AuthRepository repo = ref.read(authRepositoryProvider);
  // repo is guaranteed non-null since provider returns a value
  return repo.getUserByUsername(authState.username!);
});