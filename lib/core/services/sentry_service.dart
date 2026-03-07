import 'dart:async';

import 'package:pma_core/services/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

/// Centralized Sentry integration for app startup, crash capture, and breadcrumbs.
///
/// This keeps reporting behavior consistent across providers, repositories,
/// and widgets while avoiding direct Sentry calls scattered in UI code.
class SentryService {
  SentryService._();

  static bool _initialized = false;

  /// Initializes Sentry and runs the provided app runner.
  ///
  /// If no DSN is configured, this method still runs [appRunner] so startup
  /// behavior remains unchanged in local/dev environments.
  static Future<void> initialize({
    required FutureOr<void> Function() appRunner,
    String? dsn,
    String environment = 'production',
    bool enableAutoSessionTracking = true,
  }) async {
    if (_initialized) {
      await appRunner();
      return;
    }

    final resolvedDsn = (dsn ?? AppConfig.sentryDsn)?.trim();
    if (resolvedDsn == null || resolvedDsn.isEmpty) {
      AppLogger.instance.w('Sentry DSN missing; starting app without Sentry');
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = resolvedDsn;
        options.environment = environment;
        options.enableAutoSessionTracking = enableAutoSessionTracking;
      },
      appRunner: appRunner,
    );

    _initialized = true;
    AppLogger.instance.i('Sentry initialized for $environment');
  }

  /// Captures an exception and forwards structured context to Sentry.
  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> extras = const <String, Object?>{},
  }) async {
    AppLogger.instance.e(
      reason ?? 'Unhandled exception',
      error: error,
      stackTrace: stackTrace,
      captureToSentry: false,
    );

    if (!_initialized) {
      return;
    }

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (reason != null && reason.isNotEmpty) {
          scope.setTag('reason', reason);
        }
        if (extras.isNotEmpty) {
          scope.setContexts('extras', Map<String, dynamic>.from(extras));
        }
      },
    );
  }

  /// Adds a breadcrumb for user actions and important application flow events.
  static Future<void> addUserActionBreadcrumb(
    String action, {
    String category = 'user.action',
    SentryLevel level = SentryLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    if (data.isEmpty) {
      AppLogger.instance.i('Breadcrumb: $action');
    } else {
      final buffer = StringBuffer('Breadcrumb: $action');
      data.forEach((key, value) {
        buffer.write(', $key: $value');
      });
      AppLogger.instance.i(buffer.toString());
    }

    if (!_initialized) {
      return;
    }

    await Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        message: action,
        level: level,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  /// Returns true when Sentry has been initialized in this process.
  static bool get isInitialized => _initialized;
}
