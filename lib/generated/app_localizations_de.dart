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
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
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
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
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
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'Burndown-Diagramm fuer $projectName. Reale Punkte: $actualPoints. Ideale Punkte: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'KI-Chat';

  @override
  String get aiUsageTitle => 'KI-Nutzung';

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
  String get filterPriorityLabel => 'Priority';

  @override
  String get filterStartDateLabel => 'Start Date';

  @override
  String get filterEndDateLabel => 'End Date';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get filterDateRangeLabel => 'Date Range';

  @override
  String get applyFiltersLabel => 'Apply Filters';

  @override
  String get resetAllLabel => 'Reset All';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get projectFiltersTitle => 'Project Filters';

  @override
  String get filterButtonTooltip => 'Filter projects';

  @override
  String activeFilterPriority(String value) {
    return 'Priority: $value';
  }

  @override
  String activeFilterStartDate(String date) {
    return 'Start: $date';
  }

  @override
  String activeFilterEndDate(String date) {
    return 'End: $date';
  }

  @override
  String get allProjectsHint => 'All projects';

  @override
  String get clearAllLabel => 'Clear All';

  @override
  String get saveAsDefaultViewLabel => 'Save as Default View';

  @override
  String get saveAsDefaultSuccessMessage => 'Default view saved successfully';

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
  String showingProjectsCount(int count, int total) {
    return 'Showing $count of $total projects';
  }

  @override
  String get noProjectsMatchFiltersTitle => 'No projects match your filters';

  @override
  String get noProjectsMatchFiltersSubtitle =>
      'Try changing or clearing your filters';

  @override
  String get clearAllFiltersButtonLabel => 'Clear All Filters';

  @override
  String get smartFilterButtonLabel => 'Smart Filter';

  @override
  String get smartFilterButtonTooltip =>
      'Use AI to create filters from natural language';

  @override
  String get smartFilterDialogTitle => 'Describe Your Filter';

  @override
  String get smartFilterHint =>
      'Show high priority tasks due this week for team X';

  @override
  String get smartFilterProcessing => 'Analyzing your request...';

  @override
  String get smartFilterError =>
      'Could not understand your request. Please try rephrasing.';

  @override
  String get aiSuggestedFilterLabel => 'AI Suggested Filter';

  @override
  String get acceptFilterButtonLabel => 'Accept';

  @override
  String get editFilterButtonLabel => 'Edit';

  @override
  String get projectSortStartDate => 'Start Date';

  @override
  String get projectSortDueDate => 'Due Date';

  @override
  String get csvExportSuccessMessage => 'Projects exported to CSV successfully';

  @override
  String get viewNameLabel => 'View Name';

  @override
  String get viewNameHint => 'Enter a name for this view';

  @override
  String get viewSavedMessage => 'View saved successfully';

  @override
  String get saveCurrentAsViewLabel => 'Save Current as View';

  @override
  String get noSavedViewsMessage =>
      'No saved views yet. Save your current filters to create a view.';

  @override
  String get sortDirectionLabel => 'Sort Direction';

  @override
  String get sortAscendingLabel => 'Ascending';

  @override
  String get sortDescendingLabel => 'Descending';

  @override
  String get searchProjectsLabel => 'Search Projects';

  @override
  String get searchProjectsHint => 'Search by name, description, or tags';

  @override
  String get savedViewsTabLabel => 'Saved Views';

  @override
  String get filtersTabLabel => 'Filters';

  @override
  String get exportToCsvLabel => 'Export to CSV';

  @override
  String get exportToPdfLabel => 'Export to PDF';

  @override
  String get requiredTagsLabel => 'Required Tags';

  @override
  String get requiredTagsDescription => 'Projects must have all of these tags';

  @override
  String get optionalTagsLabel => 'Optional Tags';

  @override
  String get optionalTagsDescription => 'Projects can have any of these tags';

  @override
  String get addTagLabel => 'Add Tag';

  @override
  String get addTagHint => 'Type to add a tag';

  @override
  String get availableTagsLabel => 'Available Tags';

  @override
  String selectProjectsTitle(int count) {
    return 'Select Projects ($count)';
  }

  @override
  String get bulkActionsTooltip => 'Bulk actions';

  @override
  String get exitSelectionModeTooltip => 'Exit selection mode';

  @override
  String get savedViewsLabel => 'Saved Views';

  @override
  String get allViewsLabel => 'All Views';

  @override
  String get filterProjectsTooltip => 'Filter projects';

  @override
  String get listViewTooltip => 'List view';

  @override
  String get kanbanViewTooltip => 'Kanban view';

  @override
  String get tableViewTooltip => 'Table view';

  @override
  String bulkActionsTitle(int count) {
    return 'Bulk Actions ($count)';
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
    return '$count projects deleted successfully';
  }

  @override
  String get priorityLabel => 'Priority';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get nameLabel => 'Name';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get exportingPdfMessage => 'Exporting PDF...';

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
  String get pdfExportedMessage => 'PDF exported successfully';

  @override
  String get projectListLabel => 'Project List';

  @override
  String get recentFiltersTooltip => 'Recent filters';

  @override
  String get ownerLabel => 'Owner';

  @override
  String get ascendingLabel => 'ascending';

  @override
  String get descendingLabel => 'descending';

  @override
  String get allProjectsLabel => 'All Projects';

  @override
  String get unnamedFilterLabel => 'Unnamed Filter';
}
