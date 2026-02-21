// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '프로젝트 관리 앱';

  @override
  String get menuLabel => '메뉴';

  @override
  String get loginTitle => '로그인';

  @override
  String get usernameLabel => '사용자 이름';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get loginButton => '로그인';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get logoutTooltip => '로그아웃';

  @override
  String get closeAppTooltip => '앱 닫기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsDisplaySection => '디스플레이';

  @override
  String get settingsDarkModeTitle => '다크 모드';

  @override
  String get settingsDarkModeSubtitle => '라이트와 다크 전환';

  @override
  String get settingsFollowSystemTitle => '시스템 테마 따르기';

  @override
  String get settingsFollowSystemSubtitle => '기기 테마 사용';

  @override
  String get settingsLanguageTitle => '언어';

  @override
  String get settingsLanguageSubtitle => '앱 언어 선택';

  @override
  String get settingsNotificationsSection => '알림';

  @override
  String get settingsNotificationsTitle => '알림';

  @override
  String get settingsNotificationsSubtitle => '업데이트 및 리마인더';

  @override
  String get settingsPrivacySection => '개인정보';

  @override
  String get settingsLocalFilesConsentTitle => '로컬 파일 권한';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'AI 컨텍스트를 위해 로컬 프로젝트 파일을 읽도록 허용합니다.';

  @override
  String get settingsUseProjectFilesTitle => '프로젝트 파일 사용';

  @override
  String get settingsUseProjectFilesSubtitle => '로컬 파일을 AI 프롬프트에 추가';

  @override
  String get settingsProjectsSection => '프로젝트';

  @override
  String get settingsLogoutTitle => '로그아웃';

  @override
  String get settingsLogoutSubtitle => '현재 세션 종료';

  @override
  String get settingsExportTitle => '프로젝트 내보내기';

  @override
  String get settingsExportSubtitle => '프로젝트를 파일로 내보내기';

  @override
  String get settingsImportTitle => '프로젝트 가져오기';

  @override
  String get settingsImportSubtitle => '파일에서 프로젝트 가져오기';

  @override
  String get settingsUsersSection => '사용자';

  @override
  String get settingsCurrentUserTitle => '현재 사용자';

  @override
  String get settingsNotLoggedIn => '로그인되지 않음';

  @override
  String get settingsNoUsersFound => '사용자를 찾을 수 없습니다.';

  @override
  String get settingsLocalUserLabel => '로컬 사용자';

  @override
  String get settingsDeleteTooltip => '삭제';

  @override
  String get settingsLoadUsersFailed => '사용자 로드 실패';

  @override
  String get settingsAddUserTitle => '사용자 추가';

  @override
  String get settingsAddUserSubtitle => '추가 계정 생성';

  @override
  String get logoutDialogTitle => '로그아웃';

  @override
  String get logoutDialogContent => '로그아웃하시겠습니까?';

  @override
  String get cancelButton => '취소';

  @override
  String get logoutButton => '로그아웃';

  @override
  String get loggedOutMessage => '로그아웃되었습니다.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return '내보내기 완료: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return '내보내기 실패: $error';
  }

  @override
  String get exportPasswordTitle => '내보내기 암호화';

  @override
  String get exportPasswordSubtitle => '내보내기 파일을 암호화할 비밀번호를 설정하세요.';

  @override
  String get exportPasswordMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get importSelectFilesMessage => 'CSV 및 JSON 파일을 선택하세요.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return '가져오기 완료: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return '가져오기 실패: $error';
  }

  @override
  String get importFailedTitle => '가져오기 실패';

  @override
  String get addUserDialogTitle => '사용자 추가';

  @override
  String get saveButton => '저장';

  @override
  String get userAddedMessage => '사용자가 추가되었습니다.';

  @override
  String get invalidUserMessage => '유효하지 않은 사용자입니다.';

  @override
  String get deleteUserDialogTitle => '사용자 삭제';

  @override
  String deleteUserDialogContent(Object username) {
    return '$username를 삭제하시겠습니까?';
  }

  @override
  String get deleteButton => '삭제';

  @override
  String userDeletedMessage(Object username) {
    return '사용자 삭제됨: $username';
  }

  @override
  String get projectsTitle => '프로젝트';

  @override
  String get newProjectButton => '새 프로젝트';

  @override
  String get noProjectsYet => '아직 프로젝트가 없습니다';

  @override
  String get noProjectsFound => '프로젝트를 찾을 수 없습니다';

  @override
  String get loadingMoreProjects => '더 많은 프로젝트 로딩 중...';

  @override
  String get sortByLabel => '정렬 기준';

  @override
  String get projectSortName => '이름';

  @override
  String get projectSortProgress => '진행률';

  @override
  String get projectSortPriority => '우선순위';

  @override
  String get projectSortCreatedDate => '생성 날짜';

  @override
  String get projectSortStatus => '상태';

  @override
  String get projectSortStartDate => '시작 날짜';

  @override
  String get projectSortDueDate => '마감 날짜';

  @override
  String get sortDirectionLabel => '방향';

  @override
  String get sortAscendingLabel => '오름차순';

  @override
  String get sortDescendingLabel => '내림차순';

  @override
  String get exportToCsvLabel => 'CSV로 내보내기';

  @override
  String get csvExportSuccessMessage => 'CSV가 성공적으로 내보내지고 공유되었습니다';

  @override
  String get allLabel => '전체';

  @override
  String get loadProjectsFailed => '프로젝트 로드에 실패했습니다.';

  @override
  String projectSemanticsLabel(Object title) {
    return '프로젝트 $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return '상태 $status';
  }

  @override
  String get newProjectDialogTitle => '새 프로젝트';

  @override
  String get projectNameLabel => '프로젝트 이름';

  @override
  String get descriptionLabel => '설명';

  @override
  String get urgencyLabel => '긴급도';

  @override
  String get urgencyLow => '낮음';

  @override
  String get urgencyMedium => '중간';

  @override
  String get urgencyHigh => '높음';

  @override
  String projectCreatedMessage(Object name) {
    return '프로젝트 생성됨: $name';
  }

  @override
  String get projectDetailsTitle => '프로젝트 상세';

  @override
  String get aiChatWithProjectFilesTooltip => '프로젝트 파일로 AI 채팅';

  @override
  String get moreOptionsLabel => '추가 옵션';

  @override
  String get tasksTitle => '작업';

  @override
  String get tasksTab => '작업';

  @override
  String get detailsTab => '상세';

  @override
  String get tasksLoadFailed => '작업을 불러오지 못했습니다.';

  @override
  String get projectOverviewTitle => '프로젝트 개요';

  @override
  String get tasksLoading => '작업 로딩 중...';

  @override
  String get taskStatisticsTitle => '작업 통계';

  @override
  String get totalLabel => '전체';

  @override
  String get completedLabel => '완료';

  @override
  String get inProgressLabel => '진행 중';

  @override
  String get remainingLabel => '남음';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% 완료';
  }

  @override
  String get burndownChartTitle => '번다운 차트';

  @override
  String get chartPlaceholderTitle => '차트 자리표시자';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart 통합 예정';

  @override
  String get workflowsTitle => '워크플로';

  @override
  String get noWorkflowsAvailable => '사용 가능한 워크플로 항목이 없습니다.';

  @override
  String get taskStatusTodo => '할 일';

  @override
  String get taskStatusInProgress => '진행 중';

  @override
  String get taskStatusReview => '검토';

  @override
  String get taskStatusDone => '완료';

  @override
  String get workflowStatusActive => '활성';

  @override
  String get workflowStatusPending => '대기';

  @override
  String get noTasksYet => '아직 작업이 없습니다';

  @override
  String get projectTimeTitle => '프로젝트 시간';

  @override
  String urgencyValue(Object value) {
    return '긴급도: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return '추적된 시간: $value';
  }

  @override
  String get hourShort => '시간';

  @override
  String get minuteShort => '분';

  @override
  String get secondShort => '초';

  @override
  String get searchTasksHint => '작업 검색...';

  @override
  String get searchAttachmentsHint => '첨부 파일 검색...';

  @override
  String get clearSearchTooltip => '검색 지우기';

  @override
  String get projectMapTitle => '프로젝트 폴더';

  @override
  String get linkProjectMapButton => '프로젝트 폴더 연결';

  @override
  String get projectDataLoading => '프로젝트 데이터 로딩 중...';

  @override
  String get projectDataLoadFailed => '프로젝트 데이터 로드 실패.';

  @override
  String currentMapLabel(Object path) {
    return '현재 폴더: $path';
  }

  @override
  String get noProjectMapLinked => '연결된 폴더가 없습니다. 파일을 읽으려면 폴더를 연결하세요.';

  @override
  String get projectNotAvailable => '프로젝트를 사용할 수 없습니다.';

  @override
  String get enableConsentInSettings => '설정에서 권한을 활성화하세요.';

  @override
  String get projectMapLinked => '프로젝트 폴더가 연결되었습니다.';

  @override
  String get privacyWarningTitle => '개인정보 경고';

  @override
  String get privacyWarningContent => '경고: 민감한 데이터가 읽힐 수 있습니다.';

  @override
  String get continueButton => '계속';

  @override
  String get attachFilesTooltip => '파일 첨부';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AI 어시스턴트';

  @override
  String get welcomeBack => '다시 오신 것을 환영합니다! 👋';

  @override
  String get projectsOverviewSubtitle => '활성 프로젝트 요약입니다';

  @override
  String get recentWorkflowsTitle => '최근 워크플로';

  @override
  String get recentWorkflowsLoading => '최근 워크플로 로딩 중...';

  @override
  String get recentWorkflowsLoadFailed => '최근 워크플로 로드 실패.';

  @override
  String get retryButton => '다시 시도';

  @override
  String get noRecentTasks => '최근 작업이 없습니다.';

  @override
  String get unknownProject => '알 수 없는 프로젝트';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return '프로젝트 $projectName, 작업 $taskTitle, 상태 $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return '작업 $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes분 전';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours시간 전';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks주 전';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months개월 전';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return '$projectName 프로젝트 진행 차트. 완료 $completedPercent 퍼센트, 대기 $pendingPercent 퍼센트.';
  }

  @override
  String get progressLabel => '진행률';

  @override
  String completedPercentLabel(Object percent) {
    return '완료: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return '대기: $percent%';
  }

  @override
  String get noDescription => '설명 없음';

  @override
  String get closeButton => '닫기';

  @override
  String get burndownProgressTitle => '번다운 진행';

  @override
  String get actualProgressLabel => '실제 진행';

  @override
  String get idealTrendLabel => '이상적인 추세';

  @override
  String get statusLabel => '상태';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return '$projectName의 번다운 차트. 실제 포인트: $actualPoints. 이상적인 포인트: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'AI 채팅';

  @override
  String get aiAssistantTitle => 'AI 프로젝트 어시스턴트';

  @override
  String get clearChatTooltip => '채팅 지우기';

  @override
  String get noMessagesLabel => '메시지 없음';

  @override
  String get aiEmptyTitle => 'AI 어시스턴트와 대화를 시작하세요';

  @override
  String get aiEmptySubtitle => '예: \"프로젝트 계획 생성: 웹 상점\"';

  @override
  String get useProjectFilesLabel => '프로젝트 파일 사용';

  @override
  String get typeMessageHint => '메시지 입력...';

  @override
  String get projectFilesReadFailed => '프로젝트 파일을 읽지 못했습니다.';

  @override
  String get aiResponseFailedTitle => 'AI 응답 실패';

  @override
  String get sendMessageTooltip => '메시지 보내기';

  @override
  String get loginMissingCredentials => '사용자 이름과 비밀번호를 입력하세요.';

  @override
  String get loginFailedMessage => '로그인 실패. 자격 증명을 확인하세요.';

  @override
  String get registerTitle => '등록';

  @override
  String get languageLabel => '언어';

  @override
  String get languageSystem => '시스템 기본';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageDutch => '네덜란드어';

  @override
  String get languageSpanish => '스페인어';

  @override
  String get languageFrench => '프랑스어';

  @override
  String get languageGerman => '독일어';

  @override
  String get languagePortuguese => '포르투갈어';

  @override
  String get languageItalian => '이탈리아어';

  @override
  String get languageArabic => '아랍어';

  @override
  String get languageChinese => '중국어';

  @override
  String get languageJapanese => '일본어';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageRussian => '러시아어';

  @override
  String get languageHindi => '힌디어';

  @override
  String get repeatPasswordLabel => '비밀번호 다시 입력';

  @override
  String get passwordRulesTitle => '비밀번호 규칙';

  @override
  String get passwordRuleMinLength => '8자 이상';

  @override
  String get passwordRuleHasLetter => '문자 포함';

  @override
  String get passwordRuleHasDigit => '숫자 포함';

  @override
  String get passwordRuleMatches => '비밀번호가 일치함';

  @override
  String get registerButton => '등록';

  @override
  String get registrationIssueUsernameMissing => '사용자 이름 누락';

  @override
  String get registrationIssueMinLength => '8자 이상';

  @override
  String get registrationIssueLetter => '최소 1자';

  @override
  String get registrationIssueDigit => '최소 1숫자';

  @override
  String get registrationIssueNoMatch => '비밀번호가 일치하지 않음';

  @override
  String registrationFailedWithIssues(Object issues) {
    return '등록 실패: $issues.';
  }

  @override
  String get accountCreatedMessage => '계정이 생성되었습니다. 지금 로그인하세요.';

  @override
  String get registerFailedMessage => '등록 실패.';

  @override
  String get accessDeniedMessage => '접근이 거부되었습니다.';

  @override
  String get adminPanelTitle => '관리자 패널';

  @override
  String get adminPanelSubtitle => '역할, 그룹 및 권한 관리';

  @override
  String get rolesTitle => '역할';

  @override
  String get noRolesFound => '역할이 없습니다.';

  @override
  String permissionsCount(Object count) {
    return '권한: $count';
  }

  @override
  String get editPermissionsTooltip => '권한 편집';

  @override
  String get groupsTitle => '그룹';

  @override
  String get noGroupsFound => '그룹이 없습니다.';

  @override
  String get roleLabel => '역할';

  @override
  String get groupAddTitle => '그룹 추가';

  @override
  String get groupNameLabel => '그룹 이름';

  @override
  String get groupLabel => '그룹';

  @override
  String addGroupMemberTitle(Object groupName) {
    return '$groupName에 구성원 추가';
  }

  @override
  String get addGroupMemberTooltip => '구성원 추가';

  @override
  String groupMembersTitle(Object groupName) {
    return '그룹 구성원: $groupName';
  }

  @override
  String get noGroupMembers => '그룹 구성원이 없습니다.';

  @override
  String get removeGroupMemberTooltip => '구성원 제거';

  @override
  String get roleCreateTitle => '역할 만들기';

  @override
  String get roleNameLabel => '역할 이름';

  @override
  String get permissionsTitle => '권한';

  @override
  String get settingsBackupTitle => '백업 생성';

  @override
  String get settingsBackupSubtitle => 'Hive 데이터의 로컬 백업을 저장합니다.';

  @override
  String get settingsRestoreTitle => '백업 복원';

  @override
  String get settingsRestoreSubtitle => '로컬 데이터를 백업 파일로 대체합니다.';

  @override
  String backupSuccessMessage(Object path) {
    return '백업 저장됨: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return '백업 실패: $error';
  }

  @override
  String get restoreSuccessMessage => '백업이 복원되었습니다. 데이터를 다시 불러오려면 앱을 재시작하세요.';

  @override
  String restoreFailedMessage(Object error) {
    return '복원 실패: $error';
  }

  @override
  String get restoreConfirmTitle => '백업을 복원할까요?';

  @override
  String get restoreConfirmContent => '로컬 데이터가 덮어쓰기 됩니다.';

  @override
  String get restoreConfirmButton => '복원';

  @override
  String get settingsBackupLastRunLabel => '마지막 백업';

  @override
  String get backupNeverMessage => '없음';

  @override
  String get backupNowButton => '지금 백업';

  @override
  String get settingsBackupPathLabel => '백업 파일';

  @override
  String get backupNoFileMessage => '아직 백업 파일이 없습니다';

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
