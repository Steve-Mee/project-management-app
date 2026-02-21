// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Application de gestion de projet';

  @override
  String get menuLabel => 'Menu';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get usernameLabel => 'Nom d\'utilisateur';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get createAccount => 'Creer un compte';

  @override
  String get logoutTooltip => 'Se deconnecter';

  @override
  String get closeAppTooltip => 'Fermer l\'application';

  @override
  String get settingsTitle => 'Parametres';

  @override
  String get settingsDisplaySection => 'Affichage';

  @override
  String get settingsDarkModeTitle => 'Mode sombre';

  @override
  String get settingsDarkModeSubtitle => 'Basculer entre clair et sombre';

  @override
  String get settingsFollowSystemTitle => 'Suivre le theme du systeme';

  @override
  String get settingsFollowSystemSubtitle => 'Utiliser le theme de l\'appareil';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisir la langue de l\'application';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Mises a jour et rappels';

  @override
  String get settingsPrivacySection => 'Confidentialite';

  @override
  String get settingsLocalFilesConsentTitle => 'Autorisation de fichiers locaux';

  @override
  String get settingsLocalFilesConsentSubtitle => 'Autoriser l\'application a lire les fichiers locaux du projet pour le contexte IA.';

  @override
  String get settingsUseProjectFilesTitle => 'Utiliser les fichiers du projet';

  @override
  String get settingsUseProjectFilesSubtitle => 'Ajouter des fichiers locaux aux invites IA';

  @override
  String get settingsProjectsSection => 'Projets';

  @override
  String get settingsLogoutTitle => 'Se deconnecter';

  @override
  String get settingsLogoutSubtitle => 'Mettre fin a la session actuelle';

  @override
  String get settingsExportTitle => 'Exporter les projets';

  @override
  String get settingsExportSubtitle => 'Exporter les projets vers un fichier';

  @override
  String get settingsImportTitle => 'Importer des projets';

  @override
  String get settingsImportSubtitle => 'Importer des projets depuis un fichier';

  @override
  String get settingsUsersSection => 'Utilisateurs';

  @override
  String get settingsCurrentUserTitle => 'Utilisateur actuel';

  @override
  String get settingsNotLoggedIn => 'Non connecte';

  @override
  String get settingsNoUsersFound => 'Aucun utilisateur trouve.';

  @override
  String get settingsLocalUserLabel => 'Utilisateur local';

  @override
  String get settingsDeleteTooltip => 'Supprimer';

  @override
  String get settingsLoadUsersFailed => 'Echec du chargement des utilisateurs';

  @override
  String get settingsAddUserTitle => 'Ajouter un utilisateur';

  @override
  String get settingsAddUserSubtitle => 'Ajouter un compte supplementaire';

  @override
  String get logoutDialogTitle => 'Se deconnecter';

  @override
  String get logoutDialogContent => 'Voulez-vous vraiment vous deconnecter ?';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get logoutButton => 'Se deconnecter';

  @override
  String get loggedOutMessage => 'Vous avez ete deconnecte.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Export termine : $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Echec de l\'export : $error';
  }

  @override
  String get exportPasswordTitle => 'Chiffrer l\'export';

  @override
  String get exportPasswordSubtitle => 'Definissez un mot de passe pour chiffrer les fichiers d\'export.';

  @override
  String get exportPasswordMismatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get importSelectFilesMessage => 'Selectionnez un fichier CSV et JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Import termine : $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Echec de l\'import : $error';
  }

  @override
  String get importFailedTitle => 'Echec de l\'import';

  @override
  String get addUserDialogTitle => 'Ajouter un utilisateur';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get userAddedMessage => 'Utilisateur ajoute.';

  @override
  String get invalidUserMessage => 'Utilisateur invalide.';

  @override
  String get deleteUserDialogTitle => 'Supprimer l\'utilisateur';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Voulez-vous vraiment supprimer $username ?';
  }

  @override
  String get deleteButton => 'Supprimer';

  @override
  String userDeletedMessage(Object username) {
    return 'Utilisateur supprime : $username';
  }

  @override
  String get projectsTitle => 'Projets';

  @override
  String get newProjectButton => 'Nouveau projet';

  @override
  String get noProjectsYet => 'Aucun projet pour l\'instant';

  @override
  String get noProjectsFound => 'Aucun projet trouve';

  @override
  String get loadingMoreProjects => 'Chargement de plus de projets...';

  @override
  String get sortByLabel => 'Trier par';

  @override
  String get projectSortName => 'Nom';

  @override
  String get projectSortProgress => 'Progression';

  @override
  String get projectSortPriority => 'Priorite';

  @override
  String get projectSortCreatedDate => 'Created date';

  @override
  String get projectSortStatus => 'Status';

  @override
  String get allLabel => 'Tous';

  @override
  String get loadProjectsFailed => 'Echec du chargement des projets.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Projet $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Statut $status';
  }

  @override
  String get newProjectDialogTitle => 'Nouveau projet';

  @override
  String get projectNameLabel => 'Nom du projet';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get urgencyLabel => 'Urgence';

  @override
  String get urgencyLow => 'Basse';

  @override
  String get urgencyMedium => 'Moyenne';

  @override
  String get urgencyHigh => 'Elevee';

  @override
  String projectCreatedMessage(Object name) {
    return 'Projet cree : $name';
  }

  @override
  String get projectDetailsTitle => 'Details du projet';

  @override
  String get aiChatWithProjectFilesTooltip => 'Chat IA avec les fichiers du projet';

  @override
  String get moreOptionsLabel => 'Plus d\'options';

  @override
  String get tasksTitle => 'Taches';

  @override
  String get tasksTab => 'Taches';

  @override
  String get detailsTab => 'Details';

  @override
  String get tasksLoadFailed => 'Echec du chargement des taches.';

  @override
  String get projectOverviewTitle => 'Apercu du projet';

  @override
  String get tasksLoading => 'Chargement des taches...';

  @override
  String get taskStatisticsTitle => 'Statistiques des taches';

  @override
  String get totalLabel => 'Total';

  @override
  String get completedLabel => 'Terminees';

  @override
  String get inProgressLabel => 'En cours';

  @override
  String get remainingLabel => 'Restantes';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% termine';
  }

  @override
  String get burndownChartTitle => 'Graphique burndown';

  @override
  String get chartPlaceholderTitle => 'Espace reserve au graphique';

  @override
  String get chartPlaceholderSubtitle => 'Integration de fl_chart bientot';

  @override
  String get workflowsTitle => 'Flux de travail';

  @override
  String get noWorkflowsAvailable => 'Aucun element de flux disponible.';

  @override
  String get taskStatusTodo => 'A faire';

  @override
  String get taskStatusInProgress => 'En cours';

  @override
  String get taskStatusReview => 'Revue';

  @override
  String get taskStatusDone => 'Termine';

  @override
  String get workflowStatusActive => 'Actif';

  @override
  String get workflowStatusPending => 'En attente';

  @override
  String get noTasksYet => 'Aucune tache pour l\'instant';

  @override
  String get projectTimeTitle => 'Temps du projet';

  @override
  String urgencyValue(Object value) {
    return 'Urgence : $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Temps suivi : $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'min';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Rechercher des taches...';

  @override
  String get searchAttachmentsHint => 'Rechercher des pieces jointes...';

  @override
  String get clearSearchTooltip => 'Effacer la recherche';

  @override
  String get projectMapTitle => 'Dossier du projet';

  @override
  String get linkProjectMapButton => 'Lier le dossier du projet';

  @override
  String get projectDataLoading => 'Chargement des donnees du projet...';

  @override
  String get projectDataLoadFailed => 'Echec du chargement des donnees du projet.';

  @override
  String currentMapLabel(Object path) {
    return 'Dossier actuel : $path';
  }

  @override
  String get noProjectMapLinked => 'Aucun dossier lie. Liez un dossier pour lire les fichiers.';

  @override
  String get projectNotAvailable => 'Projet non disponible.';

  @override
  String get enableConsentInSettings => 'Activez l\'autorisation dans les parametres.';

  @override
  String get projectMapLinked => 'Dossier du projet lie.';

  @override
  String get privacyWarningTitle => 'Avertissement de confidentialite';

  @override
  String get privacyWarningContent => 'Avertissement : des donnees sensibles peuvent etre lues.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get attachFilesTooltip => 'Joindre des fichiers';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'Assistant IA';

  @override
  String get welcomeBack => 'Bon retour ! 👋';

  @override
  String get projectsOverviewSubtitle => 'Voici un apercu de vos projets actifs';

  @override
  String get recentWorkflowsTitle => 'Flux recents';

  @override
  String get recentWorkflowsLoading => 'Chargement des flux recents...';

  @override
  String get recentWorkflowsLoadFailed => 'Echec du chargement des flux recents.';

  @override
  String get retryButton => 'Reessayer';

  @override
  String get noRecentTasks => 'Aucune tache recente disponible.';

  @override
  String get unknownProject => 'Projet inconnu';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle, Object statusLabel, Object timeLabel) {
    return 'Projet $projectName, tache $taskTitle, statut $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Tache $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'A l\'instant';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'Il y a $hours h';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'Il y a $days jours';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return 'Il y a $weeks semaines';
  }

  @override
  String timeMonthsAgo(Object months) {
    return 'Il y a $months mois';
  }

  @override
  String projectProgressChartSemantics(Object projectName, Object completedPercent, Object pendingPercent) {
    return 'Graphique de progression pour $projectName. Termine $completedPercent pour cent, en attente $pendingPercent pour cent.';
  }

  @override
  String get progressLabel => 'Progression';

  @override
  String completedPercentLabel(Object percent) {
    return 'Termine : $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'En attente : $percent%';
  }

  @override
  String get noDescription => 'Aucune description';

  @override
  String get closeButton => 'Fermer';

  @override
  String get burndownProgressTitle => 'Progression burndown';

  @override
  String get actualProgressLabel => 'Progression reelle';

  @override
  String get idealTrendLabel => 'Tendance ideale';

  @override
  String get statusLabel => 'Statut';

  @override
  String burndownChartSemantics(Object projectName, Object actualPoints, Object idealPoints) {
    return 'Graphique burndown pour $projectName. Points reels : $actualPoints. Points ideaux : $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'Chat IA';

  @override
  String get aiUsageTitle => 'Utilisation IA';

  @override
  String get aiAssistantTitle => 'Assistant de projet IA';

  @override
  String get clearChatTooltip => 'Effacer le chat';

  @override
  String get noMessagesLabel => 'Aucun message';

  @override
  String get aiEmptyTitle => 'Lancez une conversation avec l\'assistant IA';

  @override
  String get aiEmptySubtitle => 'Par exemple : \"Genere un plan pour le projet : boutique web\"';

  @override
  String get useProjectFilesLabel => 'Utiliser les fichiers du projet';

  @override
  String get typeMessageHint => 'Tapez un message...';

  @override
  String get projectFilesReadFailed => 'Echec de lecture des fichiers du projet.';

  @override
  String get aiResponseFailedTitle => 'Echec de la reponse IA';

  @override
  String get sendMessageTooltip => 'Envoyer le message';

  @override
  String get loginMissingCredentials => 'Entrez le nom d\'utilisateur et le mot de passe.';

  @override
  String get loginFailedMessage => 'Echec de connexion. Verifiez vos identifiants.';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageSystem => 'Par defaut du systeme';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageDutch => 'Neerlandais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Francais';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get languageChinese => 'Chinois';

  @override
  String get languageJapanese => 'Japonais';

  @override
  String get languageKorean => 'Coreen';

  @override
  String get languageRussian => 'Russe';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Repeter le mot de passe';

  @override
  String get passwordRulesTitle => 'Regles du mot de passe';

  @override
  String get passwordRuleMinLength => 'Au moins 8 caracteres';

  @override
  String get passwordRuleHasLetter => 'Contient une lettre';

  @override
  String get passwordRuleHasDigit => 'Contient un chiffre';

  @override
  String get passwordRuleMatches => 'Les mots de passe correspondent';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get registrationIssueUsernameMissing => 'nom d\'utilisateur manquant';

  @override
  String get registrationIssueMinLength => 'au moins 8 caracteres';

  @override
  String get registrationIssueLetter => 'au moins 1 lettre';

  @override
  String get registrationIssueDigit => 'au moins 1 chiffre';

  @override
  String get registrationIssueNoMatch => 'les mots de passe ne correspondent pas';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Inscription echouee : $issues.';
  }

  @override
  String get accountCreatedMessage => 'Compte cree. Connectez-vous maintenant.';

  @override
  String get registerFailedMessage => 'Inscription echouee.';

  @override
  String get accessDeniedMessage => 'Accès refusé.';

  @override
  String get adminPanelTitle => 'Panneau d\'administration';

  @override
  String get adminPanelSubtitle => 'Gérer les rôles, groupes et autorisations.';

  @override
  String get rolesTitle => 'Rôles';

  @override
  String get noRolesFound => 'Aucun rôle trouvé.';

  @override
  String permissionsCount(Object count) {
    return 'Autorisations : $count';
  }

  @override
  String get editPermissionsTooltip => 'Modifier les autorisations';

  @override
  String get groupsTitle => 'Groupes';

  @override
  String get noGroupsFound => 'Aucun groupe trouvé.';

  @override
  String get roleLabel => 'Rôle';

  @override
  String get groupAddTitle => 'Ajouter un groupe';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String get groupLabel => 'Groupe';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Ajouter un membre à $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Ajouter un membre';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Membres du groupe : $groupName';
  }

  @override
  String get noGroupMembers => 'Aucun membre dans le groupe.';

  @override
  String get removeGroupMemberTooltip => 'Retirer le membre';

  @override
  String get roleCreateTitle => 'Créer un rôle';

  @override
  String get roleNameLabel => 'Nom du rôle';

  @override
  String get permissionsTitle => 'Autorisations';

  @override
  String get settingsBackupTitle => 'Créer une sauvegarde';

  @override
  String get settingsBackupSubtitle => 'Enregistrer une sauvegarde locale des données Hive.';

  @override
  String get settingsRestoreTitle => 'Restaurer une sauvegarde';

  @override
  String get settingsRestoreSubtitle => 'Remplacer les données locales par un fichier de sauvegarde.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Sauvegarde enregistrée : $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Échec de la sauvegarde : $error';
  }

  @override
  String get restoreSuccessMessage => 'Sauvegarde restaurée. Redémarrez l\'app pour recharger les données.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get restoreConfirmTitle => 'Restaurer la sauvegarde ?';

  @override
  String get restoreConfirmContent => 'Cela remplacera les données locales.';

  @override
  String get restoreConfirmButton => 'Restaurer';

  @override
  String get settingsBackupLastRunLabel => 'Dernière sauvegarde';

  @override
  String get backupNeverMessage => 'Jamais';

  @override
  String get backupNowButton => 'Sauvegarder maintenant';

  @override
  String get settingsBackupPathLabel => 'Fichier de sauvegarde';

  @override
  String get backupNoFileMessage => 'Aucun fichier de sauvegarde pour l\'instant';

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
  String get noProjectsMatchFiltersSubtitle => 'Try changing or clearing your filters';

  @override
  String get clearAllFiltersButtonLabel => 'Clear All Filters';
}
