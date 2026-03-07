import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pma_core/auth/auth_user.dart';

import 'auth_data_mapper.dart';
import 'auth_remote_service.dart';

/// Encapsulates auth workflows so repository persistence remains focused.
class AuthOperations {
  AuthOperations({
    required AuthDataMapper dataMapper,
    required Future<void> Function(String identifier) recordLoginAttempt,
    required Future<void> Function(String identifier) resetLoginAttempts,
  }) : _dataMapper = dataMapper,
       _recordLoginAttempt = recordLoginAttempt,
       _resetLoginAttempts = resetLoginAttempts;

  final AuthDataMapper _dataMapper;
  final Future<void> Function(String identifier) _recordLoginAttempt;
  final Future<void> Function(String identifier) _resetLoginAttempts;

  AppUser? validateUser(String username, String password) {
    final users = _dataMapper.getUsers();
    final hashedPassword = _dataMapper.hashPassword(password);
    for (final user in users) {
      if (user.username == username && user.password == hashedPassword) {
        return user;
      }
      if (user.username == username && user.password == password) {
        _upgradeLegacyPassword(username, hashedPassword, users);
        return AppUser(
          username: user.username,
          password: hashedPassword,
          roleId: user.roleId,
        );
      }
    }
    return null;
  }

  Future<bool> login(String email, String password, RemoteAuthService remote) async {
    try {
      await remote.signIn(email, password);
      await _dataMapper.setCurrentUser(email.trim());
      await _resetLoginAttempts(email.trim().toLowerCase());
      return true;
    } catch (e) {
      await _recordLoginAttempt(email.trim().toLowerCase());
      return false;
    }
  }

  Future<void> register(String email, String password, RemoteAuthService remote) async {
    await remote.registerUser(email, password);
  }

  Future<bool> isLoggedIn() async {
    return Supabase.instance.client.auth.currentSession != null;
  }

  Future<void> logout(RemoteAuthService remote) async {
    await remote.signOut();
    await _dataMapper.setCurrentUser(null);
  }

  void _upgradeLegacyPassword(
    String username,
    String hashedPassword,
    List<AppUser> users,
  ) {
    final updated = <AppUser>[];
    for (final user in users) {
      if (user.username == username) {
        updated.add(
          AppUser(
            username: user.username,
            password: hashedPassword,
            roleId: user.roleId,
          ),
        );
      } else {
        updated.add(user);
      }
    }

    // Persist into the canonical users key so legacy password upgrades survive restarts.
    _dataMapper.persistUsersSync(updated);
  }
}
