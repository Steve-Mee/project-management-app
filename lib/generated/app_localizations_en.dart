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
  String get settingsColorSchemeTitle => 'Color scheme';

  @override
  String get settingsColorSchemeSubtitle => 'Choose your preferred color theme';

  @override
  String get settingsColorSchemeDefault => 'Default (Green)';

  @override
  String get settingsColorSchemeBlue => 'Blue';

  @override
  String get settingsColorSchemePurple => 'Purple';

  @override
  String get settingsColorSchemeOrange => 'Orange';

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
  String get settingsLocalFilesConsentSubtitle =>
      'Allow the app to read local project files for AI context.';

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
  String get exportPasswordSubtitle =>
      'Set a password to encrypt the export files.';

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
  String get projectsSearchHint => 'Search projects...';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get filterByPriority => 'Filter by priority';

  @override
  String get filterByDateRange => 'Filter by date range';

  @override
  String pageXOfY(int current, int total) {
    return 'Page $current of $total';
  }

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
  String get projectSortCreatedDate => 'Created date';

  @override
  String get projectSortStatus => 'Status';

  @override
  String get projectSortStartDate => 'Start Date';

  @override
  String get projectSortDueDate => 'Due Date';

  @override
  String get sortDirectionLabel => 'Direction';

  @override
  String get sortAscendingLabel => 'Ascending';

  @override
  String get sortDescendingLabel => 'Descending';

  @override
  String get exportToCsvLabel => 'Export to CSV';

  @override
  String get csvExportSuccessMessage => 'Projects exported successfully';

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
  String get noProjectMapLinked =>
      'No folder linked yet. Link a folder to read files.';

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
  String get projectsOverviewSubtitle =>
      'Here\'s an overview of your active projects';

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
  String projectTaskStatusSemantics(Object projectName, Object taskTitle,
      Object statusLabel, Object timeLabel) {
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
  String projectProgressChartSemantics(
      Object projectName, Object completedPercent, Object pendingPercent) {
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
  String burndownChartSemantics(
      Object projectName, Object actualPoints, Object idealPoints) {
    return 'Burndown chart for $projectName. Actual points: $actualPoints. Ideal points: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'AI chat';

  @override
  String get aiAssistantTitle => 'AI Project Assistant';

  @override
  String get clearChatTooltip => 'Clear chat';

  @override
  String get noMessagesLabel => 'No messages';

  @override
  String get aiEmptyTitle => 'Start a conversation with the AI assistant';

  @override
  String get aiEmptySubtitle =>
      'For example: \"Generate a plan for project: webshop\"';

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
  String rateLimitExceeded(Object seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get captchaTitle => 'Security Verification';

  @override
  String get captchaMessage => 'Please complete the captcha to continue.';

  @override
  String get captchaVerifyButton => 'Verify';

  @override
  String get captchaFailedMessage => 'Captcha verification failed.';

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
  String get settingsRestoreSubtitle =>
      'Replace local data with a backup file.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Backup saved: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Backup restored. Restart the app to reload data.';

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

  @override
  String get filterButtonTooltip => 'Filter projects';

  @override
  String get filterPriorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get filterDateRangeLabel => 'Date Range';

  @override
  String get filterStartDateLabel => 'Start Date';

  @override
  String get filterEndDateLabel => 'End Date';

  @override
  String activeFilterPriority(String priority) {
    return 'Priority: $priority';
  }

  @override
  String activeFilterStartDate(String date) {
    return 'From $date';
  }

  @override
  String activeFilterEndDate(String date) {
    return 'To $date';
  }

  @override
  String showingProjectsCount(int count, int total) {
    return 'Showing $count of $total projects';
  }

  @override
  String get clearAllFiltersButtonLabel => 'Clear All Filters';

  @override
  String get noProjectsMatchFiltersTitle => 'No projects match your filters';

  @override
  String get noProjectsMatchFiltersSubtitle =>
      'Try changing or clearing your filters';

  @override
  String get projectFiltersTitle => 'Project Filters';

  @override
  String get allProjectsPresetLabel => 'All Projects';

  @override
  String get highPriorityPresetLabel => 'High Priority';

  @override
  String get dueThisWeekPresetLabel => 'Due This Week';

  @override
  String get overduePresetLabel => 'Overdue';

  @override
  String get myProjectsPresetLabel => 'My Projects';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get clearAllLabel => 'Clear All';

  @override
  String get saveAsDefaultSuccessMessage => 'Filter saved as default';

  @override
  String get saveAsDefaultViewLabel => 'Save as Default';

  @override
  String get applyFiltersLabel => 'Apply Filters';

  @override
  String get savedViewsTabLabel => 'Saved Views';

  @override
  String get filtersTabLabel => 'Filters';

  @override
  String get viewNameLabel => 'View Name';

  @override
  String get viewNameHint => 'Enter a name for this view';

  @override
  String get saveCurrentAsViewLabel => 'Save Current';

  @override
  String get viewSavedMessage => 'View saved successfully';

  @override
  String get noSavedViewsMessage => 'No saved views yet';

  @override
  String get savedViewsLabel => 'Saved Views';

  @override
  String get allViewsLabel => 'All Views';

  @override
  String get filterProjectsTooltip => 'Filter projects';

  @override
  String selectProjectsTitle(int count) {
    return 'Select Projects ($count)';
  }

  @override
  String get bulkActionsTooltip => 'Bulk actions';

  @override
  String get exitSelectionModeTooltip => 'Exit selection mode';

  @override
  String bulkActionsTitle(int count) {
    return 'Bulk Actions ($count selected)';
  }

  @override
  String get deleteSelectedProjectsLabel => 'Delete Selected Projects';

  @override
  String get changePriorityLabel => 'Change Priority';

  @override
  String get changeStatusLabel => 'Change Status';

  @override
  String get assignToUserLabel => 'Assign to User';

  @override
  String get exportSelectedToCsvLabel => 'Export Selected to CSV';

  @override
  String get applyActionsLabel => 'Apply Actions';

  @override
  String confirmDeleteSelectedProjectsMessage(int count) {
    return 'Are you sure you want to delete $count selected projects? This action cannot be undone.';
  }

  @override
  String bulkDeleteSuccessMessage(int count) {
    return 'Successfully deleted $count projects.';
  }

  @override
  String bulkActionsAppliedMessage(int actions, int count) {
    return 'Applied $actions action(s) to $count projects.';
  }

  @override
  String get searchProjectsLabel => 'Search Projects';

  @override
  String get searchProjectsHint => 'Search by name, description, or tags...';

  @override
  String get filterTagsLabel => 'Tags';

  @override
  String get addTagLabel => 'Add Tag';

  @override
  String get addTagHint => 'Enter tag name';

  @override
  String get availableTagsLabel => 'Available tags:';

  @override
  String get requiredTagsLabel => 'Required Tags (AND)';

  @override
  String get optionalTagsLabel => 'Optional Tags (OR)';

  @override
  String get requiredTagsDescription => 'Projects must have ALL of these tags';

  @override
  String get optionalTagsDescription => 'Projects can have ANY of these tags';

  @override
  String get listViewTooltip => 'List view';

  @override
  String get kanbanViewTooltip => 'Kanban view';

  @override
  String get tableViewTooltip => 'Table view';

  @override
  String get nameLabel => 'Name';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get exportToPdfLabel => 'Export to PDF';

  @override
  String get exportingPdfMessage => 'Generating PDF report...';

  @override
  String get pdfExportedMessage => 'PDF exported successfully';

  @override
  String get pdfExportErrorMessage => 'Failed to export PDF';

  @override
  String get projectsReportTitle => 'Projects Report';

  @override
  String get generatedOnLabel => 'Generated on';

  @override
  String get activeFiltersLabel => 'Active Filters';

  @override
  String get summaryLabel => 'Summary';

  @override
  String get totalProjectsLabel => 'Total Projects';

  @override
  String get priorityDistributionLabel => 'Priority Distribution';

  @override
  String get dueDatesLabel => 'Due Dates';

  @override
  String get projectListLabel => 'Project List';

  @override
  String get recentFiltersTooltip => 'Recent filters';

  @override
  String get unnamedFilterLabel => 'Unnamed Filter';

  @override
  String get ownerLabel => 'Owner';

  @override
  String get ascendingLabel => 'ascending';

  @override
  String get descendingLabel => 'descending';

  @override
  String get allProjectsLabel => 'All Projects';

  @override
  String get ganttViewTitle => 'Gantt Chart';

  @override
  String get zoomInTooltip => 'Zoom in';

  @override
  String get zoomOutTooltip => 'Zoom out';

  @override
  String get selectDateRangeTooltip => 'Select date range';

  @override
  String get noProjectsForGantt => 'No projects to display';

  @override
  String get addProjectsWithDates =>
      'Add projects with start and due dates to see them in the timeline.';

  @override
  String get openProjectTooltip => 'Open project';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get editedLabel => 'edited';

  @override
  String get mentionedLabel => 'Mentioned';

  @override
  String get deleteCommentTooltip => 'Delete comment';

  @override
  String get settingsBiometricLoginTitle => 'Biometric login';

  @override
  String get settingsBiometricLoginSubtitle =>
      'Use fingerprint or face ID to sign in';

  @override
  String get enableBiometricDialogTitle => 'Enable Biometric Login';

  @override
  String get enableBiometricDialogMessage =>
      'Would you like to enable biometric authentication for faster login?';

  @override
  String get enableBiometricDialogYes => 'Enable';

  @override
  String get enableBiometricDialogNo => 'Not Now';

  @override
  String get loginWithBiometric => 'Login with Biometric';

  @override
  String get loginWithPassword => 'Login with Password';

  @override
  String get biometric_login_title => 'Biometric Login';

  @override
  String get enable_biometric_login => 'Enable Biometric Login';

  @override
  String get biometric_not_available =>
      'Biometric authentication not available';

  @override
  String get use_password_instead => 'Use password instead';

  @override
  String get biometric_enroll_success => 'Biometric login enabled';

  @override
  String get biometric_auth_failed => 'Biometric authentication failed';

  @override
  String get smartFilterDialogTitle => 'Smart Filter';

  @override
  String get smartFilterHint => 'Describe what you want to filter...';

  @override
  String get smartFilterButtonLabel => 'Apply Smart Filter';

  @override
  String get smartFilterProcessing => 'Processing your request...';

  @override
  String get smartFilterError =>
      'Failed to apply smart filter. Please try again.';

  @override
  String get aiSuggestedFilterLabel => 'AI Suggested Filter';

  @override
  String get smartFilterButtonTooltip => 'Use AI to help filter projects';

  @override
  String get editFilterButtonLabel => 'Edit Filter';

  @override
  String get acceptFilterButtonLabel => 'Accept Filter';

  @override
  String get ai_per_operation_limits => 'Per-Operation Rate Limits';

  @override
  String get limit_for_chat => 'Limit for chat';

  @override
  String get limit_for_summarize => 'Limit for summarize';

  @override
  String get limit_for_generate_tasks => 'Generate tasks limit';

  @override
  String get limit_for_generate_questions => 'Limit for generate questions';

  @override
  String get limit_for_generate_proposals => 'Limit for generate proposals';

  @override
  String get limit_for_generate_plan => 'Limit for generate plan';

  @override
  String get limit_for_parse_filter => 'Limit for parse filter';

  @override
  String get ai_backoff_settings => 'AI Backoff Settings';

  @override
  String get backoff_base_delay => 'Base Delay';

  @override
  String get backoff_max_delay => 'Max Delay';

  @override
  String get max_retry_attempts => 'Max Retries';

  @override
  String get per_op_limit_saved => 'Per-operation limit saved';

  @override
  String get max_requests_per_operation => 'Max requests per operation';

  @override
  String get backoff_settings => 'Backoff Settings';

  @override
  String get request_queue_enabled => 'Request queuing enabled';

  @override
  String get undoTooltip => 'Undo last dashboard change';

  @override
  String get redoTooltip => 'Redo last undone dashboard change';

  @override
  String get offline_mode => 'Offline Mode';

  @override
  String get changes_queued => 'Changes queued for sync';

  @override
  String get syncing_requirements => 'Syncing requirements...';

  @override
  String get offline_sync_success => 'Offline sync completed successfully';

  @override
  String get captcha_verification_required => 'Security verification required';

  @override
  String get captcha_loading => 'Verifying security check...';

  @override
  String get captcha_error => 'Security verification failed. Please try again.';

  @override
  String get recaptcha_site_key => 'reCAPTCHA v3 Site Key';

  @override
  String get recaptcha_site_key_hint => 'Enter your reCAPTCHA v3 site key';

  @override
  String get ai_usage_charts => 'AI Usage Charts';

  @override
  String get export_csv => 'Export CSV';

  @override
  String get average_cost => 'Average Cost';

  @override
  String get peak_times => 'Peak Times';

  @override
  String get dashboard_theme_custom => 'Custom Theme';

  @override
  String get select_layout_template => 'Select Layout Template';

  @override
  String get resize_widget => 'Resize Widget';

  @override
  String get create_custom_widget => 'Create Custom Widget';

  @override
  String get upgrade_subscription => 'Upgrade to Premium';

  @override
  String get payment_processing => 'Processing payment...';

  @override
  String get payment_success => 'Payment successful!';

  @override
  String get payment_failed => 'Payment failed';

  @override
  String get enable_real_payment_backend =>
      'Enable Real Payment Backend (Production Only)';

  @override
  String get real_backend_warning =>
      '⚠️ WARNING: This enables real Stripe payments. Only enable in production with proper backend configuration.';

  @override
  String get mention_user => 'Mention user';

  @override
  String get no_users_found_for_mention => 'No users found for mention';

  @override
  String get typing_to_mention => 'Type @ to mention a user';

  @override
  String get parsing_format_xml => 'XML';

  @override
  String get parsing_format_yaml => 'YAML';

  @override
  String parsing_error_unsupported_format(String format, String supported) {
    return 'Unsupported format: $format. Supported formats: $supported';
  }

  @override
  String get auth_backend_error => 'Authentication backend error';

  @override
  String get session_refresh_failed => 'Session refresh failed';

  @override
  String get featureFlagGanttDisabledMessage =>
      'Gantt chart is currently disabled by admin';

  @override
  String get featureFlagOnboardingDisabledMessage =>
      'Onboarding is currently disabled by admin';

  @override
  String get featureFlagOpeningDashboardMessage => 'Opening your dashboard...';

  @override
  String get featureFlagAiAssistantDisabledMessage =>
      'AI is currently disabled by admin';

  @override
  String get featureFlagAiAdvancedPlanningDisabledMessage =>
      'Advanced AI planning is currently disabled by admin';

  @override
  String get mirrorTerminalReady => 'Loading recent workflows...';

  @override
  String mirrorProjectTaskLine(String projectId, String taskId) {
    return 'Project $projectId, task $taskId, status Status, In progress';
  }

  @override
  String mirrorProjectTaskHeader(String projectId, String taskId) {
    return 'Project $projectId, task $taskId, status Status, In progress';
  }

  @override
  String mirrorRealtimeOutputReceived(int lineCount) {
    return 'Showing $lineCount of $lineCount projects';
  }

  @override
  String mirrorStatusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get mirrorVoiceStopped => 'Continue';

  @override
  String get mirrorVoiceUnavailableTerminal => 'Could not load project data.';

  @override
  String get mirrorVoiceStarted => 'Loading tasks...';

  @override
  String mirrorVoiceAppended(String filePath) {
    return 'Save: $filePath';
  }

  @override
  String mirrorRunAbortedFileEmpty(String filePath) {
    return 'No projects found: $filePath';
  }

  @override
  String mirrorRunStarting(String filePath) {
    return 'Loading more projects... $filePath';
  }

  @override
  String get mirrorRunFlowLine => 'Apply Actions';

  @override
  String get mirrorStepGenerateSent => 'Loading more projects...';

  @override
  String get mirrorUnknownGenerateError => 'Unknown project';

  @override
  String mirrorGenerateFailedTerminal(String errorText) {
    return 'Import failed: $errorText';
  }

  @override
  String get mirrorStepGenerateCompleted => 'Completed';

  @override
  String mirrorGenerateDiagnostics(String text) {
    return 'Status: $text';
  }

  @override
  String get mirrorStepCompileSent => 'Loading more projects...';

  @override
  String get mirrorUnknownCompileError => 'Unknown project';

  @override
  String mirrorCompileFailedTerminal(String errorText) {
    return 'Export failed: $errorText';
  }

  @override
  String get mirrorStepCompileCompleted => 'Completed';

  @override
  String mirrorCompileWarnings(String text) {
    return 'Status: $text';
  }

  @override
  String get mirrorStepPreviewBuilding => 'Loading project data...';

  @override
  String get mirrorNoPatchPreviewTerminal => 'No projects found';

  @override
  String mirrorStepPreviewReady(int fileCount) {
    return 'Showing $fileCount of $fileCount projects';
  }

  @override
  String mirrorStepApplyWaiting(String path) {
    return 'Apply Actions: $path';
  }

  @override
  String get mirrorStepApplyCanceled => 'Cancel';

  @override
  String get mirrorStepApplySent => 'Apply Actions';

  @override
  String mirrorAppliedFiles(String filesText) {
    return 'Save: $filesText';
  }

  @override
  String get mirrorRunCompletedTerminal => 'Filter saved as default';

  @override
  String get mirrorUnknownApplyError => 'Unknown project';

  @override
  String mirrorApplyFailedTerminal(String errorText) {
    return 'Import failed: $errorText';
  }

  @override
  String mirrorRunCrashedTerminal(String errorText) {
    return 'Export failed: $errorText';
  }

  @override
  String get mirrorTemplatesLoadFailed => 'Could not load recent workflows.';

  @override
  String mirrorTemplateAppliedTerminal(String selectedFile, String title) {
    return 'Save: $selectedFile - $title';
  }

  @override
  String get mirrorEditorTitle => 'AI Assistant';

  @override
  String get mirrorTemplatesLabel => 'Saved Views';

  @override
  String get mirrorCloudPremiumOnly => 'Warning: Sensitive data can be read.';

  @override
  String get mirrorListeningLabel => 'Loading tasks...';

  @override
  String get mirrorVoiceInputLabel => 'Attach files';

  @override
  String get mirrorRunningLabel => 'Loading tasks...';

  @override
  String get mirrorRunLabel => 'Continue';

  @override
  String get mirrorFilesLabel => 'Use project files';

  @override
  String get mirrorTerminalLabel => 'Details';

  @override
  String get mirrorLiveOutputLabel => 'Status';

  @override
  String get mirrorWaitingRealtime => 'Loading recent workflows...';

  @override
  String get mirrorVoiceUnavailable => 'Could not load project data.';

  @override
  String get mirrorSelectedFileEmpty => 'No projects found';

  @override
  String mirrorGenerateFailed(String errorText) {
    return 'Import failed: $errorText';
  }

  @override
  String mirrorCompileFailed(String errorText) {
    return 'Export failed: $errorText';
  }

  @override
  String get mirrorNoChangesAfterCompile =>
      'Try changing or clearing your filters';

  @override
  String mirrorApplyChangesTitle(String path) {
    return 'Apply Actions: $path';
  }

  @override
  String get mirrorApplyCanceled => 'Cancel';

  @override
  String get mirrorRunSuccess => 'Filter saved as default';

  @override
  String mirrorApplyFailed(String errorText) {
    return 'Import failed: $errorText';
  }

  @override
  String mirrorRunCrashed(String errorText) {
    return 'Export failed: $errorText';
  }

  @override
  String get mirrorNoActiveTemplates => 'No saved views yet';

  @override
  String mirrorTemplateLoaded(String title) {
    return 'Save: $title';
  }

  @override
  String get mirrorModeLabel => 'Language';

  @override
  String get mirrorPrivateMode => 'Use project files';

  @override
  String get mirrorCloudMode => 'Projects';

  @override
  String get mirrorPremiumLabel => 'Save as Default';

  @override
  String get mirrorRetryButton => 'Try again';

  @override
  String get mirrorOpenEditorTooltip => 'Open Mirror Editor';

  @override
  String get mirrorUnavailableForAccount =>
      'Mirror is not available for your account.';

  @override
  String get mirrorApplyRiskAcknowledgeTitle =>
      'I understand the risk of applying directly';

  @override
  String get mirrorApplyRiskAcknowledgeSubtitle =>
      'Changes will be applied to your working directory. Prefer using a separate branch.';

  @override
  String get mirrorPermissionDenied =>
      'Mirror is not available for your account.';

  @override
  String get mirrorPermissionRevokedSessionDisabled =>
      'Your Mirror editor session was disabled because your permission changed. Close this screen to continue safely.';

  @override
  String get mirrorPermissionRevokedTerminal =>
      'Mirror access revoked: session ejected.';

  @override
  String get mirrorApplyDiffPreview => 'Diff preview';

  @override
  String get mirrorApplyNo => 'No';

  @override
  String get mirrorApplyConfirm => 'Apply';

  @override
  String get mirrorApplyNoDiff => '(No differences detected)';

  @override
  String get mirrorApplyBranchAdviceTitle =>
      'Suggested branch name – advice only';

  @override
  String mirrorApplyCurrentBranch(String branch) {
    return 'Current branch: $branch';
  }

  @override
  String mirrorApplySuggestedBranch(String branch) {
    return 'Suggested branch name (advice only): $branch';
  }

  @override
  String get mirrorApplyBranchTip =>
      'Tip: create and switch to a dedicated review branch before applying, so rollback stays simple.';

  @override
  String mirrorApplyBranchTipWithBranch(String branch) {
    return 'Advice only: consider using the suggested branch \"$branch\" for safer review and simpler rollback. Mirror will not create or switch branches for you.';
  }

  @override
  String get mirrorApplyBranchWorkingTreeNotice =>
      'Mirror applies changes in your current working tree and does not create or switch branches automatically.';

  @override
  String get mirrorOfflineTeamVariantLoadedFromCacheWarning =>
      'Offline mode: Team Mode variant loaded from local cache.';

  @override
  String get mirrorOfflineTeamVariantFallbackSoloWarning =>
      'Offline mode: Team Mode unavailable, switched to solo fallback.';

  @override
  String get mirrorOfflineRunnerVariantLoadedFromCacheWarning =>
      'Offline mode: Runner variant loaded from local cache.';

  @override
  String get mirrorOfflineRunnerVariantFallbackCloudWarning =>
      'Offline mode: Runner variant unavailable, switched to cloud fallback.';

  @override
  String get mirrorCloudModeRequiresPremiumWarning =>
      'Cloud mode requires an active Stripe premium subscription.';
}
