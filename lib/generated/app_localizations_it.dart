// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'App di gestione progetti';

  @override
  String get menuLabel => 'Menu';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Accedi';

  @override
  String get createAccount => 'Crea account';

  @override
  String get logoutTooltip => 'Esci';

  @override
  String get closeAppTooltip => 'Chiudi app';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsDisplaySection => 'Schermo';

  @override
  String get settingsDarkModeTitle => 'Modalita scura';

  @override
  String get settingsDarkModeSubtitle => 'Passa tra chiaro e scuro';

  @override
  String get settingsFollowSystemTitle => 'Segui tema di sistema';

  @override
  String get settingsFollowSystemSubtitle => 'Usa il tema del dispositivo';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsLanguageSubtitle => 'Scegli la lingua dell\'app';

  @override
  String get settingsNotificationsSection => 'Notifiche';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsNotificationsSubtitle => 'Aggiornamenti e promemoria';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsLocalFilesConsentTitle => 'Autorizzazione file locali';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Consenti all\'app di leggere i file locali del progetto per il contesto IA.';

  @override
  String get settingsUseProjectFilesTitle => 'Usa file del progetto';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Aggiungi file locali ai prompt IA';

  @override
  String get settingsProjectsSection => 'Progetti';

  @override
  String get settingsLogoutTitle => 'Esci';

  @override
  String get settingsLogoutSubtitle => 'Termina la sessione corrente';

  @override
  String get settingsExportTitle => 'Esporta progetti';

  @override
  String get settingsExportSubtitle => 'Esporta i progetti in un file';

  @override
  String get settingsImportTitle => 'Importa progetti';

  @override
  String get settingsImportSubtitle => 'Importa progetti da un file';

  @override
  String get settingsUsersSection => 'Utenti';

  @override
  String get settingsCurrentUserTitle => 'Utente corrente';

  @override
  String get settingsNotLoggedIn => 'Non connesso';

  @override
  String get settingsNoUsersFound => 'Nessun utente trovato.';

  @override
  String get settingsLocalUserLabel => 'Utente locale';

  @override
  String get settingsDeleteTooltip => 'Elimina';

  @override
  String get settingsLoadUsersFailed => 'Impossibile caricare gli utenti';

  @override
  String get settingsAddUserTitle => 'Aggiungi utente';

  @override
  String get settingsAddUserSubtitle => 'Aggiungi un account extra';

  @override
  String get logoutDialogTitle => 'Esci';

  @override
  String get logoutDialogContent => 'Vuoi davvero uscire?';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get logoutButton => 'Esci';

  @override
  String get loggedOutMessage => 'Sei uscito.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Esportazione completata: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Esportazione fallita: $error';
  }

  @override
  String get exportPasswordTitle => 'Cifrare esportazione';

  @override
  String get exportPasswordSubtitle =>
      'Imposta una password per cifrare i file di esportazione.';

  @override
  String get exportPasswordMismatch => 'Le password non corrispondono.';

  @override
  String get importSelectFilesMessage => 'Seleziona un file CSV e JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Importazione completata: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Importazione fallita: $error';
  }

  @override
  String get importFailedTitle => 'Importazione fallita';

  @override
  String get addUserDialogTitle => 'Aggiungi utente';

  @override
  String get saveButton => 'Salva';

  @override
  String get userAddedMessage => 'Utente aggiunto.';

  @override
  String get invalidUserMessage => 'Utente non valido.';

  @override
  String get deleteUserDialogTitle => 'Elimina utente';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Vuoi davvero eliminare $username?';
  }

  @override
  String get deleteButton => 'Elimina';

  @override
  String userDeletedMessage(Object username) {
    return 'Utente eliminato: $username';
  }

  @override
  String get projectsTitle => 'Progetti';

  @override
  String get newProjectButton => 'Nuovo progetto';

  @override
  String get noProjectsYet => 'Nessun progetto ancora';

  @override
  String get noProjectsFound => 'Nessun progetto trovato';

  @override
  String get loadingMoreProjects => 'Caricamento di altri progetti...';

  @override
  String get sortByLabel => 'Ordina per';

  @override
  String get projectSortName => 'Nome';

  @override
  String get projectSortProgress => 'Progresso';

  @override
  String get projectSortPriority => 'Priorita';

  @override
  String get projectSortCreatedDate => 'Created date';

  @override
  String get projectSortStatus => 'Status';

  @override
  String get allLabel => 'Tutti';

  @override
  String get loadProjectsFailed => 'Impossibile caricare i progetti.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Progetto $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Stato $status';
  }

  @override
  String get newProjectDialogTitle => 'Nuovo progetto';

  @override
  String get projectNameLabel => 'Nome del progetto';

  @override
  String get descriptionLabel => 'Descrizione';

  @override
  String get urgencyLabel => 'Urgenza';

  @override
  String get urgencyLow => 'Bassa';

  @override
  String get urgencyMedium => 'Media';

  @override
  String get urgencyHigh => 'Alta';

  @override
  String projectCreatedMessage(Object name) {
    return 'Progetto creato: $name';
  }

  @override
  String get projectDetailsTitle => 'Dettagli del progetto';

  @override
  String get aiChatWithProjectFilesTooltip => 'Chat IA con file del progetto';

  @override
  String get moreOptionsLabel => 'Altre opzioni';

  @override
  String get tasksTitle => 'Attivita';

  @override
  String get tasksTab => 'Attivita';

  @override
  String get detailsTab => 'Dettagli';

  @override
  String get tasksLoadFailed => 'Impossibile caricare le attivita.';

  @override
  String get projectOverviewTitle => 'Panoramica del progetto';

  @override
  String get tasksLoading => 'Caricamento attivita...';

  @override
  String get taskStatisticsTitle => 'Statistiche attivita';

  @override
  String get totalLabel => 'Totale';

  @override
  String get completedLabel => 'Completate';

  @override
  String get inProgressLabel => 'In corso';

  @override
  String get remainingLabel => 'Rimanenti';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% completato';
  }

  @override
  String get burndownChartTitle => 'Grafico burndown';

  @override
  String get chartPlaceholderTitle => 'Segnaposto grafico';

  @override
  String get chartPlaceholderSubtitle => 'Integrazione di fl_chart presto';

  @override
  String get workflowsTitle => 'Workflow';

  @override
  String get noWorkflowsAvailable => 'Nessun elemento di workflow disponibile.';

  @override
  String get taskStatusTodo => 'Da fare';

  @override
  String get taskStatusInProgress => 'In corso';

  @override
  String get taskStatusReview => 'Revisione';

  @override
  String get taskStatusDone => 'Fatto';

  @override
  String get workflowStatusActive => 'Attivo';

  @override
  String get workflowStatusPending => 'In attesa';

  @override
  String get noTasksYet => 'Nessuna attivita ancora';

  @override
  String get projectTimeTitle => 'Tempo del progetto';

  @override
  String urgencyValue(Object value) {
    return 'Urgenza: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Tempo registrato: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'min';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Cerca attivita...';

  @override
  String get searchAttachmentsHint => 'Cerca allegati...';

  @override
  String get clearSearchTooltip => 'Cancella ricerca';

  @override
  String get projectMapTitle => 'Cartella progetto';

  @override
  String get linkProjectMapButton => 'Collega cartella progetto';

  @override
  String get projectDataLoading => 'Caricamento dati progetto...';

  @override
  String get projectDataLoadFailed =>
      'Impossibile caricare i dati del progetto.';

  @override
  String currentMapLabel(Object path) {
    return 'Cartella corrente: $path';
  }

  @override
  String get noProjectMapLinked =>
      'Nessuna cartella collegata. Collega una cartella per leggere i file.';

  @override
  String get projectNotAvailable => 'Progetto non disponibile.';

  @override
  String get enableConsentInSettings =>
      'Abilita l\'autorizzazione nelle impostazioni.';

  @override
  String get projectMapLinked => 'Cartella progetto collegata.';

  @override
  String get privacyWarningTitle => 'Avviso privacy';

  @override
  String get privacyWarningContent =>
      'Attenzione: potrebbero essere letti dati sensibili.';

  @override
  String get continueButton => 'Continua';

  @override
  String get attachFilesTooltip => 'Allega file';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'Assistente IA';

  @override
  String get welcomeBack => 'Bentornato! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'Ecco una panoramica dei tuoi progetti attivi';

  @override
  String get recentWorkflowsTitle => 'Workflow recenti';

  @override
  String get recentWorkflowsLoading => 'Caricamento workflow recenti...';

  @override
  String get recentWorkflowsLoadFailed =>
      'Impossibile caricare i workflow recenti.';

  @override
  String get retryButton => 'Riprova';

  @override
  String get noRecentTasks => 'Nessuna attivita recente disponibile.';

  @override
  String get unknownProject => 'Progetto sconosciuto';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'Progetto $projectName, attivita $taskTitle, stato $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Attivita $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Proprio ora';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes min fa';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours ore fa';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days giorni fa';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks settimane fa';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months mesi fa';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return 'Grafico di avanzamento per $projectName. Completato $completedPercent per cento, in sospeso $pendingPercent per cento.';
  }

  @override
  String get progressLabel => 'Progresso';

  @override
  String completedPercentLabel(Object percent) {
    return 'Completato: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'In sospeso: $percent%';
  }

  @override
  String get noDescription => 'Nessuna descrizione';

  @override
  String get closeButton => 'Chiudi';

  @override
  String get burndownProgressTitle => 'Progresso burndown';

  @override
  String get actualProgressLabel => 'Progresso reale';

  @override
  String get idealTrendLabel => 'Tendenza ideale';

  @override
  String get statusLabel => 'Stato';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'Grafico burndown per $projectName. Punti reali: $actualPoints. Punti ideali: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'Chat IA';

  @override
  String get aiUsageTitle => 'Utilizzo IA';

  @override
  String get aiAssistantTitle => 'Assistente IA per progetti';

  @override
  String get clearChatTooltip => 'Cancella chat';

  @override
  String get noMessagesLabel => 'Nessun messaggio';

  @override
  String get aiEmptyTitle => 'Avvia una conversazione con l\'assistente IA';

  @override
  String get aiEmptySubtitle =>
      'Ad esempio: \"Genera un piano per il progetto: negozio web\"';

  @override
  String get useProjectFilesLabel => 'Usa i file del progetto';

  @override
  String get typeMessageHint => 'Scrivi un messaggio...';

  @override
  String get projectFilesReadFailed =>
      'Impossibile leggere i file del progetto.';

  @override
  String get aiResponseFailedTitle => 'Risposta IA fallita';

  @override
  String get sendMessageTooltip => 'Invia messaggio';

  @override
  String get loginMissingCredentials => 'Inserisci nome utente e password.';

  @override
  String get loginFailedMessage => 'Accesso fallito. Verifica le credenziali.';

  @override
  String get registerTitle => 'Registrati';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get languageSystem => 'Predefinita di sistema';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageDutch => 'Olandese';

  @override
  String get languageSpanish => 'Spagnolo';

  @override
  String get languageFrench => 'Francese';

  @override
  String get languageGerman => 'Tedesco';

  @override
  String get languagePortuguese => 'Portoghese';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageArabic => 'Arabo';

  @override
  String get languageChinese => 'Cinese';

  @override
  String get languageJapanese => 'Giapponese';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageRussian => 'Russo';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Ripeti password';

  @override
  String get passwordRulesTitle => 'Regole password';

  @override
  String get passwordRuleMinLength => 'Almeno 8 caratteri';

  @override
  String get passwordRuleHasLetter => 'Contiene una lettera';

  @override
  String get passwordRuleHasDigit => 'Contiene un numero';

  @override
  String get passwordRuleMatches => 'Le password corrispondono';

  @override
  String get registerButton => 'Registrati';

  @override
  String get registrationIssueUsernameMissing => 'nome utente mancante';

  @override
  String get registrationIssueMinLength => 'almeno 8 caratteri';

  @override
  String get registrationIssueLetter => 'almeno 1 lettera';

  @override
  String get registrationIssueDigit => 'almeno 1 numero';

  @override
  String get registrationIssueNoMatch => 'le password non corrispondono';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registrazione fallita: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Account creato. Accedi ora.';

  @override
  String get registerFailedMessage => 'Registrazione fallita.';

  @override
  String get accessDeniedMessage => 'Accesso negato.';

  @override
  String get adminPanelTitle => 'Pannello amministratore';

  @override
  String get adminPanelSubtitle => 'Gestisci ruoli, gruppi e permessi.';

  @override
  String get rolesTitle => 'Ruoli';

  @override
  String get noRolesFound => 'Nessun ruolo trovato.';

  @override
  String permissionsCount(Object count) {
    return 'Permessi: $count';
  }

  @override
  String get editPermissionsTooltip => 'Modifica permessi';

  @override
  String get groupsTitle => 'Gruppi';

  @override
  String get noGroupsFound => 'Nessun gruppo trovato.';

  @override
  String get roleLabel => 'Ruolo';

  @override
  String get groupAddTitle => 'Aggiungi gruppo';

  @override
  String get groupNameLabel => 'Nome del gruppo';

  @override
  String get groupLabel => 'Gruppo';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Aggiungi membro a $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Aggiungi membro';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Membri del gruppo: $groupName';
  }

  @override
  String get noGroupMembers => 'Nessun membro nel gruppo.';

  @override
  String get removeGroupMemberTooltip => 'Rimuovi membro';

  @override
  String get roleCreateTitle => 'Crea ruolo';

  @override
  String get roleNameLabel => 'Nome del ruolo';

  @override
  String get permissionsTitle => 'Permessi';

  @override
  String get settingsBackupTitle => 'Crea backup';

  @override
  String get settingsBackupSubtitle => 'Salva un backup locale dei dati Hive.';

  @override
  String get settingsRestoreTitle => 'Ripristina backup';

  @override
  String get settingsRestoreSubtitle =>
      'Sostituisci i dati locali con un file di backup.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Backup salvato: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Backup non riuscito: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Backup ripristinato. Riavvia l\'app per ricaricare i dati.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Ripristino non riuscito: $error';
  }

  @override
  String get restoreConfirmTitle => 'Ripristinare il backup?';

  @override
  String get restoreConfirmContent => 'Questo sovrascriverà i dati locali.';

  @override
  String get restoreConfirmButton => 'Ripristina';

  @override
  String get settingsBackupLastRunLabel => 'Ultimo backup';

  @override
  String get backupNeverMessage => 'Mai';

  @override
  String get backupNowButton => 'Esegui backup';

  @override
  String get settingsBackupPathLabel => 'File di backup';

  @override
  String get backupNoFileMessage => 'Nessun file di backup';

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
