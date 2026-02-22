// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Project Management App';

  @override
  String get menuLabel => 'Menu';

  @override
  String get loginTitle => 'Inloggen';

  @override
  String get usernameLabel => 'Gebruikersnaam';

  @override
  String get passwordLabel => 'Wachtwoord';

  @override
  String get loginButton => 'Inloggen';

  @override
  String get createAccount => 'Account aanmaken';

  @override
  String get logoutTooltip => 'Uitloggen';

  @override
  String get closeAppTooltip => 'App sluiten';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsDisplaySection => 'Weergave';

  @override
  String get settingsDarkModeTitle => 'Donkere modus';

  @override
  String get settingsDarkModeSubtitle => 'Schakel tussen licht en donker';

  @override
  String get settingsFollowSystemTitle => 'Volg systeemthema';

  @override
  String get settingsFollowSystemSubtitle => 'Gebruik het thema van je toestel';

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get settingsLanguageSubtitle => 'Kies de taal van de app';

  @override
  String get settingsNotificationsSection => 'Notificaties';

  @override
  String get settingsNotificationsTitle => 'Notificaties';

  @override
  String get settingsNotificationsSubtitle =>
      'Meldingen voor updates en reminders';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsLocalFilesConsentTitle => 'Toestemming lokale bestanden';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Sta toe dat de app lokale projectbestanden leest voor AI-context.';

  @override
  String get settingsUseProjectFilesTitle => 'Gebruik project bestanden';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Voeg lokale bestanden toe aan AI prompts';

  @override
  String get settingsProjectsSection => 'Projecten';

  @override
  String get settingsLogoutTitle => 'Uitloggen';

  @override
  String get settingsLogoutSubtitle => 'Beëindig je huidige sessie';

  @override
  String get settingsExportTitle => 'Exporteer projecten';

  @override
  String get settingsExportSubtitle => 'Exporteer projecten naar een bestand';

  @override
  String get settingsImportTitle => 'Importeer projecten';

  @override
  String get settingsImportSubtitle => 'Importeer projecten uit een bestand';

  @override
  String get settingsUsersSection => 'Gebruikers';

  @override
  String get settingsCurrentUserTitle => 'Huidige gebruiker';

  @override
  String get settingsNotLoggedIn => 'Niet ingelogd';

  @override
  String get settingsNoUsersFound => 'Geen gebruikers gevonden.';

  @override
  String get settingsLocalUserLabel => 'Lokale gebruiker';

  @override
  String get settingsDeleteTooltip => 'Verwijderen';

  @override
  String get settingsLoadUsersFailed => 'Kon gebruikers niet laden';

  @override
  String get settingsAddUserTitle => 'Gebruiker toevoegen';

  @override
  String get settingsAddUserSubtitle => 'Voeg een extra account toe';

  @override
  String get logoutDialogTitle => 'Uitloggen';

  @override
  String get logoutDialogContent => 'Weet je zeker dat je wilt uitloggen?';

  @override
  String get cancelButton => 'Annuleren';

  @override
  String get logoutButton => 'Uitloggen';

  @override
  String get loggedOutMessage => 'Je bent uitgelogd.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Export voltooid: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Export mislukt: $error';
  }

  @override
  String get exportPasswordTitle => 'Export versleutelen';

  @override
  String get exportPasswordSubtitle =>
      'Stel een wachtwoord in om de exportbestanden te versleutelen.';

  @override
  String get exportPasswordMismatch => 'Wachtwoorden komen niet overeen.';

  @override
  String get importSelectFilesMessage => 'Selecteer een CSV en JSON bestand.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Import voltooid: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Import mislukt: $error';
  }

  @override
  String get importFailedTitle => 'Import mislukt';

  @override
  String get addUserDialogTitle => 'Gebruiker toevoegen';

  @override
  String get saveButton => 'Opslaan';

  @override
  String get userAddedMessage => 'Gebruiker toegevoegd.';

  @override
  String get invalidUserMessage => 'Ongeldige gebruiker.';

  @override
  String get deleteUserDialogTitle => 'Gebruiker verwijderen';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Weet je zeker dat je $username wilt verwijderen?';
  }

  @override
  String get deleteButton => 'Verwijderen';

  @override
  String userDeletedMessage(Object username) {
    return 'Gebruiker verwijderd: $username';
  }

  @override
  String get projectsTitle => 'Projecten';

  @override
  String get newProjectButton => 'Nieuw project';

  @override
  String get noProjectsYet => 'Nog geen projecten';

  @override
  String get noProjectsFound => 'Geen projecten gevonden';

  @override
  String get loadingMoreProjects => 'Meer projecten laden...';

  @override
  String get sortByLabel => 'Sorteren op';

  @override
  String get projectSortName => 'Naam';

  @override
  String get projectSortProgress => 'Voortgang';

  @override
  String get projectSortPriority => 'Prioriteit';

  @override
  String get projectSortCreatedDate => 'Aanmaakdatum';

  @override
  String get projectSortStatus => 'Status';

  @override
  String get projectSortStartDate => 'Startdatum';

  @override
  String get projectSortDueDate => 'Vervaldatum';

  @override
  String get sortDirectionLabel => 'Richting';

  @override
  String get sortAscendingLabel => 'Oplopend';

  @override
  String get sortDescendingLabel => 'Aflopend';

  @override
  String get exportToCsvLabel => 'Exporteren naar CSV';

  @override
  String get csvExportSuccessMessage => 'CSV succesvol geëxporteerd en gedeeld';

  @override
  String get allLabel => 'Alles';

  @override
  String get loadProjectsFailed => 'Kon projecten niet laden.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Project $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Status $status';
  }

  @override
  String get newProjectDialogTitle => 'Nieuw project';

  @override
  String get projectNameLabel => 'Projectnaam';

  @override
  String get descriptionLabel => 'Beschrijving';

  @override
  String get urgencyLabel => 'Urgentie';

  @override
  String get urgencyLow => 'Laag';

  @override
  String get urgencyMedium => 'Normaal';

  @override
  String get urgencyHigh => 'Hoog';

  @override
  String projectCreatedMessage(Object name) {
    return 'Project aangemaakt: $name';
  }

  @override
  String get projectDetailsTitle => 'Projectdetails';

  @override
  String get aiChatWithProjectFilesTooltip => 'AI chat met projectbestanden';

  @override
  String get moreOptionsLabel => 'Meer opties';

  @override
  String get tasksTitle => 'Taken';

  @override
  String get tasksTab => 'Taken';

  @override
  String get detailsTab => 'Details';

  @override
  String get tasksLoadFailed => 'Kon taken niet laden.';

  @override
  String get projectOverviewTitle => 'Projectoverzicht';

  @override
  String get tasksLoading => 'Taken laden...';

  @override
  String get taskStatisticsTitle => 'Taakstatistieken';

  @override
  String get totalLabel => 'Totaal';

  @override
  String get completedLabel => 'Voltooid';

  @override
  String get inProgressLabel => 'Bezig';

  @override
  String get remainingLabel => 'Resterend';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% voltooid';
  }

  @override
  String get burndownChartTitle => 'Burndown-grafiek';

  @override
  String get chartPlaceholderTitle => 'Grafiek placeholder';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart integratie komt binnenkort';

  @override
  String get workflowsTitle => 'Workflows';

  @override
  String get noWorkflowsAvailable => 'Nog geen workflow-items beschikbaar.';

  @override
  String get taskStatusTodo => 'Te doen';

  @override
  String get taskStatusInProgress => 'Bezig';

  @override
  String get taskStatusReview => 'Review';

  @override
  String get taskStatusDone => 'Gereed';

  @override
  String get workflowStatusActive => 'Actief';

  @override
  String get workflowStatusPending => 'In afwachting';

  @override
  String get noTasksYet => 'Nog geen taken';

  @override
  String get projectTimeTitle => 'Projecttijd';

  @override
  String urgencyValue(Object value) {
    return 'Urgentie: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Gewerkte tijd: $value';
  }

  @override
  String get hourShort => 'u';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Zoek taken...';

  @override
  String get searchAttachmentsHint => 'Zoek bijlagen...';

  @override
  String get clearSearchTooltip => 'Zoekopdracht wissen';

  @override
  String get projectMapTitle => 'Projectmap';

  @override
  String get linkProjectMapButton => 'Projectmap koppelen';

  @override
  String get projectDataLoading => 'Projectgegevens laden...';

  @override
  String get projectDataLoadFailed => 'Kon projectgegevens niet laden.';

  @override
  String currentMapLabel(Object path) {
    return 'Huidige map: $path';
  }

  @override
  String get noProjectMapLinked =>
      'Nog geen map gekoppeld. Koppel een map om bestanden in te lezen.';

  @override
  String get projectNotAvailable => 'Project niet beschikbaar.';

  @override
  String get enableConsentInSettings => 'Schakel toestemming in bij Settings.';

  @override
  String get projectMapLinked => 'Projectmap gekoppeld.';

  @override
  String get privacyWarningTitle => 'Privacy waarschuwing';

  @override
  String get privacyWarningContent =>
      'Waarschuwing: Gevoelige data kan worden gelezen.';

  @override
  String get continueButton => 'Doorgaan';

  @override
  String get attachFilesTooltip => 'Bestanden koppelen';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AI Assistent';

  @override
  String get welcomeBack => 'Welkom terug! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'Hier is een overzicht van je actieve projecten';

  @override
  String get recentWorkflowsTitle => 'Recente workflows';

  @override
  String get recentWorkflowsLoading => 'Recente workflows laden...';

  @override
  String get recentWorkflowsLoadFailed => 'Kon recente workflows niet laden.';

  @override
  String get retryButton => 'Opnieuw proberen';

  @override
  String get noRecentTasks => 'Geen recente taken beschikbaar.';

  @override
  String get unknownProject => 'Onbekend project';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'Project $projectName, taak $taskTitle, status $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Taak $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Zojuist';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes min geleden';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours uur geleden';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days dagen geleden';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks weken geleden';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months maanden geleden';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return 'Project voortgangsgrafiek voor $projectName. Voltooid $completedPercent procent, resterend $pendingPercent procent.';
  }

  @override
  String get progressLabel => 'Voortgang';

  @override
  String completedPercentLabel(Object percent) {
    return 'Voltooid: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'Resterend: $percent%';
  }

  @override
  String get noDescription => 'Geen beschrijving';

  @override
  String get closeButton => 'Sluiten';

  @override
  String get burndownProgressTitle => 'Burndown voortgang';

  @override
  String get actualProgressLabel => 'Werkelijke voortgang';

  @override
  String get idealTrendLabel => 'Ideale trend';

  @override
  String get statusLabel => 'Status';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'Burndown grafiek voor $projectName. Werkelijke punten: $actualPoints. Ideale punten: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'AI chat';

  @override
  String get aiAssistantTitle => 'AI Project Assistent';

  @override
  String get clearChatTooltip => 'Chat wissen';

  @override
  String get noMessagesLabel => 'Geen berichten';

  @override
  String get aiEmptyTitle => 'Start een gesprek met de AI assistent';

  @override
  String get aiEmptySubtitle =>
      'Vraag bijvoorbeeld: \"Genereer stappenplan voor project: webshop\"';

  @override
  String get useProjectFilesLabel => 'Gebruik project bestanden';

  @override
  String get typeMessageHint => 'Type een bericht...';

  @override
  String get projectFilesReadFailed => 'Kon projectbestanden niet lezen.';

  @override
  String get aiResponseFailedTitle => 'AI antwoord mislukt';

  @override
  String get sendMessageTooltip => 'Bericht versturen';

  @override
  String get loginMissingCredentials => 'Vul gebruikersnaam en wachtwoord in.';

  @override
  String get loginFailedMessage => 'Inloggen mislukt. Controleer je gegevens.';

  @override
  String rateLimitExceeded(Object seconds) {
    return 'Te veel pogingen. Probeer opnieuw over $seconds seconden.';
  }

  @override
  String get registerTitle => 'Registreren';

  @override
  String get languageLabel => 'Taal';

  @override
  String get languageSystem => 'Systeemstandaard';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageSpanish => 'Spaans';

  @override
  String get languageFrench => 'Frans';

  @override
  String get languageGerman => 'Duits';

  @override
  String get languagePortuguese => 'Portugees';

  @override
  String get languageItalian => 'Italiaans';

  @override
  String get languageArabic => 'Arabisch';

  @override
  String get languageChinese => 'Chinees';

  @override
  String get languageJapanese => 'Japans';

  @override
  String get languageKorean => 'Koreaans';

  @override
  String get languageRussian => 'Russisch';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Herhaal wachtwoord';

  @override
  String get passwordRulesTitle => 'Wachtwoordregels';

  @override
  String get passwordRuleMinLength => 'Minimaal 8 tekens';

  @override
  String get passwordRuleHasLetter => 'Bevat een letter';

  @override
  String get passwordRuleHasDigit => 'Bevat een cijfer';

  @override
  String get passwordRuleMatches => 'Wachtwoorden komen overeen';

  @override
  String get registerButton => 'Registreren';

  @override
  String get registrationIssueUsernameMissing => 'gebruikersnaam ontbreekt';

  @override
  String get registrationIssueMinLength => 'minimaal 8 tekens';

  @override
  String get registrationIssueLetter => 'minstens 1 letter';

  @override
  String get registrationIssueDigit => 'minstens 1 cijfer';

  @override
  String get registrationIssueNoMatch => 'wachtwoorden komen niet overeen';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registratie mislukt: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Account aangemaakt. Log nu in.';

  @override
  String get registerFailedMessage => 'Registreren mislukt.';

  @override
  String get accessDeniedMessage => 'Toegang geweigerd.';

  @override
  String get adminPanelTitle => 'Beheerpaneel';

  @override
  String get adminPanelSubtitle => 'Beheer rollen, groepen en machtigingen.';

  @override
  String get rolesTitle => 'Rollen';

  @override
  String get noRolesFound => 'Geen rollen gevonden.';

  @override
  String permissionsCount(Object count) {
    return 'Machtigingen: $count';
  }

  @override
  String get editPermissionsTooltip => 'Machtigingen bewerken';

  @override
  String get groupsTitle => 'Groepen';

  @override
  String get noGroupsFound => 'Geen groepen gevonden.';

  @override
  String get roleLabel => 'Rol';

  @override
  String get groupAddTitle => 'Groep toevoegen';

  @override
  String get groupNameLabel => 'Groepsnaam';

  @override
  String get groupLabel => 'Groep';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Lid toevoegen aan $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Lid toevoegen';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Groepsleden: $groupName';
  }

  @override
  String get noGroupMembers => 'Geen groepsleden.';

  @override
  String get removeGroupMemberTooltip => 'Lid verwijderen';

  @override
  String get roleCreateTitle => 'Rol maken';

  @override
  String get roleNameLabel => 'Rolnaam';

  @override
  String get permissionsTitle => 'Machtigingen';

  @override
  String get settingsBackupTitle => 'Back-up maken';

  @override
  String get settingsBackupSubtitle =>
      'Een lokale back-up van Hive-gegevens opslaan.';

  @override
  String get settingsRestoreTitle => 'Back-up herstellen';

  @override
  String get settingsRestoreSubtitle =>
      'Lokale gegevens vervangen door een back-upbestand.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Back-up opgeslagen: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Back-up mislukt: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Back-up hersteld. Herstart de app om gegevens opnieuw te laden.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Herstellen mislukt: $error';
  }

  @override
  String get restoreConfirmTitle => 'Back-up herstellen?';

  @override
  String get restoreConfirmContent => 'Dit overschrijft lokale gegevens.';

  @override
  String get restoreConfirmButton => 'Herstellen';

  @override
  String get settingsBackupLastRunLabel => 'Laatste back-up';

  @override
  String get backupNeverMessage => 'Nooit';

  @override
  String get backupNowButton => 'Nu back-up maken';

  @override
  String get settingsBackupPathLabel => 'Back-upbestand';

  @override
  String get backupNoFileMessage => 'Nog geen back-upbestand';

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
  String get settingsBiometricLoginTitle => 'Biometrische login';

  @override
  String get settingsBiometricLoginSubtitle =>
      'Gebruik vingerafdruk of gezichts-ID om in te loggen';

  @override
  String get enableBiometricDialogTitle => 'Biometrische login inschakelen';

  @override
  String get enableBiometricDialogMessage =>
      'Wilt u biometrische authenticatie inschakelen voor snellere login?';

  @override
  String get enableBiometricDialogYes => 'Inschakelen';

  @override
  String get enableBiometricDialogNo => 'Niet nu';

  @override
  String get loginWithBiometric => 'Inloggen met biometrie';

  @override
  String get loginWithPassword => 'Inloggen met wachtwoord';

  @override
  String get biometric_login_title => 'Biometrische Login';

  @override
  String get enable_biometric_login => 'Biometrische Login Inschakelen';

  @override
  String get biometric_not_available =>
      'Biometrische authenticatie niet beschikbaar';

  @override
  String get use_password_instead => 'Gebruik wachtwoord in plaats daarvan';

  @override
  String get biometric_enroll_success => 'Biometrische login ingeschakeld';

  @override
  String get biometric_auth_failed => 'Biometrische authenticatie mislukt';

  @override
  String get smartFilterDialogTitle => 'Slim Filter';

  @override
  String get smartFilterHint => 'Beschrijf wat je wilt filteren...';

  @override
  String get smartFilterButtonLabel => 'Slim Filter Toepassen';

  @override
  String get smartFilterProcessing => 'Je verzoek wordt verwerkt...';

  @override
  String get smartFilterError =>
      'Slim filter toepassen mislukt. Probeer het opnieuw.';

  @override
  String get aiSuggestedFilterLabel => 'AI Voorgesteld Filter';

  @override
  String get smartFilterButtonTooltip => 'Gebruik AI om projecten te filteren';

  @override
  String get editFilterButtonLabel => 'Filter Bewerken';

  @override
  String get acceptFilterButtonLabel => 'Filter Accepteren';

  @override
  String get undoTooltip => 'Undo last dashboard change';

  @override
  String get redoTooltip => 'Redo last undone dashboard change';
}
