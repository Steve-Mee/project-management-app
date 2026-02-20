// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Project Management App';

  @override
  String get menuLabel => 'Menu';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get logoutTooltip => 'Sign out';

  @override
  String get closeAppTooltip => 'Close app';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDisplaySection => 'Display';

  @override
  String get settingsDarkModeTitle => 'Dark mode';

  @override
  String get settingsDarkModeSubtitle => 'Switch between light and dark';

  @override
  String get settingsFollowSystemTitle => 'Follow system theme';

  @override
  String get settingsFollowSystemSubtitle => 'Use your device theme';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Updates and reminders';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsLocalFilesConsentTitle => 'Local file permission';

  @override
  String get settingsLocalFilesConsentSubtitle => 'Allow the app to read local project files for AI context.';

  @override
  String get settingsUseProjectFilesTitle => 'Use project files';

  @override
  String get settingsUseProjectFilesSubtitle => 'Add local files to AI prompts';

  @override
  String get settingsProjectsSection => 'Projects';

  @override
  String get settingsLogoutTitle => 'Sign out';

  @override
  String get settingsLogoutSubtitle => 'End your current session';

  @override
  String get settingsExportTitle => 'Export projects';

  @override
  String get settingsExportSubtitle => 'Export projects to a file';

  @override
  String get settingsImportTitle => 'Import projects';

  @override
  String get settingsImportSubtitle => 'Import projects from a file';

  @override
  String get settingsUsersSection => 'Users';

  @override
  String get settingsCurrentUserTitle => 'Current user';

  @override
  String get settingsNotLoggedIn => 'Not signed in';

  @override
  String get settingsNoUsersFound => 'No users found.';

  @override
  String get settingsLocalUserLabel => 'Local user';

  @override
  String get settingsDeleteTooltip => 'Delete';

  @override
  String get settingsLoadUsersFailed => 'Could not load users';

  @override
  String get settingsAddUserTitle => 'Add user';

  @override
  String get settingsAddUserSubtitle => 'Add an extra account';

  @override
  String get logoutDialogTitle => 'Sign out';

  @override
  String get logoutDialogContent => 'Are you sure you want to sign out?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get loggedOutMessage => 'You have signed out.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Export complete: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get exportPasswordTitle => 'Encrypt export';

  @override
  String get exportPasswordSubtitle => 'Set a password to encrypt the export files.';

  @override
  String get exportPasswordMismatch => 'Passwords do not match.';

  @override
  String get importSelectFilesMessage => 'Select a CSV and JSON file.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Import complete: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get importFailedTitle => 'Import failed';

  @override
  String get addUserDialogTitle => 'Add user';

  @override
  String get saveButton => 'Save';

  @override
  String get userAddedMessage => 'User added.';

  @override
  String get invalidUserMessage => 'Invalid user.';

  @override
  String get deleteUserDialogTitle => 'Delete user';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Are you sure you want to delete $username?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String userDeletedMessage(Object username) {
    return 'User deleted: $username';
  }

  @override
  String get projectsTitle => 'Projects';

  @override
  String get newProjectButton => 'New project';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get loadingMoreProjects => 'Loading more projects...';

  @override
  String get sortByLabel => 'Sort by';

  @override
  String get projectSortName => 'Name';

  @override
  String get projectSortProgress => 'Progress';

  @override
  String get projectSortPriority => 'Priority';

  @override
  String get allLabel => 'All';

  @override
  String get loadProjectsFailed => 'Could not load projects.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Project $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Status $status';
  }

  @override
  String get newProjectDialogTitle => 'New project';

  @override
  String get projectNameLabel => 'Project name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get urgencyLabel => 'Urgency';

  @override
  String get urgencyLow => 'Low';

  @override
  String get urgencyMedium => 'Medium';

  @override
  String get urgencyHigh => 'High';

  @override
  String projectCreatedMessage(Object name) {
    return 'Project created: $name';
  }

  @override
  String get projectDetailsTitle => 'Project details';

  @override
  String get aiChatWithProjectFilesTooltip => 'AI chat with project files';

  @override
  String get moreOptionsLabel => 'More options';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get detailsTab => 'Details';

  @override
  String get tasksLoadFailed => 'Could not load tasks.';

  @override
  String get projectOverviewTitle => 'Project overview';

  @override
  String get tasksLoading => 'Loading tasks...';

  @override
  String get taskStatisticsTitle => 'Task statistics';

  @override
  String get totalLabel => 'Total';

  @override
  String get completedLabel => 'Completed';

  @override
  String get inProgressLabel => 'In progress';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% complete';
  }

  @override
  String get burndownChartTitle => 'Burndown chart';

  @override
  String get chartPlaceholderTitle => 'Chart placeholder';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart integration coming soon';

  @override
  String get workflowsTitle => 'Workflows';

  @override
  String get noWorkflowsAvailable => 'No workflow items available.';

  @override
  String get taskStatusTodo => 'To do';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusReview => 'Review';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get workflowStatusActive => 'Active';

  @override
  String get workflowStatusPending => 'Pending';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get projectTimeTitle => 'Project time';

  @override
  String urgencyValue(Object value) {
    return 'Urgency: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Tracked time: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Search tasks...';

  @override
  String get searchAttachmentsHint => 'Search attachments...';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get projectMapTitle => 'Project folder';

  @override
  String get linkProjectMapButton => 'Link project folder';

  @override
  String get projectDataLoading => 'Loading project data...';

  @override
  String get projectDataLoadFailed => 'Could not load project data.';

  @override
  String currentMapLabel(Object path) {
    return 'Current folder: $path';
  }

  @override
  String get noProjectMapLinked => 'No folder linked yet. Link a folder to read files.';

  @override
  String get projectNotAvailable => 'Project not available.';

  @override
  String get enableConsentInSettings => 'Enable permission in Settings.';

  @override
  String get projectMapLinked => 'Project folder linked.';

  @override
  String get privacyWarningTitle => 'Privacy warning';

  @override
  String get privacyWarningContent => 'Warning: Sensitive data can be read.';

  @override
  String get continueButton => 'Continue';

  @override
  String get attachFilesTooltip => 'Attach files';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AI Assistant';

  @override
  String get welcomeBack => 'Welcome back! 👋';

  @override
  String get projectsOverviewSubtitle => 'Here\'s an overview of your active projects';

  @override
  String get recentWorkflowsTitle => 'Recent workflows';

  @override
  String get recentWorkflowsLoading => 'Loading recent workflows...';

  @override
  String get recentWorkflowsLoadFailed => 'Could not load recent workflows.';

  @override
  String get retryButton => 'Try again';

  @override
  String get noRecentTasks => 'No recent tasks available.';

  @override
  String get unknownProject => 'Unknown project';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle, Object statusLabel, Object timeLabel) {
    return 'Project $projectName, task $taskTitle, status $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Task $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks weeks ago';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months months ago';
  }

  @override
  String projectProgressChartSemantics(Object projectName, Object completedPercent, Object pendingPercent) {
    return 'Project progress chart for $projectName. Completed $completedPercent percent, pending $pendingPercent percent.';
  }

  @override
  String get progressLabel => 'Progress';

  @override
  String completedPercentLabel(Object percent) {
    return 'Completed: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'Pending: $percent%';
  }

  @override
  String get noDescription => 'No description';

  @override
  String get closeButton => 'Close';

  @override
  String get burndownProgressTitle => 'Burndown progress';

  @override
  String get actualProgressLabel => 'Actual progress';

  @override
  String get idealTrendLabel => 'Ideal trend';

  @override
  String get statusLabel => 'Status';

  @override
  String burndownChartSemantics(Object projectName, Object actualPoints, Object idealPoints) {
    return 'Burndown chart for $projectName. Actual points: $actualPoints. Ideal points: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'AI chat';

  @override
  String get aiUsageTitle => 'AI Usage';

  @override
  String get aiAssistantTitle => 'AI Project Assistant';

  @override
  String get clearChatTooltip => 'Clear chat';

  @override
  String get noMessagesLabel => 'No messages';

  @override
  String get aiEmptyTitle => 'Start a conversation with the AI assistant';

  @override
  String get aiEmptySubtitle => 'For example: \"Generate a plan for project: webshop\"';

  @override
  String get useProjectFilesLabel => 'Use project files';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get projectFilesReadFailed => 'Could not read project files.';

  @override
  String get aiResponseFailedTitle => 'AI response failed';

  @override
  String get sendMessageTooltip => 'Send message';

  @override
  String get loginMissingCredentials => 'Enter username and password.';

  @override
  String get loginFailedMessage => 'Sign in failed. Check your credentials.';

  @override
  String get registerTitle => 'Register';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Dutch';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Repeat password';

  @override
  String get passwordRulesTitle => 'Password rules';

  @override
  String get passwordRuleMinLength => 'At least 8 characters';

  @override
  String get passwordRuleHasLetter => 'Contains a letter';

  @override
  String get passwordRuleHasDigit => 'Contains a number';

  @override
  String get passwordRuleMatches => 'Passwords match';

  @override
  String get registerButton => 'Register';

  @override
  String get registrationIssueUsernameMissing => 'username missing';

  @override
  String get registrationIssueMinLength => 'minimum 8 characters';

  @override
  String get registrationIssueLetter => 'at least 1 letter';

  @override
  String get registrationIssueDigit => 'at least 1 number';

  @override
  String get registrationIssueNoMatch => 'passwords do not match';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registration failed: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Account created. Sign in now.';

  @override
  String get registerFailedMessage => 'Registration failed.';

  @override
  String get accessDeniedMessage => 'Access denied.';

  @override
  String get adminPanelTitle => 'Admin panel';

  @override
  String get adminPanelSubtitle => 'Manage roles, groups, and permissions.';

  @override
  String get rolesTitle => 'Roles';

  @override
  String get noRolesFound => 'No roles found.';

  @override
  String permissionsCount(Object count) {
    return 'Permissions: $count';
  }

  @override
  String get editPermissionsTooltip => 'Edit permissions';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get noGroupsFound => 'No groups found.';

  @override
  String get roleLabel => 'Role';

  @override
  String get groupAddTitle => 'Add group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupLabel => 'Group';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Add member to $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Add member';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Group members: $groupName';
  }

  @override
  String get noGroupMembers => 'No group members.';

  @override
  String get removeGroupMemberTooltip => 'Remove member';

  @override
  String get roleCreateTitle => 'Create role';

  @override
  String get roleNameLabel => 'Role name';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get settingsBackupTitle => 'Create backup';

  @override
  String get settingsBackupSubtitle => 'Save a local backup of Hive data.';

  @override
  String get settingsRestoreTitle => 'Restore backup';

  @override
  String get settingsRestoreSubtitle => 'Replace local data with a backup file.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Backup saved: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreSuccessMessage => 'Backup restored. Restart the app to reload data.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get restoreConfirmTitle => 'Restore backup?';

  @override
  String get restoreConfirmContent => 'This will overwrite your local data.';

  @override
  String get restoreConfirmButton => 'Restore';

  @override
  String get settingsBackupLastRunLabel => 'Last backup';

  @override
  String get backupNeverMessage => 'Never';

  @override
  String get backupNowButton => 'Backup now';

  @override
  String get settingsBackupPathLabel => 'Backup file';

  @override
  String get backupNoFileMessage => 'No backup file yet';
}
