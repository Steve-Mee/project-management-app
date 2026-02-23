// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '项目管理应用';

  @override
  String get menuLabel => '菜单';

  @override
  String get loginTitle => '登录';

  @override
  String get usernameLabel => '用户名';

  @override
  String get passwordLabel => '密码';

  @override
  String get loginButton => '登录';

  @override
  String get createAccount => '创建账号';

  @override
  String get logoutTooltip => '退出登录';

  @override
  String get closeAppTooltip => '关闭应用';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDisplaySection => '显示';

  @override
  String get settingsDarkModeTitle => '深色模式';

  @override
  String get settingsDarkModeSubtitle => '在浅色与深色之间切换';

  @override
  String get settingsFollowSystemTitle => '跟随系统主题';

  @override
  String get settingsFollowSystemSubtitle => '使用设备主题';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSubtitle => '选择应用语言';

  @override
  String get settingsNotificationsSection => '通知';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsNotificationsSubtitle => '更新和提醒';

  @override
  String get settingsPrivacySection => '隐私';

  @override
  String get settingsLocalFilesConsentTitle => '本地文件权限';

  @override
  String get settingsLocalFilesConsentSubtitle => '允许应用读取本地项目文件用于AI上下文。';

  @override
  String get settingsUseProjectFilesTitle => '使用项目文件';

  @override
  String get settingsUseProjectFilesSubtitle => '将本地文件加入AI提示词';

  @override
  String get settingsProjectsSection => '项目';

  @override
  String get settingsLogoutTitle => '退出登录';

  @override
  String get settingsLogoutSubtitle => '结束当前会话';

  @override
  String get settingsExportTitle => '导出项目';

  @override
  String get settingsExportSubtitle => '将项目导出到文件';

  @override
  String get settingsImportTitle => '导入项目';

  @override
  String get settingsImportSubtitle => '从文件导入项目';

  @override
  String get settingsUsersSection => '用户';

  @override
  String get settingsCurrentUserTitle => '当前用户';

  @override
  String get settingsNotLoggedIn => '未登录';

  @override
  String get settingsNoUsersFound => '未找到用户。';

  @override
  String get settingsLocalUserLabel => '本地用户';

  @override
  String get settingsDeleteTooltip => '删除';

  @override
  String get settingsLoadUsersFailed => '加载用户失败';

  @override
  String get settingsAddUserTitle => '添加用户';

  @override
  String get settingsAddUserSubtitle => '添加额外账号';

  @override
  String get logoutDialogTitle => '退出登录';

  @override
  String get logoutDialogContent => '确定要退出登录吗？';

  @override
  String get cancelButton => '取消';

  @override
  String get logoutButton => '退出登录';

  @override
  String get loggedOutMessage => '已退出登录。';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return '导出完成: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return '导出失败: $error';
  }

  @override
  String get exportPasswordTitle => '加密导出';

  @override
  String get exportPasswordSubtitle => '设置密码以加密导出文件。';

  @override
  String get exportPasswordMismatch => '密码不匹配。';

  @override
  String get importSelectFilesMessage => '请选择CSV和JSON文件。';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return '导入完成: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return '导入失败: $error';
  }

  @override
  String get importFailedTitle => '导入失败';

  @override
  String get addUserDialogTitle => '添加用户';

  @override
  String get saveButton => '保存';

  @override
  String get userAddedMessage => '用户已添加。';

  @override
  String get invalidUserMessage => '无效用户。';

  @override
  String get deleteUserDialogTitle => '删除用户';

  @override
  String deleteUserDialogContent(Object username) {
    return '确定要删除 $username 吗？';
  }

  @override
  String get deleteButton => '删除';

  @override
  String userDeletedMessage(Object username) {
    return '用户已删除: $username';
  }

  @override
  String get projectsTitle => '项目';

  @override
  String get newProjectButton => '新建项目';

  @override
  String get noProjectsYet => '暂无项目';

  @override
  String get noProjectsFound => '未找到项目';

  @override
  String get loadingMoreProjects => '正在加载更多项目...';

  @override
  String get sortByLabel => '排序';

  @override
  String get projectSortName => '名称';

  @override
  String get projectSortProgress => '进度';

  @override
  String get projectSortPriority => '优先级';

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
  String get allLabel => '全部';

  @override
  String get loadProjectsFailed => '加载项目失败。';

  @override
  String projectSemanticsLabel(Object title) {
    return '项目 $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return '状态 $status';
  }

  @override
  String get newProjectDialogTitle => '新建项目';

  @override
  String get projectNameLabel => '项目名称';

  @override
  String get descriptionLabel => '描述';

  @override
  String get urgencyLabel => '紧急度';

  @override
  String get urgencyLow => '低';

  @override
  String get urgencyMedium => '中';

  @override
  String get urgencyHigh => '高';

  @override
  String projectCreatedMessage(Object name) {
    return '项目已创建: $name';
  }

  @override
  String get projectDetailsTitle => '项目详情';

  @override
  String get aiChatWithProjectFilesTooltip => '使用项目文件的AI聊天';

  @override
  String get moreOptionsLabel => '更多选项';

  @override
  String get tasksTitle => '任务';

  @override
  String get tasksTab => '任务';

  @override
  String get detailsTab => '详情';

  @override
  String get tasksLoadFailed => '加载任务失败。';

  @override
  String get projectOverviewTitle => '项目概览';

  @override
  String get tasksLoading => '正在加载任务...';

  @override
  String get taskStatisticsTitle => '任务统计';

  @override
  String get totalLabel => '总计';

  @override
  String get completedLabel => '已完成';

  @override
  String get inProgressLabel => '进行中';

  @override
  String get remainingLabel => '剩余';

  @override
  String completionPercentLabel(Object percent) {
    return '完成 $percent%';
  }

  @override
  String get burndownChartTitle => '燃尽图';

  @override
  String get chartPlaceholderTitle => '图表占位符';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart 集成即将到来';

  @override
  String get workflowsTitle => '工作流';

  @override
  String get noWorkflowsAvailable => '没有可用的工作流项目。';

  @override
  String get taskStatusTodo => '待办';

  @override
  String get taskStatusInProgress => '进行中';

  @override
  String get taskStatusReview => '评审';

  @override
  String get taskStatusDone => '完成';

  @override
  String get workflowStatusActive => '活动';

  @override
  String get workflowStatusPending => '待处理';

  @override
  String get noTasksYet => '暂无任务';

  @override
  String get projectTimeTitle => '项目时间';

  @override
  String urgencyValue(Object value) {
    return '紧急度: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return '已记录时间: $value';
  }

  @override
  String get hourShort => '时';

  @override
  String get minuteShort => '分';

  @override
  String get secondShort => '秒';

  @override
  String get searchTasksHint => '搜索任务...';

  @override
  String get searchAttachmentsHint => '搜索附件...';

  @override
  String get clearSearchTooltip => '清除搜索';

  @override
  String get projectMapTitle => '项目文件夹';

  @override
  String get linkProjectMapButton => '链接项目文件夹';

  @override
  String get projectDataLoading => '正在加载项目数据...';

  @override
  String get projectDataLoadFailed => '加载项目数据失败。';

  @override
  String currentMapLabel(Object path) {
    return '当前文件夹: $path';
  }

  @override
  String get noProjectMapLinked => '未链接文件夹。请链接文件夹以读取文件。';

  @override
  String get projectNotAvailable => '项目不可用。';

  @override
  String get enableConsentInSettings => '请在设置中启用权限。';

  @override
  String get projectMapLinked => '项目文件夹已链接。';

  @override
  String get privacyWarningTitle => '隐私提示';

  @override
  String get privacyWarningContent => '警告: 可能会读取敏感数据。';

  @override
  String get continueButton => '继续';

  @override
  String get attachFilesTooltip => '添加附件';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AI助手';

  @override
  String get welcomeBack => '欢迎回来！👋';

  @override
  String get projectsOverviewSubtitle => '这是你的活动项目概览';

  @override
  String get recentWorkflowsTitle => '最近工作流';

  @override
  String get recentWorkflowsLoading => '正在加载最近的工作流...';

  @override
  String get recentWorkflowsLoadFailed => '加载最近工作流失败。';

  @override
  String get retryButton => '重试';

  @override
  String get noRecentTasks => '暂无最近任务。';

  @override
  String get unknownProject => '未知项目';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return '项目 $projectName，任务 $taskTitle，状态 $statusLabel，$timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return '任务 $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes 分钟前';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours 小时前';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days 天前';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks 周前';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months 个月前';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return '项目 $projectName 的进度图。完成 $completedPercent% ，待处理 $pendingPercent% 。';
  }

  @override
  String get progressLabel => '进度';

  @override
  String completedPercentLabel(Object percent) {
    return '完成: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return '待处理: $percent%';
  }

  @override
  String get noDescription => '无描述';

  @override
  String get closeButton => '关闭';

  @override
  String get burndownProgressTitle => '燃尽进度';

  @override
  String get actualProgressLabel => '实际进度';

  @override
  String get idealTrendLabel => '理想趋势';

  @override
  String get statusLabel => '状态';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return '项目 $projectName 的燃尽图。实际点: $actualPoints。理想点: $idealPoints。';
  }

  @override
  String get aiChatSemanticsLabel => 'AI聊天';

  @override
  String get aiAssistantTitle => 'AI项目助手';

  @override
  String get clearChatTooltip => '清空聊天';

  @override
  String get noMessagesLabel => '没有消息';

  @override
  String get aiEmptyTitle => '开始与AI助手对话';

  @override
  String get aiEmptySubtitle => '例如: \"为项目生成计划: 网店\"';

  @override
  String get useProjectFilesLabel => '使用项目文件';

  @override
  String get typeMessageHint => '输入消息...';

  @override
  String get projectFilesReadFailed => '读取项目文件失败。';

  @override
  String get aiResponseFailedTitle => 'AI响应失败';

  @override
  String get sendMessageTooltip => '发送消息';

  @override
  String get loginMissingCredentials => '请输入用户名和密码。';

  @override
  String get loginFailedMessage => '登录失败。请检查凭据。';

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
  String get registerTitle => '注册';

  @override
  String get languageLabel => '语言';

  @override
  String get languageSystem => '系统默认';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageDutch => '荷兰语';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageFrench => '法语';

  @override
  String get languageGerman => '德语';

  @override
  String get languagePortuguese => '葡萄牙语';

  @override
  String get languageItalian => '意大利语';

  @override
  String get languageArabic => '阿拉伯语';

  @override
  String get languageChinese => '中文';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageKorean => '韩语';

  @override
  String get languageRussian => '俄语';

  @override
  String get languageHindi => '印地语';

  @override
  String get repeatPasswordLabel => '重复密码';

  @override
  String get passwordRulesTitle => '密码规则';

  @override
  String get passwordRuleMinLength => '至少8个字符';

  @override
  String get passwordRuleHasLetter => '包含一个字母';

  @override
  String get passwordRuleHasDigit => '包含一个数字';

  @override
  String get passwordRuleMatches => '密码一致';

  @override
  String get registerButton => '注册';

  @override
  String get registrationIssueUsernameMissing => '缺少用户名';

  @override
  String get registrationIssueMinLength => '至少8个字符';

  @override
  String get registrationIssueLetter => '至少1个字母';

  @override
  String get registrationIssueDigit => '至少1个数字';

  @override
  String get registrationIssueNoMatch => '密码不一致';

  @override
  String registrationFailedWithIssues(Object issues) {
    return '注册失败: $issues。';
  }

  @override
  String get accountCreatedMessage => '账号已创建。请登录。';

  @override
  String get registerFailedMessage => '注册失败。';

  @override
  String get accessDeniedMessage => '访问被拒绝。';

  @override
  String get adminPanelTitle => '管理员面板';

  @override
  String get adminPanelSubtitle => '管理角色、群组和权限';

  @override
  String get rolesTitle => '角色';

  @override
  String get noRolesFound => '未找到角色。';

  @override
  String permissionsCount(Object count) {
    return '权限：$count';
  }

  @override
  String get editPermissionsTooltip => '编辑权限';

  @override
  String get groupsTitle => '群组';

  @override
  String get noGroupsFound => '未找到群组。';

  @override
  String get roleLabel => '角色';

  @override
  String get groupAddTitle => '添加群组';

  @override
  String get groupNameLabel => '群组名称';

  @override
  String get groupLabel => '群组';

  @override
  String addGroupMemberTitle(Object groupName) {
    return '将成员添加到 $groupName';
  }

  @override
  String get addGroupMemberTooltip => '添加成员';

  @override
  String groupMembersTitle(Object groupName) {
    return '群组成员：$groupName';
  }

  @override
  String get noGroupMembers => '该群组没有成员。';

  @override
  String get removeGroupMemberTooltip => '移除成员';

  @override
  String get roleCreateTitle => '创建角色';

  @override
  String get roleNameLabel => '角色名称';

  @override
  String get permissionsTitle => '权限';

  @override
  String get settingsBackupTitle => '创建备份';

  @override
  String get settingsBackupSubtitle => '保存 Hive 数据的本地备份。';

  @override
  String get settingsRestoreTitle => '恢复备份';

  @override
  String get settingsRestoreSubtitle => '用备份文件替换本地数据。';

  @override
  String backupSuccessMessage(Object path) {
    return '备份已保存：$path';
  }

  @override
  String backupFailedMessage(Object error) {
    return '备份失败：$error';
  }

  @override
  String get restoreSuccessMessage => '备份已恢复。请重启应用以重新加载数据。';

  @override
  String restoreFailedMessage(Object error) {
    return '恢复失败：$error';
  }

  @override
  String get restoreConfirmTitle => '恢复备份？';

  @override
  String get restoreConfirmContent => '这将覆盖本地数据。';

  @override
  String get restoreConfirmButton => '恢复';

  @override
  String get settingsBackupLastRunLabel => '上次备份';

  @override
  String get backupNeverMessage => '从未';

  @override
  String get backupNowButton => '立即备份';

  @override
  String get settingsBackupPathLabel => '备份文件';

  @override
  String get backupNoFileMessage => '尚无备份文件';

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
  String get limit_for_chat => 'Chat limit';

  @override
  String get limit_for_summarize => 'Summarize limit';

  @override
  String get limit_for_generate_tasks => 'Generate tasks limit';

  @override
  String get per_op_limit_saved => 'Per-operation limits saved';

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
}
