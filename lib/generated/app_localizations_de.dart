// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Projektmanagement-App';

  @override
  String get menuLabel => 'Menü';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get logoutTooltip => 'Abmelden';

  @override
  String get closeAppTooltip => 'App schliessen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsDisplaySection => 'Anzeige';

  @override
  String get settingsDarkModeTitle => 'Dunkelmodus';

  @override
  String get settingsDarkModeSubtitle => 'Zwischen hell und dunkel wechseln';

  @override
  String get settingsFollowSystemTitle => 'Systemdesign verwenden';

  @override
  String get settingsFollowSystemSubtitle => 'Design des Geraets nutzen';

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
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'App-Sprache waehlen';

  @override
  String get settingsNotificationsSection => 'Benachrichtigungen';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsSubtitle => 'Updates und Erinnerungen';

  @override
  String get settingsPrivacySection => 'Datenschutz';

  @override
  String get settingsLocalFilesConsentTitle => 'Lokale Dateiberechtigung';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Der App erlauben, lokale Projektdateien fuer KI-Kontext zu lesen.';

  @override
  String get settingsUseProjectFilesTitle => 'Projektdateien verwenden';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Lokale Dateien zu KI-Prompts hinzufuegen';

  @override
  String get settingsProjectsSection => 'Projekte';

  @override
  String get settingsLogoutTitle => 'Abmelden';

  @override
  String get settingsLogoutSubtitle => 'Aktuelle Sitzung beenden';

  @override
  String get settingsExportTitle => 'Projekte exportieren';

  @override
  String get settingsExportSubtitle => 'Projekte in eine Datei exportieren';

  @override
  String get settingsImportTitle => 'Projekte importieren';

  @override
  String get settingsImportSubtitle => 'Projekte aus einer Datei importieren';

  @override
  String get settingsUsersSection => 'Benutzer';

  @override
  String get settingsCurrentUserTitle => 'Aktueller Benutzer';

  @override
  String get settingsNotLoggedIn => 'Nicht angemeldet';

  @override
  String get settingsNoUsersFound => 'Keine Benutzer gefunden.';

  @override
  String get settingsLocalUserLabel => 'Lokaler Benutzer';

  @override
  String get settingsDeleteTooltip => 'Loeschen';

  @override
  String get settingsLoadUsersFailed => 'Benutzer konnten nicht geladen werden';

  @override
  String get settingsAddUserTitle => 'Benutzer hinzufuegen';

  @override
  String get settingsAddUserSubtitle => 'Zusaetzliches Konto hinzufuegen';

  @override
  String get logoutDialogTitle => 'Abmelden';

  @override
  String get logoutDialogContent => 'Moechten Sie sich wirklich abmelden?';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get logoutButton => 'Abmelden';

  @override
  String get loggedOutMessage => 'Sie wurden abgemeldet.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Export abgeschlossen: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get exportPasswordTitle => 'Export verschluesseln';

  @override
  String get exportPasswordSubtitle =>
      'Legen Sie ein Passwort fest, um die Exportdateien zu verschluesseln.';

  @override
  String get exportPasswordMismatch => 'Passwoerter stimmen nicht ueberein.';

  @override
  String get importSelectFilesMessage =>
      'Waehlen Sie eine CSV- und JSON-Datei aus.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Import abgeschlossen: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get importFailedTitle => 'Import fehlgeschlagen';

  @override
  String get addUserDialogTitle => 'Benutzer hinzufuegen';

  @override
  String get saveButton => 'Speichern';

  @override
  String get userAddedMessage => 'Benutzer hinzugefuegt.';

  @override
  String get invalidUserMessage => 'Ungueltiger Benutzer.';

  @override
  String get deleteUserDialogTitle => 'Benutzer loeschen';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Moechten Sie $username wirklich loeschen?';
  }

  @override
  String get deleteButton => 'Loeschen';

  @override
  String userDeletedMessage(Object username) {
    return 'Benutzer geloescht: $username';
  }

  @override
  String get projectsTitle => 'Projekte';

  @override
  String get newProjectButton => 'Neues Projekt';

  @override
  String get noProjectsYet => 'Noch keine Projekte';

  @override
  String get noProjectsFound => 'Keine Projekte gefunden';

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
  String get loadingMoreProjects => 'Weitere Projekte werden geladen...';

  @override
  String get sortByLabel => 'Sortieren nach';

  @override
  String get projectSortName => 'Name';

  @override
  String get projectSortProgress => 'Fortschritt';

  @override
  String get projectSortPriority => 'Prioritaet';

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
  String get allLabel => 'Alle';

  @override
  String get loadProjectsFailed => 'Projekte konnten nicht geladen werden.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Projekt $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Status $status';
  }

  @override
  String get newProjectDialogTitle => 'Neues Projekt';

  @override
  String get projectNameLabel => 'Projektname';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get urgencyLabel => 'Dringlichkeit';

  @override
  String get urgencyLow => 'Niedrig';

  @override
  String get urgencyMedium => 'Mittel';

  @override
  String get urgencyHigh => 'Hoch';

  @override
  String projectCreatedMessage(Object name) {
    return 'Projekt erstellt: $name';
  }

  @override
  String get projectDetailsTitle => 'Projektdetails';

  @override
  String get aiChatWithProjectFilesTooltip => 'KI-Chat mit Projektdateien';

  @override
  String get moreOptionsLabel => 'Mehr Optionen';

  @override
  String get tasksTitle => 'Aufgaben';

  @override
  String get tasksTab => 'Aufgaben';

  @override
  String get detailsTab => 'Details';

  @override
  String get tasksLoadFailed => 'Aufgaben konnten nicht geladen werden.';

  @override
  String get projectOverviewTitle => 'Projektuebersicht';

  @override
  String get tasksLoading => 'Aufgaben werden geladen...';

  @override
  String get taskStatisticsTitle => 'Aufgabenstatistik';

  @override
  String get totalLabel => 'Gesamt';

  @override
  String get completedLabel => 'Erledigt';

  @override
  String get inProgressLabel => 'In Bearbeitung';

  @override
  String get remainingLabel => 'Uebrig';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% abgeschlossen';
  }

  @override
  String get burndownChartTitle => 'Burndown-Diagramm';

  @override
  String get chartPlaceholderTitle => 'Diagrammplatzhalter';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart-Integration bald';

  @override
  String get workflowsTitle => 'Workflows';

  @override
  String get noWorkflowsAvailable => 'Keine Workflow-Elemente verfuegbar.';

  @override
  String get taskStatusTodo => 'Zu erledigen';

  @override
  String get taskStatusInProgress => 'In Bearbeitung';

  @override
  String get taskStatusReview => 'Pruefung';

  @override
  String get taskStatusDone => 'Erledigt';

  @override
  String get workflowStatusActive => 'Aktiv';

  @override
  String get workflowStatusPending => 'Ausstehend';

  @override
  String get noTasksYet => 'Noch keine Aufgaben';

  @override
  String get projectTimeTitle => 'Projektzeit';

  @override
  String urgencyValue(Object value) {
    return 'Dringlichkeit: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Erfasste Zeit: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'min';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Aufgaben suchen...';

  @override
  String get searchAttachmentsHint => 'Anhange suchen...';

  @override
  String get clearSearchTooltip => 'Suche loeschen';

  @override
  String get projectMapTitle => 'Projektordner';

  @override
  String get linkProjectMapButton => 'Projektordner verknuepfen';

  @override
  String get projectDataLoading => 'Projektdaten werden geladen...';

  @override
  String get projectDataLoadFailed =>
      'Projektdaten konnten nicht geladen werden.';

  @override
  String currentMapLabel(Object path) {
    return 'Aktueller Ordner: $path';
  }

  @override
  String get noProjectMapLinked =>
      'Kein Ordner verknuepft. Verknuepfen Sie einen Ordner, um Dateien zu lesen.';

  @override
  String get projectNotAvailable => 'Projekt nicht verfuegbar.';

  @override
  String get enableConsentInSettings =>
      'Aktivieren Sie die Berechtigung in den Einstellungen.';

  @override
  String get projectMapLinked => 'Projektordner verknuepft.';

  @override
  String get privacyWarningTitle => 'Datenschutzhinweis';

  @override
  String get privacyWarningContent =>
      'Warnung: Es koennen sensible Daten gelesen werden.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get attachFilesTooltip => 'Dateien anhaengen';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'KI-Assistent';

  @override
  String get welcomeBack => 'Willkommen zurueck! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'Hier ist ein Ueberblick ueber deine aktiven Projekte';

  @override
  String get recentWorkflowsTitle => 'Neueste Workflows';

  @override
  String get recentWorkflowsLoading => 'Neueste Workflows werden geladen...';

  @override
  String get recentWorkflowsLoadFailed =>
      'Neueste Workflows konnten nicht geladen werden.';

  @override
  String get retryButton => 'Erneut versuchen';

  @override
  String get noRecentTasks => 'Keine aktuellen Aufgaben verfuegbar.';

  @override
  String get unknownProject => 'Unbekanntes Projekt';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle,
      Object statusLabel, Object timeLabel) {
    return 'Projekt $projectName, Aufgabe $taskTitle, Status $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Aufgabe $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Gerade eben';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'Vor $minutes Min';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'Vor $hours Std';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'Vor $days Tagen';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return 'Vor $weeks Wochen';
  }

  @override
  String timeMonthsAgo(Object months) {
    return 'Vor $months Monaten';
  }

  @override
  String projectProgressChartSemantics(
      Object projectName, Object completedPercent, Object pendingPercent) {
    return 'Projektfortschritt fuer $projectName. Abgeschlossen $completedPercent Prozent, ausstehend $pendingPercent Prozent.';
  }

  @override
  String get progressLabel => 'Fortschritt';

  @override
  String completedPercentLabel(Object percent) {
    return 'Abgeschlossen: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'Ausstehend: $percent%';
  }

  @override
  String get noDescription => 'Keine Beschreibung';

  @override
  String get closeButton => 'Schliessen';

  @override
  String get burndownProgressTitle => 'Burndown-Fortschritt';

  @override
  String get actualProgressLabel => 'Tatsaechlicher Fortschritt';

  @override
  String get idealTrendLabel => 'Idealer Trend';

  @override
  String get statusLabel => 'Status';

  @override
  String burndownChartSemantics(
      Object projectName, Object actualPoints, Object idealPoints) {
    return 'Burndown-Diagramm fuer $projectName. Reale Punkte: $actualPoints. Ideale Punkte: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'KI-Chat';

  @override
  String get aiAssistantTitle => 'Projekt-KI-Assistent';

  @override
  String get clearChatTooltip => 'Chat leeren';

  @override
  String get noMessagesLabel => 'Keine Nachrichten';

  @override
  String get aiEmptyTitle => 'Starte ein Gespraech mit dem KI-Assistenten';

  @override
  String get aiEmptySubtitle =>
      'Zum Beispiel: \"Erstelle einen Plan fuer das Projekt: Webshop\"';

  @override
  String get useProjectFilesLabel => 'Projektdateien verwenden';

  @override
  String get typeMessageHint => 'Nachricht eingeben...';

  @override
  String get projectFilesReadFailed =>
      'Projektdateien konnten nicht gelesen werden.';

  @override
  String get aiResponseFailedTitle => 'KI-Antwort fehlgeschlagen';

  @override
  String get sendMessageTooltip => 'Nachricht senden';

  @override
  String get loginMissingCredentials =>
      'Bitte Benutzername und Passwort eingeben.';

  @override
  String get loginFailedMessage =>
      'Anmeldung fehlgeschlagen. Bitte Zugangsdaten pruefen.';

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
  String get registerTitle => 'Registrieren';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageDutch => 'Niederlaendisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageFrench => 'Franzoesisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String get languageItalian => 'Italienisch';

  @override
  String get languageArabic => 'Arabisch';

  @override
  String get languageChinese => 'Chinesisch';

  @override
  String get languageJapanese => 'Japanisch';

  @override
  String get languageKorean => 'Koreanisch';

  @override
  String get languageRussian => 'Russisch';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Passwort wiederholen';

  @override
  String get passwordRulesTitle => 'Passwortregeln';

  @override
  String get passwordRuleMinLength => 'Mindestens 8 Zeichen';

  @override
  String get passwordRuleHasLetter => 'Enthaelt einen Buchstaben';

  @override
  String get passwordRuleHasDigit => 'Enthaelt eine Zahl';

  @override
  String get passwordRuleMatches => 'Passwoerter stimmen ueberein';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get registrationIssueUsernameMissing => 'Benutzername fehlt';

  @override
  String get registrationIssueMinLength => 'mindestens 8 Zeichen';

  @override
  String get registrationIssueLetter => 'mindestens 1 Buchstabe';

  @override
  String get registrationIssueDigit => 'mindestens 1 Zahl';

  @override
  String get registrationIssueNoMatch => 'Passwoerter stimmen nicht ueberein';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registrierung fehlgeschlagen: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Konto erstellt. Jetzt anmelden.';

  @override
  String get registerFailedMessage => 'Registrierung fehlgeschlagen.';

  @override
  String get accessDeniedMessage => 'Zugriff verweigert.';

  @override
  String get adminPanelTitle => 'Admin-Bereich';

  @override
  String get adminPanelSubtitle =>
      'Rollen, Gruppen und Berechtigungen verwalten.';

  @override
  String get rolesTitle => 'Rollen';

  @override
  String get noRolesFound => 'Keine Rollen gefunden.';

  @override
  String permissionsCount(Object count) {
    return 'Berechtigungen: $count';
  }

  @override
  String get editPermissionsTooltip => 'Berechtigungen bearbeiten';

  @override
  String get groupsTitle => 'Gruppen';

  @override
  String get noGroupsFound => 'Keine Gruppen gefunden.';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get groupAddTitle => 'Gruppe hinzufügen';

  @override
  String get groupNameLabel => 'Gruppenname';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Mitglied zu $groupName hinzufügen';
  }

  @override
  String get addGroupMemberTooltip => 'Mitglied hinzufügen';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Gruppenmitglieder: $groupName';
  }

  @override
  String get noGroupMembers => 'Keine Gruppenmitglieder.';

  @override
  String get removeGroupMemberTooltip => 'Mitglied entfernen';

  @override
  String get roleCreateTitle => 'Rolle erstellen';

  @override
  String get roleNameLabel => 'Rollenname';

  @override
  String get permissionsTitle => 'Berechtigungen';

  @override
  String get settingsBackupTitle => 'Backup erstellen';

  @override
  String get settingsBackupSubtitle =>
      'Lokale Sicherung der Hive-Daten speichern.';

  @override
  String get settingsRestoreTitle => 'Backup wiederherstellen';

  @override
  String get settingsRestoreSubtitle =>
      'Lokale Daten durch eine Sicherungsdatei ersetzen.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Backup gespeichert: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Backup fehlgeschlagen: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Backup wiederhergestellt. App neu starten, um Daten zu laden.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get restoreConfirmTitle => 'Backup wiederherstellen?';

  @override
  String get restoreConfirmContent =>
      'Dadurch werden lokale Daten überschrieben.';

  @override
  String get restoreConfirmButton => 'Wiederherstellen';

  @override
  String get settingsBackupLastRunLabel => 'Letztes Backup';

  @override
  String get backupNeverMessage => 'Nie';

  @override
  String get backupNowButton => 'Jetzt sichern';

  @override
  String get settingsBackupPathLabel => 'Backup-Datei';

  @override
  String get backupNoFileMessage => 'Noch keine Backup-Datei';

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
  String get saveAsDefaultSuccessMessage => 'Default view saved successfully';

  @override
  String get saveAsDefaultViewLabel => 'Save as Default View';

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
      'Ich verstehe das Risiko der direkten Übernahme';

  @override
  String get mirrorApplyRiskAcknowledgeSubtitle =>
      'Änderungen werden auf Ihr Arbeitsverzeichnis angewendet. Bevorzugen Sie einen separaten Branch.';

  @override
  String get mirrorPermissionDenied =>
      'Mirror ist für Ihr Konto nicht verfügbar.';

  @override
  String get mirrorPermissionRevokedSessionDisabled =>
      'Ihre Mirror-Editor-Sitzung wurde deaktiviert, weil sich Ihre Berechtigung geändert hat. Schließen Sie diesen Bildschirm, um sicher fortzufahren.';

  @override
  String get mirrorPermissionRevokedTerminal =>
      'Mirror-Zugriff entzogen: Sitzung beendet.';

  @override
  String get mirrorApplyDiffPreview => 'Diff-Vorschau';

  @override
  String get mirrorApplyNo => 'Nein';

  @override
  String get mirrorApplyConfirm => 'Anwenden';

  @override
  String get mirrorApplyNoDiff => '(Keine Unterschiede festgestellt)';

  @override
  String get mirrorApplyBranchAdviceTitle => 'Git-Branch-Empfehlung';

  @override
  String mirrorApplyCurrentBranch(String branch) {
    return 'Aktueller Branch: $branch';
  }

  @override
  String mirrorApplySuggestedBranch(String branch) {
    return 'Empfohlener Branch: $branch';
  }

  @override
  String get mirrorApplyBranchTip =>
      'Tipp: Erstellen Sie zuerst einen neuen Branch für sichere Überprüfung und Rollback.';

  @override
  String get mirrorApplyBranchWorkingTreeNotice =>
      'Mirror wendet Änderungen in Ihrem aktuellen Arbeitsverzeichnis an und erstellt oder wechselt keine Branches automatisch.';

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
