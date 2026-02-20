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
  String get settingsLocalFilesConsentSubtitle => 'Разрешить приложению читать локальные файлы проекта для контекста ИИ.';

  @override
  String get settingsUseProjectFilesTitle => 'Использовать файлы проекта';

  @override
  String get settingsUseProjectFilesSubtitle => 'Добавлять локальные файлы в подсказки ИИ';

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
  String get exportPasswordSubtitle => 'Установите пароль для шифрования файлов экспорта.';

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
  String get noProjectMapLinked => 'Папка не связана. Свяжите папку для чтения файлов.';

  @override
  String get projectNotAvailable => 'Проект недоступен.';

  @override
  String get enableConsentInSettings => 'Включите разрешение в настройках.';

  @override
  String get projectMapLinked => 'Папка проекта связана.';

  @override
  String get privacyWarningTitle => 'Предупреждение о конфиденциальности';

  @override
  String get privacyWarningContent => 'Внимание: могут быть прочитаны конфиденциальные данные.';

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
  String get recentWorkflowsLoadFailed => 'Не удалось загрузить недавние процессы.';

  @override
  String get retryButton => 'Повторить';

  @override
  String get noRecentTasks => 'Нет недавних задач.';

  @override
  String get unknownProject => 'Неизвестный проект';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle, Object statusLabel, Object timeLabel) {
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
  String projectProgressChartSemantics(Object projectName, Object completedPercent, Object pendingPercent) {
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
  String burndownChartSemantics(Object projectName, Object actualPoints, Object idealPoints) {
    return 'Диаграмма сгорания для $projectName. Фактические точки: $actualPoints. Идеальные точки: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'ИИ чат';

  @override
  String get aiUsageTitle => 'AI Usage';

  @override
  String get aiAssistantTitle => 'ИИ помощник по проектам';

  @override
  String get clearChatTooltip => 'Очистить чат';

  @override
  String get noMessagesLabel => 'Нет сообщений';

  @override
  String get aiEmptyTitle => 'Начните разговор с ИИ помощником';

  @override
  String get aiEmptySubtitle => 'Например: \"Сгенерируй план для проекта: веб-магазин\"';

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
  String get loginFailedMessage => 'Не удалось войти. Проверьте учетные данные.';

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
  String get settingsBackupSubtitle => 'Сохранить локальную резервную копию данных Hive.';

  @override
  String get settingsRestoreTitle => 'Восстановить резервную копию';

  @override
  String get settingsRestoreSubtitle => 'Заменить локальные данные файлом резервной копии.';

  @override
  String backupSuccessMessage(Object path) {
    return 'Резервная копия сохранена: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'Ошибка резервного копирования: $error';
  }

  @override
  String get restoreSuccessMessage => 'Резервная копия восстановлена. Перезапустите приложение, чтобы загрузить данные.';

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
}
