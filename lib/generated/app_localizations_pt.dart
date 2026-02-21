// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Aplicativo de gestao de projetos';

  @override
  String get menuLabel => 'Menu';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get loginButton => 'Entrar';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get logoutTooltip => 'Sair';

  @override
  String get closeAppTooltip => 'Fechar app';

  @override
  String get settingsTitle => 'Configuracoes';

  @override
  String get settingsDisplaySection => 'Tela';

  @override
  String get settingsDarkModeTitle => 'Modo escuro';

  @override
  String get settingsDarkModeSubtitle => 'Alternar entre claro e escuro';

  @override
  String get settingsFollowSystemTitle => 'Seguir tema do sistema';

  @override
  String get settingsFollowSystemSubtitle => 'Usar o tema do dispositivo';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolher idioma do app';

  @override
  String get settingsNotificationsSection => 'Notificacoes';

  @override
  String get settingsNotificationsTitle => 'Notificacoes';

  @override
  String get settingsNotificationsSubtitle => 'Atualizacoes e lembretes';

  @override
  String get settingsPrivacySection => 'Privacidade';

  @override
  String get settingsLocalFilesConsentTitle => 'Permissao de arquivos locais';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Permitir que o app leia arquivos locais do projeto para contexto de IA.';

  @override
  String get settingsUseProjectFilesTitle => 'Usar arquivos do projeto';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Adicionar arquivos locais aos prompts de IA';

  @override
  String get settingsProjectsSection => 'Projetos';

  @override
  String get settingsLogoutTitle => 'Sair';

  @override
  String get settingsLogoutSubtitle => 'Encerrar a sessao atual';

  @override
  String get settingsExportTitle => 'Exportar projetos';

  @override
  String get settingsExportSubtitle => 'Exportar projetos para um arquivo';

  @override
  String get settingsImportTitle => 'Importar projetos';

  @override
  String get settingsImportSubtitle => 'Importar projetos de um arquivo';

  @override
  String get settingsUsersSection => 'Usuarios';

  @override
  String get settingsCurrentUserTitle => 'Usuario atual';

  @override
  String get settingsNotLoggedIn => 'Nao conectado';

  @override
  String get settingsNoUsersFound => 'Nenhum usuario encontrado.';

  @override
  String get settingsLocalUserLabel => 'Usuario local';

  @override
  String get settingsDeleteTooltip => 'Excluir';

  @override
  String get settingsLoadUsersFailed => 'Falha ao carregar usuarios';

  @override
  String get settingsAddUserTitle => 'Adicionar usuario';

  @override
  String get settingsAddUserSubtitle => 'Adicionar uma conta extra';

  @override
  String get logoutDialogTitle => 'Sair';

  @override
  String get logoutDialogContent => 'Deseja realmente sair?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get logoutButton => 'Sair';

  @override
  String get loggedOutMessage => 'Voce saiu.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Exportacao concluida: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Exportacao falhou: $error';
  }

  @override
  String get exportPasswordTitle => 'Criptografar exportacao';

  @override
  String get exportPasswordSubtitle =>
      'Defina uma senha para criptografar os arquivos de exportacao.';

  @override
  String get exportPasswordMismatch => 'As senhas nao correspondem.';

  @override
  String get importSelectFilesMessage => 'Selecione um arquivo CSV e JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Importacao concluida: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Importacao falhou: $error';
  }

  @override
  String get importFailedTitle => 'Importacao falhou';

  @override
  String get addUserDialogTitle => 'Adicionar usuario';

  @override
  String get saveButton => 'Salvar';

  @override
  String get userAddedMessage => 'Usuario adicionado.';

  @override
  String get invalidUserMessage => 'Usuario invalido.';

  @override
  String get deleteUserDialogTitle => 'Excluir usuario';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Deseja realmente excluir $username?';
  }

  @override
  String get deleteButton => 'Excluir';

  @override
  String userDeletedMessage(Object username) {
    return 'Usuario excluido: $username';
  }

  @override
  String get projectsTitle => 'Projetos';

  @override
  String get newProjectButton => 'Novo projeto';

  @override
  String get noProjectsYet => 'Ainda nao ha projetos';

  @override
  String get noProjectsFound => 'Nenhum projeto encontrado';

  @override
  String get loadingMoreProjects => 'Carregando mais projetos...';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get projectSortName => 'Nome';

  @override
  String get projectSortProgress => 'Progresso';

  @override
  String get projectSortPriority => 'Prioridade';

  @override
  String get projectSortCreatedDate => 'Data de criação';

  @override
  String get projectSortStatus => 'Status';

  @override
  String get projectSortStartDate => 'Data de início';

  @override
  String get projectSortDueDate => 'Data de vencimento';

  @override
  String get sortDirectionLabel => 'Direção';

  @override
  String get sortAscendingLabel => 'Crescente';

  @override
  String get sortDescendingLabel => 'Decrescente';

  @override
  String get exportToCsvLabel => 'Exportar para CSV';

  @override
  String get csvExportSuccessMessage =>
      'CSV exportado e compartilhado com sucesso';

  @override
  String get allLabel => 'Todos';

  @override
  String get loadProjectsFailed => 'Falha ao carregar projetos.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Projeto $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Status $status';
  }

  @override
  String get newProjectDialogTitle => 'Novo projeto';

  @override
  String get projectNameLabel => 'Nome do projeto';

  @override
  String get descriptionLabel => 'Descricao';

  @override
  String get urgencyLabel => 'Urgencia';

  @override
  String get urgencyLow => 'Baixa';

  @override
  String get urgencyMedium => 'Media';

  @override
  String get urgencyHigh => 'Alta';

  @override
  String projectCreatedMessage(Object name) {
    return 'Projeto criado: $name';
  }

  @override
  String get projectDetailsTitle => 'Detalhes do projeto';

  @override
  String get aiChatWithProjectFilesTooltip =>
      'Chat de IA com arquivos do projeto';

  @override
  String get moreOptionsLabel => 'Mais opcoes';

  @override
  String get tasksTitle => 'Tarefas';

  @override
  String get tasksTab => 'Tarefas';

  @override
  String get detailsTab => 'Detalhes';

  @override
  String get tasksLoadFailed => 'Falha ao carregar tarefas.';

  @override
  String get projectOverviewTitle => 'Resumo do projeto';

  @override
  String get tasksLoading => 'Carregando tarefas...';

  @override
  String get taskStatisticsTitle => 'Estatisticas de tarefas';

  @override
  String get totalLabel => 'Total';

  @override
  String get completedLabel => 'Concluidas';

  @override
  String get inProgressLabel => 'Em andamento';

  @override
  String get remainingLabel => 'Restantes';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% concluido';
  }

  @override
  String get burndownChartTitle => 'Grafico burndown';

  @override
  String get chartPlaceholderTitle => 'Espaco reservado para grafico';

  @override
  String get chartPlaceholderSubtitle => 'Integracao do fl_chart em breve';

  @override
  String get workflowsTitle => 'Fluxos de trabalho';

  @override
  String get noWorkflowsAvailable => 'Nenhum item de fluxo disponivel.';

  @override
  String get taskStatusTodo => 'A fazer';

  @override
  String get taskStatusInProgress => 'Em andamento';

  @override
  String get taskStatusReview => 'Revisao';

  @override
  String get taskStatusDone => 'Concluido';

  @override
  String get workflowStatusActive => 'Ativo';

  @override
  String get workflowStatusPending => 'Pendente';

  @override
  String get noTasksYet => 'Ainda nao ha tarefas';

  @override
  String get projectTimeTitle => 'Tempo do projeto';

  @override
  String urgencyValue(Object value) {
    return 'Urgencia: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Tempo registrado: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'min';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Buscar tarefas...';

  @override
  String get searchAttachmentsHint => 'Buscar anexos...';

  @override
  String get clearSearchTooltip => 'Limpar busca';

  @override
  String get projectMapTitle => 'Pasta do projeto';

  @override
  String get linkProjectMapButton => 'Vincular pasta do projeto';

  @override
  String get projectDataLoading => 'Carregando dados do projeto...';

  @override
  String get projectDataLoadFailed => 'Falha ao carregar dados do projeto.';

  @override
  String currentMapLabel(Object path) {
    return 'Pasta atual: $path';
  }

  @override
  String get noProjectMapLinked =>
      'Nenhuma pasta vinculada. Vincule uma pasta para ler arquivos.';

  @override
  String get projectNotAvailable => 'Projeto nao disponivel.';

  @override
  String get enableConsentInSettings => 'Ative a permissao nas configuracoes.';

  @override
  String get projectMapLinked => 'Pasta do projeto vinculada.';

  @override
  String get privacyWarningTitle => 'Aviso de privacidade';

  @override
  String get privacyWarningContent => 'Aviso: dados sensiveis podem ser lidos.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get attachFilesTooltip => 'Anexar arquivos';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'Assistente de IA';

  @override
  String get welcomeBack => 'Bem-vindo de volta! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'Aqui esta um resumo dos seus projetos ativos';

  @override
  String get recentWorkflowsTitle => 'Fluxos recentes';

  @override
  String get recentWorkflowsLoading => 'Carregando fluxos recentes...';

  @override
  String get recentWorkflowsLoadFailed => 'Falha ao carregar fluxos recentes.';

  @override
  String get retryButton => 'Tentar novamente';

  @override
  String get noRecentTasks => 'Nenhuma tarefa recente disponivel.';

  @override
  String get unknownProject => 'Projeto desconhecido';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'Projeto $projectName, tarefa $taskTitle, status $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Tarefa $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Agora mesmo';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'Ha $minutes min';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'Ha $hours h';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'Ha $days dias';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return 'Ha $weeks semanas';
  }

  @override
  String timeMonthsAgo(Object months) {
    return 'Ha $months meses';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return 'Grafico de progresso do projeto para $projectName. Concluido $completedPercent por cento, pendente $pendingPercent por cento.';
  }

  @override
  String get progressLabel => 'Progresso';

  @override
  String completedPercentLabel(Object percent) {
    return 'Concluido: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'Pendente: $percent%';
  }

  @override
  String get noDescription => 'Sem descricao';

  @override
  String get closeButton => 'Fechar';

  @override
  String get burndownProgressTitle => 'Progresso burndown';

  @override
  String get actualProgressLabel => 'Progresso real';

  @override
  String get idealTrendLabel => 'Tendencia ideal';

  @override
  String get statusLabel => 'Status';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'Grafico burndown para $projectName. Pontos reais: $actualPoints. Pontos ideais: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'Chat de IA';

  @override
  String get aiAssistantTitle => 'Assistente de projetos IA';

  @override
  String get clearChatTooltip => 'Limpar chat';

  @override
  String get noMessagesLabel => 'Nenhuma mensagem';

  @override
  String get aiEmptyTitle => 'Inicie uma conversa com o assistente de IA';

  @override
  String get aiEmptySubtitle =>
      'Por exemplo: \"Gere um plano para o projeto: loja web\"';

  @override
  String get useProjectFilesLabel => 'Usar arquivos do projeto';

  @override
  String get typeMessageHint => 'Digite uma mensagem...';

  @override
  String get projectFilesReadFailed => 'Falha ao ler arquivos do projeto.';

  @override
  String get aiResponseFailedTitle => 'Resposta da IA falhou';

  @override
  String get sendMessageTooltip => 'Enviar mensagem';

  @override
  String get loginMissingCredentials => 'Informe usuario e senha.';

  @override
  String get loginFailedMessage =>
      'Falha ao entrar. Verifique suas credenciais.';

  @override
  String get registerTitle => 'Registrar';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Padrao do sistema';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get languageDutch => 'Holandes';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Frances';

  @override
  String get languageGerman => 'Alemao';

  @override
  String get languagePortuguese => 'Portugues';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get languageChinese => 'Chines';

  @override
  String get languageJapanese => 'Japones';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageRussian => 'Russo';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Repetir senha';

  @override
  String get passwordRulesTitle => 'Regras de senha';

  @override
  String get passwordRuleMinLength => 'Pelo menos 8 caracteres';

  @override
  String get passwordRuleHasLetter => 'Contem uma letra';

  @override
  String get passwordRuleHasDigit => 'Contem um numero';

  @override
  String get passwordRuleMatches => 'As senhas coincidem';

  @override
  String get registerButton => 'Registrar';

  @override
  String get registrationIssueUsernameMissing => 'falta usuario';

  @override
  String get registrationIssueMinLength => 'minimo 8 caracteres';

  @override
  String get registrationIssueLetter => 'pelo menos 1 letra';

  @override
  String get registrationIssueDigit => 'pelo menos 1 numero';

  @override
  String get registrationIssueNoMatch => 'as senhas nao coincidem';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registro falhou: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Conta criada. Entre agora.';

  @override
  String get registerFailedMessage => 'Registro falhou.';

  @override
  String get accessDeniedMessage => 'Acesso negado.';

  @override
  String get adminPanelTitle => 'Painel de administração';

  @override
  String get adminPanelSubtitle => 'Gerencie funções, grupos e permissões.';

  @override
  String get rolesTitle => 'Funções';

  @override
  String get noRolesFound => 'Nenhuma função encontrada.';

  @override
  String permissionsCount(Object count) {
    return 'Permissões: $count';
  }

  @override
  String get editPermissionsTooltip => 'Editar permissões';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get noGroupsFound => 'Nenhum grupo encontrado.';

  @override
  String get roleLabel => 'Função';

  @override
  String get groupAddTitle => 'Adicionar grupo';

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String get groupLabel => 'Grupo';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Adicionar membro a $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Adicionar membro';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Membros do grupo: $groupName';
  }

  @override
  String get noGroupMembers => 'Nenhum membro no grupo.';

  @override
  String get removeGroupMemberTooltip => 'Remover membro';

  @override
  String get roleCreateTitle => 'Criar função';

  @override
  String get roleNameLabel => 'Nome da função';

  @override
  String get permissionsTitle => 'Permissões';

  @override
  String get settingsBackupTitle => 'Criar backup';

  @override
  String get settingsBackupSubtitle =>
      'Salvar um backup local dos dados do Hive.';

  @override
  String get settingsRestoreTitle => 'Restaurar backup';

  @override
  String get settingsRestoreSubtitle =>
      'Substituir os dados locais por um arquivo de backup.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Backup salvo: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Backup falhou: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Backup restaurado. Reinicie o app para recarregar os dados.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Falha na restauração: $error';
  }

  @override
  String get restoreConfirmTitle => 'Restaurar backup?';

  @override
  String get restoreConfirmContent => 'Isso substituirá os dados locais.';

  @override
  String get restoreConfirmButton => 'Restaurar';

  @override
  String get settingsBackupLastRunLabel => 'Último backup';

  @override
  String get backupNeverMessage => 'Nunca';

  @override
  String get backupNowButton => 'Fazer backup agora';

  @override
  String get settingsBackupPathLabel => 'Arquivo de backup';

  @override
  String get backupNoFileMessage => 'Ainda não há arquivo de backup';

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
}
