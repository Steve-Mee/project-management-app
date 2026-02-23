// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'प्रोजेक्ट प्रबंधन ऐप';

  @override
  String get menuLabel => 'मेनू';

  @override
  String get loginTitle => 'लॉगिन';

  @override
  String get usernameLabel => 'यूज़रनेम';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get logoutTooltip => 'लॉगआउट';

  @override
  String get closeAppTooltip => 'ऐप बंद करें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsDisplaySection => 'डिस्प्ले';

  @override
  String get settingsDarkModeTitle => 'डार्क मोड';

  @override
  String get settingsDarkModeSubtitle => 'लाइट और डार्क में बदलें';

  @override
  String get settingsFollowSystemTitle => 'सिस्टम थीम का पालन करें';

  @override
  String get settingsFollowSystemSubtitle => 'डिवाइस थीम का उपयोग करें';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSubtitle => 'ऐप की भाषा चुनें';

  @override
  String get settingsNotificationsSection => 'सूचनाएं';

  @override
  String get settingsNotificationsTitle => 'सूचनाएं';

  @override
  String get settingsNotificationsSubtitle => 'अपडेट और रिमाइंडर';

  @override
  String get settingsPrivacySection => 'गोपनीयता';

  @override
  String get settingsLocalFilesConsentTitle => 'लोकल फाइल अनुमति';

  @override
  String get settingsLocalFilesConsentSubtitle =>
      'AI संदर्भ के लिए ऐप को लोकल प्रोजेक्ट फाइलें पढ़ने की अनुमति दें।';

  @override
  String get settingsUseProjectFilesTitle => 'प्रोजेक्ट फाइलें उपयोग करें';

  @override
  String get settingsUseProjectFilesSubtitle =>
      'लोकल फाइलें AI प्रॉम्प्ट में जोड़ें';

  @override
  String get settingsProjectsSection => 'प्रोजेक्ट';

  @override
  String get settingsLogoutTitle => 'लॉगआउट';

  @override
  String get settingsLogoutSubtitle => 'वर्तमान सत्र समाप्त करें';

  @override
  String get settingsExportTitle => 'प्रोजेक्ट निर्यात करें';

  @override
  String get settingsExportSubtitle => 'प्रोजेक्ट को फाइल में निर्यात करें';

  @override
  String get settingsImportTitle => 'प्रोजेक्ट आयात करें';

  @override
  String get settingsImportSubtitle => 'फाइल से प्रोजेक्ट आयात करें';

  @override
  String get settingsUsersSection => 'यूज़र';

  @override
  String get settingsCurrentUserTitle => 'वर्तमान यूज़र';

  @override
  String get settingsNotLoggedIn => 'लॉगिन नहीं है';

  @override
  String get settingsNoUsersFound => 'कोई यूज़र नहीं मिला।';

  @override
  String get settingsLocalUserLabel => 'लोकल यूज़र';

  @override
  String get settingsDeleteTooltip => 'हटाएं';

  @override
  String get settingsLoadUsersFailed => 'यूज़र लोड नहीं हो सके';

  @override
  String get settingsAddUserTitle => 'यूज़र जोड़ें';

  @override
  String get settingsAddUserSubtitle => 'एक अतिरिक्त खाता जोड़ें';

  @override
  String get logoutDialogTitle => 'लॉगआउट';

  @override
  String get logoutDialogContent => 'क्या आप लॉगआउट करना चाहते हैं?';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get logoutButton => 'लॉगआउट';

  @override
  String get loggedOutMessage => 'आप लॉगआउट हो गए हैं।';

  @override
  String exportCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'निर्यात पूरा: $projectsPath, $tasksPath';
  }

  @override
  String exportFailedMessage(Object error) {
    return 'निर्यात असफल: $error';
  }

  @override
  String get exportPasswordTitle => 'एक्सपोर्ट एन्क्रिप्ट करें';

  @override
  String get exportPasswordSubtitle =>
      'एक्सपोर्ट फाइलों को एन्क्रिप्ट करने के लिए पासवर्ड सेट करें।';

  @override
  String get exportPasswordMismatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get importSelectFilesMessage => 'कृपया CSV और JSON फाइल चुनें।';

  @override
  String importCompleteMessage(Object projectsPath, Object tasksPath) {
    return 'आयात पूरा: $projectsPath, $tasksPath';
  }

  @override
  String importFailedMessage(Object error) {
    return 'आयात असफल: $error';
  }

  @override
  String get importFailedTitle => 'आयात असफल';

  @override
  String get addUserDialogTitle => 'यूज़र जोड़ें';

  @override
  String get saveButton => 'सेव करें';

  @override
  String get userAddedMessage => 'यूज़र जोड़ा गया।';

  @override
  String get invalidUserMessage => 'अमान्य यूज़र।';

  @override
  String get deleteUserDialogTitle => 'यूज़र हटाएं';

  @override
  String deleteUserDialogContent(Object username) {
    return 'क्या आप $username को हटाना चाहते हैं?';
  }

  @override
  String get deleteButton => 'हटाएं';

  @override
  String userDeletedMessage(Object username) {
    return 'यूज़र हटाया गया: $username';
  }

  @override
  String get projectsTitle => 'प्रोजेक्ट';

  @override
  String get newProjectButton => 'नया प्रोजेक्ट';

  @override
  String get noProjectsYet => 'अभी कोई प्रोजेक्ट नहीं';

  @override
  String get noProjectsFound => 'कोई प्रोजेक्ट नहीं मिला';

  @override
  String get loadingMoreProjects => 'और प्रोजेक्ट लोड हो रहे हैं...';

  @override
  String get sortByLabel => 'क्रमबद्ध करें';

  @override
  String get projectSortName => 'नाम';

  @override
  String get projectSortProgress => 'प्रगति';

  @override
  String get projectSortPriority => 'प्राथमिकता';

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
  String get allLabel => 'सभी';

  @override
  String get loadProjectsFailed => 'प्रोजेक्ट लोड नहीं हो सके।';

  @override
  String projectSemanticsLabel(Object title) {
    return 'प्रोजेक्ट $title';
  }

  @override
  String statusSemanticsLabel(Object status) {
    return 'स्थिति $status';
  }

  @override
  String get newProjectDialogTitle => 'नया प्रोजेक्ट';

  @override
  String get projectNameLabel => 'प्रोजेक्ट नाम';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get urgencyLabel => 'तात्कालिकता';

  @override
  String get urgencyLow => 'कम';

  @override
  String get urgencyMedium => 'मध्यम';

  @override
  String get urgencyHigh => 'उच्च';

  @override
  String projectCreatedMessage(Object name) {
    return 'प्रोजेक्ट बनाया गया: $name';
  }

  @override
  String get projectDetailsTitle => 'प्रोजेक्ट विवरण';

  @override
  String get aiChatWithProjectFilesTooltip => 'प्रोजेक्ट फाइलों के साथ AI चैट';

  @override
  String get moreOptionsLabel => 'और विकल्प';

  @override
  String get tasksTitle => 'कार्य';

  @override
  String get tasksTab => 'कार्य';

  @override
  String get detailsTab => 'विवरण';

  @override
  String get tasksLoadFailed => 'कार्य लोड नहीं हो सके।';

  @override
  String get projectOverviewTitle => 'प्रोजेक्ट अवलोकन';

  @override
  String get tasksLoading => 'कार्य लोड हो रहे हैं...';

  @override
  String get taskStatisticsTitle => 'कार्य सांख्यिकी';

  @override
  String get totalLabel => 'कुल';

  @override
  String get completedLabel => 'पूरा';

  @override
  String get inProgressLabel => 'चल रहा';

  @override
  String get remainingLabel => 'शेष';

  @override
  String completionPercentLabel(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get burndownChartTitle => 'बरडाउन चार्ट';

  @override
  String get chartPlaceholderTitle => 'चार्ट प्लेसहोल्डर';

  @override
  String get chartPlaceholderSubtitle => 'fl_chart एकीकरण जल्द आ रहा है';

  @override
  String get workflowsTitle => 'वर्कफ़्लो';

  @override
  String get noWorkflowsAvailable => 'कोई वर्कफ़्लो आइटम उपलब्ध नहीं।';

  @override
  String get taskStatusTodo => 'करना है';

  @override
  String get taskStatusInProgress => 'चल रहा';

  @override
  String get taskStatusReview => 'समीक्षा';

  @override
  String get taskStatusDone => 'पूरा';

  @override
  String get workflowStatusActive => 'सक्रिय';

  @override
  String get workflowStatusPending => 'लंबित';

  @override
  String get noTasksYet => 'अभी कोई कार्य नहीं';

  @override
  String get projectTimeTitle => 'प्रोजेक्ट समय';

  @override
  String urgencyValue(Object value) {
    return 'तात्कालिकता: $value';
  }

  @override
  String trackedTimeValue(Object value) {
    return 'ट्रैक किया गया समय: $value';
  }

  @override
  String get hourShort => 'घं';

  @override
  String get minuteShort => 'मि';

  @override
  String get secondShort => 'से';

  @override
  String get searchTasksHint => 'कार्य खोजें...';

  @override
  String get searchAttachmentsHint => 'अटैचमेंट खोजें...';

  @override
  String get clearSearchTooltip => 'खोज साफ करें';

  @override
  String get projectMapTitle => 'प्रोजेक्ट फ़ोल्डर';

  @override
  String get linkProjectMapButton => 'प्रोजेक्ट फ़ोल्डर लिंक करें';

  @override
  String get projectDataLoading => 'प्रोजेक्ट डेटा लोड हो रहा है...';

  @override
  String get projectDataLoadFailed => 'प्रोजेक्ट डेटा लोड नहीं हो सका।';

  @override
  String currentMapLabel(Object path) {
    return 'वर्तमान फ़ोल्डर: $path';
  }

  @override
  String get noProjectMapLinked =>
      'कोई फ़ोल्डर लिंक नहीं है। फ़ाइलें पढ़ने के लिए फ़ोल्डर लिंक करें।';

  @override
  String get projectNotAvailable => 'प्रोजेक्ट उपलब्ध नहीं है।';

  @override
  String get enableConsentInSettings => 'सेटिंग्स में अनुमति सक्षम करें।';

  @override
  String get projectMapLinked => 'प्रोजेक्ट फ़ोल्डर लिंक हो गया।';

  @override
  String get privacyWarningTitle => 'गोपनीयता चेतावनी';

  @override
  String get privacyWarningContent =>
      'चेतावनी: संवेदनशील डेटा पढ़ा जा सकता है।';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get attachFilesTooltip => 'फाइलें संलग्न करें';

  @override
  String moreAttachmentsLabel(Object count) {
    return '+$count';
  }

  @override
  String get aiAssistantLabel => 'AI सहायक';

  @override
  String get welcomeBack => 'वापस स्वागत है! 👋';

  @override
  String get projectsOverviewSubtitle =>
      'यह आपके सक्रिय प्रोजेक्ट्स का सारांश है';

  @override
  String get recentWorkflowsTitle => 'हाल के वर्कफ़्लो';

  @override
  String get recentWorkflowsLoading => 'हाल के वर्कफ़्लो लोड हो रहे हैं...';

  @override
  String get recentWorkflowsLoadFailed => 'हाल के वर्कफ़्लो लोड नहीं हो सके।';

  @override
  String get retryButton => 'फिर से प्रयास करें';

  @override
  String get noRecentTasks => 'कोई हालिया कार्य उपलब्ध नहीं।';

  @override
  String get unknownProject => 'अज्ञात प्रोजेक्ट';

  @override
  String projectTaskStatusSemantics(
    Object projectName,
    Object taskTitle,
    Object statusLabel,
    Object timeLabel,
  ) {
    return 'प्रोजेक्ट $projectName, कार्य $taskTitle, स्थिति $statusLabel, $timeLabel';
  }

  @override
  String taskStatusSemantics(Object taskTitle, Object statusLabel) {
    return 'कार्य $taskTitle $statusLabel';
  }

  @override
  String get timeJustNow => 'अभी';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours घंटे पहले';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days दिन पहले';
  }

  @override
  String timeWeeksAgo(Object weeks) {
    return '$weeks सप्ताह पहले';
  }

  @override
  String timeMonthsAgo(Object months) {
    return '$months महीने पहले';
  }

  @override
  String projectProgressChartSemantics(
    Object projectName,
    Object completedPercent,
    Object pendingPercent,
  ) {
    return '$projectName के लिए प्रगति चार्ट। पूरा $completedPercent प्रतिशत, लंबित $pendingPercent प्रतिशत।';
  }

  @override
  String get progressLabel => 'प्रगति';

  @override
  String completedPercentLabel(Object percent) {
    return 'पूरा: $percent%';
  }

  @override
  String pendingPercentLabel(Object percent) {
    return 'लंबित: $percent%';
  }

  @override
  String get noDescription => 'कोई विवरण नहीं';

  @override
  String get closeButton => 'बंद करें';

  @override
  String get burndownProgressTitle => 'बरडाउन प्रगति';

  @override
  String get actualProgressLabel => 'वास्तविक प्रगति';

  @override
  String get idealTrendLabel => 'आदर्श प्रवृत्ति';

  @override
  String get statusLabel => 'स्थिति';

  @override
  String burndownChartSemantics(
    Object projectName,
    Object actualPoints,
    Object idealPoints,
  ) {
    return '$projectName के लिए बरडाउन चार्ट। वास्तविक बिंदु: $actualPoints। आदर्श बिंदु: $idealPoints।';
  }

  @override
  String get aiChatSemanticsLabel => 'AI चैट';

  @override
  String get aiAssistantTitle => 'AI प्रोजेक्ट सहायक';

  @override
  String get clearChatTooltip => 'चैट साफ करें';

  @override
  String get noMessagesLabel => 'कोई संदेश नहीं';

  @override
  String get aiEmptyTitle => 'AI सहायक से बातचीत शुरू करें';

  @override
  String get aiEmptySubtitle =>
      'उदाहरण: \"प्रोजेक्ट के लिए योजना बनाएं: वेब शॉप\"';

  @override
  String get useProjectFilesLabel => 'प्रोजेक्ट फाइलें उपयोग करें';

  @override
  String get typeMessageHint => 'संदेश लिखें...';

  @override
  String get projectFilesReadFailed => 'प्रोजेक्ट फाइलें पढ़ने में विफल।';

  @override
  String get aiResponseFailedTitle => 'AI उत्तर विफल';

  @override
  String get sendMessageTooltip => 'संदेश भेजें';

  @override
  String get loginMissingCredentials => 'कृपया यूज़रनेम और पासवर्ड दर्ज करें।';

  @override
  String get loginFailedMessage => 'लॉगिन विफल। कृपया अपनी जानकारी जांचें।';

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
  String get registerTitle => 'रजिस्टर';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageDutch => 'डच';

  @override
  String get languageSpanish => 'स्पेनिश';

  @override
  String get languageFrench => 'फ्रेंच';

  @override
  String get languageGerman => 'जर्मन';

  @override
  String get languagePortuguese => 'पुर्तगाली';

  @override
  String get languageItalian => 'इटालियन';

  @override
  String get languageArabic => 'अरबी';

  @override
  String get languageChinese => 'चीनी';

  @override
  String get languageJapanese => 'जापानी';

  @override
  String get languageKorean => 'कोरियन';

  @override
  String get languageRussian => 'रूसी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get repeatPasswordLabel => 'पासवर्ड दोबारा';

  @override
  String get passwordRulesTitle => 'पासवर्ड नियम';

  @override
  String get passwordRuleMinLength => 'कम से कम 8 अक्षर';

  @override
  String get passwordRuleHasLetter => 'एक अक्षर शामिल';

  @override
  String get passwordRuleHasDigit => 'एक अंक शामिल';

  @override
  String get passwordRuleMatches => 'पासवर्ड मेल खाते हैं';

  @override
  String get registerButton => 'रजिस्टर';

  @override
  String get registrationIssueUsernameMissing => 'यूज़रनेम नहीं है';

  @override
  String get registrationIssueMinLength => 'कम से कम 8 अक्षर';

  @override
  String get registrationIssueLetter => 'कम से कम 1 अक्षर';

  @override
  String get registrationIssueDigit => 'कम से कम 1 अंक';

  @override
  String get registrationIssueNoMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String registrationFailedWithIssues(Object issues) {
    return 'रजिस्ट्रेशन विफल: $issues।';
  }

  @override
  String get accountCreatedMessage => 'खाता बन गया। अब लॉगिन करें।';

  @override
  String get registerFailedMessage => 'रजिस्ट्रेशन विफल।';

  @override
  String get accessDeniedMessage => 'पहुंच अस्वीकृत.';

  @override
  String get adminPanelTitle => 'एडमिन पैनल';

  @override
  String get adminPanelSubtitle => 'भूमिकाएँ, समूह और अनुमतियाँ प्रबंधित करें.';

  @override
  String get rolesTitle => 'भूमिकाएँ';

  @override
  String get noRolesFound => 'कोई भूमिका नहीं मिली.';

  @override
  String permissionsCount(Object count) {
    return 'अनुमतियाँ: $count';
  }

  @override
  String get editPermissionsTooltip => 'अनुमतियाँ संपादित करें';

  @override
  String get groupsTitle => 'समूह';

  @override
  String get noGroupsFound => 'कोई समूह नहीं मिला.';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get groupAddTitle => 'समूह जोड़ें';

  @override
  String get groupNameLabel => 'समूह का नाम';

  @override
  String get groupLabel => 'समूह';

  @override
  String addGroupMemberTitle(Object groupName) {
    return '$groupName में सदस्य जोड़ें';
  }

  @override
  String get addGroupMemberTooltip => 'सदस्य जोड़ें';

  @override
  String groupMembersTitle(Object groupName) {
    return 'समूह के सदस्य: $groupName';
  }

  @override
  String get noGroupMembers => 'समूह में कोई सदस्य नहीं है.';

  @override
  String get removeGroupMemberTooltip => 'सदस्य हटाएँ';

  @override
  String get roleCreateTitle => 'भूमिका बनाएँ';

  @override
  String get roleNameLabel => 'भूमिका का नाम';

  @override
  String get permissionsTitle => 'अनुमतियाँ';

  @override
  String get settingsBackupTitle => 'बैकअप बनाएं';

  @override
  String get settingsBackupSubtitle => 'हाइव डेटा का स्थानीय बैकअप सहेजें.';

  @override
  String get settingsRestoreTitle => 'बैकअप पुनर्स्थापित करें';

  @override
  String get settingsRestoreSubtitle => 'स्थानीय डेटा को बैकअप फ़ाइल से बदलें.';

  @override
  String backupSuccessMessage(Object path) {
    return 'बैकअप सहेजा गया: $path';
  }

  @override
  String backupFailedMessage(Object error) {
    return 'बैकअप असफल: $error';
  }

  @override
  String get restoreSuccessMessage =>
      'बैकअप पुनर्स्थापित हो गया। डेटा लोड करने के लिए ऐप रीस्टार्ट करें.';

  @override
  String restoreFailedMessage(Object error) {
    return 'पुनर्स्थापना असफल: $error';
  }

  @override
  String get restoreConfirmTitle => 'बैकअप पुनर्स्थापित करें?';

  @override
  String get restoreConfirmContent => 'इससे स्थानीय डेटा ओवरराइट होगा.';

  @override
  String get restoreConfirmButton => 'पुनर्स्थापित करें';

  @override
  String get settingsBackupLastRunLabel => 'अंतिम बैकअप';

  @override
  String get backupNeverMessage => 'कभी नहीं';

  @override
  String get backupNowButton => 'अब बैकअप करें';

  @override
  String get settingsBackupPathLabel => 'बैकअप फ़ाइल';

  @override
  String get backupNoFileMessage => 'अभी कोई बैकअप फ़ाइल नहीं है';

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

  @override
  String get ai_usage_charts => 'AI Usage Charts';

  @override
  String get export_csv => 'Export CSV';

  @override
  String get average_cost => 'Average Cost';

  @override
  String get peak_times => 'Peak Times';
}
