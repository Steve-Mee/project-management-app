// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Приложение для управления проектами';

  @override
  String get menuLabel => 'Меню';

  @override
  String get loginTitle => 'Вход';

  @override
  String get usernameLabel => 'Имя пользователя';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get logoutTooltip => 'Выйти';

  @override
  String get closeAppTooltip => 'Закрыть приложение';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsDisplaySection => 'Экран';

  @override
  String get settingsDarkModeTitle => 'Темная тема';

  @override
  String get settingsDarkModeSubtitle => 'Переключение между светлой и темной';

  @override
  String get settingsFollowSystemTitle => 'Следовать теме системы';

  @override
  String get settingsFollowSystemSubtitle => 'Использовать тему устройства';

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
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Выбрать язык приложения';

  @override
  String get settingsNotificationsSection => 'Уведомления';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsNotificationsSubtitle => 'Обновления и напоминания';

  @override
  String get settingsPrivacySection => 'Конфиденциальность';

  @override
  String get settingsLocalFilesConsentTitle => 'Разрешение на локальные файлы';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'Разрешить приложению читать локальные файлы проекта для контекста ИИ.';

  @override
  String get settingsUseProjectFilesTitle => 'Использовать файлы проекта';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'Добавлять локальные файлы в подсказки ИИ';

  @override
  String get settingsProjectsSection => 'Проекты';

  @override
  String get settingsLogoutTitle => 'Выйти';

  @override
  String get settingsLogoutSubtitle => 'Завершить текущую сессию';

  @override
  String get settingsExportTitle => 'Экспортировать проекты';

  @override
  String get settingsExportSubtitle => 'Экспортировать проекты в файл';

  @override
  String get settingsImportTitle => 'Импортировать проекты';

  @override
  String get settingsImportSubtitle => 'Импортировать проекты из файла';

  @override
  String get settingsUsersSection => 'Пользователи';

  @override
  String get settingsCurrentUserTitle => 'Текущий пользователь';

  @override
  String get settingsNotLoggedIn => 'Вы не вошли';

  @override
  String get settingsNoUsersFound => 'Пользователи не найдены.';

  @override
  String get settingsLocalUserLabel => 'Локальный пользователь';

  @override
  String get settingsDeleteTooltip => 'Удалить';

  @override
  String get settingsLoadUsersFailed => 'Не удалось загрузить пользователей';

  @override
  String get settingsAddUserTitle => 'Добавить пользователя';

  @override
  String get settingsAddUserSubtitle => 'Добавить дополнительный аккаунт';

  @override
  String get logoutDialogTitle => 'Выйти';

  @override
  String get logoutDialogContent => 'Выйти из аккаунта?';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get logoutButton => 'Выйти';

  @override
  String get loggedOutMessage => 'Вы вышли из аккаунта.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Экспорт завершен: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'Экспорт не удался: $error';
  }

  @override
  String get exportPasswordTitle => 'Зашифровать экспорт';

  @override
  String get exportPasswordSubtitle =>
      'Установите пароль для шифрования файлов экспорта.';

  @override
  String get exportPasswordMismatch => 'Пароли не совпадают.';

  @override
  String get importSelectFilesMessage => 'Выберите файлы CSV и JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'Импорт завершен: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'Импорт не удался: $error';
  }

  @override
  String get importFailedTitle => 'Импорт не удался';

  @override
  String get addUserDialogTitle => 'Добавить пользователя';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get userAddedMessage => 'Пользователь добавлен.';

  @override
  String get invalidUserMessage => 'Недействительный пользователь.';

  @override
  String get deleteUserDialogTitle => 'Удалить пользователя';

  @override
  String deleteUserDialogContent(Object username) {
    return 'Удалить $username?';
  }

  @override
  String get deleteButton => 'Удалить';

  @override
  String userDeletedMessage(Object username) {
    return 'Пользователь удален: $username';
  }

  @override
  String get projectsTitle => 'Проекты';

  @override
  String get newProjectButton => 'Новый проект';

  @override
  String get noProjectsYet => 'Проектов пока нет';

  @override
  String get noProjectsFound => 'Проекты не найдены';

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
  String get loadingMoreProjects => 'Загрузка дополнительных проектов...';

  @override
  String get sortByLabel => 'Сортировать по';

  @override
  String get projectSortName => 'Название';

  @override
  String get projectSortProgress => 'Прогресс';

  @override
  String get projectSortPriority => 'Приоритет';

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
  String get allLabel => 'Все';

  @override
  String get loadProjectsFailed => 'Не удалось загрузить проекты.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'Проект $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'Статус $status';
  }

  @override
  String get newProjectDialogTitle => 'Новый проект';

  @override
  String get projectNameLabel => 'Название проекта';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get urgencyLabel => 'Срочность';

  @override
  String get urgencyLow => 'Низкая';

  @override
  String get urgencyMedium => 'Средняя';

  @override
  String get urgencyHigh => 'Высокая';

  @override
  String projectCreatedMessage(Object name) {
    return 'Проект создан: $name';
  }

  @override
  String get projectDetailsTitle => 'Детали проекта';

  @override
  String get aiChatWithProjectFilesTooltip => 'ИИ-чат с файлами проекта';

  @override
  String get moreOptionsLabel => 'Больше опций';

  @override
  String get tasksTitle => 'Задачи';

  @override
  String get tasksTab => 'Задачи';

  @override
  String get detailsTab => 'Детали';

  @override
  String get tasksLoadFailed => 'Не удалось загрузить задачи.';

  @override
  String get projectOverviewTitle => 'Обзор проекта';

  @override
  String get tasksLoading => 'Загрузка задач...';

  @override
  String get taskStatisticsTitle => 'Статистика задач';

  @override
  String get totalLabel => 'Всего';

  @override
  String get completedLabel => 'Завершено';

  @override
  String get inProgressLabel => 'В работе';

  @override
  String get remainingLabel => 'Осталось';

  @override
  String completionPercentLabel(Object percent) {
    return 'Выполнено $percent%';
  }

  @override
  String get burndownChartTitle => 'Диаграмма сгорания';

  @override
  String get chartPlaceholderTitle => 'Заполнитель диаграммы';

  @override
  String get chartPlaceholderSubtitle => 'Интеграция fl_chart скоро';

  @override
  String get workflowsTitle => 'Процессы';

  @override
  String get noWorkflowsAvailable => 'Нет доступных элементов процесса.';

  @override
  String get taskStatusTodo => 'К выполнению';

  @override
  String get taskStatusInProgress => 'В работе';

  @override
  String get taskStatusReview => 'На проверке';

  @override
  String get taskStatusDone => 'Готово';

  @override
  String get workflowStatusActive => 'Активно';

  @override
  String get workflowStatusPending => 'Ожидает';

  @override
  String get noTasksYet => 'Задач пока нет';

  @override
  String get projectTimeTitle => 'Время проекта';

  @override
  String urgencyValue(Object value) {
    return 'Срочность: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'Отслеженное время: $value';
  }

  @override
  String get hourShort => 'ч';

  @override
  String get minuteShort => 'м';

  @override
  String get secondShort => 'с';

  @override
  String get searchTasksHint => 'Поиск задач...';

  @override
  String get searchAttachmentsHint => 'Поиск вложений...';

  @override
  String get clearSearchTooltip => 'Очистить поиск';

  @override
  String get projectMapTitle => 'Папка проекта';

  @override
  String get linkProjectMapButton => 'Связать папку проекта';

  @override
  String get projectDataLoading => 'Загрузка данных проекта...';

  @override
  String get projectDataLoadFailed => 'Не удалось загрузить данные проекта.';

  @override
  String currentMapLabel(Object path) {
    return 'Текущая папка: $path';
  }

  @override
  String get noProjectMapLinked =>
      'Папка не связана. Свяжите папку для чтения файлов.';

  @override
  String get projectNotAvailable => 'Проект недоступен.';

  @override
  String get enableConsentInSettings => 'Включите разрешение в настройках.';

  @override
  String get projectMapLinked => 'Папка проекта связана.';

  @override
  String get privacyWarningTitle => 'Предупреждение о конфиденциальности';

  @override
  String get privacyWarningContent =>
      'Внимание: могут быть прочитаны конфиденциальные данные.';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get attachFilesTooltip => 'Прикрепить файлы';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'ИИ помощник';

  @override
  String get welcomeBack => 'С возвращением! 👋';

  @override
  String get projectsOverviewSubtitle => 'Вот обзор ваших активных проектов';

  @override
  String get recentWorkflowsTitle => 'Недавние процессы';

  @override
  String get recentWorkflowsLoading => 'Загрузка недавних процессов...';

  @override
  String get recentWorkflowsLoadFailed =>
      'Не удалось загрузить недавние процессы.';

  @override
  String get retryButton => 'Повторить';

  @override
  String get noRecentTasks => 'Нет недавних задач.';

  @override
  String get unknownProject => 'Неизвестный проект';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle,
      Object statusLabel, Object timeLabel) {
    return 'Проект $projectName, задача $taskTitle, статус $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'Задача $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'Только что';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes мин назад';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours ч назад';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days дн назад';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks нед назад';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months мес назад';
  }

  @override
  String projectProgressChartSemantics(
      Object projectName, Object completedPercent, Object pendingPercent) {
    return 'Диаграмма прогресса проекта $projectName. Выполнено $completedPercent процентов, в ожидании $pendingPercent процентов.';
  }

  @override
  String get progressLabel => 'Прогресс';

  @override
  String completedPercentLabel(Object percent) {
    return 'Выполнено: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'В ожидании: $percent%';
  }

  @override
  String get noDescription => 'Без описания';

  @override
  String get closeButton => 'Закрыть';

  @override
  String get burndownProgressTitle => 'Прогресс сгорания';

  @override
  String get actualProgressLabel => 'Фактический прогресс';

  @override
  String get idealTrendLabel => 'Идеальная линия';

  @override
  String get statusLabel => 'Статус';

  @override
  String burndownChartSemantics(
      Object projectName, Object actualPoints, Object idealPoints) {
    return 'Диаграмма сгорания для $projectName. Фактические точки: $actualPoints. Идеальные точки: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'ИИ чат';

  @override
  String get aiAssistantTitle => 'ИИ помощник по проектам';

  @override
  String get clearChatTooltip => 'Очистить чат';

  @override
  String get noMessagesLabel => 'Нет сообщений';

  @override
  String get aiEmptyTitle => 'Начните разговор с ИИ помощником';

  @override
  String get aiEmptySubtitle =>
      'Например: \"Сгенерируй план для проекта: веб-магазин\"';

  @override
  String get useProjectFilesLabel => 'Использовать файлы проекта';

  @override
  String get typeMessageHint => 'Введите сообщение...';

  @override
  String get projectFilesReadFailed => 'Не удалось прочитать файлы проекта.';

  @override
  String get aiResponseFailedTitle => 'Ответ ИИ не получен';

  @override
  String get sendMessageTooltip => 'Отправить сообщение';

  @override
  String get loginMissingCredentials => 'Введите имя пользователя и пароль.';

  @override
  String get loginFailedMessage =>
      'Не удалось войти. Проверьте учетные данные.';

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
  String get registerTitle => 'Регистрация';

  @override
  String get languageLabel => 'Язык';

  @override
  String get languageSystem => 'Системный по умолчанию';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageDutch => 'Нидерландский';

  @override
  String get languageSpanish => 'Испанский';

  @override
  String get languageFrench => 'Французский';

  @override
  String get languageGerman => 'Немецкий';

  @override
  String get languagePortuguese => 'Португальский';

  @override
  String get languageItalian => 'Итальянский';

  @override
  String get languageArabic => 'Арабский';

  @override
  String get languageChinese => 'Китайский';

  @override
  String get languageJapanese => 'Японский';

  @override
  String get languageKorean => 'Корейский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageHindi => 'Хинди';

  @override
  String get repeatPasswordLabel => 'Повторите пароль';

  @override
  String get passwordRulesTitle => 'Правила пароля';

  @override
  String get passwordRuleMinLength => 'Не менее 8 символов';

  @override
  String get passwordRuleHasLetter => 'Содержит букву';

  @override
  String get passwordRuleHasDigit => 'Содержит цифру';

  @override
  String get passwordRuleMatches => 'Пароли совпадают';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get registrationIssueUsernameMissing => 'нет имени пользователя';

  @override
  String get registrationIssueMinLength => 'минимум 8 символов';

  @override
  String get registrationIssueLetter => 'минимум 1 буква';

  @override
  String get registrationIssueDigit => 'минимум 1 цифра';

  @override
  String get registrationIssueNoMatch => 'пароли не совпадают';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'Регистрация не удалась: $issues.';
  }

  @override
  String get accountCreatedMessage => 'Аккаунт создан. Войдите сейчас.';

  @override
  String get registerFailedMessage => 'Регистрация не удалась.';

  @override
  String get accessDeniedMessage => 'Доступ запрещен.';

  @override
  String get adminPanelTitle => 'Панель администратора';

  @override
  String get adminPanelSubtitle => 'Управление ролями, группами и правами.';

  @override
  String get rolesTitle => 'Роли';

  @override
  String get noRolesFound => 'Роли не найдены.';

  @override
  String permissionsCount(Object count) {
    return 'Права: $count';
  }

  @override
  String get editPermissionsTooltip => 'Изменить права';

  @override
  String get groupsTitle => 'Группы';

  @override
  String get noGroupsFound => 'Группы не найдены.';

  @override
  String get roleLabel => 'Роль';

  @override
  String get groupAddTitle => 'Добавить группу';

  @override
  String get groupNameLabel => 'Название группы';

  @override
  String get groupLabel => 'Группа';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'Добавить участника в $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'Добавить участника';

  @override
  String groupMembersTitle(Object groupName) {
    return 'Участники группы: $groupName';
  }

  @override
  String get noGroupMembers => 'В группе нет участников.';

  @override
  String get removeGroupMemberTooltip => 'Удалить участника';

  @override
  String get roleCreateTitle => 'Создать роль';

  @override
  String get roleNameLabel => 'Название роли';

  @override
  String get permissionsTitle => 'Права';

  @override
  String get settingsBackupTitle => 'Создать резервную копию';

  @override
  String get settingsBackupSubtitle =>
      'Сохранить локальную резервную копию данных Hive.';

  @override
  String get settingsRestoreTitle => 'Восстановить резервную копию';

  @override
  String get settingsRestoreSubtitle =>
      'Заменить локальные данные файлом резервной копии.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Резервная копия сохранена: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Ошибка резервного копирования: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'Резервная копия восстановлена. Перезапустите приложение, чтобы загрузить данные.';

  @override
  String restoreFailedMessage(Object error) {
    return 'Ошибка восстановления: $error';
  }

  @override
  String get restoreConfirmTitle => 'Восстановить резервную копию?';

  @override
  String get restoreConfirmContent => 'Это перезапишет локальные данные.';

  @override
  String get restoreConfirmButton => 'Восстановить';

  @override
  String get settingsBackupLastRunLabel => 'Последняя резервная копия';

  @override
  String get backupNeverMessage => 'Никогда';

  @override
  String get backupNowButton => 'Сделать резервную копию';

  @override
  String get settingsBackupPathLabel => 'Файл резервной копии';

  @override
  String get backupNoFileMessage => 'Файл резервной копии еще не создан';

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
  String get mirrorTemplatesStaleFallbackWarning =>
      'Showing cached saved views because live templates could not be refreshed.';

  @override
  String mirrorTemplatesStaleFallbackWarningWithTime(String lastUpdated) {
    return 'Showing cached saved views from $lastUpdated because live templates could not be refreshed.';
  }

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
      'Я понимаю риск прямого применения';

  @override
  String get mirrorApplyRiskAcknowledgeSubtitle =>
      'Изменения будут применены к рабочему каталогу. Предпочтительно использовать отдельную ветку.';

  @override
  String get mirrorPermissionDenied =>
      'Mirror недоступен для вашей учётной записи.';

  @override
  String get mirrorFeatureDisabled =>
      'Mirror в настоящее время отключён администратором.';

  @override
  String get mirrorPermissionRevokedSessionDisabled =>
      'Сессия редактора Mirror была отключена, потому что ваши права изменились. Закройте этот экран, чтобы безопасно продолжить.';

  @override
  String get mirrorPermissionRevokedTerminal =>
      'Доступ к Mirror отозван: сеанс завершен.';

  @override
  String get mirrorApplyDiffPreview => 'Предварительный просмотр изменений';

  @override
  String get mirrorApplyNo => 'Нет';

  @override
  String get mirrorApplyConfirm => 'Применить';

  @override
  String get mirrorApplyNoDiff => '(Различий не обнаружено)';

  @override
  String get mirrorApplyBranchAdviceTitle =>
      'Предлагаемое имя ветки – только рекомендация';

  @override
  String mirrorApplyCurrentBranch(String branch) {
    return 'Текущая ветка: $branch';
  }

  @override
  String mirrorApplySuggestedBranch(String branch) {
    return 'Предлагаемое имя ветки (только рекомендация): $branch';
  }

  @override
  String get mirrorApplyBranchTip =>
      'Совет: сначала создайте новую ветку для безопасной проверки и отката.';

  @override
  String mirrorApplyBranchTipWithBranch(String branch) {
    return 'Только совет: рассматривайте предложенную ветку \"$branch\" как рекомендацию для более безопасной проверки и простого отката.';
  }

  @override
  String get mirrorApplyBranchWorkingTreeNotice =>
      'Mirror применяет изменения в вашем текущем рабочем каталоге и не создает и не переключает ветки автоматически.';

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
