import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

// Recommended async settings access pattern (see 018-auth-settings-repo-access.md):
// final settings = await ref.read(settingsRepositoryProvider.future);
// await settings.someMethod();

/// Custom exception for rate limit exceeded
class RateLimitExceededException implements Exception {
  final Duration backoffDuration;

  RateLimitExceededException(this.backoffDuration);

  @override
  String toString() => 'Rate limit exceeded. Try again in ${backoffDuration.inSeconds} seconds.';
}

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

/// Filter parameters for user search and filtering operations.
/// 
/// This immutable class encapsulates all filtering criteria that can be applied
/// to user collections. All fields are optional and null values indicate no filtering
/// on that criterion.
/// 
/// Used by [filteredUsersProvider] family provider for client-side filtering.
class UsersFilter {
  /// Optional search query to filter users by username (case-insensitive substring match).
  final String? searchQuery;
  
  /// Optional role ID to filter users by their assigned role.
  final String? role;
  
  /// Optional status filter (reserved for future implementation when AppUser model supports status).
  final String? status;

  const UsersFilter({
    this.searchQuery,
    this.role,
    this.status,
  });

  /// Creates a copy of this filter with optionally updated fields.
  /// Null values in parameters preserve the current values.
  UsersFilter copyWith({
    String? searchQuery,
    String? role,
    String? status,
  }) {
    return UsersFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  /// Returns an empty filter with all criteria set to null (no filtering).
  UsersFilter get empty => const UsersFilter();
}

/// Notifier for authentication with robust error handling
class AuthNotifier extends AsyncNotifier<AuthState> {
  final CloudSyncService _cloudSync = CloudSyncService();
  final ABTestingService _abTesting = ABTestingService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box<List<DateTime>> attemptsBox;
  bool _listening = false;

  @override
  Future<AuthState> build() async {
    if (!_listening) {
      _listening = true;
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        await _handleAuthStateChange(event);
      });
    }

    attemptsBox = await Hive.openBox<List<DateTime>>('failed_login_attempts');

    // Check initial auth state with error handling
    return await _checkInitialAuthState();
  }

  Future<AuthState> _checkInitialAuthState() async {
    final current = Supabase.instance.client.auth.currentUser;
    if (current != null) {
      return _createAuthenticatedState(current);
    }

    // Add async settings check for auto-login
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
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

  Future<List<DateTime>> _loadFailedAttempts() async {
    final attempts = attemptsBox.get('global') ?? [];
    final now = DateTime.now();
    final cleaned = attempts.where((t) => now.difference(t).inSeconds <= 60).toList();
    if (cleaned.length != attempts.length) {
      await _saveFailedAttempts(cleaned);
    }
    return cleaned;
  }

  Future<void> _saveFailedAttempts(List<DateTime> attempts) async {
    await attemptsBox.put('global', attempts);
  }

  bool _canAttemptLogin(List<DateTime> attempts) {
    return attempts.length < 5;
  }

  Future<void> _recordFailedAttempt() async {
    final attempts = await _loadFailedAttempts();
    attempts.add(DateTime.now());
    await _saveFailedAttempts(attempts);
  }

  Duration? _getBackoffTime(List<DateTime> attempts) {
    if (attempts.length >= 5) {
      return const Duration(seconds: 60);
    }
    return null;
  }

  Future<void> _resetAttempts() async {
    await _saveFailedAttempts([]);
  }

  /// Login with error handling and persistent rate limiting
  Future<bool> login(String username, String password, {bool enableAutoLogin = false}) async {

    // Check rate limiting before attempting login
    final attempts = await _loadFailedAttempts();
    if (!_canAttemptLogin(attempts)) {
      AppLogger.event('auth_rate_limit_exceeded', details: {'email': username, 'timestamp': DateTime.now().toIso8601String()});
      throw RateLimitExceededException(_getBackoffTime(attempts)!);
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
          // Use centralized async settings access (see 018-auth-settings-repo-access.md)
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
        await _resetAttempts();
        return true;
      }
    } catch (e) {
      AppLogger.instance.w('Supabase login failed', error: e);
      // Record failed attempt for rate limiting
      await _recordFailedAttempt();
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
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getAiConsentEnabled();
  }

  /// legacy name used by UI
  Future<void> setEnabled(bool enabled) => setConsent(enabled);

  Future<void> setConsent(bool enabled) async {
    state = AsyncValue.data(enabled);
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setAiConsentEnabled(enabled);
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
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getAiConsentEnabled();
  }

  Future<void> setEnabled(bool value) async {
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
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
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getEnableBiometricLogin();
  }

  Future<void> setEnabled(bool value) async {
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
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
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
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

  Future<void> setHelpLevel(ai_config.HelpLevel level) async {
    state = AsyncValue.data(level);
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setHelpLevel(level.name);
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
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.read(settingsRepositoryProvider.future);
    return settings.getUseBiometricsEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    // Use centralized async settings access (see 018-auth-settings-repo-access.md)
    final settings = await ref.watch(settingsRepositoryProvider.future);
    await settings.setUseBiometricsEnabled(enabled);
    state = AsyncValue.data(enabled);
  }
}

final useBiometricsProvider = AsyncNotifierProvider<UseBiometricsNotifier, bool>(
  UseBiometricsNotifier.new,
);

/// Private helper method for searching users by query
List<AppUser> _searchUsers(List<AppUser> users, String query) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) {
    AppLogger.instance.d('User search: empty query, returning all users (${users.length})');
    return users;
  }
  
  final lowerQuery = trimmedQuery.toLowerCase();
  final filtered = users.where((user) => 
    user.username.toLowerCase().contains(lowerQuery)
  ).toList();
  
  AppLogger.instance.d('User search: query="$trimmedQuery", found ${filtered.length} of ${users.length} users');
  return filtered;
}

/// Private helper method for filtering users by criteria
List<AppUser> _filterUsers(List<AppUser> users, UsersFilter filter) {
  var filtered = users;
  
  // Filter by search query (case-insensitive on username)
  if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
    final query = filter.searchQuery!.trim().toLowerCase();
    filtered = filtered.where((user) => 
      user.username.toLowerCase().contains(query)
    ).toList();
  }
  
  // Filter by role (exact match)
  if (filter.role != null && filter.role!.trim().isNotEmpty) {
    final role = filter.role!.trim();
    filtered = filtered.where((user) => user.roleId == role).toList();
  }
  
  // Filter by status (exact match, if implemented)
  if (filter.status != null && filter.status!.trim().isNotEmpty) {
    // Status filtering not yet implemented in AppUser model
    AppLogger.instance.d('User filter: status filtering requested but not implemented');
  }
  
  AppLogger.instance.d('User filter: applied filters, found ${filtered.length} of ${users.length} users');
  return filtered;
}

final authUsersProvider = FutureProvider<List<AppUser>>((ref) {
  final IAuthRepository repo = ref.watch(authRepositoryProvider);
  return repo.getUsers();
});

/// Family provider for searching users by query (case-insensitive on username)
final searchUsersProvider = Provider.autoDispose.family<List<AppUser>, String>((ref, query) {
  final usersAsync = ref.watch(authUsersProvider);
  return usersAsync.maybeWhen(
    data: (users) => _searchUsers(users, query),
    orElse: () => <AppUser>[],
  );
});

/// Family provider for filtering users by role and status
final filteredUsersProvider = Provider.autoDispose.family<List<AppUser>, UsersFilter>((ref, filter) {
  final usersAsync = ref.watch(authUsersProvider);
  return usersAsync.maybeWhen(
    data: (users) => _filterUsers(users, filter),
    orElse: () => <AppUser>[],
  );
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

/// ============================================================================
/// UI EXAMPLE CODE - User Search and Filter Components
/// ============================================================================
///
/// This section provides reusable UI components that demonstrate usage of the
/// searchUsersProvider and filteredUsersProvider family providers.
///
/// Example usage in a settings or user management screen:
///
/// ```dart
/// class UserManagementScreen extends ConsumerStatefulWidget {
///   const UserManagementScreen({super.key});
///
///   @override
///   ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
/// }
///
/// class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
///   final TextEditingController _searchController = TextEditingController();
///   Timer? _debounceTimer;
///   UsersFilter _currentFilter = const UsersFilter();
///
///   @override
///   void dispose() {
///     _searchController.dispose();
///     _debounceTimer?.cancel();
///     super.dispose();
///   }
///
///   void _onSearchChanged(String query) {
///     _debounceTimer?.cancel();
///     _debounceTimer = Timer(const Duration(milliseconds: 300), () {
///       setState(() {
///         _currentFilter = _currentFilter.copyWith(searchQuery: query);
///       });
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final l10n = AppLocalizations.of(context)!;
///
///     return Scaffold(
///       appBar: AppBar(title: Text('User Management')),
///       body: Column(
///         children: [
///           // Search TextField (debounced)
///           Padding(
///             padding: const EdgeInsets.all(16),
///             child: TextField(
///               controller: _searchController,
///               decoration: InputDecoration(
///                 hintText: l10n.searchUsersHint,
///                 prefixIcon: const Icon(Icons.search),
///                 border: const OutlineInputBorder(),
///               ),
///               onChanged: _onSearchChanged,
///             ),
///           ),
///
///           // Filter Row
///           Padding(
///             padding: const EdgeInsets.symmetric(horizontal: 16),
///             child: Row(
///               children: [
///                 // Role Filter Dropdown
///                 Expanded(
///                   child: DropdownButtonFormField<String?>(
///                     decoration: InputDecoration(
///                       labelText: l10n.filterByRole,
///                       border: const OutlineInputBorder(),
///                     ),
///                     value: _currentFilter.role,
///                     items: [
///                       const DropdownMenuItem(value: null, child: Text('All Roles')),
///                       const DropdownMenuItem(value: 'role_admin', child: Text('Admin')),
///                       const DropdownMenuItem(value: 'role_member', child: Text('Member')),
///                       const DropdownMenuItem(value: 'role_viewer', child: Text('Viewer')),
///                     ],
///                     onChanged: (value) => setState(() {
///                       _currentFilter = _currentFilter.copyWith(role: value);
///                     }),
///                   ),
///                 ),
///                 const SizedBox(width: 16),
///                 // Status Filter Dropdown (placeholder for future implementation)
///                 Expanded(
///                   child: DropdownButtonFormField<String?>(
///                     decoration: InputDecoration(
///                       labelText: l10n.filterByStatus,
///                       border: const OutlineInputBorder(),
///                     ),
///                     value: _currentFilter.status,
///                     items: const [
///                       DropdownMenuItem(value: null, child: Text('All Statuses')),
///                       DropdownMenuItem(value: 'active', child: Text('Active')),
///                       DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
///                     ],
///                     onChanged: (value) => setState(() {
///                       _currentFilter = _currentFilter.copyWith(status: value);
///                     }),
///                   ),
///                 ),
///               ],
///             ),
///           ),
///
///           // Users List with Consumer
///           Expanded(
///             child: Consumer(
///               builder: (context, ref, child) {
///                 final filteredUsers = ref.watch(filteredUsersProvider(_currentFilter));
///
///                 if (filteredUsers.isEmpty) {
///                   return Center(
///                     child: Text(
///                       l10n.noUsersFound,
///                       style: Theme.of(context).textTheme.bodyLarge,
///                     ),
///                   );
///                 }
///
///                 return Column(
///                   children: [
///                     Padding(
///                       padding: const EdgeInsets.all(16),
///                       child: Text(
///                         l10n.usersCount(filteredUsers.length),
///                         style: Theme.of(context).textTheme.titleMedium,
///                       ),
///                     ),
///                     Expanded(
///                       child: ListView.builder(
///                         itemCount: filteredUsers.length,
///                         itemBuilder: (context, index) {
///                           final user = filteredUsers[index];
///                           return ListTile(
///                             leading: const Icon(Icons.account_circle_outlined),
///                             title: Text(user.username),
///                             subtitle: Text('Role: ${user.roleId}'),
///                           );
///                         },
///                       ),
///                     ),
///                   ],
///                 );
///               },
///             ),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// Alternative simplified ConsumerWidget approach:
///
/// ```dart
/// class FilteredUsersList extends ConsumerWidget {
///   const FilteredUsersList({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final l10n = AppLocalizations.of(context)!;
///     final currentFilter = ref.watch(someFilterStateProvider); // Your filter state
///     final filteredUsers = ref.watch(filteredUsersProvider(currentFilter));
///
///     return filteredUsers.isEmpty
///         ? Center(child: Text(l10n.noUsersFound))
///         : ListView.builder(
///             itemCount: filteredUsers.length,
///             itemBuilder: (context, index) {
///               final user = filteredUsers[index];
///               return ListTile(
///                 title: Text(user.username),
///                 subtitle: Text(user.roleId),
///               );
///             },
///           );
///   }
/// }
/// ```