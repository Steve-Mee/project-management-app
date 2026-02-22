// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق ادارة المشاريع';

  @override
  String get menuLabel => 'القائمة';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get createAccount => 'انشاء حساب';

  @override
  String get logoutTooltip => 'تسجيل الخروج';

  @override
  String get closeAppTooltip => 'اغلاق التطبيق';

  @override
  String get settingsTitle => 'الاعدادات';

  @override
  String get settingsDisplaySection => 'العرض';

  @override
  String get settingsDarkModeTitle => 'الوضع الداكن';

  @override
  String get settingsDarkModeSubtitle => 'التبديل بين الفاتح والداكن';

  @override
  String get settingsFollowSystemTitle => 'اتباع سمة النظام';

  @override
  String get settingsFollowSystemSubtitle => 'استخدام سمة الجهاز';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'اختيار لغة التطبيق';

  @override
  String get settingsNotificationsSection => 'الاشعارات';

  @override
  String get settingsNotificationsTitle => 'الاشعارات';

  @override
  String get settingsNotificationsSubtitle => 'التحديثات والتذكيرات';

  @override
  String get settingsPrivacySection => 'الخصوصية';

  @override
  String get settingsLocalFilesConsentTitle => 'اذن الملفات المحلية';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'السماح للتطبيق بقراءة ملفات المشروع المحلية لسياق الذكاء الاصطناعي.';

  @override
  String get settingsUseProjectFilesTitle => 'استخدام ملفات المشروع';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'اضافة ملفات محلية الى مطالبات الذكاء الاصطناعي';

  @override
  String get settingsProjectsSection => 'المشاريع';

  @override
  String get settingsLogoutTitle => 'تسجيل الخروج';

  @override
  String get settingsLogoutSubtitle => 'انهاء الجلسة الحالية';

  @override
  String get settingsExportTitle => 'تصدير المشاريع';

  @override
  String get settingsExportSubtitle => 'تصدير المشاريع الى ملف';

  @override
  String get settingsImportTitle => 'استيراد المشاريع';

  @override
  String get settingsImportSubtitle => 'استيراد المشاريع من ملف';

  @override
  String get settingsUsersSection => 'المستخدمون';

  @override
  String get settingsCurrentUserTitle => 'المستخدم الحالي';

  @override
  String get settingsNotLoggedIn => 'غير مسجل الدخول';

  @override
  String get settingsNoUsersFound => 'لم يتم العثور على مستخدمين.';

  @override
  String get settingsLocalUserLabel => 'مستخدم محلي';

  @override
  String get settingsDeleteTooltip => 'حذف';

  @override
  String get settingsLoadUsersFailed => 'فشل تحميل المستخدمين';

  @override
  String get settingsAddUserTitle => 'اضافة مستخدم';

  @override
  String get settingsAddUserSubtitle => 'اضافة حساب اضافي';

  @override
  String get logoutDialogTitle => 'تسجيل الخروج';

  @override
  String get logoutDialogContent => 'هل تريد تسجيل الخروج؟';

  @override
  String get cancelButton => 'الغاء';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get loggedOutMessage => 'تم تسجيل الخروج.';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'اكتمل التصدير: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get exportPasswordTitle => 'تشفير التصدير';

  @override
  String get exportPasswordSubtitle =>
      'قم بتعيين كلمة مرور لتشفير ملفات التصدير.';

  @override
  String get exportPasswordMismatch => 'كلمات المرور غير متطابقة.';

  @override
  String get importSelectFilesMessage => 'حدد ملف CSV و JSON.';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'اكتمل الاستيراد: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get importFailedTitle => 'فشل الاستيراد';

  @override
  String get addUserDialogTitle => 'اضافة مستخدم';

  @override
  String get saveButton => 'حفظ';

  @override
  String get userAddedMessage => 'تمت اضافة المستخدم.';

  @override
  String get invalidUserMessage => 'مستخدم غير صالح.';

  @override
  String get deleteUserDialogTitle => 'حذف المستخدم';

  @override
  String deleteUserDialogContent(Object username) {
    return 'هل تريد حذف $username؟';
  }

  @override
  String get deleteButton => 'حذف';

  @override
  String userDeletedMessage(Object username) {
    return 'تم حذف المستخدم: $username';
  }

  @override
  String get projectsTitle => 'المشاريع';

  @override
  String get newProjectButton => 'مشروع جديد';

  @override
  String get noProjectsYet => 'لا توجد مشاريع بعد';

  @override
  String get noProjectsFound => 'لم يتم العثور على مشاريع';

  @override
  String get loadingMoreProjects => 'جاري تحميل المزيد من المشاريع...';

  @override
  String get sortByLabel => 'ترتيب حسب';

  @override
  String get projectSortName => 'الاسم';

  @override
  String get projectSortProgress => 'التقدم';

  @override
  String get projectSortPriority => 'الاولوية';

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
  String get allLabel => 'الكل';

  @override
  String get loadProjectsFailed => 'فشل تحميل المشاريع.';

  @override
  String projectSemanticsLabel(Object title) {
    return 'مشروع $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'الحالة $status';
  }

  @override
  String get newProjectDialogTitle => 'مشروع جديد';

  @override
  String get projectNameLabel => 'اسم المشروع';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get urgencyLabel => 'الاستعجال';

  @override
  String get urgencyLow => 'منخفض';

  @override
  String get urgencyMedium => 'متوسط';

  @override
  String get urgencyHigh => 'مرتفع';

  @override
  String projectCreatedMessage(Object name) {
    return 'تم انشاء المشروع: $name';
  }

  @override
  String get projectDetailsTitle => 'تفاصيل المشروع';

  @override
  String get aiChatWithProjectFilesTooltip =>
      'دردشة ذكاء اصطناعي مع ملفات المشروع';

  @override
  String get moreOptionsLabel => 'المزيد من الخيارات';

  @override
  String get tasksTitle => 'المهام';

  @override
  String get tasksTab => 'المهام';

  @override
  String get detailsTab => 'التفاصيل';

  @override
  String get tasksLoadFailed => 'فشل تحميل المهام.';

  @override
  String get projectOverviewTitle => 'نظرة عامة على المشروع';

  @override
  String get tasksLoading => 'جاري تحميل المهام...';

  @override
  String get taskStatisticsTitle => 'احصاءات المهام';

  @override
  String get totalLabel => 'الاجمالي';

  @override
  String get completedLabel => 'مكتملة';

  @override
  String get inProgressLabel => 'قيد التنفيذ';

  @override
  String get remainingLabel => 'المتبقية';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% مكتمل';
  }

  @override
  String get burndownChartTitle => 'مخطط الاحتراق';

  @override
  String get chartPlaceholderTitle => 'عنصر نائب للرسم';

  @override
  String get chartPlaceholderSubtitle => 'تكامل fl_chart قريبا';

  @override
  String get workflowsTitle => 'سير العمل';

  @override
  String get noWorkflowsAvailable => 'لا توجد عناصر سير عمل.';

  @override
  String get taskStatusTodo => 'للقيام';

  @override
  String get taskStatusInProgress => 'قيد التنفيذ';

  @override
  String get taskStatusReview => 'مراجعة';

  @override
  String get taskStatusDone => 'تم';

  @override
  String get workflowStatusActive => 'نشط';

  @override
  String get workflowStatusPending => 'معلق';

  @override
  String get noTasksYet => 'لا توجد مهام بعد';

  @override
  String get projectTimeTitle => 'وقت المشروع';

  @override
  String urgencyValue(Object value) {
    return 'الاستعجال: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'الوقت المسجل: $value';
  }

  @override
  String get hourShort => 'س';

  @override
  String get minuteShort => 'د';

  @override
  String get secondShort => 'ث';

  @override
  String get searchTasksHint => 'ابحث عن المهام...';

  @override
  String get searchAttachmentsHint => 'ابحث عن المرفقات...';

  @override
  String get clearSearchTooltip => 'مسح البحث';

  @override
  String get projectMapTitle => 'مجلد المشروع';

  @override
  String get linkProjectMapButton => 'ربط مجلد المشروع';

  @override
  String get projectDataLoading => 'جاري تحميل بيانات المشروع...';

  @override
  String get projectDataLoadFailed => 'فشل تحميل بيانات المشروع.';

  @override
  String currentMapLabel(Object path) {
    return 'المجلد الحالي: $path';
  }

  @override
  String get noProjectMapLinked =>
      'لا يوجد مجلد مرتبط. اربط مجلدا لقراءة الملفات.';

  @override
  String get projectNotAvailable => 'المشروع غير متاح.';

  @override
  String get enableConsentInSettings => 'فعّل الاذن في الاعدادات.';

  @override
  String get projectMapLinked => 'تم ربط مجلد المشروع.';

  @override
  String get privacyWarningTitle => 'تحذير الخصوصية';

  @override
  String get privacyWarningContent => 'تحذير: قد تتم قراءة بيانات حساسة.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get attachFilesTooltip => 'ارفاق ملفات';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'مساعد الذكاء الاصطناعي';

  @override
  String get welcomeBack => 'اهلا بعودتك! 👋';

  @override
  String get projectsOverviewSubtitle => 'اليك نظرة عامة على مشاريعك النشطة';

  @override
  String get recentWorkflowsTitle => 'سير العمل الاحدث';

  @override
  String get recentWorkflowsLoading => 'جاري تحميل سير العمل الاحدث...';

  @override
  String get recentWorkflowsLoadFailed => 'فشل تحميل سير العمل الاحدث.';

  @override
  String get retryButton => 'اعادة المحاولة';

  @override
  String get noRecentTasks => 'لا توجد مهام حديثة.';

  @override
  String get unknownProject => 'مشروع غير معروف';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'المشروع $projectName، المهمة $taskTitle، الحالة $statusLabel، $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'المهمة $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'الان';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'قبل $hours ساعة';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'قبل $days يوم';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return 'قبل $weeks اسبوع';
  }

  @override
  String timeMonthsAgo(Object months) {
    return 'قبل $months شهر';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return 'مخطط تقدم المشروع لـ $projectName. مكتمل $completedPercent بالمئة، معلّق $pendingPercent بالمئة.';
  }

  @override
  String get progressLabel => 'التقدم';

  @override
  String completedPercentLabel(Object percent) {
    return 'مكتمل: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'معلق: $percent%';
  }

  @override
  String get noDescription => 'لا يوجد وصف';

  @override
  String get closeButton => 'اغلاق';

  @override
  String get burndownProgressTitle => 'تقدم مخطط الاحتراق';

  @override
  String get actualProgressLabel => 'التقدم الفعلي';

  @override
  String get idealTrendLabel => 'الاتجاه المثالي';

  @override
  String get statusLabel => 'الحالة';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return 'مخطط الاحتراق لـ $projectName. نقاط فعلية: $actualPoints. نقاط مثالية: $idealPoints.';
  }

  @override
  String get aiChatSemanticsLabel => 'دردشة الذكاء الاصطناعي';

  @override
  String get aiAssistantTitle => 'مساعد مشاريع بالذكاء الاصطناعي';

  @override
  String get clearChatTooltip => 'مسح الدردشة';

  @override
  String get noMessagesLabel => 'لا توجد رسائل';

  @override
  String get aiEmptyTitle => 'ابدأ محادثة مع مساعد الذكاء الاصطناعي';

  @override
  String get aiEmptySubtitle => 'مثال: \"انشئ خطة للمشروع: متجر ويب\"';

  @override
  String get useProjectFilesLabel => 'استخدام ملفات المشروع';

  @override
  String get typeMessageHint => 'اكتب رسالة...';

  @override
  String get projectFilesReadFailed => 'فشل قراءة ملفات المشروع.';

  @override
  String get aiResponseFailedTitle => 'فشل رد الذكاء الاصطناعي';

  @override
  String get sendMessageTooltip => 'ارسال الرسالة';

  @override
  String get loginMissingCredentials => 'ادخل اسم المستخدم وكلمة المرور.';

  @override
  String get loginFailedMessage => 'فشل تسجيل الدخول. تحقق من بياناتك.';

  @override
  String rateLimitExceeded(Object seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get registerTitle => 'تسجيل';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageSystem => 'افتراضي النظام';

  @override
  String get languageEnglish => 'الانجليزية';

  @override
  String get languageDutch => 'الهولندية';

  @override
  String get languageSpanish => 'الاسبانية';

  @override
  String get languageFrench => 'الفرنسية';

  @override
  String get languageGerman => 'الالمانية';

  @override
  String get languagePortuguese => 'البرتغالية';

  @override
  String get languageItalian => 'الايطالية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageChinese => 'الصينية';

  @override
  String get languageJapanese => 'اليابانية';

  @override
  String get languageKorean => 'الكورية';

  @override
  String get languageRussian => 'الروسية';

  @override
  String get languageHindi => 'الهندية';

  @override
  String get repeatPasswordLabel => 'اعادة كلمة المرور';

  @override
  String get passwordRulesTitle => 'قواعد كلمة المرور';

  @override
  String get passwordRuleMinLength => '8 احرف على الاقل';

  @override
  String get passwordRuleHasLetter => 'تحتوي على حرف';

  @override
  String get passwordRuleHasDigit => 'تحتوي على رقم';

  @override
  String get passwordRuleMatches => 'كلمتا المرور متطابقتان';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get registrationIssueUsernameMissing => 'اسم المستخدم مفقود';

  @override
  String get registrationIssueMinLength => 'ثمانية احرف على الاقل';

  @override
  String get registrationIssueLetter => 'حرف واحد على الاقل';

  @override
  String get registrationIssueDigit => 'رقم واحد على الاقل';

  @override
  String get registrationIssueNoMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'فشل التسجيل: $issues.';
  }

  @override
  String get accountCreatedMessage => 'تم انشاء الحساب. سجل الدخول الان.';

  @override
  String get registerFailedMessage => 'فشل التسجيل.';

  @override
  String get accessDeniedMessage => 'تم رفض الوصول.';

  @override
  String get adminPanelTitle => 'لوحة المشرف';

  @override
  String get adminPanelSubtitle => 'إدارة الأدوار والمجموعات والأذونات.';

  @override
  String get rolesTitle => 'الأدوار';

  @override
  String get noRolesFound => 'لم يتم العثور على أدوار.';

  @override
  String permissionsCount(Object count) {
    return 'عدد الأذونات: $count';
  }

  @override
  String get editPermissionsTooltip => 'تعديل الأذونات';

  @override
  String get groupsTitle => 'المجموعات';

  @override
  String get noGroupsFound => 'لم يتم العثور على مجموعات.';

  @override
  String get roleLabel => 'الدور';

  @override
  String get groupAddTitle => 'إضافة مجموعة';

  @override
  String get groupNameLabel => 'اسم المجموعة';

  @override
  String get groupLabel => 'مجموعة';

  @override
  String addGroupMemberTitle(Object groupName) {
    return 'إضافة عضو إلى $groupName';
  }

  @override
  String get addGroupMemberTooltip => 'إضافة عضو';

  @override
  String groupMembersTitle(Object groupName) {
    return 'أعضاء المجموعة: $groupName';
  }

  @override
  String get noGroupMembers => 'لا يوجد أعضاء في المجموعة.';

  @override
  String get removeGroupMemberTooltip => 'إزالة عضو';

  @override
  String get roleCreateTitle => 'إنشاء دور';

  @override
  String get roleNameLabel => 'اسم الدور';

  @override
  String get permissionsTitle => 'الأذونات';

  @override
  String get settingsBackupTitle => 'إنشاء نسخة احتياطية';

  @override
  String get settingsBackupSubtitle => 'احفظ نسخة احتياطية محلية لبيانات Hive.';

  @override
  String get settingsRestoreTitle => 'استعادة نسخة احتياطية';

  @override
  String get settingsRestoreSubtitle =>
      'استبدل البيانات المحلية بملف النسخة الاحتياطية.';

  @override
  String backupSuccessMessage(Object path) {
    return 'تم حفظ النسخة الاحتياطية: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'فشل النسخ الاحتياطي: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'تمت استعادة النسخة الاحتياطية. أعد تشغيل التطبيق لتحميل البيانات.';

  @override
  String restoreFailedMessage(Object error) {
    return 'فشلت الاستعادة: $error';
  }

  @override
  String get restoreConfirmTitle => 'استعادة النسخة الاحتياطية؟';

  @override
  String get restoreConfirmContent => 'سيؤدي ذلك إلى استبدال بياناتك المحلية.';

  @override
  String get restoreConfirmButton => 'استعادة';

  @override
  String get settingsBackupLastRunLabel => 'آخر نسخة احتياطية';

  @override
  String get backupNeverMessage => 'أبدًا';

  @override
  String get backupNowButton => 'نسخ احتياطي الآن';

  @override
  String get settingsBackupPathLabel => 'ملف النسخة الاحتياطية';

  @override
  String get backupNoFileMessage => 'لا يوجد ملف نسخة احتياطية بعد';

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
}
