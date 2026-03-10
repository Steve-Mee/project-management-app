// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'core/theme.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart';
import 'package:pma_core/providers/navigation/navigation_providers.dart';
import 'package:pma_core/providers/onboarding_providers.dart';
import 'package:pma_core/providers/project/project_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/providers/theme/theme_providers.dart';
import 'package:pma_core/services/cloud_sync_service.dart';
import 'package:pma_core/repository/impl/hive_project_repository.dart';
import 'core/routes.dart';
import 'package:pma_core/widgets/offline_indicator.dart';
import 'package:pma_core/repository/hive_initializer.dart' hide ProjectsInitializer;
import 'package:pma_core/core/services/feature_flag_service.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/services/login_rate_limiter.dart';
import 'package:pma_core/services/recaptcha_config.dart';
import 'package:pma_core/services/project_invitation_service.dart';
import 'package:pma_core/services/supabase_connection_diagnostics.dart';
import 'core/widgets/onboarding_wizard.dart';
import 'features/auth/login_screen.dart';
import 'models/project_model.dart';
import 'models/task_model.dart';
import 'models/comment_model.dart';
import 'package:pma_core/models/adapters/migrated_model_adapters.dart';
import 'core/config/app_config.dart';
import 'core/services/sentry_service.dart';
import 'core/widgets/error_boundary.dart';
import 'core/projects_initializer.dart';
import 'features/mirror/services/mirror_outbox_replay_service.dart';

/// Enable Semantics Debugger only in debug mode when explicitly requested.
/// Use: flutter run --dart-define=ENABLE_SEMANTICS_DEBUGGER=true
const bool _enableSemanticsDebugger =
  bool.fromEnvironment('ENABLE_SEMANTICS_DEBUGGER', defaultValue: false);
const bool _showSemanticsDebugger =
  kDebugMode && _enableSemanticsDebugger;

/// Debug flags for issue #072 error-path verification.
///
/// Examples:
/// - flutter run --dart-define=DEBUG_THROW_STARTUP_ERROR=true
/// - flutter run --dart-define=DEBUG_THROW_POSTFRAME_ERROR=true
const bool _debugThrowStartupError =
  bool.fromEnvironment('DEBUG_THROW_STARTUP_ERROR', defaultValue: false);
const bool _debugThrowPostFrameError =
  bool.fromEnvironment('DEBUG_THROW_POSTFRAME_ERROR', defaultValue: false);

/// Main entry point of the application
/// Initializes Riverpod for state management and ScreenUtil for responsive design
void main() async {
  // Guard startup and uncaught async exceptions at the process level.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize application configuration and service dependencies.
    await AppConfig.initialize();

    // Firebase: initialize only Core + Messaging.
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();
    }
    await SupabaseConnectionDiagnostics.logConfigurationSnapshot(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      context: 'startup_before_supabase_initialize',
    );
    await SupabaseConnectionDiagnostics.logNetworkDiagnostics(
      url: AppConfig.supabaseUrl,
      context: 'startup_before_supabase_initialize',
      force: true,
    );
    await Supabase.initialize(
      url: AppConfig.supabaseUrl!,
      anonKey: AppConfig.supabaseAnonKey!,
    );

    // Initialize Stripe.
    Stripe.publishableKey = AppConfig.stripePublishableKey ?? '';
    Stripe.merchantIdentifier = 'merchant.com.example';
    Stripe.urlScheme = 'flutterstripe';

    Hive.registerAdapter<ProjectModel>(ProjectModelAdapter());
    Hive.registerAdapter<TaskStatus>(TaskStatusAdapter());
    Hive.registerAdapter<Task>(TaskAdapter());
    Hive.registerAdapter<CommentModel>(CommentModelAdapter());
    registerSafeMigratedModelAdapters();
    await Hive.initFlutter();
    await Hive.openBox('groups');
    await Hive.openBox('roles');
    // Canonical box initialization (encrypted + performance boxes).
    await HiveInitializer.initialize();
    await LoginRateLimiter.instance.initialize();

    final featureFlags = FeatureFlagService(
      supabaseClient: Supabase.instance.client,
    );
    await featureFlags.initialize();
    await featureFlags.refresh();

    final container = ProviderContainer();

    // Start mirror outbox replay worker for startup/network restoration replay.
    container.read(mirrorOutboxReplayServiceProvider);

    // Initialize reCAPTCHA config with settings repository.
    final settingsRepo = await container.read(settingsRepositoryProvider.future);
    RecaptchaConfig.initializeWithRepository(settingsRepo);
    RecaptchaConfig.initialize();

    final lifecycleHandler = _AppLifecycleHandler(container);
    lifecycleHandler.startPeriodicBackup();
    WidgetsBinding.instance.addObserver(lifecycleHandler);

    if (kDebugMode && _debugThrowStartupError) {
      throw StateError('Debug startup error for ErrorBoundary/Sentry validation');
    }

    // Initialize Sentry, then launch the app tree with global ErrorBoundary.
    await SentryService.initialize(
      environment: kReleaseMode ? 'production' : 'development',
      appRunner: () {
        // Trigger a framework error after first frame to validate ErrorBoundary UI.
        if (kDebugMode && _debugThrowPostFrameError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            throw FlutterError(
              'Debug post-frame Flutter error for ErrorBoundary validation',
            );
          });
        }

        runApp(
          UncontrolledProviderScope(
            container: container,
            child: const ErrorBoundary(
              child: _AppBootstrapGate(child: MyApp()),
            ),
          ),
        );
      },
    );
  }, (Object error, StackTrace stackTrace) {
    // Last-resort catch for uncaught zone errors.
    unawaited(
      SentryService.captureException(
        error,
        stackTrace: stackTrace,
        reason: 'main_run_zoned_guarded',
      ),
    );
  });
}

/// Global startup gate for issue #067 onboarding flow.
///
/// The onboarding wizard is shown before [ProjectsInitializer] on first launch.
/// After completion, the persisted shared_preferences flag prevents it from
/// appearing again and we transition smoothly into the main app.
class _AppBootstrapGate extends ConsumerStatefulWidget {
  final Widget child;

  const _AppBootstrapGate({required this.child});

  @override
  ConsumerState<_AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends ConsumerState<_AppBootstrapGate> {
  bool _isResolving = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _resolveFirstLaunch();
  }

  Future<void> _resolveFirstLaunch() async {
    final isFirstLaunch =
        await ref.read(onboardingProvider.notifier).isFirstLaunch();

    if (!mounted) {
      return;
    }

    setState(() {
      _showOnboarding = isFirstLaunch;
      _isResolving = false;
    });
  }

  void _handleOnboardingCompleted() {
    if (!mounted) {
      return;
    }

    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolving) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: _showSemanticsDebugger,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final currentChild = _showOnboarding
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            showSemanticsDebugger: _showSemanticsDebugger,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: OnboardingWizard(onCompleted: _handleOnboardingCompleted),
          )
        : ProjectsInitializer(child: widget.child);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_showOnboarding ? 'onboarding' : 'main-app'),
        child: currentChild,
      ),
    );
  }
}

class _AppLifecycleHandler extends WidgetsBindingObserver {
  final ProviderContainer _container;
  bool _closed = false;
  late final CloudSyncService _cloudSync;
  Timer? _backupTimer;

  _AppLifecycleHandler(this._container) {
    final repository = _container.read(projectRepositoryProvider) as HiveProjectRepository;
    _cloudSync = CloudSyncService(repository: repository);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _closeRepositories();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backupOnBackground();
    }

    if (state == AppLifecycleState.resumed) {
      _syncOnResume();
    }
  }

  Future<void> _syncOnResume() async {
    try {
      await _cloudSync.syncAll();
    } catch (e) {
      AppLogger.instance.e('Error syncing on resume', error: e);
    }
  }

  // Fully implemented in 040-supabase-sync-cleanup.md

  Future<void> _backupOnBackground() async {
    try {
      await HiveInitializer.backupHive();
      // Persist AI request queue for offline recovery
      final aiChatNotifier = _container.read(aiChatProvider.notifier);
      await aiChatNotifier.persistQueue();
    } catch (e) {
      AppLogger.instance.e('Error creating background backup', error: e);
    }
  }

  Future<void> _closeRepositories() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await HiveInitializer.backupHive();
      final projectRepository =
          _container.read(projectRepositoryProvider);
      await projectRepository.close();

        final taskRepository =
          await _container.read(taskRepositoryProvider.future);
        await taskRepository.close();

        final metaRepository =
          await _container.read(projectMetaRepositoryProvider.future);
        await metaRepository.close();
    } catch (e) {
      AppLogger.instance.e('Error closing repositories', error: e);
    } finally {
      _backupTimer?.cancel();
      _container.dispose();
    }
  }

  void startPeriodicBackup() {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(const Duration(days: 1), (_) async {
      try {
        await HiveInitializer.backupHive();
      } catch (e) {
        AppLogger.instance.e('Error creating scheduled Hive backup', error: e);
      }
    });
  }
}

/// Root widget of the application
/// Configures MaterialApp with theme support via Riverpod, responsive design, and routing
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  AppLinks? _appLinks;
  StreamSubscription? _linkSubscription;
  String? _pendingInvitationToken;

  @override
  void initState() {
    super.initState();
    _setupDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link
    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      AppLogger.instance.e('Failed to get initial link', error: e);
    }

    // Listen for new links
    _linkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      AppLogger.instance.e('Deep link error', error: err);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path == '/accept-invite' && uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token']!;
      _handleInvitationToken(token);
    }
  }

  Future<void> _handleInvitationToken(String token) async {
    final authState = ref.read(authProvider).valueOrNull;
    if (authState == null || !authState.isAuthenticated) {
      // Store token for after login
      setState(() {
        _pendingInvitationToken = token;
      });
      // Redirect to login
      if (mounted) {
        context.go('/login'); // Assuming login route exists
      }
      return;
    }

    // Accept invitation
    try {
      final invitationService = ProjectInvitationService(Supabase.instance.client);
      await invitationService.acceptInvitation(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Je bent toegevoegd aan het project!')),
        );
        // Navigate to dashboard
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij accepteren uitnodiging: $e')),
        );
      }
    }
  }

  void _checkPendingInvitation() {
    if (_pendingInvitationToken != null) {
      final token = _pendingInvitationToken!;
      _pendingInvitationToken = null;
      _handleInvitationToken(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the theme mode provider to rebuild when it changes
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentThemeMode = themeModeAsync.maybeWhen(
      data: (t) => t,
      orElse: () => ThemeMode.system,
    );
    final colorSchemeSeedAsync = ref.watch(colorSchemeSeedProvider);
    final colorSchemeSeed = colorSchemeSeedAsync.maybeWhen(
      data: (seed) => seed,
      orElse: () => null,
    );
    final authStateAsync = ref.watch(authProvider);
    final authState = authStateAsync.valueOrNull;
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.maybeWhen(
      data: (l) => l,
      orElse: () => null,
    );
    final effectiveLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    final isRtl = _isRtlLocale(effectiveLocale);
    
    // Create router for navigation
    final goRouter = AppRoutes.createRouter();

    // Check for pending invitation when auth state changes
    if (authState?.isAuthenticated == true && _pendingInvitationToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPendingInvitation();
      });
    }

    // Initialize ScreenUtil for responsive design across different screen sizes
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Base design size (iPhone X dimensions)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        if (authStateAsync.isLoading || authState == null) {
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appTitle ??
                  'Project Management App',
              debugShowCheckedModeBanner: false,
              showSemanticsDebugger: _showSemanticsDebugger,
              locale: locale,
              themeMode: currentThemeMode,
              theme: AppTheme.lightTheme(seedColor: colorSchemeSeed),
              darkTheme: AppTheme.darkTheme(seedColor: colorSchemeSeed),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        if (!authState.isAuthenticated) {
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appTitle ??
                  'Project Management App',
              debugShowCheckedModeBanner: false,
              showSemanticsDebugger: _showSemanticsDebugger,
              locale: locale,
              themeMode: currentThemeMode,
              theme: AppTheme.lightTheme(seedColor: colorSchemeSeed),
              darkTheme: AppTheme.darkTheme(seedColor: colorSchemeSeed),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginScreen(),
            ),
          );
        }

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp.router(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ??
                'Project Management App',
            debugShowCheckedModeBanner: false,
            showSemanticsDebugger: _showSemanticsDebugger,

            // Theme mode - supports system/dark/light
            themeMode: currentThemeMode,

            locale: locale,

            // Light theme configuration
            theme: AppTheme.lightTheme(seedColor: colorSchemeSeed),

            // Dark theme configuration
            darkTheme: AppTheme.darkTheme(seedColor: colorSchemeSeed),

            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            // Router configuration for navigation
            routerConfig: goRouter,
          ),
        );
      },
    );
  }
}

bool _isRtlLocale(Locale locale) {
  const rtlLanguageCodes = <String>['ar'];
  return rtlLanguageCodes.contains(locale.languageCode.toLowerCase());
}
/// Responsive navigation layout widget
/// Shows Drawer on desktop (width > 600) and BottomNavigationBar on mobile
class ResponsiveNavigationLayout extends ConsumerWidget {
  final Widget child;

  const ResponsiveNavigationLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final l10n = AppLocalizations.of(context)!;
    final items = NavigationConfig.items(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;

        if (isDesktop) {
          // Desktop layout with Drawer
          return Scaffold(
            drawer: _buildNavigationDrawer(context, ref, selectedIndex),
            body: Row(
              children: [
                // Side drawer visible on desktop
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 280.w,
                    minWidth: 200.w,
                  ),
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      _handleNavigation(context, ref, items, index);
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: items
                        .map(
                          (item) => NavigationRailDestination(
                            icon: (Platform.isWindows ||
                                    Platform.isLinux ||
                                    Platform.isMacOS)
                                ? Semantics(
                                    label: item.label,
                                    child: Icon(item.icon),
                                  )
                                : Tooltip(
                                    message: item.label,
                                    child: Icon(item.icon),
                                  ),
                            label: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Main content area
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: max(constraints.maxWidth - 280.w, 400.w), // Account for max nav width
                    ),
                    child: Column(
                      children: [
                        // App bar with theme toggle
                        OfflineIndicatorAppBar(
                          // Keep global indicator above the desktop app bar.
                          appBar: AppBar(
                            title: Text(l10n.appTitle),
                            centerTitle: true,
                            elevation: 0,
                            actions: _buildAppActions(context, ref),
                          ),
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout with BottomNavigationBar
          return Scaffold(
            appBar: OfflineIndicatorAppBar(
              // Global status bar appears above the route-level app bar.
              appBar: AppBar(
                title: Text(l10n.appTitle),
                centerTitle: true,
                actions: _buildAppActions(context, ref),
              ),
            ),
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                _handleNavigation(context, ref, items, index);
              },
              type: BottomNavigationBarType.fixed,
              items: items
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: (Platform.isWindows ||
                              Platform.isLinux ||
                              Platform.isMacOS)
                          ? Icon(item.icon)
                          : Tooltip(
                              message: item.label,
                              child: Icon(item.icon),
                            ),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }
      },
    );
  }

  /// Build navigation drawer for desktop
  Widget _buildNavigationDrawer(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = NavigationConfig.items(l10n);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.dashboard,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.appTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          ...items.asMap().entries.map(
            (entry) {
              int index = entry.key;
              NavigationItem item = entry.value;
              bool isSelected = index == selectedIndex;

              return ListTile(
                leading: Semantics(
                  label: item.label,
                  child: Icon(item.icon),
                ),
                title: Text(item.label),
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                onTap: () {
                  _handleNavigation(context, ref, items, index);
                  Navigator.pop(context); // Close drawer after selection
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Handle navigation to a specific index
  void _handleNavigation(
    BuildContext context,
    WidgetRef ref,
    List<NavigationItem> items,
    int index,
  ) {
    ref.read(navigationIndexProvider.notifier).setSelectedIndex(index);
    final item = items[index];
    if (item.routePath != null) {
      GoRouter.of(context).go(item.routePath!);
    }
  }

  /// Build shared app bar actions
  List<Widget> _buildAppActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <Widget>[
      _buildThemeToggle(ref),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: l10n.logoutTooltip,
        onPressed: () {
          _confirmLogout(context, ref);
        },
      ),
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.closeAppTooltip,
        onPressed: () {
          _closeApp();
        },
      ),
    ];

    return actions;
  }

  void _closeApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
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
  }

  /// Build theme toggle button
  Widget _buildThemeToggle(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final themeModeAsync = ref.watch(themeModeProvider);
        final currentThemeMode = themeModeAsync.maybeWhen(
          data: (t) => t,
          orElse: () => ThemeMode.system,
        );
        final l10n = AppLocalizations.of(context)!;

        return IconButton(
          icon: Icon(
            _getThemeIcon(currentThemeMode),
            size: 24.sp,
          ),
          onPressed: () {
            ThemeMode nextMode;
            if (currentThemeMode == ThemeMode.system) {
              nextMode = ThemeMode.dark;
            } else if (currentThemeMode == ThemeMode.dark) {
              nextMode = ThemeMode.light;
            } else {
              nextMode = ThemeMode.system;
            }
            ref.read(themeModeProvider.notifier).setThemeMode(nextMode);
          },
          tooltip: l10n.settingsDarkModeTitle,
        );
      },
    );
  }

  /// Get the appropriate icon based on theme mode
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.dark:
        return Icons.brightness_2;
      case ThemeMode.light:
        return Icons.brightness_7;
    }
  }
}

// Import GoRouter extension moved to top



