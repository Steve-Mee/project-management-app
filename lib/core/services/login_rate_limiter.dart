import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';

/// Service for managing login rate limiting with persistent storage.
/// Implements sliding-window rate limiting with progressive backoff to protect against brute-force attacks.
/// Uses Hive for persistence across app sessions.
class LoginRateLimiter {
  static const String _boxName = 'login_attempts';
  static const int maxAttempts = 5;
  static const int windowSeconds = 60;
  static const List<Duration> _backoffDurations = [
    Duration(seconds: 30), // 1st exceed: 30 seconds
    Duration(minutes: 2),   // 2nd exceed: 2 minutes
    Duration(minutes: 10),  // 3rd+ exceed: 10 minutes (capped)
  ];

  static LoginRateLimiter? _instance;
  late Box<Map<dynamic, dynamic>> _box;

  /// Private constructor for singleton pattern.
  LoginRateLimiter._();

  /// Singleton instance.
  static LoginRateLimiter get instance {
    _instance ??= LoginRateLimiter._();
    return _instance!;
  }

  /// Initializes the Hive box. Must be called before using the service.
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      AppLogger.instance.d('LoginRateLimiter initialized');
    } catch (e, stack) {
      AppLogger.instance.e('Failed to initialize LoginRateLimiter', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Checks if the given email is currently blocked due to rate limiting.
  /// Cleans old attempts before checking.
  /// Returns true if blocked, false otherwise.
  Future<bool> isBlocked(String email) async {
    try {
      final key = _hashEmail(email);
      final data = _box.get(key) ?? {};
      final attempts = List<DateTime>.from(data['attempts'] ?? []);
      final consecutiveFailures = data['consecutiveFailures'] ?? 0;
      final lastBlockTime = data['lastBlockTime'] as DateTime?;

      _cleanOldAttempts(attempts);
      await _box.put(key, {
        'attempts': attempts,
        'consecutiveFailures': consecutiveFailures,
        'lastBlockTime': lastBlockTime,
      });

      if (attempts.length < maxAttempts) {
        return false;
      }

      if (lastBlockTime == null) {
        return false;
      }

      final backoffIndex = (consecutiveFailures - 1).clamp(0, _backoffDurations.length - 1);
      final lockoutDuration = _backoffDurations[backoffIndex];
      final timeSinceBlock = DateTime.now().difference(lastBlockTime);

      return timeSinceBlock < lockoutDuration;
    } catch (e, stack) {
      AppLogger.instance.e('Error checking if blocked for $email', error: e, stackTrace: stack);
      return false; // Fail-safe: allow login on error
    }
  }

  /// Records a failed login attempt for the given email.
  /// Increments consecutive failures if now exceeding max attempts.
  Future<void> recordAttempt(String email) async {
    try {
      final key = _hashEmail(email);
      final data = _box.get(key) ?? {};
      final attempts = List<DateTime>.from(data['attempts'] ?? []);
      var consecutiveFailures = data['consecutiveFailures'] ?? 0;
      DateTime? lastBlockTime = data['lastBlockTime'] as DateTime?;

      attempts.add(DateTime.now());
      _cleanOldAttempts(attempts);

      if (attempts.length >= maxAttempts) {
        consecutiveFailures++;
        lastBlockTime = DateTime.now();
        AppLogger.event('auth_rate_limit_exceeded', details: {
          'email': email,
          'attempts': attempts.length,
          'consecutive_failures': consecutiveFailures,
          'lockout_duration_seconds': _backoffDurations[(consecutiveFailures - 1).clamp(0, _backoffDurations.length - 1)].inSeconds,
        });
      }

      await _box.put(key, {
        'attempts': attempts,
        'consecutiveFailures': consecutiveFailures,
        'lastBlockTime': lastBlockTime,
      });
    } catch (e, stack) {
      AppLogger.instance.e('Error recording attempt for $email', error: e, stackTrace: stack);
    }
  }

  /// Resets the rate limiter state for the given email on successful login.
  /// Clears attempts and consecutive failures.
  Future<void> resetOnSuccess(String email) async {
    try {
      final key = _hashEmail(email);
      await _box.put(key, {
        'attempts': <DateTime>[],
        'consecutiveFailures': 0,
        'lastBlockTime': null,
      });
    } catch (e, stack) {
      AppLogger.instance.e('Error resetting on success for $email', error: e, stackTrace: stack);
    }
  }

  /// Cleans attempts older than the sliding window.
  void _cleanOldAttempts(List<DateTime> attempts) {
    final cutoff = DateTime.now().subtract(Duration(seconds: windowSeconds));
    attempts.removeWhere((attempt) => attempt.isBefore(cutoff));
  }

  /// Hashes the email for privacy in storage.
  String _hashEmail(String email) {
    return sha256.convert(utf8.encode(email.toLowerCase())).toString();
  }

  @visibleForTesting
  Future<void> clearForTesting() async {
    await _box.clear();
  }
}