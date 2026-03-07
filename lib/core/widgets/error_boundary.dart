import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pma_core/services/app_logger.dart';

import '../services/sentry_service.dart';

/// Global application error boundary.
///
/// Place this at the top of the widget tree so it can:
/// - install global Flutter/engine error hooks,
/// - report crashes to AppLogger and Sentry,
/// - and show a restartable fallback UI.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onRestart,
  });

  final Widget child;

  /// Optional callback for additional restart side effects.
  final FutureOr<void> Function()? onRestart;

  /// Restarts the nearest [ErrorBoundary] subtree.
  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<_ErrorBoundaryState>();
    state?._restartApp();
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  void Function(FlutterErrorDetails details)? _previousFlutterErrorHandler;
  ErrorWidgetBuilder? _previousErrorWidgetBuilder;
  bool Function(Object, StackTrace)? _previousPlatformErrorHandler;

  Object? _lastError;
  StackTrace? _lastStackTrace;
  String? _lastErrorId;
  int _restartVersion = 0;

  bool get _hasError => _lastError != null;

  @override
  void initState() {
    super.initState();
    _installGlobalHandlers();
  }

  @override
  void dispose() {
    _restoreGlobalHandlers();
    super.dispose();
  }

  void _installGlobalHandlers() {
    _previousFlutterErrorHandler = FlutterError.onError;
    _previousErrorWidgetBuilder = ErrorWidget.builder;
    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      _recordError(
        details.exception,
        details.stack,
        reason: 'flutter_framework_error',
        isFatal: true,
      );

      if (_previousFlutterErrorHandler != null) {
        _previousFlutterErrorHandler!(details);
      }
    };

    // Captures asynchronous/unhandled engine-level errors.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      _recordError(
        error,
        stackTrace,
        reason: 'platform_dispatcher_error',
        isFatal: true,
      );
      return true;
    };

    // Intercepts build-phase widget failures to trigger fallback screen.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _recordError(
        details.exception,
        details.stack,
        reason: 'error_widget_builder',
        isFatal: true,
      );

      return const SizedBox.shrink();
    };

    unawaited(
      SentryService.addUserActionBreadcrumb(
        'error_boundary_initialized',
        category: 'app.lifecycle',
      ),
    );
  }

  void _restoreGlobalHandlers() {
    FlutterError.onError = _previousFlutterErrorHandler;
    ErrorWidget.builder = _previousErrorWidgetBuilder ??
        (FlutterErrorDetails details) => ErrorWidget.withDetails(
              message: details.exceptionAsString(),
              error: details.exception is FlutterError
                  ? details.exception as FlutterError
                  : null,
            );
    PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
  }

  void _recordError(
    Object error,
    StackTrace? stackTrace, {
    required String reason,
    required bool isFatal,
  }) {
    AppLogger.instance.e(
      'ErrorBoundary caught error ($reason)',
      error: error,
      stackTrace: stackTrace,
      captureToSentry: false,
    );

    unawaited(
      SentryService.addUserActionBreadcrumb(
        'error_boundary_caught',
        category: 'app.error',
        data: <String, Object?>{
          'reason': reason,
          'fatal': isFatal,
          'error_type': error.runtimeType.toString(),
        },
      ),
    );

    unawaited(
      SentryService.captureException(
        error,
        stackTrace: stackTrace,
        reason: reason,
        extras: <String, Object?>{
          'fatal': isFatal,
          'error_type': error.runtimeType.toString(),
          'error_id': _buildErrorId(),
        },
      ),
    );

    _setBoundaryError(error, stackTrace);
  }

  String _buildErrorId() {
    return DateTime.now().toIso8601String();
  }

  void _setBoundaryError(Object error, StackTrace? stackTrace) {
    if (!mounted) {
      return;
    }

    void apply() {
      if (!mounted) {
        return;
      }

      if (_lastError == error && _lastStackTrace == stackTrace) {
        return;
      }

      setState(() {
        _lastError = error;
        _lastStackTrace = stackTrace;
        _lastErrorId = _buildErrorId();
      });
    }

    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        apply();
      });
      return;
    }

    apply();
  }

  Future<void> _restartApp() async {
    unawaited(
      SentryService.addUserActionBreadcrumb(
        'error_boundary_restart_pressed',
        category: 'user.action',
      ),
    );

    if (widget.onRestart != null) {
      await widget.onRestart!();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _lastError = null;
      _lastStackTrace = null;
      _lastErrorId = null;
      _restartVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorFallbackScreen(
        error: _lastError,
        errorId: _lastErrorId,
        onRestart: _restartApp,
      );
    }

    return KeyedSubtree(
      key: ValueKey<int>(_restartVersion),
      child: widget.child,
    );
  }
}

class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen({
    required this.error,
    required this.errorId,
    required this.onRestart,
  });

  final Object? error;
  final String? errorId;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: colorScheme.primary,
        brightness: theme.brightness,
      ),
      home: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Something went wrong',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The app ran into an unexpected error. You can restart the app now.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            error?.toString() ?? 'Unknown error',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (errorId != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Error ID: $errorId',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: onRestart,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart App'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
