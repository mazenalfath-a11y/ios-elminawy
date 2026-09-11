enum HomeSection {
  teachers,
  lastQuiz,
  reels,
  myCourses,
  availableCourses,
  categories,
}

class AppConfig {
  static const String teacherName = "الرياضه مع المنياوى";
  static const String teacherNumber = "201155771120";
  static const String facebookUrl = "";
  static const String suuportNumber = "201044690582";

  static const String apiBaseUrl = "https://me.genuisweb.com/app";
  static const String appVersion = "1.0.3";

  static const bool preventScreenShoot = true;
  static const bool notification = true;

  // Language and Theme Defaults
  static const String defaultLanguage = 'ar';
  static const bool defaultIsDarkMode = false;

  // Parent Phone Mandatory Setting:
  // - If true: when parent phone is enabled by company settings, it is strictly mandatory (11 digits required).
  // - If false: when parent phone is enabled by company settings, the field is shown on UI but optional for the student.
  static const bool isParentPhoneMandatory = true;

  // Language Selection Screen Control
  // Show language selection screen for unauthenticated users before login
  static const bool showLanguageSelectionScreen = false;

  // Home Page Section Controls
  // 1. Show or hide rank card (floating under header)
  static const bool showRankCard = true;

  // 2. Show or hide global leaderboard button inside rank card
  static const bool showGlobalLeaderboardButton = false;

  // 2. Order of home page scrollable sections
  static const List<HomeSection> homeSectionOrder = [
    HomeSection.teachers,
    HomeSection.lastQuiz,
    HomeSection.reels,
    HomeSection.myCourses,
    HomeSection.availableCourses,
    HomeSection.categories,
  ];

  // 3. Visibility of home page scrollable sections
  static const Map<HomeSection, bool> homeSectionVisibility = {
    HomeSection.teachers: true,
    HomeSection.lastQuiz: true,
    HomeSection.reels: true,
    HomeSection.myCourses: true,
    HomeSection.availableCourses: true,
    HomeSection.categories: true,
  };

  // Company code - if set, will be used automatically in registration
  // If empty, user will be prompted to enter it
  static const String companyCode = "250528";

  // Available companies - if not empty, user will select from this list
  // If empty, user will enter company code manually (if companyCode is also empty)
  static const List<Map<String, String>> availableCompanies = [
    // {"name": "Company Name", "code": "company_code"},
    // {"name": "Company Name2", "code": "company_code2"},
    // {"name": "Company Name3", "code": "company_code3"}
  ];

  // Registration Custom Labels Override
  // Set non-empty string to override default label in Ar / En
  static const String customEducationalStageAr =
      ''; // e.g. "المرحلة الدراسية" or "الكلية"
  static const String customEducationalStageEn =
      ''; // e.g. "Educational Stage" or "Faculty"

  static const String customAcademicYearAr =
      ''; // e.g. "اختر السنة الدراسية" or "الفرقة الدراسية"
  static const String customAcademicYearEn =
      ''; // e.g. "Select Academic Year" or "Academic Grade"
}
