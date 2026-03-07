import 'dart:async';

import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Keep existing AppLogger.instance.* callsites intact, while ensuring
  // error logs are consistently forwarded to Sentry.
  static final _SentryAwareLogger instance = _SentryAwareLogger(_logger);

  static void event(String name, {Map<String, Object?>? params}) {
    final payload = params ?? const {};
    if (payload.isEmpty) {
      instance.i('Event: $name');
      _addBreadcrumb(
        message: 'Event: $name',
        category: 'app.event',
        data: payload,
      );
      return;
    }

    final buffer = StringBuffer('Event: $name');
    payload.forEach((key, value) {
      buffer.write(', $key: $value');
    });
    instance.i(buffer.toString());
    _addBreadcrumb(
      message: 'Event: $name',
      category: 'app.event',
      data: payload,
    );
  }

  static void warning(String message, {Map<String, Object?>? params}) {
    final payload = params ?? const {};
    if (payload.isEmpty) {
      instance.w('Warning: $message');
      _addBreadcrumb(
        message: 'Warning: $message',
        category: 'app.warning',
        level: SentryLevel.warning,
        data: payload,
      );
      return;
    }

    final buffer = StringBuffer('Warning: $message');
    payload.forEach((key, value) {
      buffer.write(', $key: $value');
    });
    instance.w(buffer.toString());
    _addBreadcrumb(
      message: 'Warning: $message',
      category: 'app.warning',
      level: SentryLevel.warning,
      data: payload,
    );
  }

  static void debug(String message, {Map<String, Object?>? params}) {
    final payload = params ?? const {};
    if (payload.isEmpty) {
      instance.d('Debug: $message');
      _addBreadcrumb(
        message: 'Debug: $message',
        category: 'app.debug',
        level: SentryLevel.debug,
        data: payload,
      );
      return;
    }

    final buffer = StringBuffer('Debug: $message');
    payload.forEach((key, value) {
      buffer.write(', $key: $value');
    });
    instance.d(buffer.toString());
    _addBreadcrumb(
      message: 'Debug: $message',
      category: 'app.debug',
      level: SentryLevel.debug,
      data: payload,
    );
  }

  /// Human-readable breadcrumb helper for user actions such as
  /// add/update/delete operations across the app.
  static void userAction(String message, {Map<String, Object?>? data}) {
    final payload = data ?? const {};
    if (payload.isEmpty) {
      instance.i('UserAction: $message');
    } else {
      final buffer = StringBuffer('UserAction: $message');
      payload.forEach((key, value) {
        buffer.write(', $key: $value');
      });
      instance.i(buffer.toString());
    }

    _addBreadcrumb(
      message: message,
      category: 'user.action',
      data: payload,
    );
  }

  static Future<void> error(String message, {Object? error, StackTrace? stackTrace}) async {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  static void _addBreadcrumb({
    required String message,
    required String category,
    SentryLevel level = SentryLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    try {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: message,
            category: category,
            level: level,
            timestamp: DateTime.now(),
            data: data,
          ),
        ),
      );
    } catch (_) {
      // Never throw from logging.
    }
  }
}

class _SentryAwareLogger {
  _SentryAwareLogger(this._delegate);

  final Logger _delegate;

  void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _delegate.i(message, time: time, error: error, stackTrace: stackTrace);
  }

  void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _delegate.w(message, time: time, error: error, stackTrace: stackTrace);
  }

  void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _delegate.d(message, time: time, error: error, stackTrace: stackTrace);
  }

  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    bool captureToSentry = true,
  }) {
    _delegate.e(message, time: time, error: error, stackTrace: stackTrace);

    if (!captureToSentry) {
      return;
    }

    unawaited(_captureException(message, error: error, stackTrace: stackTrace));
  }

  Future<void> _captureException(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    try {
      await Sentry.captureException(
        error ?? message,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('logger.message', message.toString());
        },
      );
    } catch (_) {
      // Never throw from logging.
    }
  }
}

/// Provider for AppLogger (for testing purposes)
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger._());
