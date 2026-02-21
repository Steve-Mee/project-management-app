import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// Auto-generated description for appTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Management App'**
  String get appTitle;

  /// Auto-generated description for menuLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuLabel;

  /// Auto-generated description for loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Auto-generated description for usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Auto-generated description for passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Auto-generated description for loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// Auto-generated description for createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Auto-generated description for logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutTooltip;

  /// Auto-generated description for closeAppTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get closeAppTooltip;

  /// Auto-generated description for settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Auto-generated description for settingsDisplaySection.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsDisplaySection;

  /// Auto-generated description for settingsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkModeTitle;

  /// Auto-generated description for settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark'**
  String get settingsDarkModeSubtitle;

  /// Auto-generated description for settingsFollowSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get settingsFollowSystemTitle;

  /// Auto-generated description for settingsFollowSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your device theme'**
  String get settingsFollowSystemSubtitle;

  /// Auto-generated description for settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Auto-generated description for settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageSubtitle;

  /// Auto-generated description for settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// Auto-generated description for settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// Auto-generated description for settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates and reminders'**
  String get settingsNotificationsSubtitle;

  /// Auto-generated description for settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// Auto-generated description for settingsLocalFilesConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Local file permission'**
  String get settingsLocalFilesConsentTitle;

  /// Auto-generated description for settingsLocalFilesConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow the app to read local project files for AI context.'**
  String get settingsLocalFilesConsentSubtitle;

  /// Auto-generated description for settingsUseProjectFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Use project files'**
  String get settingsUseProjectFilesTitle;

  /// Auto-generated description for settingsUseProjectFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add local files to AI prompts'**
  String get settingsUseProjectFilesSubtitle;

  /// Auto-generated description for settingsProjectsSection.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get settingsProjectsSection;

  /// Auto-generated description for settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutTitle;

  /// Auto-generated description for settingsLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End your current session'**
  String get settingsLogoutSubtitle;

  /// Auto-generated description for settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export projects'**
  String get settingsExportTitle;

  /// Auto-generated description for settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export projects to a file'**
  String get settingsExportSubtitle;

  /// Auto-generated description for settingsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import projects'**
  String get settingsImportTitle;

  /// Auto-generated description for settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import projects from a file'**
  String get settingsImportSubtitle;

  /// Auto-generated description for settingsUsersSection.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get settingsUsersSection;

  /// Auto-generated description for settingsCurrentUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Current user'**
  String get settingsCurrentUserTitle;

  /// Auto-generated description for settingsNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsNotLoggedIn;

  /// Auto-generated description for settingsNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get settingsNoUsersFound;

  /// Auto-generated description for settingsLocalUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Local user'**
  String get settingsLocalUserLabel;

  /// Auto-generated description for settingsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteTooltip;

  /// Auto-generated description for settingsLoadUsersFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load users'**
  String get settingsLoadUsersFailed;

  /// Auto-generated description for settingsAddUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get settingsAddUserTitle;

  /// Auto-generated description for settingsAddUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an extra account'**
  String get settingsAddUserSubtitle;

  /// Auto-generated description for logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutDialogTitle;

  /// Auto-generated description for logoutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutDialogContent;

  /// Auto-generated description for cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Auto-generated description for logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutButton;

  /// Auto-generated description for loggedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You have signed out.'**
  String get loggedOutMessage;

  /// Auto-generated description for exportCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Export complete: {projectsPath}, {tasksPath}'**
  String exportCompleteMessage(Object projectsPath, Object tasksPath);

  /// Auto-generated description for exportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedMessage(Object error);

  /// Auto-generated description for exportPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypt export'**
  String get exportPasswordTitle;

  /// Auto-generated description for exportPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a password to encrypt the export files.'**
  String get exportPasswordSubtitle;

  /// Auto-generated description for exportPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get exportPasswordMismatch;

  /// Auto-generated description for importSelectFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV and JSON file.'**
  String get importSelectFilesMessage;

  /// Auto-generated description for importCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Import complete: {projectsPath}, {tasksPath}'**
  String importCompleteMessage(Object projectsPath, Object tasksPath);

  /// Auto-generated description for importFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedMessage(Object error);

  /// Auto-generated description for importFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailedTitle;

  /// Auto-generated description for addUserDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUserDialogTitle;

  /// Auto-generated description for saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Auto-generated description for userAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'User added.'**
  String get userAddedMessage;

  /// Auto-generated description for invalidUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid user.'**
  String get invalidUserMessage;

  /// Auto-generated description for deleteUserDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUserDialogTitle;

  /// Auto-generated description for deleteUserDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {username}?'**
  String deleteUserDialogContent(Object username);

  /// Auto-generated description for deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Auto-generated description for userDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'User deleted: {username}'**
  String userDeletedMessage(Object username);

  /// Auto-generated description for projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// Auto-generated description for newProjectButton.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProjectButton;

  /// Auto-generated description for noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// Auto-generated description for noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// Auto-generated description for loadingMoreProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading more projects...'**
  String get loadingMoreProjects;

  /// Auto-generated description for sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByLabel;

  /// Auto-generated description for projectSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectSortName;

  /// Auto-generated description for projectSortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get projectSortProgress;

  /// Auto-generated description for projectSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get projectSortPriority;

  /// Label for sorting projects by creation date.
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get projectSortCreatedDate;

  /// Label for sorting projects by status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectSortStatus;

  /// Auto-generated description for allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// Auto-generated description for loadProjectsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load projects.'**
  String get loadProjectsFailed;

  /// Auto-generated description for projectSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Project {title}'**
  String projectSemanticsLabel(Object title);

  /// Auto-generated description for statusSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Status {status}'**
  String statusSemanticsLabel(Object status);

  /// Auto-generated description for newProjectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProjectDialogTitle;

  /// Auto-generated description for projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameLabel;

  /// Auto-generated description for descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Auto-generated description for urgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgencyLabel;

  /// Auto-generated description for urgencyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get urgencyLow;

  /// Auto-generated description for urgencyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get urgencyMedium;

  /// Auto-generated description for urgencyHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get urgencyHigh;

  /// Auto-generated description for projectCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Project created: {name}'**
  String projectCreatedMessage(Object name);

  /// Auto-generated description for projectDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetailsTitle;

  /// Auto-generated description for aiChatWithProjectFilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI chat with project files'**
  String get aiChatWithProjectFilesTooltip;

  /// Auto-generated description for moreOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptionsLabel;

  /// Auto-generated description for tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Auto-generated description for tasksTab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTab;

  /// Auto-generated description for detailsTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTab;

  /// Auto-generated description for tasksLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks.'**
  String get tasksLoadFailed;

  /// Auto-generated description for projectOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Project overview'**
  String get projectOverviewTitle;

  /// Auto-generated description for tasksLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks...'**
  String get tasksLoading;

  /// Auto-generated description for taskStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Task statistics'**
  String get taskStatisticsTitle;

  /// Auto-generated description for totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// Auto-generated description for completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// Auto-generated description for inProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgressLabel;

  /// Auto-generated description for remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// Auto-generated description for completionPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String completionPercentLabel(Object percent);

  /// Auto-generated description for burndownChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Burndown chart'**
  String get burndownChartTitle;

  /// Auto-generated description for chartPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart placeholder'**
  String get chartPlaceholderTitle;

  /// Auto-generated description for chartPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'fl_chart integration coming soon'**
  String get chartPlaceholderSubtitle;

  /// Auto-generated description for workflowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflowsTitle;

  /// Auto-generated description for noWorkflowsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No workflow items available.'**
  String get noWorkflowsAvailable;

  /// Auto-generated description for taskStatusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskStatusTodo;

  /// Auto-generated description for taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// Auto-generated description for taskStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get taskStatusReview;

  /// Auto-generated description for taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// Auto-generated description for workflowStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get workflowStatusActive;

  /// Auto-generated description for workflowStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get workflowStatusPending;

  /// Auto-generated description for noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// Auto-generated description for projectTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Project time'**
  String get projectTimeTitle;

  /// Auto-generated description for urgencyValue.
  ///
  /// In en, this message translates to:
  /// **'Urgency: {value}'**
  String urgencyValue(Object value);

  /// Auto-generated description for trackedTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Tracked time: {value}'**
  String trackedTimeValue(Object value);

  /// Auto-generated description for hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// Auto-generated description for minuteShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteShort;

  /// Auto-generated description for secondShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondShort;

  /// Auto-generated description for searchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasksHint;

  /// Auto-generated description for searchAttachmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search attachments...'**
  String get searchAttachmentsHint;

  /// Auto-generated description for clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// Auto-generated description for projectMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Project folder'**
  String get projectMapTitle;

  /// Auto-generated description for linkProjectMapButton.
  ///
  /// In en, this message translates to:
  /// **'Link project folder'**
  String get linkProjectMapButton;

  /// Auto-generated description for projectDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading project data...'**
  String get projectDataLoading;

  /// Auto-generated description for projectDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load project data.'**
  String get projectDataLoadFailed;

  /// Auto-generated description for currentMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Current folder: {path}'**
  String currentMapLabel(Object path);

  /// Auto-generated description for noProjectMapLinked.
  ///
  /// In en, this message translates to:
  /// **'No folder linked yet. Link a folder to read files.'**
  String get noProjectMapLinked;

  /// Auto-generated description for projectNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Project not available.'**
  String get projectNotAvailable;

  /// Auto-generated description for enableConsentInSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable permission in Settings.'**
  String get enableConsentInSettings;

  /// Auto-generated description for projectMapLinked.
  ///
  /// In en, this message translates to:
  /// **'Project folder linked.'**
  String get projectMapLinked;

  /// Auto-generated description for privacyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy warning'**
  String get privacyWarningTitle;

  /// Auto-generated description for privacyWarningContent.
  ///
  /// In en, this message translates to:
  /// **'Warning: Sensitive data can be read.'**
  String get privacyWarningContent;

  /// Auto-generated description for continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Auto-generated description for attachFilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get attachFilesTooltip;

  /// Auto-generated description for moreAttachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreAttachmentsLabel(Object count);

  /// Auto-generated description for aiAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantLabel;

  /// Auto-generated description for welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! 👋'**
  String get welcomeBack;

  /// Auto-generated description for projectsOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s an overview of your active projects'**
  String get projectsOverviewSubtitle;

  /// Auto-generated description for recentWorkflowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent workflows'**
  String get recentWorkflowsTitle;

  /// Auto-generated description for recentWorkflowsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recent workflows...'**
  String get recentWorkflowsLoading;

  /// Auto-generated description for recentWorkflowsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent workflows.'**
  String get recentWorkflowsLoadFailed;

  /// Auto-generated description for retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// Auto-generated description for noRecentTasks.
  ///
  /// In en, this message translates to:
  /// **'No recent tasks available.'**
  String get noRecentTasks;

  /// Auto-generated description for unknownProject.
  ///
  /// In en, this message translates to:
  /// **'Unknown project'**
  String get unknownProject;

  /// Auto-generated description for projectTaskStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'Project {projectName}, task {taskTitle}, status {statusLabel}, {timeLabel}'**
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  );

  /// Auto-generated description for taskStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'Task {taskTitle} {statusLabel}'**
  String taskStatusSemantics(Object taskTitle, Object statusLabel);

  /// Auto-generated description for timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// Auto-generated description for timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(Object minutes);

  /// Auto-generated description for timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeHoursAgo(Object hours);

  /// Auto-generated description for timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(Object days);

  /// Auto-generated description for timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String timeWeeksAgo(Object weeks);

  /// Auto-generated description for timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String timeMonthsAgo(Object months);

  /// Auto-generated description for projectProgressChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Project progress chart for {projectName}. Completed {completedPercent} percent, pending {pendingPercent} percent.'**
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  );

  /// Label for progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// Auto-generated description for completedPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: {percent}%'**
  String completedPercentLabel(Object percent);

  /// Auto-generated description for pendingPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending: {percent}%'**
  String pendingPercentLabel(Object percent);

  /// Auto-generated description for noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// Auto-generated description for closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Auto-generated description for burndownProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Burndown progress'**
  String get burndownProgressTitle;

  /// Auto-generated description for actualProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual progress'**
  String get actualProgressLabel;

  /// Auto-generated description for idealTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Ideal trend'**
  String get idealTrendLabel;

  /// Auto-generated description for statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Auto-generated description for burndownChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Burndown chart for {projectName}. Actual points: {actualPoints}. Ideal points: {idealPoints}.'**
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  );

  /// Auto-generated description for aiChatSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get aiChatSemanticsLabel;

  /// Title for the AI usage overview screen.
  ///
  /// In en, this message translates to:
  /// **'AI Usage'**
  String get aiUsageTitle;

  /// Auto-generated description for aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Project Assistant'**
  String get aiAssistantTitle;

  /// Auto-generated description for clearChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChatTooltip;

  /// Auto-generated description for noMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessagesLabel;

  /// Auto-generated description for aiEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with the AI assistant'**
  String get aiEmptyTitle;

  /// Auto-generated description for aiEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'For example: \"Generate a plan for project: webshop\"'**
  String get aiEmptySubtitle;

  /// Auto-generated description for useProjectFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Use project files'**
  String get useProjectFilesLabel;

  /// Auto-generated description for typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// Auto-generated description for projectFilesReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read project files.'**
  String get projectFilesReadFailed;

  /// Auto-generated description for aiResponseFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'AI response failed'**
  String get aiResponseFailedTitle;

  /// Auto-generated description for sendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessageTooltip;

  /// Auto-generated description for loginMissingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter username and password.'**
  String get loginMissingCredentials;

  /// Auto-generated description for loginFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Check your credentials.'**
  String get loginFailedMessage;

  /// Auto-generated description for registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Auto-generated description for languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Auto-generated description for languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Auto-generated description for languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Auto-generated description for languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageDutch;

  /// Auto-generated description for languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Auto-generated description for languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// Auto-generated description for languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// Auto-generated description for languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// Auto-generated description for languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// Auto-generated description for languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// Auto-generated description for languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// Auto-generated description for languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// Auto-generated description for languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// Auto-generated description for languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// Auto-generated description for languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// Auto-generated description for repeatPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPasswordLabel;

  /// Auto-generated description for passwordRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Password rules'**
  String get passwordRulesTitle;

  /// Auto-generated description for passwordRuleMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleMinLength;

  /// Auto-generated description for passwordRuleHasLetter.
  ///
  /// In en, this message translates to:
  /// **'Contains a letter'**
  String get passwordRuleHasLetter;

  /// Auto-generated description for passwordRuleHasDigit.
  ///
  /// In en, this message translates to:
  /// **'Contains a number'**
  String get passwordRuleHasDigit;

  /// Auto-generated description for passwordRuleMatches.
  ///
  /// In en, this message translates to:
  /// **'Passwords match'**
  String get passwordRuleMatches;

  /// Auto-generated description for registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Auto-generated description for registrationIssueUsernameMissing.
  ///
  /// In en, this message translates to:
  /// **'username missing'**
  String get registrationIssueUsernameMissing;

  /// Auto-generated description for registrationIssueMinLength.
  ///
  /// In en, this message translates to:
  /// **'minimum 8 characters'**
  String get registrationIssueMinLength;

  /// Auto-generated description for registrationIssueLetter.
  ///
  /// In en, this message translates to:
  /// **'at least 1 letter'**
  String get registrationIssueLetter;

  /// Auto-generated description for registrationIssueDigit.
  ///
  /// In en, this message translates to:
  /// **'at least 1 number'**
  String get registrationIssueDigit;

  /// Auto-generated description for registrationIssueNoMatch.
  ///
  /// In en, this message translates to:
  /// **'passwords do not match'**
  String get registrationIssueNoMatch;

  /// Auto-generated description for registrationFailedWithIssues.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {issues}.'**
  String registrationFailedWithIssues(Object issues);

  /// Auto-generated description for accountCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created. Sign in now.'**
  String get accountCreatedMessage;

  /// Auto-generated description for registerFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get registerFailedMessage;

  /// Message shown when a user lacks permission.
  ///
  /// In en, this message translates to:
  /// **'Access denied.'**
  String get accessDeniedMessage;

  /// Title for the admin panel screen.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanelTitle;

  /// Subtitle for the admin panel entry.
  ///
  /// In en, this message translates to:
  /// **'Manage roles, groups, and permissions.'**
  String get adminPanelSubtitle;

  /// Header for roles section.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesTitle;

  /// Shown when no roles exist.
  ///
  /// In en, this message translates to:
  /// **'No roles found.'**
  String get noRolesFound;

  /// Displays the number of permissions on a role.
  ///
  /// In en, this message translates to:
  /// **'Permissions: {count}'**
  String permissionsCount(Object count);

  /// Tooltip for editing permissions.
  ///
  /// In en, this message translates to:
  /// **'Edit permissions'**
  String get editPermissionsTooltip;

  /// Header for groups section.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// Shown when no groups exist.
  ///
  /// In en, this message translates to:
  /// **'No groups found.'**
  String get noGroupsFound;

  /// Label for a role selection.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Title for adding a group.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get groupAddTitle;

  /// Label for the group name input.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// Label for a group chip or field.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// Title for adding a member to a specific group.
  ///
  /// In en, this message translates to:
  /// **'Add member to {groupName}'**
  String addGroupMemberTitle(Object groupName);

  /// Tooltip for adding a group member.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addGroupMemberTooltip;

  /// Title for the group members dialog.
  ///
  /// In en, this message translates to:
  /// **'Group members: {groupName}'**
  String groupMembersTitle(Object groupName);

  /// Shown when a group has no members.
  ///
  /// In en, this message translates to:
  /// **'No group members.'**
  String get noGroupMembers;

  /// Tooltip for removing a group member.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeGroupMemberTooltip;

  /// Title for creating a role.
  ///
  /// In en, this message translates to:
  /// **'Create role'**
  String get roleCreateTitle;

  /// Label for the role name input.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleNameLabel;

  /// Title for permissions selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// Title for manual Hive backup action.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get settingsBackupTitle;

  /// Subtitle for manual Hive backup action.
  ///
  /// In en, this message translates to:
  /// **'Save a local backup of Hive data.'**
  String get settingsBackupSubtitle;

  /// Title for restoring Hive backup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get settingsRestoreTitle;

  /// Subtitle for restoring Hive backup.
  ///
  /// In en, this message translates to:
  /// **'Replace local data with a backup file.'**
  String get settingsRestoreSubtitle;

  /// Shown after a backup file is created.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {path}'**
  String backupSuccessMessage(Object path);

  /// Shown when backup fails.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailedMessage(Object error);

  /// Shown after a successful restore.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Restart the app to reload data.'**
  String get restoreSuccessMessage;

  /// Shown when restore fails.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailedMessage(Object error);

  /// Title for restore confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreConfirmTitle;

  /// Content for restore confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite your local data.'**
  String get restoreConfirmContent;

  /// Button label for confirming restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreConfirmButton;

  /// Label for last backup timestamp.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get settingsBackupLastRunLabel;

  /// Shown when no backup has been created yet.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backupNeverMessage;

  /// Button label to trigger a backup immediately.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backupNowButton;

  /// Label for last backup file path.
  ///
  /// In en, this message translates to:
  /// **'Backup file'**
  String get settingsBackupPathLabel;

  /// Shown when no backup file path is available.
  ///
  /// In en, this message translates to:
  /// **'No backup file yet'**
  String get backupNoFileMessage;

  /// Label for priority filter
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get filterPriorityLabel;

  /// Label for start date filter
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get filterStartDateLabel;

  /// Label for end date filter
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get filterEndDateLabel;

  /// Low priority option
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Medium priority option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// High priority option
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Label for date range filter section
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get filterDateRangeLabel;

  /// Label for apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFiltersLabel;

  /// Label for reset all filters button
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAllLabel;

  /// Label for cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Title for project filters dialog
  ///
  /// In en, this message translates to:
  /// **'Project Filters'**
  String get projectFiltersTitle;

  /// Tooltip for filter button
  ///
  /// In en, this message translates to:
  /// **'Filter projects'**
  String get filterButtonTooltip;

  /// Active filter chip for priority
  ///
  /// In en, this message translates to:
  /// **'Priority: {value}'**
  String activeFilterPriority(String value);

  /// Active filter chip for start date
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String activeFilterStartDate(String date);

  /// Active filter chip for end date
  ///
  /// In en, this message translates to:
  /// **'End: {date}'**
  String activeFilterEndDate(String date);

  /// Hint shown when no filters are active
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get allProjectsHint;

  /// Label for clearing all filters
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllLabel;

  /// Label for saving current filter as default view
  ///
  /// In en, this message translates to:
  /// **'Save as Default View'**
  String get saveAsDefaultViewLabel;

  /// Success message when default view is saved
  ///
  /// In en, this message translates to:
  /// **'Default view saved successfully'**
  String get saveAsDefaultSuccessMessage;

  /// Label for all projects preset filter
  ///
  /// In en, this message translates to:
  /// **'All Projects'**
  String get allProjectsPresetLabel;

  /// Label for high priority preset filter
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriorityPresetLabel;

  /// Label for due this week preset filter
  ///
  /// In en, this message translates to:
  /// **'Due This Week'**
  String get dueThisWeekPresetLabel;

  /// Label for overdue preset filter
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overduePresetLabel;

  /// Label for my projects preset filter
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjectsPresetLabel;

  /// Summary showing filtered project count
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} projects'**
  String showingProjectsCount(int count, int total);

  /// Title for empty state when filters have no results
  ///
  /// In en, this message translates to:
  /// **'No projects match your filters'**
  String get noProjectsMatchFiltersTitle;

  /// Subtitle for empty state when filters have no results
  ///
  /// In en, this message translates to:
  /// **'Try changing or clearing your filters'**
  String get noProjectsMatchFiltersSubtitle;

  /// Button label to clear all active filters
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFiltersButtonLabel;

  /// Button label for AI-powered smart filtering
  ///
  /// In en, this message translates to:
  /// **'Smart Filter'**
  String get smartFilterButtonLabel;

  /// Tooltip for the smart filter button
  ///
  /// In en, this message translates to:
  /// **'Use AI to create filters from natural language'**
  String get smartFilterButtonTooltip;

  /// Title for the smart filter input dialog
  ///
  /// In en, this message translates to:
  /// **'Describe Your Filter'**
  String get smartFilterDialogTitle;

  /// Hint text for the smart filter input field
  ///
  /// In en, this message translates to:
  /// **'Show high priority tasks due this week for team X'**
  String get smartFilterHint;

  /// Message shown while AI is processing the filter request
  ///
  /// In en, this message translates to:
  /// **'Analyzing your request...'**
  String get smartFilterProcessing;

  /// Error message when AI cannot parse the filter request
  ///
  /// In en, this message translates to:
  /// **'Could not understand your request. Please try rephrasing.'**
  String get smartFilterError;

  /// Label for the AI suggested filter chip
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Filter'**
  String get aiSuggestedFilterLabel;

  /// Button to accept the AI suggested filter
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptFilterButtonLabel;

  /// Button to edit the AI suggested filter
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editFilterButtonLabel;

  /// Label for sorting projects by start date
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get projectSortStartDate;

  /// Label for sorting projects by due date
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get projectSortDueDate;

  /// Success message when exporting projects to CSV
  ///
  /// In en, this message translates to:
  /// **'Projects exported to CSV successfully'**
  String get csvExportSuccessMessage;

  /// Label for the saved view name input field
  ///
  /// In en, this message translates to:
  /// **'View Name'**
  String get viewNameLabel;

  /// Hint text for the view name input field
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this view'**
  String get viewNameHint;

  /// Message shown when a view is saved
  ///
  /// In en, this message translates to:
  /// **'View saved successfully'**
  String get viewSavedMessage;

  /// Button label to save current filter settings as a named view
  ///
  /// In en, this message translates to:
  /// **'Save Current as View'**
  String get saveCurrentAsViewLabel;

  /// Message shown when there are no saved views
  ///
  /// In en, this message translates to:
  /// **'No saved views yet. Save your current filters to create a view.'**
  String get noSavedViewsMessage;

  /// Label for sort direction selection
  ///
  /// In en, this message translates to:
  /// **'Sort Direction'**
  String get sortDirectionLabel;

  /// Label for ascending sort direction
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscendingLabel;

  /// Label for descending sort direction
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescendingLabel;

  /// Label for project search field
  ///
  /// In en, this message translates to:
  /// **'Search Projects'**
  String get searchProjectsLabel;

  /// Hint text for project search field
  ///
  /// In en, this message translates to:
  /// **'Search by name, description, or tags'**
  String get searchProjectsHint;

  /// Tab label for saved views
  ///
  /// In en, this message translates to:
  /// **'Saved Views'**
  String get savedViewsTabLabel;

  /// Tab label for filters
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTabLabel;

  /// Button label for CSV export
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCsvLabel;

  /// Button label for PDF export
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPdfLabel;

  /// Label for required tags section
  ///
  /// In en, this message translates to:
  /// **'Required Tags'**
  String get requiredTagsLabel;

  /// Description for required tags
  ///
  /// In en, this message translates to:
  /// **'Projects must have all of these tags'**
  String get requiredTagsDescription;

  /// Label for optional tags section
  ///
  /// In en, this message translates to:
  /// **'Optional Tags'**
  String get optionalTagsLabel;

  /// Description for optional tags
  ///
  /// In en, this message translates to:
  /// **'Projects can have any of these tags'**
  String get optionalTagsDescription;

  /// Button label to add a tag
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTagLabel;

  /// Hint text for adding tags
  ///
  /// In en, this message translates to:
  /// **'Type to add a tag'**
  String get addTagHint;

  /// Label for available tags list
  ///
  /// In en, this message translates to:
  /// **'Available Tags'**
  String get availableTagsLabel;

  /// Title for project selection mode with count
  ///
  /// In en, this message translates to:
  /// **'Select Projects ({count})'**
  String selectProjectsTitle(int count);

  /// Tooltip for bulk actions button
  ///
  /// In en, this message translates to:
  /// **'Bulk actions'**
  String get bulkActionsTooltip;

  /// Tooltip for exiting selection mode
  ///
  /// In en, this message translates to:
  /// **'Exit selection mode'**
  String get exitSelectionModeTooltip;

  /// Label for saved views section
  ///
  /// In en, this message translates to:
  /// **'Saved Views'**
  String get savedViewsLabel;

  /// Label for all views option
  ///
  /// In en, this message translates to:
  /// **'All Views'**
  String get allViewsLabel;

  /// Tooltip for filter projects button
  ///
  /// In en, this message translates to:
  /// **'Filter projects'**
  String get filterProjectsTooltip;

  /// Tooltip for list view button
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listViewTooltip;

  /// Tooltip for kanban view button
  ///
  /// In en, this message translates to:
  /// **'Kanban view'**
  String get kanbanViewTooltip;

  /// Tooltip for table view button
  ///
  /// In en, this message translates to:
  /// **'Table view'**
  String get tableViewTooltip;

  /// Title for bulk actions dialog with count
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions ({count})'**
  String bulkActionsTitle(int count);

  /// Label for delete selected projects action
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Projects'**
  String get deleteSelectedProjectsLabel;

  /// Label for change priority action
  ///
  /// In en, this message translates to:
  /// **'Change Priority'**
  String get changePriorityLabel;

  /// Label for change status action
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatusLabel;

  /// Label for assign to user action
  ///
  /// In en, this message translates to:
  /// **'Assign to User'**
  String get assignToUserLabel;

  /// Label for export selected to CSV action
  ///
  /// In en, this message translates to:
  /// **'Export Selected to CSV'**
  String get exportSelectedToCsvLabel;

  /// Label for apply actions button
  ///
  /// In en, this message translates to:
  /// **'Apply Actions'**
  String get applyActionsLabel;

  /// Confirmation message for deleting selected projects with count
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected projects? This action cannot be undone.'**
  String confirmDeleteSelectedProjectsMessage(int count);

  /// Success message for bulk delete operation with count
  ///
  /// In en, this message translates to:
  /// **'{count} projects deleted successfully'**
  String bulkDeleteSuccessMessage(int count);

  /// Label for priority field
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// Label for tags field
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Label for start date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// Label for due date field
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateLabel;

  /// Message shown while exporting PDF
  ///
  /// In en, this message translates to:
  /// **'Exporting PDF...'**
  String get exportingPdfMessage;

  /// Error message for PDF export failure
  ///
  /// In en, this message translates to:
  /// **'Failed to export PDF'**
  String get pdfExportErrorMessage;

  /// Title for projects PDF report
  ///
  /// In en, this message translates to:
  /// **'Projects Report'**
  String get projectsReportTitle;

  /// Label for report generation date
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get generatedOnLabel;

  /// Label for active filters section in report
  ///
  /// In en, this message translates to:
  /// **'Active Filters'**
  String get activeFiltersLabel;

  /// Label for summary section
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryLabel;

  /// Label for total projects count
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get totalProjectsLabel;

  /// Label for priority distribution chart
  ///
  /// In en, this message translates to:
  /// **'Priority Distribution'**
  String get priorityDistributionLabel;

  /// Success message for PDF export
  ///
  /// In en, this message translates to:
  /// **'PDF exported successfully'**
  String get pdfExportedMessage;

  /// Label for project list section
  ///
  /// In en, this message translates to:
  /// **'Project List'**
  String get projectListLabel;

  /// Tooltip for recent filters button
  ///
  /// In en, this message translates to:
  /// **'Recent filters'**
  String get recentFiltersTooltip;

  /// Label for owner field
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// Label for ascending sort order
  ///
  /// In en, this message translates to:
  /// **'ascending'**
  String get ascendingLabel;

  /// Label for descending sort order
  ///
  /// In en, this message translates to:
  /// **'descending'**
  String get descendingLabel;

  /// Label for all projects option
  ///
  /// In en, this message translates to:
  /// **'All Projects'**
  String get allProjectsLabel;

  /// Label for unnamed filter
  ///
  /// In en, this message translates to:
  /// **'Unnamed Filter'**
  String get unnamedFilterLabel;

  /// Title for comments section.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// Hint text for comment input field.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// Message when there are no comments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// Label indicating a comment was edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get editedLabel;

  /// Label for mentioned users.
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get mentionedLabel;

  /// Tooltip for delete comment button.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteCommentTooltip;

  /// Title for Gantt chart view.
  ///
  /// In en, this message translates to:
  /// **'Gantt Chart'**
  String get ganttViewTitle;

  /// Tooltip for zoom in button.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomInTooltip;

  /// Tooltip for zoom out button.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOutTooltip;

  /// Tooltip for reset zoom button.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoomTooltip;

  /// Button to jump to today's date.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayButton;

  /// Label for project timeline section.
  ///
  /// In en, this message translates to:
  /// **'Project Timeline'**
  String get projectTimelineLabel;

  /// Label for task timeline section.
  ///
  /// In en, this message translates to:
  /// **'Task Timeline'**
  String get taskTimelineLabel;

  /// Label for end date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// Label for duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// Tooltip for select date range button.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRangeTooltip;

  /// Message when no projects have dates for Gantt chart.
  ///
  /// In en, this message translates to:
  /// **'No projects with dates to display'**
  String get noProjectsForGantt;

  /// Message suggesting to add projects with dates.
  ///
  /// In en, this message translates to:
  /// **'Add projects with start and end dates to see the timeline'**
  String get addProjectsWithDates;

  /// Tooltip for open project button.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get openProjectTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
