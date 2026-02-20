import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../generated/app_localizations.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/project/project_screen.dart';
import '../features/project/project_detail_screen.dart';
import '../features/project/project_members_screen.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/ai_usage/ai_usage_screen.dart';
import 'providers.dart';
import 'auth/permissions.dart';

/// Navigation route definitions for the application
/// Uses go_router for declarative routing with named routes
class AppRoutes {
  // Route names (paths)
  static const String dashboard = '/dashboard';
  static const String projects = '/projects';
  static const String aiChat = '/ai-chat';
  static const String aiUsage = '/ai-usage';
  static const String settings = '/settings';
  static const String projectDetail = '/projects/:id';
  static const String projectMembers = '/projects/:id/members';
  static const String admin = '/admin';

  // Private constructor to prevent instantiation
  AppRoutes._();

  /// Initialize GoRouter with all application routes
  /// Provides named route definitions for easy navigation
  static GoRouter createRouter() {
    return GoRouter(
      // Initial route when app starts
      initialLocation: dashboard,
      
      // Route definitions
      routes: [
        // Dashboard/Home route
        ShellRoute(
          builder: (context, state, child) {
            return ResponsiveNavigationLayout(child: child);
          },
          routes: [
            GoRoute(
              path: dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            
            // Projects list route
            GoRoute(
              path: projects,
              name: 'projects',
              builder: (context, state) => const ProjectScreen(),
              
              // Project detail route - nested under projects
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'project-detail',
                  builder: (context, state) {
                    final projectId = state.pathParameters['id'] ?? 'unknown';
                    return ProjectDetailScreen(projectId: projectId);
                  },
                  routes: [
                    GoRoute(
                      path: 'members',
                      name: 'project-members',
                      builder: (context, state) {
                        final projectId = state.pathParameters['id'] ?? 'unknown';
                        return ProjectMembersScreen(projectId: projectId);
                      },
                    ),
                  ],
                ),
              ],
            ),
            
            // AI Chat route
            GoRoute(
              path: aiChat,
              name: 'ai-chat',
              builder: (context, state) => const AIChatScreen(),
            ),
            
            // AI Usage route
            GoRoute(
              path: aiUsage,
              name: 'ai-usage',
              builder: (context, state) => const AIUsageScreen(),
            ),
            
            // Settings route
            GoRoute(
              path: settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: admin,
              name: 'admin',
              builder: (context, state) => const AdminScreen(),
            ),
          ],
        ),
      ],
      
      // Error route handler
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Route not found: ${state.uri.toString()}'),
        ),
      ),
    );
  }
}

/// Navigation item model for modular navigation
/// Easily extend by adding new items to the navigation list
class NavigationItem {
  final String label;
  final IconData icon;
  final String routeName;
  final String? routePath;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.routeName,
    this.routePath,
  });
}

/// Navigation items configuration
/// Modular structure for easy addition/removal of navigation items
class NavigationConfig {
  static List<NavigationItem> items(AppLocalizations l10n) => [
    NavigationItem(
      label: l10n.projectOverviewTitle,
      icon: Icons.home_outlined,
      routeName: 'dashboard',
      routePath: '/dashboard',
    ),
    NavigationItem(
      label: l10n.projectsTitle,
      icon: Icons.folder_outlined,
      routeName: 'projects',
      routePath: '/projects',
    ),
    NavigationItem(
      label: l10n.aiChatSemanticsLabel,
      icon: Icons.chat_bubble_outline,
      routeName: 'ai-chat',
      routePath: '/ai-chat',
    ),
    NavigationItem(
      label: 'AI Usage',
      icon: Icons.analytics_outlined,
      routeName: 'ai-usage',
      routePath: '/ai-usage',
    ),
    NavigationItem(
      label: l10n.settingsTitle,
      icon: Icons.settings_outlined,
      routeName: 'settings',
      routePath: '/settings',
    ),
    NavigationItem(
      label: l10n.adminPanelTitle,
      icon: Icons.admin_panel_settings,
      routeName: 'admin',
      routePath: '/admin',
    ),
  ];

  // Private constructor to prevent instantiation
  NavigationConfig._();
}

/// Responsive navigation layout that adapts to screen size
/// Uses LayoutBuilder and MediaQuery for breakpoint detection
class ResponsiveNavigationLayout extends ConsumerWidget {
  final Widget child;

  const ResponsiveNavigationLayout({super.key, required this.child});

  int _calculateSelectedIndex(
    BuildContext context,
    List<NavigationItem> items,
  ) {
    final String location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < items.length; i++) {
      final path = items[i].routePath ?? '';
      if (path.isNotEmpty && location.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }

  void _onItemSelected(
    int index,
    BuildContext context,
    List<NavigationItem> items,
  ) {
    context.go(items[index].routePath!);
  }

  bool _hasNavPermission(NavigationItem item, Set<String> permissions) {
    switch (item.routeName) {
      case 'dashboard':
      case 'projects':
        return permissions.contains(AppPermissions.viewProjects);
      case 'ai-chat':
      case 'ai-usage':
        return permissions.contains(AppPermissions.useAi);
      case 'settings':
        return permissions.contains(AppPermissions.viewSettings);
      case 'admin':
        return permissions.contains(AppPermissions.manageRoles);
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final permissions = ref.watch(permissionsProvider);
    final items = NavigationConfig.items(l10n)
        .where((item) => _hasNavPermission(item, permissions))
        .toList();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isDesktop = MediaQuery.of(context).size.width > 600;

        if (isDesktop) {
          // Desktop layout with sidebar (NavigationRail)
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.appTitle),
              actions: _buildAppActions(context),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _GlobalSearchField(),
                ),
              ),
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _calculateSelectedIndex(context, items),
                  onDestinationSelected: (index) =>
                      _onItemSelected(index, context, items),
                  labelType: NavigationRailLabelType.all,
                  destinations: items.map((item) {
                    return NavigationRailDestination(
                      icon: Tooltip(
                        message: item.label,
                        child: Icon(item.icon),
                      ),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        } else {
          // Mobile layout with Drawer
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.appTitle),
              actions: _buildAppActions(context),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _GlobalSearchField(),
                ),
              ),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                    ),
                    child: Text(l10n.menuLabel),
                  ),
                  ...items.map((item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, item.routePath!);
                        },
                      )),
                ],
              ),
            ),
            body: child,
          );
        }
      },
    );
  }

  List<Widget> _buildAppActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: l10n.settingsTitle,
        onPressed: () => context.go(AppRoutes.settings),
      ),
      Consumer(
        builder: (context, ref, _) {
          return IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutTooltip,
            onPressed: () async {
              final result = await _confirmLogout(context);
              if (result != true) {
                return;
              }
              await ref.read(authProvider.notifier).logout();
            },
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.closeAppTooltip,
        onPressed: _closeApp,
      ),
    ];
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
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
  }

  void _closeApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      windowManager.close();
    }
  }
}

class _GlobalSearchField extends ConsumerStatefulWidget {
  const _GlobalSearchField();

  @override
  ConsumerState<_GlobalSearchField> createState() => _GlobalSearchFieldState();
}

class _GlobalSearchFieldState extends ConsumerState<_GlobalSearchField> {
  late final TextEditingController _controller;
  late final ProviderSubscription<String> _searchSubscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    _searchSubscription = ref.listenManual<String>(
      searchQueryProvider,
      (_, next) {
        if (next == _controller.text) {
          return;
        }
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchSubscription.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Zoek projecten...',
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).setQuery(value);
          setState(() {});
        },
      ),
    );
  }
}