import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_project_management_app/core/repository/auth_repository.dart';
import 'package:my_project_management_app/core/repository/i_auth_repository.dart';
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/services/cloud_sync_service.dart';
import 'package:my_project_management_app/core/services/ab_testing_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/services/login_rate_limiter.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;

/// Provider for auth repository (exposed via interface to allow swapping)
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for SettingsRepository
/// Initializes the repository on first access
final settingsRepositoryProvider = FutureProvider<SettingsRepository>((ref) async {
  final repository = SettingsRepository();
  await repository.initialize();
  return repository;
});

/// Provider for LoginRateLimiter
final loginRateLimiterProvider = Provider<LoginRateLimiter>((ref) => LoginRateLimiter.instance);

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
class AuthNotifier extends AsyncNotifier<AuthState> {
  final CloudSyncService _cloudSync = CloudSyncService();
  final ABTestingService _abTesting = ABTestingService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _listening = false;

  @override
  Future<AuthState> build() async {
    if (!_listening) {
      _listening = true;
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        await _handleAuthStateChange(event);
      });
    }

    // Check initial auth state with error handling
    return await _checkInitialAuthState();
  }

  Future<AuthState> _checkInitialAuthState() async {
    final current = Supabase.instance.client.auth.currentUser;
    if (current != null) {
      // Implemented: initial auth state is created synchronously; settings-based checks occur after login
      return _createAuthenticatedState(current);
    }

    // Add async settings check for auto-login
    final settings = await ref.read(settingsRepositoryProvider.future);
    if (settings.getAutoLoginEnabled() && settings.getEnableBiometricLogin() && await isBiometricAvailable()) {
      await authenticateWithBiometrics();
      return state.value!;
    }

    return const AuthState(isAuthenticated: false);
  }

  AuthState _createAuthenticatedState(dynamic user) {
    final email = user.email ?? user.id;
    final IAuthRepository repo = ref.read(authRepositoryProvider);
    final localUser = repo.getUserByUsername(email);
    final role = localUser != null ? repo.getRoleById(localUser.roleId) : null;

    return AuthState(
      isAuthenticated: true,
      username: email,
      roleId: role?.id ?? repo.defaultUserRoleId,
      roleName: role?.name ?? 'Member',
    );
  }

  Future<void> _handleAuthStateChange(dynamic event) async {
    final user = event.session?.user;
    if (user != null) {
      state = AsyncValue.data(_createAuthenticatedState(user));
    } else {
      state = AsyncValue.data(const AuthState(isAuthenticated: false));
    }
  }

  /// Login with error handling and persistent rate limiting
  Future<bool> login(String username, String password, {bool enableAutoLogin = false}) async {
    final repo = ref.read(authRepositoryProvider);

    // Check rate limiting before attempting login
    if (await repo.isLoginBlocked(username)) {
      state = AsyncValue.data(state.value!.copyWith(error: 'Rate limit exceeded. Please try again later.'));
      AppLogger.event('auth_rate_limit_exceeded', details: {'email': username, 'timestamp': DateTime.now().toIso8601String()});
      return false;
    }

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
        final userEmail = user.email ?? user.id;
        final IAuthRepository repo = ref.read(authRepositoryProvider);
        final localUser = repo.getUserByUsername(userEmail);
        final role = localUser != null ? repo.getRoleById(localUser.roleId) : null;

        state = AsyncValue.data(AuthState(
          isAuthenticated: true,
          username: userEmail,
          roleId: role?.id ?? repo.defaultUserRoleId,
          roleName: role?.name ?? 'Member',
        ));

        await _abTesting.initialize();
        await _abTesting.assignGroupForUser(userEmail);

        AppLogger.event('auth_sign_in', details: {'id': user.id});

        await _cloudSync.authSignInPlaceholder(
          user.id,
          metadata: {'role': role?.name ?? 'Member'},
        );
        // Update auto-login settings using async settings provider
        try {
          final settingsRepo = await ref.watch(settingsRepositoryProvider.future);
          if (enableAutoLogin || settingsRepo.getLastLoginTime() == null) {
            await settingsRepo.setAutoLoginEnabled(true);
          }
          await settingsRepo.setLastLoginTime(DateTime.now());

          // Enroll biometrics if enabled
          if (settingsRepo.getEnableBiometricLogin()) {
            await enrollBiometrics(username, password);
          }
        } catch (e) {
          AppLogger.instance.w('Settings update or biometric enrollment failed', error: e);
        }

        // Reset rate limiter on successful login
        await repo.resetLoginAttempts(userEmail);
        return true;
      }
    } catch (e) {
      AppLogger.instance.w('Supabase login failed', error: e);
      // Record failed attempt for rate limiting
      await repo.recordLoginAttempt(username);
    }

    state = AsyncValue.data(state.value!.copyWith(error: 'Invalid username or password.'));
    return false;
  }

  /// Logout with proper cleanup
  Future<void> logout() async {
    final userId = state.value!.username;
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
    String? roleId,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      state = AsyncValue.data(state.value!.copyWith(error: 'Username and password are required.'));
      return false;
    }

    try {
      final IAuthRepository repo = ref.read(authRepositoryProvider);
      final effectiveRoleId = roleId ?? repo.defaultUserRoleId;
      await repo.addUser(
        AppUser(
          username: username.trim(),
          password: password,
          roleId: effectiveRoleId,
        ),
      );
      return true;
    } catch (e) {
      state = AsyncValue.error('Failed to add user: $e', StackTrace.current);
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

        // Auto-login if email confirmation is off (respect rate limiting)
        final limiter = ref.watch(loginRateLimiterProvider);
        if (!await limiter.isBlocked(trimmedEmail)) {
          final loginRes = await Supabase.instance.client.auth.signInWithPassword(
            email: trimmedEmail,
            password: password,
          );
          if (loginRes.session != null) {
            AppLogger.instance.d('Auto-login after signup successful');
          }
        } else {
          AppLogger.event('auth_rate_limit_exceeded', details: {'email': trimmedEmail, 'context': 'auto-login after signup'});
        }
        return true;
      } else {
        AppLogger.instance.w('Signup response without user: session=${response.session}');
        return false;
      }
    } on AuthException catch (e) {
      AppLogger.instance.w('Supabase sign-up failed', error: e);
      state = AsyncValue.data(state.value!.copyWith(error: 'Registration failed: ${e.message} (${e.code ?? 'no code'})'));
    } catch (e, stack) {
      AppLogger.instance.e('Unexpected signup error', error: e, stackTrace: stack);
      state = AsyncValue.data(state.value!.copyWith(error: 'Unexpected error during registration'));
    }
    return false;
  }

  /// Delete user with permission checking
  Future<void> deleteUser(String username) async {
    try {
      final IAuthRepository repo = ref.read(authRepositoryProvider);
      final roleId = state.value!.roleId ?? repo.defaultUserRoleId;
      final role = repo.getRoleById(roleId);
      final canManageUsers = role?.permissions.contains(AppPermissions.manageUsers) ?? false;

      if (!canManageUsers) {
        state = AsyncValue.data(state.value!.copyWith(error: 'You do not have permission to delete users.'));
        return;
      }

      await repo.deleteUser(username.trim());
      final current = repo.getCurrentUser();
      if (current == null) {
        state = AsyncValue.data(const AuthState(isAuthenticated: false));
      }
    } catch (e) {
      state = AsyncValue.error('Failed to delete user: $e', StackTrace.current);
    }
  }

  /// Check if biometric authentication is available (mobile platforms only)
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      AppLogger.instance.w('Biometric availability check failed', error: e);
      return false;
    }
  }

  /// Authenticate using biometrics and perform login with stored credentials
  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricAvailable()) {
      state = AsyncValue.data(state.value!.copyWith(error: 'Biometric authentication not available.'));
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        biometricOnly: true,
      );

      if (!authenticated) {
        state = AsyncValue.data(state.value!.copyWith(error: 'Biometric authentication failed.'));
        return false;
      }

      // Retrieve stored credentials
      final storedPassword = await _secureStorage.read(key: 'biometric_password');
      final storedUsername = await _secureStorage.read(key: 'biometric_username');

      if (storedPassword == null || storedUsername == null) {
        state = AsyncValue.data(state.value!.copyWith(error: 'No stored credentials for biometric login.'));
        return false;
      }

      // Perform login with stored credentials
      return await login(storedUsername, storedPassword, enableAutoLogin: false);
    } catch (e) {
      AppLogger.instance.w('Biometric authentication failed', error: e);
      state = AsyncValue.data(state.value!.copyWith(error: 'Biometric authentication error: $e'));
      return false;
    }
  }

  /// Enroll biometrics by storing credentials after successful password login
  Future<bool> enrollBiometrics(String username, String password) async {
    if (!await isBiometricAvailable()) {
      return false;
    }

    try {
      await _secureStorage.write(key: 'biometric_username', value: username);
      await _secureStorage.write(key: 'biometric_password', value: password);
      return true;
    } catch (e) {
      AppLogger.instance.w('Biometric enrollment failed', error: e);
      return false;
    }
  }
}

/// Provider for authentication state
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider exposing current user's permission set based on their role
final permissionsProvider = Provider<Set<String>>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.maybeWhen(
    data: (auth) {
      if (!auth.isAuthenticated || auth.roleId == null) {
        return <String>{};
      }
      final IAuthRepository repo = ref.read(authRepositoryProvider);
      final role = repo.getRoleById(auth.roleId!);
      return role?.permissions.toSet() ?? <String>{};
    },
    orElse: () => <String>{},
  );
});

/// Convenience family provider for checking a single permission
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final perms = ref.watch(permissionsProvider);
  return perms.contains(permission);
});

/// Notifier for user consent to upload project files for AI prompts
class PrivacyConsentNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // stored in settings repository
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getAiConsentEnabled();
  }

  /// legacy name used by UI
  Future<void> setEnabled(bool enabled) => setConsent(enabled);

  Future<void> setConsent(bool enabled) async {
    state = AsyncValue.data(enabled);
    try {
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.setAiConsentEnabled(enabled);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for privacy/AI consent toggle
final privacyConsentProvider = AsyncNotifierProvider<PrivacyConsentNotifier, bool>(
  PrivacyConsentNotifier.new,
);

/// Notifier for AI consent setting.
class AiConsentNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getAiConsentEnabled();
  }

  Future<void> setEnabled(bool value) async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setAiConsentEnabled(value);
    state = AsyncValue.data(value);
  }
}

/// Whether the user has consented to AI usage with compliance.
final aiConsentProvider = AsyncNotifierProvider<AiConsentNotifier, bool>(
  AiConsentNotifier.new,
);

/// Notifier for biometric login setting.
class BiometricLoginNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getEnableBiometricLogin();
  }

  Future<void> setEnabled(bool value) async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setEnableBiometricLogin(value);
    state = AsyncValue.data(value);
  }
}

/// Provider for biometric login toggle
final biometricLoginProvider = AsyncNotifierProvider<BiometricLoginNotifier, bool>(
  BiometricLoginNotifier.new,
);

/// Notifier for help level setting.
class HelpLevelNotifier extends AsyncNotifier<ai_config.HelpLevel> {
  @override
  Future<ai_config.HelpLevel> build() async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    final level = settings.getHelpLevel();
    switch (level) {
      case 'gedetailleerd':
        return ai_config.HelpLevel.gedetailleerd;
      case 'stapVoorStap':
        return ai_config.HelpLevel.stapVoorStap;
      default:
        return ai_config.HelpLevel.basis;
    }
  }

  void setHelpLevel(ai_config.HelpLevel level) {
    state = AsyncValue.data(level);
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setHelpLevel(level.name));
  }
}

/// Provider for help level setting (basic/detailed).
final helpLevelProvider = AsyncNotifierProvider<HelpLevelNotifier, ai_config.HelpLevel>(
  HelpLevelNotifier.new,
);

/// Add search/filtering capabilities
final biometricSupportedProvider = FutureProvider<bool>((ref) async {
  final localAuth = LocalAuthentication();
  try {
    return await localAuth.isDeviceSupported();
  } catch (e) {
    return false;
  }
});

class UseBiometricsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getUseBiometricsEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    await settings.setUseBiometricsEnabled(enabled);
    state = AsyncValue.data(enabled);
  }
}

final useBiometricsProvider = AsyncNotifierProvider<UseBiometricsNotifier, bool>(
  UseBiometricsNotifier.new,
);

final authUsersProvider = FutureProvider<List<AppUser>>((ref) {
  final IAuthRepository repo = ref.watch(authRepositoryProvider);
  return repo.getUsers();
});

/// Provider for current authenticated user
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = await ref.watch(authProvider.future);
  if (!authState.isAuthenticated || authState.username == null) {
    return null;
  }

  final IAuthRepository repo = ref.read(authRepositoryProvider);
  // repo is guaranteed non-null since provider returns a value
  return repo.getUserByUsername(authState.username!);
});