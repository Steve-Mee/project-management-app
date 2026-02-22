import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:app_links/app_links.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'core/theme.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'core/providers/auth_providers.dart';
import 'core/providers/theme_providers.dart';
import 'core/providers/navigation_providers.dart';
import 'core/routes.dart';
import 'core/repository/hive_initializer.dart';
import 'core/services/app_logger.dart';
import 'core/services/ab_testing_service.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/login_rate_limiter.dart';
import 'core/services/project_invitation_service.dart';
import 'features/auth/login_screen.dart';
import 'models/project_model.dart';
import 'models/task_model.dart';
import 'models/comment_model.dart';

/// Initializes environment variables from .env file
/// Loads dotenv for development. In production, uses secure storage if available
/// Future expansions: Add more env vars like OPENAI_API_KEY, etc.
Future<Map<String, String>> initEnv() async {
  String url;
  String anonKey;
  
  if (!kReleaseMode) {
    // Debug mode: load from .env file
    await dotenv.load();
    url = dotenv.env['SUPABASE_URL'] ?? '';
    anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  } else {
    // Release mode: Use secure storage for production security
    const storage = FlutterSecureStorage();
    url = await storage.read(key: 'SUPABASE_URL') ?? '';
    anonKey = await storage.read(key: 'SUPABASE_ANON_KEY') ?? '';
    if (url.isEmpty || anonKey.isEmpty) {
      // Fallback to .env if secure storage is empty
      await dotenv.load();
      url = dotenv.env['SUPABASE_URL'] ?? '';
      anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    }
  }
  
  if (url.isEmpty) {
    throw Exception('SUPABASE_URL not found');
  }
  if (anonKey.isEmpty) {
    throw Exception('SUPABASE_ANON_KEY not found');
  }
  
  // Future expansions: Add more env vars here
  // String openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  
  return {
    'url': url,
    'anonKey': anonKey,
    // 'openaiKey': openaiKey,
  };
}



/// Main entry point of the application
/// Initializes Riverpod for state management and ScreenUtil for responsive design
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  final env = await initEnv();
  
  // Future expansions: Add more env vars here, e.g., OPENAI_API_KEY
  // String openaiKey = env['openaiKey']!;
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }
  await Supabase.initialize(
    url: env['url']!,
    anonKey: env['anonKey']!,
  );
  Hive.registerAdapter(ProjectModelAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CommentModelAdapter());
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('auth');
  await Hive.openBox('groups');
  await Hive.openBox('roles');
  await HiveInitializer.initialize();
  await LoginRateLimiter.instance.initialize();
  final abTesting = ABTestingService.instance;
  await abTesting.initialize();
  await abTesting.fetchRemoteConfigs();
  final container = ProviderContainer();
  final lifecycleHandler = _AppLifecycleHandler(container);
  lifecycleHandler.startPeriodicBackup();
  WidgetsBinding.instance.addObserver(lifecycleHandler);
  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://4cc5120c8496e93b5b9f1798f0d1077b@o4510841439453184.ingest.de.sentry.io/4510841442402384';
        options.enableAutoSessionTracking = true;
        options.environment = 'production';
      },
      appRunner: () {
        runApp(
          UncontrolledProviderScope(
            container: container,
            child: const ProjectsInitializer(child: MyApp()),
          ),
        );
      },
    );
    return;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ProjectsInitializer(child: MyApp()),
    ),
  );
}

class _AppLifecycleHandler extends WidgetsBindingObserver {
  final ProviderContainer _container;
  bool _closed = false;
  final CloudSyncService _cloudSync = CloudSyncService();
  Timer? _backupTimer;

  _AppLifecycleHandler(this._container);

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

  Future<void> _backupOnBackground() async {
    try {
      await HiveInitializer.backupHive();
    } catch (e) {
      AppLogger.instance.e('Error creating background Hive backup', error: e);
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
    final authState = ref.read(authProvider).value!;
    if (!authState.isAuthenticated) {
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
    final authState = ref.watch(authProvider).value!;
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
    if (authState.isAuthenticated && _pendingInvitationToken != null) {
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
        if (!authState.isAuthenticated) {
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appTitle ??
                  'Project Management App',
              debugShowCheckedModeBanner: false,
              locale: locale,
              themeMode: currentThemeMode,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
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

            // Theme mode - supports system/dark/light
            themeMode: currentThemeMode,

            locale: locale,

            // Light theme configuration
            theme: AppTheme.lightTheme(),

            // Dark theme configuration
            darkTheme: AppTheme.darkTheme(),

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
                        AppBar(
                          title: Text(l10n.appTitle),
                          centerTitle: true,
                          elevation: 0,
                          actions: _buildAppActions(context, ref),
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
            appBar: AppBar(
              title: Text(l10n.appTitle),
              centerTitle: true,
              actions: _buildAppActions(context, ref),
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
                Icon(
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



