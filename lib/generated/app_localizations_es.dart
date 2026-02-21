// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aplicacion de gestion de proyectos';

  @override
  String get menuLabel => 'Menú';

  @override
  String get loginTitle => 'Iniciar sesion';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Contrasena';

  @override
  String get loginButton => 'Iniciar sesion';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get logoutTooltip => 'Cerrar sesion';

  @override
  String get closeAppTooltip => 'Cerrar app';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsDisplaySection => 'Pantalla';

  @override
  String get settingsDarkModeTitle => 'Modo oscuro';

  @override
  String get settingsDarkModeSubtitle => 'Cambiar entre claro y oscuro';

  @override
  String get settingsFollowSystemTitle => 'Seguir tema del sistema';

  @override
  String get settingsFollowSystemSubtitle => 'Usar el tema del dispositivo';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elegir el idioma de la app';

  @override
  String get settingsNotificationsSection => 'Notificaciones';

  @override
  String get settingsNotificationsTitle => 'Notificaciones';

  @override
  String get settingsNotificationsSubtitle => 'Actualizaciones y recordatorios';

  @override
  String get settingsPrivacySection => 'Privacidad';

  @override
  String get settingsLocalFilesConsentTitle => 'Permiso de archivos locales';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Permitir a la app leer archivos locales del proyecto para contexto de IA.';

  @override
  String get settingsUseProjectFilesTitle => 'Usar archivos del proyecto';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Agregar archivos locales a los prompts de IA';

  @override
  String get settingsProjectsSection => 'Proyectos';

  @override
  String get settingsLogoutTitle => 'Cerrar sesion';

  @override
  String get settingsLogoutSubtitle => 'Finalizar la sesion actual';

  @override
  String get settingsExportTitle => 'Exportar proyectos';

  @override
  String get settingsExportSubtitle => 'Exportar proyectos a un archivo';

  @override
  String get settingsImportTitle => 'Importar proyectos';

  @override
  String get settingsImportSubtitle => 'Importar proyectos desde un archivo';

  @override
  String get settingsUsersSection => 'Usuarios';

  @override
  String get settingsCurrentUserTitle => 'Usuario actual';

  @override
  String get settingsNotLoggedIn => 'No has iniciado sesion';

  @override
  String get settingsNoUsersFound => 'No se encontraron usuarios.';

  @override
  String get settingsLocalUserLabel => 'Usuario local';

  @override
  String get settingsDeleteTooltip => 'Eliminar';

  @override
  String get settingsLoadUsersFailed => 'No se pudieron cargar los usuarios';

  @override
  String get settingsAddUserTitle => 'Agregar usuario';

  @override
  String get settingsAddUserSubtitle => 'Agregar una cuenta adicional';

  @override
  String get logoutDialogTitle => 'Cerrar sesion';

  @override
  String get logoutDialogContent => '¿Seguro que deseas cerrar sesion?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get logoutButton => 'Cerrar sesion';

  @override
  String get loggedOutMessage => 'Has cerrado sesion.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Exportacion completa: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'La exportacion fallo: $error';
  }

  @override
  String get exportPasswordTitle => 'Cifrar exportacion';

  @override
  String get exportPasswordSubtitle =>
      'Establece una contrasena para cifrar los archivos de exportacion.';

  @override
  String get exportPasswordMismatch => 'Las contrasenas no coinciden.';

  @override
  String get importSelectFilesMessage => 'Selecciona un archivo CSV y JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Importacion completa: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'La importacion fallo: $error';
  }

  @override
  String get importFailedTitle => 'Importacion fallida';

  @override
  String get addUserDialogTitle => 'Agregar usuario';

  @override
  String get saveButton => 'Guardar';

  @override
  String get userAddedMessage => 'Usuario agregado.';

  @override
  String get invalidUserMessage => 'Usuario invalido.';

  @override
  String get deleteUserDialogTitle => 'Eliminar usuario';

  @override
  String deleteUserDialogContent(Object username) {
    return '¿Seguro que deseas eliminar a $username?';
  }

  @override
  String get deleteButton => 'Eliminar';

  @override
  String userDeletedMessage(Object username) {
    return 'Usuario eliminado: $username';
  }

  @override
  String get projectsTitle => 'Proyectos';

  @override
  String get newProjectButton => 'Nuevo proyecto';

  @override
  String get noProjectsYet => 'Aun no hay proyectos';

  @override
  String get noProjectsFound => 'No se encontraron proyectos';

  @override
  String get loadingMoreProjects => 'Cargando mas proyectos...';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get projectSortName => 'Nombre';

  @override
  String get projectSortProgress => 'Progreso';

  @override
  String get projectSortPriority => 'Prioridad';

  @override
  String get projectSortCreatedDate => 'Fecha de creación';

  @override
  String get projectSortStatus => 'Estado';

  @override
  String get allLabel => 'Todos';

  @override
  String get loadProjectsFailed => 'No se pudieron cargar los proyectos.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Proyecto $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Estado $status';
  }

  @override
  String get newProjectDialogTitle => 'Nuevo proyecto';

  @override
  String get projectNameLabel => 'Nombre del proyecto';

  @override
  String get descriptionLabel => 'Descripcion';

  @override
  String get urgencyLabel => 'Urgencia';

  @override
  String get urgencyLow => 'Baja';

  @override
  String get urgencyMedium => 'Media';

  @override
  String get urgencyHigh => 'Alta';

  @override
  String projectCreatedMessage(Object name) {
    return 'Proyecto creado: $name';
  }

  @override
  String get projectDetailsTitle => 'Detalles del proyecto';

  @override
  String get aiChatWithProjectFilesTooltip =>
      'Chat de IA con archivos del proyecto';

  @override
  String get moreOptionsLabel => 'Mas opciones';

  @override
  String get tasksTitle => 'Tareas';

  @override
  String get tasksTab => 'Tareas';

  @override
  String get detailsTab => 'Detalles';

  @override
  String get tasksLoadFailed => 'No se pudieron cargar las tareas.';

  @override
  String get projectOverviewTitle => 'Resumen del proyecto';

  @override
  String get tasksLoading => 'Cargando tareas...';

  @override
  String get taskStatisticsTitle => 'Estadisticas de tareas';

  @override
  String get totalLabel => 'Total';

  @override
  String get completedLabel => 'Completadas';

  @override
  String get inProgressLabel => 'En progreso';

  @override
  String get remainingLabel => 'Restantes';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% completado';
  }

  @override
  String get burndownChartTitle => 'Grafico burndown';

  @override
  String get chartPlaceholderTitle => 'Marcador de grafico';

  @override
  String get chartPlaceholderSubtitle => 'Integracion de fl_chart pronto';

  @override
  String get workflowsTitle => 'Flujos de trabajo';

  @override
  String get noWorkflowsAvailable => 'No hay elementos de flujo disponibles.';

  @override
  String get taskStatusTodo => 'Por hacer';

  @override
  String get taskStatusInProgress => 'En progreso';

  @override
  String get taskStatusReview => 'Revision';

  @override
  String get taskStatusDone => 'Hecho';

  @override
  String get workflowStatusActive => 'Activo';

  @override
  String get workflowStatusPending => 'Pendiente';

  @override
  String get noTasksYet => 'Aun no hay tareas';

  @override
  String get projectTimeTitle => 'Tiempo del proyecto';

  @override
  String urgencyValue(Object value) {
    return 'Urgencia: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Tiempo registrado: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'Buscar tareas...';

  @override
  String get searchAttachmentsHint => 'Buscar adjuntos...';

  @override
  String get clearSearchTooltip => 'Borrar busqueda';

  @override
  String get projectMapTitle => 'Carpeta del proyecto';

  @override
  String get linkProjectMapButton => 'Vincular carpeta del proyecto';

  @override
  String get projectDataLoading => 'Cargando datos del proyecto...';

  @override
  String get projectDataLoadFailed =>
      'No se pudieron cargar los datos del proyecto.';

  @override
  String currentMapLabel(Object path) {
    return 'Carpeta actual: $path';
  }

  @override
  String get noProjectMapLinked =>
      'No hay carpeta vinculada. Vincula una carpeta para leer archivos.';

  @override
  String get projectNotAvailable => 'Proyecto no disponible.';

  @override
  String get enableConsentInSettings => 'Activa el permiso en Ajustes.';

  @override
  String get projectMapLinked => 'Carpeta del proyecto vinculada.';

  @override
  String get privacyWarningTitle => 'Aviso de privacidad';

  @override
  String get privacyWarningContent =>
      'Advertencia: Se pueden leer datos sensibles.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get attachFilesTooltip => 'Adjuntar archivos';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'Asistente IA';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'Aqui tienes un resumen de tus proyectos activos';

  @override
  String get recentWorkflowsTitle => 'Flujos recientes';

  @override
  String get recentWorkflowsLoading => 'Cargando flujos recientes...';

  @override
  String get recentWorkflowsLoadFailed =>
      'No se pudieron cargar los flujos recientes.';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get noRecentTasks => 'No hay tareas recientes disponibles.';

  @override
  String get unknownProject => 'Proyecto desconocido';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'Proyecto $projectName, tarea $taskTitle, estado $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Tarea $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Ahora mismo';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'Hace $minutes min';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'Hace $hours horas';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'Hace $days dias';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return 'Hace $weeks semanas';
  }

  @override
  String timeMonthsAgo(Object months) {
    return 'Hace $months meses';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return 'Grafico de progreso del proyecto para $projectName. Completado $completedPercent por ciento, pendiente $pendingPercent por ciento.';
  }

  @override
  String get progressLabel => 'Progreso';

  @override
  String completedPercentLabel(Object percent) {
    return 'Completado: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'Pendiente: $percent%';
  }

  @override
  String get noDescription => 'Sin descripcion';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get burndownProgressTitle => 'Progreso burndown';

  @override
  String get actualProgressLabel => 'Progreso real';

  @override
  String get idealTrendLabel => 'Tendencia ideal';

  @override
  String get statusLabel => 'Estado';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'Grafico burndown para $projectName. Puntos reales: $actualPoints. Puntos ideales: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'Chat IA';

  @override
  String get aiAssistantTitle => 'Asistente de proyectos IA';

  @override
  String get clearChatTooltip => 'Borrar chat';

  @override
  String get noMessagesLabel => 'No hay mensajes';

  @override
  String get aiEmptyTitle => 'Inicia una conversacion con el asistente de IA';

  @override
  String get aiEmptySubtitle =>
      'Por ejemplo: \"Genera un plan para el proyecto: tienda web\"';

  @override
  String get useProjectFilesLabel => 'Usar archivos del proyecto';

  @override
  String get typeMessageHint => 'Escribe un mensaje...';

  @override
  String get projectFilesReadFailed =>
      'No se pudieron leer los archivos del proyecto.';

  @override
  String get aiResponseFailedTitle => 'La respuesta de la IA fallo';

  @override
  String get sendMessageTooltip => 'Enviar mensaje';

  @override
  String get loginMissingCredentials => 'Ingresa usuario y contrasena.';

  @override
  String get loginFailedMessage =>
      'Error al iniciar sesion. Verifica tus credenciales.';

  @override
  String get registerTitle => 'Registrar';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get languageDutch => 'Neerlandes';

  @override
  String get languageSpanish => 'Espanol';

  @override
  String get languageFrench => 'Frances';

  @override
  String get languageGerman => 'Aleman';

  @override
  String get languagePortuguese => 'Portugues';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get languageChinese => 'Chino';

  @override
  String get languageJapanese => 'Japones';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageRussian => 'Ruso';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get repeatPasswordLabel => 'Repetir contrasena';

  @override
  String get passwordRulesTitle => 'Reglas de contrasena';

  @override
  String get passwordRuleMinLength => 'Al menos 8 caracteres';

  @override
  String get passwordRuleHasLetter => 'Contiene una letra';

  @override
  String get passwordRuleHasDigit => 'Contiene un numero';

  @override
  String get passwordRuleMatches => 'Las contrasenas coinciden';

  @override
  String get registerButton => 'Registrar';

  @override
  String get registrationIssueUsernameMissing => 'falta el usuario';

  @override
  String get registrationIssueMinLength => 'minimo 8 caracteres';

  @override
  String get registrationIssueLetter => 'al menos 1 letra';

  @override
  String get registrationIssueDigit => 'al menos 1 numero';

  @override
  String get registrationIssueNoMatch => 'las contrasenas no coinciden';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Registro fallido: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Cuenta creada. Inicia sesion ahora.';

  @override
  String get registerFailedMessage => 'Registro fallido.';

  @override
  String get accessDeniedMessage => 'Acceso denegado.';

  @override
  String get adminPanelTitle => 'Panel de administrador';

  @override
  String get adminPanelSubtitle => 'Gestiona roles, grupos y permisos.';

  @override
  String get rolesTitle => 'Roles';

  @override
  String get noRolesFound => 'No se encontraron roles.';

  @override
  String permissionsCount(Object count) {
    return 'Permisos: $count';
  }

  @override
  String get editPermissionsTooltip => 'Editar permisos';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get noGroupsFound => 'No se encontraron grupos.';

  @override
  String get roleLabel => 'Rol';

  @override
  String get groupAddTitle => 'Agregar grupo';

  @override
  String get groupNameLabel => 'Nombre del grupo';

  @override
  String get groupLabel => 'Grupo';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Agregar miembro a $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Agregar miembro';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Miembros del grupo: $groupName';
  }

  @override
  String get noGroupMembers => 'No hay miembros en el grupo.';

  @override
  String get removeGroupMemberTooltip => 'Quitar miembro';

  @override
  String get roleCreateTitle => 'Crear rol';

  @override
  String get roleNameLabel => 'Nombre del rol';

  @override
  String get permissionsTitle => 'Permisos';

  @override
  String get settingsBackupTitle => 'Crear copia de seguridad';

  @override
  String get settingsBackupSubtitle =>
      'Guardar una copia local de datos de Hive.';

  @override
  String get settingsRestoreTitle => 'Restaurar copia de seguridad';

  @override
  String get settingsRestoreSubtitle =>
      'Reemplazar los datos locales con un archivo de copia.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Copia guardada: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Fallo en la copia: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Copia restaurada. Reinicia la app para recargar los datos.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Fallo al restaurar: $error';
  }

  @override
  String get restoreConfirmTitle => '¿Restaurar copia de seguridad?';

  @override
  String get restoreConfirmContent => 'Esto sobrescribirá los datos locales.';

  @override
  String get restoreConfirmButton => 'Restaurar';

  @override
  String get settingsBackupLastRunLabel => 'Última copia de seguridad';

  @override
  String get backupNeverMessage => 'Nunca';

  @override
  String get backupNowButton => 'Hacer copia ahora';

  @override
  String get settingsBackupPathLabel => 'Archivo de copia';

  @override
  String get backupNoFileMessage => 'Aún no hay archivo de copia';
}
