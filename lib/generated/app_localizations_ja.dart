// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'プロジェクト管理アプリ';

  @override
  String get menuLabel => 'メニュー';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get loginButton => 'ログイン';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get logoutTooltip => 'ログアウト';

  @override
  String get closeAppTooltip => 'アプリを閉じる';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsDisplaySection => '表示';

  @override
  String get settingsDarkModeTitle => 'ダークモード';

  @override
  String get settingsDarkModeSubtitle => 'ライトとダークを切り替え';

  @override
  String get settingsFollowSystemTitle => 'システムテーマに従う';

  @override
  String get settingsFollowSystemSubtitle => 'デバイスのテーマを使用';

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
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsLanguageSubtitle => 'アプリの言語を選択';

  @override
  String get settingsNotificationsSection => '通知';

  @override
  String get settingsNotificationsTitle => '通知';

  @override
  String get settingsNotificationsSubtitle => '更新とリマインダー';

  @override
  String get settingsPrivacySection => 'プライバシー';

  @override
  String get settingsLocalFilesConsentTitle => 'ローカルファイルの許可';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'AIのコンテキストのためにローカルのプロジェクトファイルを読み取ることを許可します。';

  @override
  String get settingsUseProjectFilesTitle => 'プロジェクトファイルを使用';

  @override
  String get settingsUseProjectFilesSubtitle => 'ローカルファイルをAIプロンプトに追加';

  @override
  String get settingsProjectsSection => 'プロジェクト';

  @override
  String get settingsLogoutTitle => 'ログアウト';

  @override
  String get settingsLogoutSubtitle => '現在のセッションを終了';

  @override
  String get settingsExportTitle => 'プロジェクトを書き出す';

  @override
  String get settingsExportSubtitle => 'プロジェクトをファイルに書き出す';

  @override
  String get settingsImportTitle => 'プロジェクトを読み込む';

  @override
  String get settingsImportSubtitle => 'ファイルからプロジェクトを読み込む';

  @override
  String get settingsUsersSection => 'ユーザー';

  @override
  String get settingsCurrentUserTitle => '現在のユーザー';

  @override
  String get settingsNotLoggedIn => '未ログイン';

  @override
  String get settingsNoUsersFound => 'ユーザーが見つかりません。';

  @override
  String get settingsLocalUserLabel => 'ローカルユーザー';

  @override
  String get settingsDeleteTooltip => '削除';

  @override
  String get settingsLoadUsersFailed => 'ユーザーの読み込みに失敗しました';

  @override
  String get settingsAddUserTitle => 'ユーザーを追加';

  @override
  String get settingsAddUserSubtitle => '追加のアカウントを追加';

  @override
  String get logoutDialogTitle => 'ログアウト';

  @override
  String get logoutDialogContent => 'ログアウトしますか？';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get logoutButton => 'ログアウト';

  @override
  String get loggedOutMessage => 'ログアウトしました。';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return '書き出し完了: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return '書き出し失敗: $error';
  }

  @override
  String get exportPasswordTitle => 'エクスポートを暗号化';

  @override
  String get exportPasswordSubtitle => 'エクスポートファイルを暗号化するためのパスワードを設定してください。';

  @override
  String get exportPasswordMismatch => 'パスワードが一致しません。';

  @override
  String get importSelectFilesMessage => 'CSVとJSONファイルを選択してください。';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return '読み込み完了: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return '読み込み失敗: $error';
  }

  @override
  String get importFailedTitle => '読み込み失敗';

  @override
  String get addUserDialogTitle => 'ユーザーを追加';

  @override
  String get saveButton => '保存';

  @override
  String get userAddedMessage => 'ユーザーを追加しました。';

  @override
  String get invalidUserMessage => '無効なユーザーです。';

  @override
  String get deleteUserDialogTitle => 'ユーザーを削除';

  @override
  String deleteUserDialogContent(Object username) {
    return '$username を削除しますか？';
  }

  @override
  String get deleteButton => '削除';

  @override
  String userDeletedMessage(Object username) {
    return 'ユーザーを削除しました: $username';
  }

  @override
  String get projectsTitle => 'プロジェクト';

  @override
  String get newProjectButton => '新規プロジェクト';

  @override
  String get noProjectsYet => 'まだプロジェクトがありません';

  @override
  String get noProjectsFound => 'プロジェクトが見つかりません';

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
  String get loadingMoreProjects => 'さらに読み込み中...';

  @override
  String get sortByLabel => '並び替え';

  @override
  String get projectSortName => '名前';

  @override
  String get projectSortProgress => '進捗';

  @override
  String get projectSortPriority => '優先度';

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
  String get allLabel => 'すべて';

  @override
  String get loadProjectsFailed => 'プロジェクトの読み込みに失敗しました。';

  @override
  String projectSemanticsLabel(Object title) {
    return 'プロジェクト $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'ステータス $status';
  }

  @override
  String get newProjectDialogTitle => '新規プロジェクト';

  @override
  String get projectNameLabel => 'プロジェクト名';

  @override
  String get descriptionLabel => '説明';

  @override
  String get urgencyLabel => '緊急度';

  @override
  String get urgencyLow => '低';

  @override
  String get urgencyMedium => '中';

  @override
  String get urgencyHigh => '高';

  @override
  String projectCreatedMessage(Object name) {
    return 'プロジェクトを作成しました: $name';
  }

  @override
  String get projectDetailsTitle => 'プロジェクト詳細';

  @override
  String get aiChatWithProjectFilesTooltip => 'プロジェクトファイルでAIチャット';

  @override
  String get moreOptionsLabel => 'その他のオプション';

  @override
  String get tasksTitle => 'タスク';

  @override
  String get tasksTab => 'タスク';

  @override
  String get detailsTab => '詳細';

  @override
  String get tasksLoadFailed => 'タスクの読み込みに失敗しました。';

  @override
  String get projectOverviewTitle => 'プロジェクト概要';

  @override
  String get tasksLoading => 'タスクを読み込み中...';

  @override
  String get taskStatisticsTitle => 'タスク統計';

  @override
  String get totalLabel => '合計';

  @override
  String get completedLabel => '完了';

  @override
  String get inProgressLabel => '進行中';

  @override
  String get remainingLabel => '残り';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% 完了';
  }

  @override
  String get burndownChartTitle => 'バーンダウンチャート';

  @override
  String get chartPlaceholderTitle => 'チャートのプレースホルダー';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart の統合は近日予定';

  @override
  String get workflowsTitle => 'ワークフロー';

  @override
  String get noWorkflowsAvailable => '利用可能なワークフローはありません。';

  @override
  String get taskStatusTodo => '未着手';

  @override
  String get taskStatusInProgress => '進行中';

  @override
  String get taskStatusReview => 'レビュー';

  @override
  String get taskStatusDone => '完了';

  @override
  String get workflowStatusActive => 'アクティブ';

  @override
  String get workflowStatusPending => '保留';

  @override
  String get noTasksYet => 'まだタスクがありません';

  @override
  String get projectTimeTitle => 'プロジェクト時間';

  @override
  String urgencyValue(Object value) {
    return '緊急度: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return '記録時間: $value';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get searchTasksHint => 'タスクを検索...';

  @override
  String get searchAttachmentsHint => '添付ファイルを検索...';

  @override
  String get clearSearchTooltip => '検索をクリア';

  @override
  String get projectMapTitle => 'プロジェクトフォルダー';

  @override
  String get linkProjectMapButton => 'プロジェクトフォルダーをリンク';

  @override
  String get projectDataLoading => 'プロジェクトデータを読み込み中...';

  @override
  String get projectDataLoadFailed => 'プロジェクトデータの読み込みに失敗しました。';

  @override
  String currentMapLabel(Object path) {
    return '現在のフォルダー: $path';
  }

  @override
  String get noProjectMapLinked => 'フォルダーがリンクされていません。ファイルを読むにはフォルダーをリンクしてください。';

  @override
  String get projectNotAvailable => 'プロジェクトを利用できません。';

  @override
  String get enableConsentInSettings => '設定で許可を有効にしてください。';

  @override
  String get projectMapLinked => 'プロジェクトフォルダーをリンクしました。';

  @override
  String get privacyWarningTitle => 'プライバシー警告';

  @override
  String get privacyWarningContent => '警告: 機密データが読み取られる可能性があります。';

  @override
  String get continueButton => '続行';

  @override
  String get attachFilesTooltip => 'ファイルを添付';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AIアシスタント';

  @override
  String get welcomeBack => 'おかえりなさい！👋';

  @override
  String get projectsOverviewSubtitle => 'アクティブなプロジェクトの概要です';

  @override
  String get recentWorkflowsTitle => '最近のワークフロー';

  @override
  String get recentWorkflowsLoading => '最近のワークフローを読み込み中...';

  @override
  String get recentWorkflowsLoadFailed => '最近のワークフローの読み込みに失敗しました。';

  @override
  String get retryButton => '再試行';

  @override
  String get noRecentTasks => '最近のタスクはありません。';

  @override
  String get unknownProject => '不明なプロジェクト';

  @override
  String projectTaskStatusSemantics(Object projectName, Object taskTitle,
      Object statusLabel, Object timeLabel) {
    return 'プロジェクト $projectName、タスク $taskTitle、ステータス $statusLabel、$timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'タスク $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes 分前';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours 時間前';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days 日前';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks 週間前';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months か月前';
  }

  @override
  String projectProgressChartSemantics(
      Object projectName, Object completedPercent, Object pendingPercent) {
    return '$projectName の進捗チャート。完了 $completedPercent パーセント、保留 $pendingPercent パーセント。';
  }

  @override
  String get progressLabel => '進捗';

  @override
  String completedPercentLabel(Object percent) {
    return '完了: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return '保留: $percent%';
  }

  @override
  String get noDescription => '説明なし';

  @override
  String get closeButton => '閉じる';

  @override
  String get burndownProgressTitle => 'バーンダウン進捗';

  @override
  String get actualProgressLabel => '実際の進捗';

  @override
  String get idealTrendLabel => '理想トレンド';

  @override
  String get statusLabel => 'ステータス';

  @override
  String burndownChartSemantics(
      Object projectName, Object actualPoints, Object idealPoints) {
    return '$projectName のバーンダウンチャート。実測点: $actualPoints。理想点: $idealPoints。';
  }

  @override
  String get aiChatSemanticsLabel => 'AIチャット';

  @override
  String get aiAssistantTitle => 'AIプロジェクトアシスタント';

  @override
  String get clearChatTooltip => 'チャットをクリア';

  @override
  String get noMessagesLabel => 'メッセージなし';

  @override
  String get aiEmptyTitle => 'AIアシスタントとの会話を開始';

  @override
  String get aiEmptySubtitle => '例: \"プロジェクトの計画を作成: Webショップ\"';

  @override
  String get useProjectFilesLabel => 'プロジェクトファイルを使用';

  @override
  String get typeMessageHint => 'メッセージを入力...';

  @override
  String get projectFilesReadFailed => 'プロジェクトファイルの読み取りに失敗しました。';

  @override
  String get aiResponseFailedTitle => 'AI応答に失敗しました';

  @override
  String get sendMessageTooltip => 'メッセージ送信';

  @override
  String get loginMissingCredentials => 'ユーザー名とパスワードを入力してください。';

  @override
  String get loginFailedMessage => 'ログインに失敗しました。資格情報を確認してください。';

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
  String get registerTitle => '登録';

  @override
  String get languageLabel => '言語';

  @override
  String get languageSystem => 'システム既定';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageDutch => 'オランダ語';

  @override
  String get languageSpanish => 'スペイン語';

  @override
  String get languageFrench => 'フランス語';

  @override
  String get languageGerman => 'ドイツ語';

  @override
  String get languagePortuguese => 'ポルトガル語';

  @override
  String get languageItalian => 'イタリア語';

  @override
  String get languageArabic => 'アラビア語';

  @override
  String get languageChinese => '中国語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageRussian => 'ロシア語';

  @override
  String get languageHindi => 'ヒンディー語';

  @override
  String get repeatPasswordLabel => 'パスワードを再入力';

  @override
  String get passwordRulesTitle => 'パスワードのルール';

  @override
  String get passwordRuleMinLength => '8文字以上';

  @override
  String get passwordRuleHasLetter => '文字を含む';

  @override
  String get passwordRuleHasDigit => '数字を含む';

  @override
  String get passwordRuleMatches => 'パスワードが一致';

  @override
  String get registerButton => '登録';

  @override
  String get registrationIssueUsernameMissing => 'ユーザー名がありません';

  @override
  String get registrationIssueMinLength => '8文字以上';

  @override
  String get registrationIssueLetter => '少なくとも1文字';

  @override
  String get registrationIssueDigit => '少なくとも1数字';

  @override
  String get registrationIssueNoMatch => 'パスワードが一致しません';

  @override
  String registrationFailedWithIssues(Object issues) {
    return '登録に失敗しました: $issues。';
  }

  @override
  String get accountCreatedMessage => 'アカウントが作成されました。ログインしてください。';

  @override
  String get registerFailedMessage => '登録に失敗しました。';

  @override
  String get accessDeniedMessage => 'アクセスが拒否されました。';

  @override
  String get adminPanelTitle => '管理パネル';

  @override
  String get adminPanelSubtitle => 'ロール、グループ、権限を管理';

  @override
  String get rolesTitle => 'ロール';

  @override
  String get noRolesFound => 'ロールが見つかりません。';

  @override
  String permissionsCount(Object count) {
    return '権限: $count';
  }

  @override
  String get editPermissionsTooltip => '権限を編集';

  @override
  String get groupsTitle => 'グループ';

  @override
  String get noGroupsFound => 'グループが見つかりません。';

  @override
  String get roleLabel => 'ロール';

  @override
  String get groupAddTitle => 'グループを追加';

  @override
  String get groupNameLabel => 'グループ名';

  @override
  String get groupLabel => 'グループ';

  @override
  String addGroupMemberTitle(Object groupName) {
    return '$groupNameにメンバーを追加';
  }

  @override
  String get addGroupMemberTooltip => 'メンバーを追加';

  @override
  String groupMembersTitle(Object groupName) {
    return 'グループのメンバー: $groupName';
  }

  @override
  String get noGroupMembers => 'グループにメンバーがいません。';

  @override
  String get removeGroupMemberTooltip => 'メンバーを削除';

  @override
  String get roleCreateTitle => 'ロールを作成';

  @override
  String get roleNameLabel => 'ロール名';

  @override
  String get permissionsTitle => '権限';

  @override
  String get settingsBackupTitle => 'バックアップを作成';

  @override
  String get settingsBackupSubtitle => 'Hive データのローカルバックアップを保存します。';

  @override
  String get settingsRestoreTitle => 'バックアップを復元';

  @override
  String get settingsRestoreSubtitle => 'ローカルデータをバックアップファイルで置き換えます。';

  @override
  String backupSuccessMessage(Object path) {
    return 'バックアップを保存しました: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'バックアップに失敗しました: $error';
  }

  @override
  String get restoreSuccessMessage => 'バックアップを復元しました。データを読み込むためにアプリを再起動してください。';

  @override
  String restoreFailedMessage(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get restoreConfirmTitle => 'バックアップを復元しますか？';

  @override
  String get restoreConfirmContent => 'ローカルデータが上書きされます。';

  @override
  String get restoreConfirmButton => '復元';

  @override
  String get settingsBackupLastRunLabel => '最終バックアップ';

  @override
  String get backupNeverMessage => 'なし';

  @override
  String get backupNowButton => '今すぐバックアップ';

  @override
  String get settingsBackupPathLabel => 'バックアップ ファイル';

  @override
  String get backupNoFileMessage => 'バックアップ ファイルがありません';

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
}
