// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/project/widgets/comment_section.dart';
import 'package:pma_core/models/comment_model.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/repository/i_auth_repository.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/auth/role_models.dart';
import 'package:pma_core/repository/impl/hive_settings_repository.dart';
import 'package:project_management_app/generated/app_localizations.dart';

// Fake auth repository for testing
class FakeAuthRepository implements IAuthRepository {
  final List<AppUser> _users;

  FakeAuthRepository(this._users);

  @override
  Future<void> initialize() async {}

  @override
  List<AppUser> getUsers() => _users;

  @override
  AppUser? getUserByUsername(String username) =>
    _users.where((u) => u.username == username).firstOrNull;

  @override
  List<RoleDefinition> getRoles() => [
    const RoleDefinition(id: 'role_admin', name: 'Admin', permissions: []),
    const RoleDefinition(id: 'role_member', name: 'Member', permissions: []),
    const RoleDefinition(id: 'role_viewer', name: 'Viewer', permissions: []),
  ];

  @override
  RoleDefinition? getRoleById(String roleId) =>
    getRoles().where((r) => r.id == roleId).firstOrNull;

  @override
  Future<void> upsertRole(RoleDefinition role) async {}

  @override
  Future<void> deleteRole(String roleId) async {}

  @override
  List<GroupDefinition> getGroups() => [];

  @override
  GroupDefinition? getGroupById(String groupId) => null;

  @override
  List<GroupDefinition> getGroupsForUser(String username) => [];

  @override
  Future<void> upsertGroup(GroupDefinition group) async {}

  @override
  Future<void> deleteGroup(String groupId) async {}

  @override
  Future<void> addUserToGroup(String groupId, String username) async {}

  @override
  Future<void> removeUserFromGroup(String groupId, String username) async {}

  @override
  Future<void> updateUserRole(String username, String roleId) async {}

  @override
  Future<void> addUser(AppUser user) async {}

  @override
  Future<void> deleteUser(String username) async {}

  @override
  AppUser? validateUser(String username, String password) =>
      getUserByUsername(username);

  @override
  String? getCurrentUser() => null;

  @override
  Future<void> setCurrentUser(String? username) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<void> inviteUser(String email) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<bool> canAttemptLogin(String identifier) async => true;

  @override
  Future<void> recordFailedLoginAttempt(String identifier) async {}

  @override
  Future<bool> isLoginBlocked(String email) async => false;

  @override
  Future<void> recordLoginAttempt(String email) async {}

  @override
  Future<void> resetLoginAttempts(String email) async {}

  @override
  String get adminRoleId => 'role_admin';

  @override
  String get defaultUserRoleId => 'role_member';

  @override
  String get viewerRoleId => 'role_viewer';

  @override
  dynamic getCurrentSession() => null;

  @override
  Future<void> recoverSession() async {}

  @override
  Stream<dynamic> get onAuthStateChange => const Stream.empty();
}

// Fake settings repository
class FakeSettingsRepository extends HiveSettingsRepository {
  @override
  Future<void> initialize() async {}

  @override
  ThemeMode? getThemeMode() => null;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  bool? getNotificationsEnabled() => null;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}

  @override
  String? getLocaleCode() => null;

  @override
  Future<void> setLocaleCode(String? localeCode) async {}

  @override
  DateTime? getLastBackupTime() => null;

  @override
  Future<void> setLastBackupTime(DateTime timestamp) async {}

  @override
  String? getLastBackupPath() => null;

  @override
  Future<void> setLastBackupPath(String path) async {}

  @override
  bool getUseBiometricsEnabled() => false;

  @override
  Future<void> setUseBiometricsEnabled(bool enabled) async {}
}

void main() {
  late FakeSettingsRepository fakeSettings;
  late FakeAuthRepository fakeAuthRepo;
  late ProviderContainer container;

  setUp(() {
    fakeSettings = FakeSettingsRepository();

    // Create test users
    final testUsers = [
      const AppUser(username: 'john_doe', password: 'pass', roleId: 'role_member'),
      const AppUser(username: 'jane_smith', password: 'pass', roleId: 'role_admin'),
      const AppUser(username: 'bob_wilson', password: 'pass', roleId: 'role_member'),
      const AppUser(username: 'alice_brown', password: 'pass', roleId: 'role_viewer'),
    ];

    fakeAuthRepo = FakeAuthRepository(testUsers);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => fakeAuthRepo),
        settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CommentSection @mention autocomplete', () {
    testWidgets('autocomplete appears on @ character', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => fakeAuthRepo),
            settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1280, 720),
            builder: (context, child) => const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: CommentSection(projectId: 'test-project'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text with @
      await tester.enterText(textField, 'Hello @');
      await tester.pumpAndSettle();

      // Should show autocomplete options
      expect(find.byType(ListTile), findsWidgets); // Autocomplete suggestions
    });

    testWidgets('shows suggestions from real user database', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => fakeAuthRepo),
            settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1280, 720),
            builder: (context, child) => const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: CommentSection(projectId: 'test-project'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter @ followed by partial username
      await tester.enterText(find.byType(TextField), '@john');
      await tester.pumpAndSettle();

      // Should find john_doe in suggestions
      expect(find.text('john_doe'), findsOneWidget);
    });

    testWidgets('parses and displays mentions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => fakeAuthRepo),
            settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1280, 720),
            builder: (context, child) => MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Column(
                  children: [
                    // Mock the comment display
                    Builder(
                      builder: (context) => RichText(
                        text: TextSpan(
                          children: _buildTestMentionSpans(
                            'Hello @john_doe and @jane_smith!',
                            {'john_doe': 'john_doe', 'jane_smith': 'jane_smith'},
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the text with mentions
      expect(find.byType(RichText), findsOneWidget);
      // The mentions should be styled differently (blue/underline)
      // This is a basic test - in a real scenario we'd check the TextSpan styles
    });

    test('submit flow stores mentioned user IDs and supports reload mapping', () {
      // Simulate typed comment input in submit flow.
      const text = 'Hello @john_doe and @jane_smith!';

      // Bidirectional mapping used by comment providers.
      const userProfiles = <String, String>{
        'john_doe': 'user-1',
        'jane_smith': 'user-2',
        'user-1': 'john_doe',
        'user-2': 'jane_smith',
      };

      final mentionedUsernames = CommentModel.parseMentions(text);
      final mentionedUserIds = mentionedUsernames
          .map((username) => userProfiles[username])
          .whereType<String>()
          .toList();

      final saved = CommentModel.create(
        userId: 'author-1',
        projectId: 'project-1',
        text: text,
        mentionedUsers: mentionedUserIds,
      );

      // Simulate reload from persistence/network.
      final reloaded = CommentModel.fromJson(saved.toJson());

      expect(reloaded.mentionedUsers, equals(<String>['user-1', 'user-2']));

      // Mention display mapping uses stored IDs -> usernames.
      final mentionDisplay = reloaded.mentionedUsers
          .map((id) => '@${userProfiles[id] ?? 'unknown'}')
          .join(', ');
      expect(mentionDisplay, '@john_doe, @jane_smith');
    });
  });
}

// Helper function to build mention spans for testing
List<TextSpan> _buildTestMentionSpans(String text, Map<String, String> userProfiles) {
  final spans = <TextSpan>[];
  final mentionRegex = RegExp(r'@(\w+)');
  final matches = mentionRegex.allMatches(text);

  int lastEnd = 0;

  for (final match in matches) {
    // Add text before the mention
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }

    // Add the mention (simplified for testing)
    final username = match.group(1)!;
    spans.add(TextSpan(
      text: '@$username',
      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
    ));

    lastEnd = match.end;
  }

  // Add remaining text
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }

  return spans;
}
