import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @myAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get myAccount;

  /// No description provided for @exams.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات'**
  String get exams;

  /// No description provided for @courses.
  ///
  /// In ar, this message translates to:
  /// **'كورساتي'**
  String get courses;

  /// No description provided for @videos.
  ///
  /// In ar, this message translates to:
  /// **'فيديوهات'**
  String get videos;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @userName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get userName;

  /// No description provided for @online.
  ///
  /// In ar, this message translates to:
  /// **'اونلاين'**
  String get online;

  /// No description provided for @editGroup.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المجموعة'**
  String get editGroup;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @contactTeacherWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'عبر واتساب'**
  String get contactTeacherWhatsapp;

  /// No description provided for @contactTeacherFacebook.
  ///
  /// In ar, this message translates to:
  /// **'عبر فيسبوك'**
  String get contactTeacherFacebook;

  /// No description provided for @contactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم الفني'**
  String get contactSupport;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @companyCodeNote.
  ///
  /// In ar, this message translates to:
  /// **'رقم المحاضر مثال \'110490\''**
  String get companyCodeNote;

  /// No description provided for @companyCodeNote1.
  ///
  /// In ar, this message translates to:
  /// **'ليس الرقم الطويل المخصص لشراء الكورس'**
  String get companyCodeNote1;

  /// No description provided for @teacherWhatsappMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً مستر , أريد استفسار.'**
  String get teacherWhatsappMessage;

  /// No description provided for @supportWhatsappMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً , أريد استفسار.'**
  String get supportWhatsappMessage;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة'**
  String get changeLanguage;

  /// No description provided for @groupModifiedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تعديل المجموعة بنجاح ✅'**
  String get groupModifiedSuccess;

  /// No description provided for @reviewErrors.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الاخطاء'**
  String get reviewErrors;

  /// No description provided for @gradesHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدرجات'**
  String get gradesHistory;

  /// No description provided for @errorModifyingGroup.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تعديل المجموعة'**
  String get errorModifyingGroup;

  /// No description provided for @pleaseEnterUsernamePassword.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم المستخدم وكلمة المرور'**
  String get pleaseEnterUsernamePassword;

  /// No description provided for @loginSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get loginSuccess;

  /// No description provided for @invalidLogin.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تسجيل الدخول غير صحيحة'**
  String get invalidLogin;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك'**
  String get welcome;

  /// No description provided for @loginToPlatform.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدخول للوصول إلي كورساتك'**
  String loginToPlatform(String appName);

  /// No description provided for @username.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get username;

  /// No description provided for @nameNote.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول واسم العائلة يكونوا باللغة العربية أو الإنجليزية'**
  String get nameNote;

  /// No description provided for @usernameNote.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم يكون حروف وأرقام بالإنجليزية بدون مسافات'**
  String get usernameNote;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @mobilePhoneNote.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف يجب أن يكون 11 رقمًا يبدأ بـ 01'**
  String get mobilePhoneNote;

  /// No description provided for @dontHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ '**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك الآن'**
  String get createAccount;

  /// No description provided for @firstName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get lastName;

  /// No description provided for @companyCode.
  ///
  /// In ar, this message translates to:
  /// **'كود المحاضر'**
  String get companyCode;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @passwordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'يجب ان يكون الرقم السري مكون من 8 أرقام على الأقل'**
  String get passwordMinLength;

  /// No description provided for @fillAllFields.
  ///
  /// In ar, this message translates to:
  /// **'يرجى ملء جميع الحقول'**
  String get fillAllFields;

  /// No description provided for @companyCodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'كود المحاضر غير صحيح'**
  String get companyCodeInvalid;

  /// No description provided for @companyCodeError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في التحقق من كود المحاضر'**
  String get companyCodeError;

  /// No description provided for @companyCodeMinLength.
  ///
  /// In ar, this message translates to:
  /// **'كود المحاضر يجب أن يكون 3 أحرف على الأقل'**
  String get companyCodeMinLength;

  /// No description provided for @usernameMinLength.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم يجب أن يكون 3 أحرف على الأقل'**
  String get usernameMinLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور غير متطابقة'**
  String get passwordMismatch;

  /// No description provided for @usernameAlpha.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم يجب أن يحتوي على حرف واحد على الأقل'**
  String get usernameAlpha;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {param}'**
  String errorOccurred(String param);

  /// No description provided for @studentPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف الطالب'**
  String get studentPhone;

  /// No description provided for @parentPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف ولي الأمر'**
  String get parentPhone;

  /// No description provided for @selectGroupOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختر المجموعة (اختياري)'**
  String get selectGroupOptional;

  /// No description provided for @selectAcademicYear.
  ///
  /// In ar, this message translates to:
  /// **'اختر السنة الدراسية'**
  String get selectAcademicYear;

  /// No description provided for @noLevelsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستويات متاحة'**
  String get noLevelsAvailable;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح!'**
  String get accountCreatedSuccess;

  /// No description provided for @registerError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في التسجيل'**
  String get registerError;

  /// No description provided for @enterValidStudentPhone.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم طالب صحيح مكون من 11 رقمًا'**
  String get enterValidStudentPhone;

  /// No description provided for @enterValidParentPhone.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم ولي أمر صحيح مكون من 11 رقمًا'**
  String get enterValidParentPhone;

  /// No description provided for @selectAcademicYearError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار السنة الدراسية'**
  String get selectAcademicYearError;

  /// No description provided for @loadingLevels.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المستويات'**
  String get loadingLevels;

  /// No description provided for @selected.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار'**
  String get selected;

  /// No description provided for @retrievePassword.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع كلمة المرور'**
  String get retrievePassword;

  /// No description provided for @registeredPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف المسجل'**
  String get registeredPhone;

  /// No description provided for @retrieve.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get retrieve;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إرسال رابط استرجاع كلمة المرور'**
  String get passwordResetLinkSent;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارِ التحميل...'**
  String get loading;

  /// No description provided for @user.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get user;

  /// No description provided for @updateRequired.
  ///
  /// In ar, this message translates to:
  /// **'تحديث مطلوب'**
  String get updateRequired;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In ar, this message translates to:
  /// **'يجب عليك تحديث التطبيق إلى أحدث إصدار لاستخدامه.'**
  String get updateRequiredMessage;

  /// No description provided for @undefined.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get undefined;

  /// No description provided for @myCourses.
  ///
  /// In ar, this message translates to:
  /// **'كورساتي'**
  String get myCourses;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات'**
  String get categories;

  /// No description provided for @availableCoursesForPurchase.
  ///
  /// In ar, this message translates to:
  /// **'كورسات متاحة للشراء'**
  String get availableCoursesForPurchase;

  /// No description provided for @currentPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقاطك الحالية'**
  String get currentPoints;

  /// No description provided for @pointsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نقطة'**
  String pointsCount(int count);

  /// No description provided for @examsResults.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدرجات'**
  String get examsResults;

  /// No description provided for @teachers.
  ///
  /// In ar, this message translates to:
  /// **'المعلمين'**
  String get teachers;

  /// No description provided for @noCoursesAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كورسات حالياً'**
  String get noCoursesAvailable;

  /// No description provided for @priceWithCurrency.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج.م'**
  String priceWithCurrency(Object price);

  /// No description provided for @teacherLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدرس'**
  String teacherLabel(String name);

  /// No description provided for @noCoursesPurchased.
  ///
  /// In ar, this message translates to:
  /// **'لم تشترِ أي كورسات بعد'**
  String get noCoursesPurchased;

  /// No description provided for @shortClips.
  ///
  /// In ar, this message translates to:
  /// **'مقاطع قصيرة'**
  String get shortClips;

  /// No description provided for @selectedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار: {label}'**
  String selectedLabel(String label);

  /// No description provided for @unknownExam.
  ///
  /// In ar, this message translates to:
  /// **'امتحان غير معروف'**
  String get unknownExam;

  /// No description provided for @currentExams.
  ///
  /// In ar, this message translates to:
  /// **'الامتحانات الحالية'**
  String get currentExams;

  /// No description provided for @noCurrentExams.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد امتحانات حالياً'**
  String get noCurrentExams;

  /// No description provided for @upcomingExams.
  ///
  /// In ar, this message translates to:
  /// **'الامتحانات القادمة'**
  String get upcomingExams;

  /// No description provided for @noUpcomingExams.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد امتحانات قادمة'**
  String get noUpcomingExams;

  /// No description provided for @pastExams.
  ///
  /// In ar, this message translates to:
  /// **'الامتحانات السابقة'**
  String get pastExams;

  /// No description provided for @noPastExams.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد امتحانات سابقة'**
  String get noPastExams;

  /// No description provided for @cannotEnterExamYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكنك الدخول للامتحان بعد ✅'**
  String get cannotEnterExamYet;

  /// No description provided for @noTitle.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get noTitle;

  /// No description provided for @noSubject.
  ///
  /// In ar, this message translates to:
  /// **'بدون مادة'**
  String get noSubject;

  /// No description provided for @unknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get unknown;

  /// No description provided for @noPurchasedCourses.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كورسات حالياً'**
  String get noPurchasedCourses;

  /// No description provided for @purchasedVideos.
  ///
  /// In ar, this message translates to:
  /// **'الفيديوهات المشتراة'**
  String get purchasedVideos;

  /// No description provided for @noPurchasedVideos.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فيديوهات مشتراة حالياً'**
  String get noPurchasedVideos;

  /// No description provided for @lessons.
  ///
  /// In ar, this message translates to:
  /// **'الدروس'**
  String get lessons;

  /// No description provided for @files.
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get files;

  /// No description provided for @live.
  ///
  /// In ar, this message translates to:
  /// **'لايف'**
  String get live;

  /// No description provided for @rank.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get rank;

  /// No description provided for @purchaseFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في الشراء. تأكد من الكود.'**
  String get purchaseFailed;

  /// No description provided for @failedToFetchRank.
  ///
  /// In ar, this message translates to:
  /// **'فشل في جلب بيانات الترتيب'**
  String get failedToFetchRank;

  /// No description provided for @ongoingExamsLabel.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات جارية:'**
  String get ongoingExamsLabel;

  /// No description provided for @upcomingExamsLabel.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات قادمة:'**
  String get upcomingExamsLabel;

  /// No description provided for @endedExamsLabel.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات منتهية:'**
  String get endedExamsLabel;

  /// No description provided for @start.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get start;

  /// No description provided for @examEnded.
  ///
  /// In ar, this message translates to:
  /// **'الامتحان قد انتهى بالفعل'**
  String get examEnded;

  /// No description provided for @cannotStartExam.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن بدء الامتحان حالياً'**
  String get cannotStartExam;

  /// No description provided for @courseContent.
  ///
  /// In ar, this message translates to:
  /// **'محتويات الكورس'**
  String get courseContent;

  /// No description provided for @noExamsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد امتحانات متاحة حالياً'**
  String get noExamsAvailable;

  /// No description provided for @soon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get soon;

  /// No description provided for @noFilesAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات حالياً'**
  String get noFilesAvailable;

  /// No description provided for @pdfFiles.
  ///
  /// In ar, this message translates to:
  /// **'ملفات PDF'**
  String get pdfFiles;

  /// No description provided for @pdfFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF'**
  String get pdfFile;

  /// No description provided for @mustBuyCourseFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب شراء الكورس أولاً'**
  String get mustBuyCourseFirst;

  /// No description provided for @imageGroups.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات الصور'**
  String get imageGroups;

  /// No description provided for @imageGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة صور'**
  String get imageGroup;

  /// No description provided for @failedToLoadPdf.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل ملف PDF'**
  String get failedToLoadPdf;

  /// No description provided for @invalidFile.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير صالح أو فارغ'**
  String get invalidFile;

  /// No description provided for @student.
  ///
  /// In ar, this message translates to:
  /// **'طالب'**
  String get student;

  /// No description provided for @exerciseNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'التمرين غير متاح حالياً'**
  String get exerciseNotAvailable;

  /// No description provided for @exercises.
  ///
  /// In ar, this message translates to:
  /// **'تمارين'**
  String get exercises;

  /// No description provided for @comments.
  ///
  /// In ar, this message translates to:
  /// **'تعليقات'**
  String get comments;

  /// No description provided for @watchVideo.
  ///
  /// In ar, this message translates to:
  /// **'مشاهدة الفيديو'**
  String get watchVideo;

  /// No description provided for @exercise.
  ///
  /// In ar, this message translates to:
  /// **'تمرين'**
  String get exercise;

  /// No description provided for @typeQuestionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالك هنا...'**
  String get typeQuestionHint;

  /// No description provided for @voiceMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية'**
  String get voiceMessage;

  /// No description provided for @teacherReply.
  ///
  /// In ar, this message translates to:
  /// **'رد المعلم: {reply}'**
  String teacherReply(String reply);

  /// No description provided for @noAdditionalVideos.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فيديوهات إضافية حالياً'**
  String get noAdditionalVideos;

  /// No description provided for @mainVideo.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو الرئيسي'**
  String get mainVideo;

  /// No description provided for @additionalVideoCount.
  ///
  /// In ar, this message translates to:
  /// **'فيديو إضافي {count}'**
  String additionalVideoCount(int count);

  /// No description provided for @noExamsResultsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج اختبارات حتى الآن'**
  String get noExamsResultsYet;

  /// No description provided for @generalExam.
  ///
  /// In ar, this message translates to:
  /// **'امتحان عام'**
  String get generalExam;

  /// No description provided for @test.
  ///
  /// In ar, this message translates to:
  /// **'اختبار'**
  String get test;

  /// No description provided for @yourScoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'درجتك: {score}'**
  String yourScoreLabel(Object score);

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل'**
  String get details;

  /// No description provided for @failedToDisplayAnswers.
  ///
  /// In ar, this message translates to:
  /// **'تعذر عرض الإجابات'**
  String get failedToDisplayAnswers;

  /// No description provided for @examResultTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة الاختبار'**
  String get examResultTitle;

  /// No description provided for @yourScoreWithTotal.
  ///
  /// In ar, this message translates to:
  /// **'نتيجتك: {score} / {total}'**
  String yourScoreWithTotal(Object score, Object total);

  /// No description provided for @notAnswered.
  ///
  /// In ar, this message translates to:
  /// **'لم تجب'**
  String get notAnswered;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاحة'**
  String get notAvailable;

  /// No description provided for @yourAnswerLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجابتك:'**
  String get yourAnswerLabel;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة الصحيحة:'**
  String get correctAnswerLabel;

  /// No description provided for @questionScoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة: {score} / {total}'**
  String questionScoreLabel(Object score, Object total);

  /// No description provided for @failedToFetchServerTime.
  ///
  /// In ar, this message translates to:
  /// **'فشل في جلب توقيت السيرفر'**
  String get failedToFetchServerTime;

  /// No description provided for @remainingTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المتبقي'**
  String get remainingTimeLabel;

  /// No description provided for @timeSpentLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المستغرق'**
  String get timeSpentLabel;

  /// No description provided for @minutesShort.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get minutesShort;

  /// No description provided for @noQuestions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أسئلة'**
  String get noQuestions;

  /// No description provided for @questionIndex.
  ///
  /// In ar, this message translates to:
  /// **'السؤال {param}'**
  String questionIndex(String param);

  /// No description provided for @failedToLoadImage.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الصورة'**
  String get failedToLoadImage;

  /// No description provided for @trueValue.
  ///
  /// In ar, this message translates to:
  /// **'صح'**
  String get trueValue;

  /// No description provided for @falseValue.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get falseValue;

  /// No description provided for @enterAnswerHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل إجابتك هنا'**
  String get enterAnswerHint;

  /// No description provided for @completeAnswerHint.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الإجابة...'**
  String get completeAnswerHint;

  /// No description provided for @typeDialogueHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الحوار هنا...'**
  String get typeDialogueHint;

  /// No description provided for @previous.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In ar, this message translates to:
  /// **'تسليم الحل'**
  String get finish;

  /// No description provided for @noRanksAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رتب حالياً'**
  String get noRanksAvailable;

  /// No description provided for @yourCurrentPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقاطك الحالية: {points}'**
  String yourCurrentPoints(Object points);

  /// No description provided for @teacherCourses.
  ///
  /// In ar, this message translates to:
  /// **'كورسات {name}'**
  String teacherCourses(String name);

  /// No description provided for @noCoursesForTeacher.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كورسات لهذا المعلم'**
  String get noCoursesForTeacher;

  /// No description provided for @liveStreamTitle.
  ///
  /// In ar, this message translates to:
  /// **'البث المباشر'**
  String get liveStreamTitle;

  /// No description provided for @liveLabel.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get liveLabel;

  /// No description provided for @commentsLabel.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get commentsLabel;

  /// No description provided for @writeCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تعليقك...'**
  String get writeCommentHint;

  /// No description provided for @voiceUploadSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع التعليق الصوتي بنجاح'**
  String get voiceUploadSuccess;

  /// No description provided for @voiceUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل رفع الملف الصوتي!'**
  String get voiceUploadFailed;

  /// No description provided for @userLabel.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get userLabel;

  /// No description provided for @noNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'بدون رقم'**
  String get noNumberLabel;

  /// No description provided for @whatsappError.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح واتساب. تأكد من تثبيت التطبيق على جهازك.'**
  String get whatsappError;

  /// No description provided for @whatsappNotSupported.
  ///
  /// In ar, this message translates to:
  /// **'واتساب غير مدعوم على هذا النظام.'**
  String get whatsappNotSupported;

  /// No description provided for @technicalSupport.
  ///
  /// In ar, this message translates to:
  /// **'الدعم الفني'**
  String get technicalSupport;

  /// No description provided for @supportEmailBody.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، أحتاج مساعدة في ...'**
  String get supportEmailBody;

  /// No description provided for @secondary.
  ///
  /// In ar, this message translates to:
  /// **'الثانوية'**
  String get secondary;

  /// No description provided for @preparatory.
  ///
  /// In ar, this message translates to:
  /// **'الاعدادية'**
  String get preparatory;

  /// No description provided for @primary.
  ///
  /// In ar, this message translates to:
  /// **'الابتدائية'**
  String get primary;

  /// No description provided for @level1.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الأول'**
  String get level1;

  /// No description provided for @level2.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الثاني'**
  String get level2;

  /// No description provided for @level3.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الثالث'**
  String get level3;

  /// No description provided for @level4.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الرابع'**
  String get level4;

  /// No description provided for @level5.
  ///
  /// In ar, this message translates to:
  /// **'المستوى الخامس'**
  String get level5;

  /// No description provided for @level6.
  ///
  /// In ar, this message translates to:
  /// **'المستوى السادس'**
  String get level6;

  /// No description provided for @pointsLabel.
  ///
  /// In ar, this message translates to:
  /// **'نقاطك: {points}'**
  String pointsLabel(int points);

  /// No description provided for @pointsTitle.
  ///
  /// In ar, this message translates to:
  /// **'النقاط: {points}'**
  String pointsTitle(int points);

  /// No description provided for @accountInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الحساب'**
  String get accountInfo;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم:'**
  String get nameLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم:'**
  String get usernameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف:'**
  String get phoneLabel;

  /// No description provided for @studentData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الطالب'**
  String get studentData;

  /// No description provided for @loginData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدخول'**
  String get loginData;

  /// No description provided for @notAllowed.
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح'**
  String get notAllowed;

  /// No description provided for @emulatorBlockMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذا التطبيق لا يعمل على المحاكي\nيرجى استخدام جهاز حقيقي'**
  String get emulatorBlockMessage;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الرسالة'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الرسالة؟'**
  String get deleteMessageConfirm;

  /// No description provided for @noTeachersAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مدرسون متاحون حالياً'**
  String get noTeachersAvailable;

  /// No description provided for @activateNow.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الآن'**
  String get activateNow;

  /// No description provided for @activateVideo.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الفيديو'**
  String get activateVideo;

  /// No description provided for @noMistakesToReview.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أخطاء عشان تراجعها دلوقتي 🎉'**
  String get noMistakesToReview;

  /// No description provided for @failedToLoadReviewQuestions.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل أسئلة المراجعة'**
  String get failedToLoadReviewQuestions;

  /// No description provided for @tournamentsHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل البطولات'**
  String get tournamentsHistory;

  /// No description provided for @changeGroup.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المجموعة'**
  String get changeGroup;

  /// No description provided for @addAnotherAccount.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب آخر'**
  String get addAnotherAccount;

  /// No description provided for @audioRecordingNotSupportedOnWeb.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الصوت غير متاح على المتصفح حالياً'**
  String get audioRecordingNotSupportedOnWeb;

  /// No description provided for @failedToExtractVideoId.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر استخراج معرّف الفيديو'**
  String get failedToExtractVideoId;

  /// No description provided for @downloadedWatchOffline.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم التنزيل — يمكنك المشاهدة بدون إنترنت'**
  String get downloadedWatchOffline;

  /// No description provided for @cannotWatchVideoOffline.
  ///
  /// In ar, this message translates to:
  /// **'هذا الفيديو لا يمكن عرضه بدون إنترنت'**
  String get cannotWatchVideoOffline;

  /// No description provided for @savedOffline.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ بدون إنترنت'**
  String get savedOffline;

  /// No description provided for @downloadOffline.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل بدون إنترنت'**
  String get downloadOffline;

  /// No description provided for @lessonCompletionQuiz.
  ///
  /// In ar, this message translates to:
  /// **'كويز إتمام الدرس'**
  String get lessonCompletionQuiz;

  /// No description provided for @nextLectureAvailableNow.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرة القادمة متاحة الآن'**
  String get nextLectureAvailableNow;

  /// No description provided for @reviewMyMistakes.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة اخطائي'**
  String get reviewMyMistakes;

  /// No description provided for @nextLecture.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرة التالية'**
  String get nextLecture;

  /// No description provided for @examNotAvailableNow.
  ///
  /// In ar, this message translates to:
  /// **'الامتحان غير متاح حالياً'**
  String get examNotAvailableNow;

  /// No description provided for @subscribed.
  ///
  /// In ar, this message translates to:
  /// **'تم الاشتراك'**
  String get subscribed;

  /// No description provided for @couldNotFindPdfFile.
  ///
  /// In ar, this message translates to:
  /// **'Could not find PDF file'**
  String get couldNotFindPdfFile;

  /// No description provided for @failedToDownloadFile.
  ///
  /// In ar, this message translates to:
  /// **'Failed to download file'**
  String get failedToDownloadFile;

  /// No description provided for @goToFirstUnansweredQuestion.
  ///
  /// In ar, this message translates to:
  /// **'روح لأول سؤال ناقص'**
  String get goToFirstUnansweredQuestion;

  /// No description provided for @submitNow.
  ///
  /// In ar, this message translates to:
  /// **'سلم دلوقتي'**
  String get submitNow;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @noQuestionsToReview.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أسئلة للمراجعة'**
  String get noQuestionsToReview;

  /// No description provided for @notAllowedTxt.
  ///
  /// In ar, this message translates to:
  /// **'غير مسموح'**
  String get notAllowedTxt;

  /// No description provided for @emulatorError.
  ///
  /// In ar, this message translates to:
  /// **'هذا التطبيق لا يعمل على المحاكي\\nيرجى استخدام جهاز حقيقي'**
  String get emulatorError;

  /// No description provided for @closeDialog.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get closeDialog;

  /// No description provided for @chat.
  ///
  /// In ar, this message translates to:
  /// **'الشات'**
  String get chat;

  /// No description provided for @unknownPerson.
  ///
  /// In ar, this message translates to:
  /// **'مجهول'**
  String get unknownPerson;

  /// No description provided for @studentRole.
  ///
  /// In ar, this message translates to:
  /// **'طالب'**
  String get studentRole;

  /// No description provided for @invalidCourseId.
  ///
  /// In ar, this message translates to:
  /// **'معرف الكورس غير صالح'**
  String get invalidCourseId;

  /// No description provided for @noServerResponse.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رد من الخادم'**
  String get noServerResponse;

  /// No description provided for @sessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً'**
  String get sessionExpired;

  /// No description provided for @failedToLoadMessages.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الرسائل'**
  String get failedToLoadMessages;

  /// No description provided for @you.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get you;

  /// No description provided for @failedToSendMsg.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال الرسالة: {param}'**
  String failedToSendMsg(String param);

  /// No description provided for @errorSending.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإرسال: {param}'**
  String errorSending(String param);

  /// No description provided for @deleteMessageBtn.
  ///
  /// In ar, this message translates to:
  /// **'حذف الرسالة'**
  String get deleteMessageBtn;

  /// No description provided for @confirmDeleteMsg.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الرسالة؟'**
  String get confirmDeleteMsg;

  /// No description provided for @cancelBtn.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelBtn;

  /// No description provided for @deleteBtn.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteBtn;

  /// No description provided for @msgDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الرسالة'**
  String get msgDeletedSuccess;

  /// No description provided for @failedToDeleteMsg.
  ///
  /// In ar, this message translates to:
  /// **'فشل حذف الرسالة'**
  String get failedToDeleteMsg;

  /// No description provided for @errorDeleting.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الحذف'**
  String get errorDeleting;

  /// No description provided for @hoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'{param} ساعة'**
  String hoursAgo(String param);

  /// No description provided for @minutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'{param} دقيقة'**
  String minutesAgo(String param);

  /// No description provided for @justNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get justNow;

  /// No description provided for @deletedMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة محذوفة'**
  String get deletedMessage;

  /// No description provided for @sendFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'فشل الإرسال، اضغط لإعادة المحاولة'**
  String get sendFailedRetry;

  /// No description provided for @sendingMsg.
  ///
  /// In ar, this message translates to:
  /// **'جاري الإرسال...'**
  String get sendingMsg;

  /// No description provided for @cannotLoadMessages.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الرسائل'**
  String get cannotLoadMessages;

  /// No description provided for @retryBtn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryBtn;

  /// No description provided for @noMessagesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل بعد'**
  String get noMessagesYet;

  /// No description provided for @beFirstToWrite.
  ///
  /// In ar, this message translates to:
  /// **'كن أول من يكتب!'**
  String get beFirstToWrite;

  /// No description provided for @replyingTo.
  ///
  /// In ar, this message translates to:
  /// **'الرد على:'**
  String get replyingTo;

  /// No description provided for @writeMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة...'**
  String get writeMessageHint;

  /// No description provided for @examNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الامتحان غير متاح حالياً'**
  String get examNotAvailable;

  /// No description provided for @courseChat.
  ///
  /// In ar, this message translates to:
  /// **'شات الكورس'**
  String get courseChat;

  /// No description provided for @lessonsCount.
  ///
  /// In ar, this message translates to:
  /// **'{param} درس'**
  String lessonsCount(String param);

  /// No description provided for @filesCount.
  ///
  /// In ar, this message translates to:
  /// **'{param} ملفات'**
  String filesCount(String param);

  /// No description provided for @nextLesson.
  ///
  /// In ar, this message translates to:
  /// **'الدرس التالي'**
  String get nextLesson;

  /// No description provided for @priceEgp.
  ///
  /// In ar, this message translates to:
  /// **'{param} ج.م'**
  String priceEgp(String param);

  /// No description provided for @totalPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر الإجمالي'**
  String get totalPrice;

  /// No description provided for @subscribeNow.
  ///
  /// In ar, this message translates to:
  /// **'اشترك الآن'**
  String get subscribeNow;

  /// No description provided for @lessonLocked.
  ///
  /// In ar, this message translates to:
  /// **'الدرس مقفل'**
  String get lessonLocked;

  /// No description provided for @mustSolvePreviousVideoExam.
  ///
  /// In ar, this message translates to:
  /// **'عليك حل اختبار الفيديو السابق لتستطيع المشاهدة'**
  String get mustSolvePreviousVideoExam;

  /// No description provided for @okBtn.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get okBtn;

  /// No description provided for @completedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completedStatus;

  /// No description provided for @buyVideo.
  ///
  /// In ar, this message translates to:
  /// **'اشترِ الفيديو'**
  String get buyVideo;

  /// No description provided for @solveExamFirst.
  ///
  /// In ar, this message translates to:
  /// **'حل الاختبار أولاً'**
  String get solveExamFirst;

  /// No description provided for @freeWatch.
  ///
  /// In ar, this message translates to:
  /// **'مجاني • مشاهدة'**
  String get freeWatch;

  /// No description provided for @video45Mins.
  ///
  /// In ar, this message translates to:
  /// **'فيديو • 45 دقيقة'**
  String get video45Mins;

  /// No description provided for @freeBadge.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get freeBadge;

  /// No description provided for @purchaseBtn.
  ///
  /// In ar, this message translates to:
  /// **'شراء'**
  String get purchaseBtn;

  /// No description provided for @startsInExam.
  ///
  /// In ar, this message translates to:
  /// **'تبدأ في: {param}'**
  String startsInExam(String param);

  /// No description provided for @pdfFileLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF'**
  String get pdfFileLabel;

  /// No description provided for @invalidOrEmptyFile.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير صالح أو فارغ'**
  String get invalidOrEmptyFile;

  /// No description provided for @localFileNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على الملف المحلي'**
  String get localFileNotFound;

  /// No description provided for @errorOpeningFile.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء فتح الملف'**
  String get errorOpeningFile;

  /// No description provided for @invalidDownloadLink.
  ///
  /// In ar, this message translates to:
  /// **'الرابط غير صالح للتنزيل'**
  String get invalidDownloadLink;

  /// No description provided for @failedToDownloadPdfCode.
  ///
  /// In ar, this message translates to:
  /// **'فشل تنزيل ملف PDF ({param})'**
  String failedToDownloadPdfCode(String param);

  /// No description provided for @downloadedFileInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الملف المٌنزَّل غير صالح'**
  String get downloadedFileInvalid;

  /// No description provided for @canSaveFromShare.
  ///
  /// In ar, this message translates to:
  /// **'✅ يمكنك حفظ الملف من قائمة المشاركة'**
  String get canSaveFromShare;

  /// No description provided for @errorDownloadingFile.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تنزيل الملف'**
  String get errorDownloadingFile;

  /// No description provided for @thirdSecGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف الثالث الثانوي'**
  String get thirdSecGrade;

  /// No description provided for @subscribedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مشترك'**
  String get subscribedBadge;

  /// No description provided for @coursePromo.
  ///
  /// In ar, this message translates to:
  /// **'اعلان الكورس'**
  String get coursePromo;

  /// No description provided for @activateCourse.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الكورس'**
  String get activateCourse;

  /// No description provided for @enterActivationCodeCourse.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التفعيل لفتح محتويات الكورس.'**
  String get enterActivationCodeCourse;

  /// No description provided for @activateNowBtn.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الآن'**
  String get activateNowBtn;

  /// No description provided for @activateVideoBtn.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الفيديو'**
  String get activateVideoBtn;

  /// No description provided for @enterActivationCodeVideo.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التفعيل لفتح هذا الفيديو.'**
  String get enterActivationCodeVideo;

  /// No description provided for @invalidCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صالح!'**
  String get invalidCode;

  /// No description provided for @checkCodeTypo.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التأكد من كتابة الأرقام والحروف بشكل صحيح، أو أن الكود لم يتم استخدامه من قبل.'**
  String get checkCodeTypo;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة اخرى'**
  String get tryAgain;

  /// No description provided for @contactSupportToSolve.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم الفني لحل المشكلة'**
  String get contactSupportToSolve;

  /// No description provided for @activatedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم التفعيل بنجاح'**
  String get activatedSuccessfully;

  /// No description provided for @videoAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة الفيديو إلى محتواك بنجاح.'**
  String get videoAddedSuccess;

  /// No description provided for @itemAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة \"{param}\" إلى محتواك بنجاح.'**
  String itemAddedSuccess(String param);

  /// No description provided for @watchVideoBtn.
  ///
  /// In ar, this message translates to:
  /// **'مشاهدة الفيديو'**
  String get watchVideoBtn;

  /// No description provided for @goToCourseBtn.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب للكورس'**
  String get goToCourseBtn;

  /// No description provided for @noLiveStreamNow.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بث مباشر متاح حالياً'**
  String get noLiveStreamNow;

  /// No description provided for @cannotShowStream.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن عرض البث'**
  String get cannotShowStream;

  /// No description provided for @tapToOpenLive.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لفتح البث المباشر'**
  String get tapToOpenLive;

  /// No description provided for @courseLiveChat.
  ///
  /// In ar, this message translates to:
  /// **'شات الكورس المباشر'**
  String get courseLiveChat;

  /// No description provided for @questionsLessonsChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة الأسئلة والدروس'**
  String get questionsLessonsChat;

  /// No description provided for @outOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'من {param}'**
  String outOfTotal(String param);

  /// No description provided for @reviewMistakesBtn.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الأخطاء'**
  String get reviewMistakesBtn;

  /// No description provided for @backToHomeBtn.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلي الرئيسية'**
  String get backToHomeBtn;

  /// No description provided for @trueVal.
  ///
  /// In ar, this message translates to:
  /// **'صح'**
  String get trueVal;

  /// No description provided for @falseVal.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get falseVal;

  /// No description provided for @questionsRemainingTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه فيه أسئلة متبقية'**
  String get questionsRemainingTitle;

  /// No description provided for @mustAnswerAllQuestions.
  ///
  /// In ar, this message translates to:
  /// **'لازم تحل كل الأسئلة قبل ما تقدر تسلم الامتحان.\\نباقيلك {param} سؤال لسه محلتوش.'**
  String mustAnswerAllQuestions(String param);

  /// No description provided for @goToFirstMissingQ.
  ///
  /// In ar, this message translates to:
  /// **'روح لأول سؤال ناقص'**
  String get goToFirstMissingQ;

  /// No description provided for @submitExamBtn.
  ///
  /// In ar, this message translates to:
  /// **'تسليم الامتحان'**
  String get submitExamBtn;

  /// No description provided for @confirmSubmitExam.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد إنك عايز تسلم الامتحان دلوقتي؟'**
  String get confirmSubmitExam;

  /// No description provided for @goBackBtn.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get goBackBtn;

  /// No description provided for @submitBtn.
  ///
  /// In ar, this message translates to:
  /// **'تسليم'**
  String get submitBtn;

  /// No description provided for @progressPercentDone.
  ///
  /// In ar, this message translates to:
  /// **'تم إنجاز {param}%'**
  String progressPercentDone(String param);

  /// No description provided for @submittingExam.
  ///
  /// In ar, this message translates to:
  /// **'جاري تسليم الامتحان...'**
  String get submittingExam;

  /// No description provided for @dontCloseApp.
  ///
  /// In ar, this message translates to:
  /// **'من فضلك متقفلش التطبيق'**
  String get dontCloseApp;

  /// No description provided for @choiceA.
  ///
  /// In ar, this message translates to:
  /// **'أ'**
  String get choiceA;

  /// No description provided for @choiceB.
  ///
  /// In ar, this message translates to:
  /// **'ب'**
  String get choiceB;

  /// No description provided for @choiceC.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get choiceC;

  /// No description provided for @choiceD.
  ///
  /// In ar, this message translates to:
  /// **'د'**
  String get choiceD;

  /// No description provided for @failedToSendExerciseResult.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال نتيجة التدريب (كود {param}). حاول مرة أخرى.'**
  String failedToSendExerciseResult(String param);

  /// No description provided for @errorSendingExercise.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إرسال التدريب. حاول مرة أخرى.'**
  String get errorSendingExercise;

  /// No description provided for @questionXOfY.
  ///
  /// In ar, this message translates to:
  /// **'السؤال {param1} من {param2}'**
  String questionXOfY(String param1, String param2);

  /// No description provided for @unansweredQuestionsOpt.
  ///
  /// In ar, this message translates to:
  /// **'لسه محلتش {param} سؤال. تقدر تكمل أو تسلم اللي حليته بس.'**
  String unansweredQuestionsOpt(String param);

  /// No description provided for @submitNowBtn.
  ///
  /// In ar, this message translates to:
  /// **'سلم دلوقتي'**
  String get submitNowBtn;

  /// No description provided for @solvedCorrectXOfY.
  ///
  /// In ar, this message translates to:
  /// **'حليت صح {param1} من {param2}'**
  String solvedCorrectXOfY(String param1, String param2);

  /// No description provided for @timeSpentFormat.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المستغرق: {param}'**
  String timeSpentFormat(String param);

  /// No description provided for @doneBtn.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get doneBtn;

  /// No description provided for @qXOfY.
  ///
  /// In ar, this message translates to:
  /// **'سؤال {param1} من {param2}'**
  String qXOfY(String param1, String param2);

  /// No description provided for @wrongChoice.
  ///
  /// In ar, this message translates to:
  /// **'غلط'**
  String get wrongChoice;

  /// No description provided for @typeAnswerHere.
  ///
  /// In ar, this message translates to:
  /// **'اكتب إجابتك هنا'**
  String get typeAnswerHere;

  /// No description provided for @completeSentence.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الجملة'**
  String get completeSentence;

  /// No description provided for @typeDialogue.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الحوار'**
  String get typeDialogue;

  /// No description provided for @previousBtn.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previousBtn;

  /// No description provided for @finishBtn.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get finishBtn;

  /// No description provided for @nextBtn.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get nextBtn;

  /// No description provided for @audioNotSupportedWeb.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الصوت غير متاح على المتصفح حالياً'**
  String get audioNotSupportedWeb;

  /// No description provided for @userRole.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get userRole;

  /// No description provided for @downloadedFileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف محمل: {param}'**
  String downloadedFileTitle(String param);

  /// No description provided for @downloadedFilesOffline.
  ///
  /// In ar, this message translates to:
  /// **'الملفات المحملة (بدون إنترنت)'**
  String get downloadedFilesOffline;

  /// No description provided for @noDownloadedPdfs.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات PDF تم تحميلها مسبقاً'**
  String get noDownloadedPdfs;

  /// No description provided for @availableOffline.
  ///
  /// In ar, this message translates to:
  /// **'متاح للاستخدام بدون إنترنت'**
  String get availableOffline;

  /// No description provided for @failedToLoadRank.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل بيانات الترتيب'**
  String get failedToLoadRank;

  /// No description provided for @letterA1.
  ///
  /// In ar, this message translates to:
  /// **'ا'**
  String get letterA1;

  /// No description provided for @letterA2.
  ///
  /// In ar, this message translates to:
  /// **'إ'**
  String get letterA2;

  /// No description provided for @letterA3.
  ///
  /// In ar, this message translates to:
  /// **'آ'**
  String get letterA3;

  /// No description provided for @letterTa.
  ///
  /// In ar, this message translates to:
  /// **'ة'**
  String get letterTa;

  /// No description provided for @letterHa.
  ///
  /// In ar, this message translates to:
  /// **'ه'**
  String get letterHa;

  /// No description provided for @letterYa.
  ///
  /// In ar, this message translates to:
  /// **'ى'**
  String get letterYa;

  /// No description provided for @letterYaa.
  ///
  /// In ar, this message translates to:
  /// **'ي'**
  String get letterYaa;

  /// No description provided for @coursesTab.
  ///
  /// In ar, this message translates to:
  /// **'الكورسات'**
  String get coursesTab;

  /// No description provided for @videosTab.
  ///
  /// In ar, this message translates to:
  /// **'الفيديوهات'**
  String get videosTab;

  /// No description provided for @searchResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج البحث'**
  String get searchResults;

  /// No description provided for @searchForSomethingElse.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن شيء آخر...'**
  String get searchForSomethingElse;

  /// No description provided for @isSubscribed.
  ///
  /// In ar, this message translates to:
  /// **'تم الاشتراك'**
  String get isSubscribed;

  /// No description provided for @noMatchingResults.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد نتائج مطابقة لبحثك'**
  String get noMatchingResults;

  /// No description provided for @tryDifferentWords.
  ///
  /// In ar, this message translates to:
  /// **'جرب البحث بكلمات مختلفة'**
  String get tryDifferentWords;

  /// No description provided for @videoPlayerTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشغل الفيديو'**
  String get videoPlayerTitle;

  /// No description provided for @videoViewCounted.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم احتساب مشاهدة الفيديو — +50 XP'**
  String get videoViewCounted;

  /// No description provided for @cannotExtractVideoId.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر استخراج معرّف الفيديو'**
  String get cannotExtractVideoId;

  /// No description provided for @failedToGetDownloadLink.
  ///
  /// In ar, this message translates to:
  /// **'فشل جلب رابط التنزيل'**
  String get failedToGetDownloadLink;

  /// No description provided for @downloadFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التنزيل'**
  String get downloadFailed;

  /// No description provided for @downloadSuccessOffline.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم التنزيل — يمكنك المشاهدة بدون إنترنت'**
  String get downloadSuccessOffline;

  /// No description provided for @errorDisplay.
  ///
  /// In ar, this message translates to:
  /// **'❌ خطأ: {param}'**
  String errorDisplay(String param);

  /// No description provided for @videoCannotBeOffline.
  ///
  /// In ar, this message translates to:
  /// **'هذا الفيديو لا يمكن عرضه بدون إنترنت'**
  String get videoCannotBeOffline;

  /// No description provided for @watchedBadge.
  ///
  /// In ar, this message translates to:
  /// **'تمت المشاهدة'**
  String get watchedBadge;

  /// No description provided for @alertTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه '**
  String get alertTitle;

  /// No description provided for @maxViewsReached.
  ///
  /// In ar, this message translates to:
  /// **'لقد وصلت للحد الأقصى من مشاهدات هذا الفيديو. تواصل مع المعلم لزيادة الحد.'**
  String get maxViewsReached;

  /// No description provided for @returnBtn.
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get returnBtn;

  /// No description provided for @teacherMohamed.
  ///
  /// In ar, this message translates to:
  /// **'أ. محمد عبد المعبود'**
  String get teacherMohamed;

  /// No description provided for @watchForXp.
  ///
  /// In ar, this message translates to:
  /// **'للمشاهده +50 XP'**
  String get watchForXp;

  /// No description provided for @minutesWatchedNeeded.
  ///
  /// In ar, this message translates to:
  /// **'{param1} / {param2} د'**
  String minutesWatchedNeeded(String param1, String param2);

  /// No description provided for @watchProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم المشاهدة'**
  String get watchProgress;

  /// No description provided for @savedOfflineBadge.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ بدون إنترنت'**
  String get savedOfflineBadge;

  /// No description provided for @downloadingPercent.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنزيل {param}%'**
  String downloadingPercent(String param);

  /// No description provided for @downloadingDots.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنزيل…'**
  String get downloadingDots;

  /// No description provided for @downloadOfflineBtn.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل بدون إنترنت'**
  String get downloadOfflineBtn;

  /// No description provided for @mustPassQuizToUnlock.
  ///
  /// In ar, this message translates to:
  /// **'يلزم اجتياز الكويز لفتح الدرس التالي'**
  String get mustPassQuizToUnlock;

  /// No description provided for @htmlPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة HTML'**
  String get htmlPageLabel;

  /// No description provided for @questionsCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{param} اسئلة'**
  String questionsCountLabel(String param);

  /// No description provided for @durationMinsLabel.
  ///
  /// In ar, this message translates to:
  /// **'{param} دقيقة'**
  String durationMinsLabel(String param);

  /// No description provided for @passMarkPercent.
  ///
  /// In ar, this message translates to:
  /// **'النجاح من {param}%'**
  String passMarkPercent(String param);

  /// No description provided for @startExamNowBtn.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الاختبار الآن'**
  String get startExamNowBtn;

  /// No description provided for @nextLectureAvailable.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرة القادمة متاحة الآن'**
  String get nextLectureAvailable;

  /// No description provided for @nextLectureBtn.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرة التالية'**
  String get nextLectureBtn;

  /// No description provided for @voiceMessageLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية'**
  String get voiceMessageLabel;

  /// No description provided for @enterPhoneOrEmail.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم الهاتف أو البريد الإلكتروني المسجل'**
  String get enterPhoneOrEmail;

  /// No description provided for @whatsappCodeSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال كود التحقق بنجاح على الواتساب'**
  String get whatsappCodeSentSuccess;

  /// No description provided for @failedToSendCode.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال الكود'**
  String get failedToSendCode;

  /// No description provided for @errorConnectingToServer.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الاتصال بالخادم'**
  String get errorConnectingToServer;

  /// No description provided for @enter6DigitCode.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال كود التحقق المكون من 6 أرقام'**
  String get enter6DigitCode;

  /// No description provided for @verifiedEnterNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق بنجاح، أدخل كلمة المرور الجديدة'**
  String get verifiedEnterNewPassword;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In ar, this message translates to:
  /// **'كود التحقق غير صحيح'**
  String get invalidVerificationCode;

  /// No description provided for @errorVerifyingCode.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء التحقق من الكود'**
  String get errorVerifyingCode;

  /// No description provided for @passwordMinLength6.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get passwordMinLength6;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور وتأكيدها غير متطابقين'**
  String get passwordsDoNotMatch;

  /// No description provided for @failedToChangePassword.
  ///
  /// In ar, this message translates to:
  /// **'فشل تغيير كلمة المرور'**
  String get failedToChangePassword;

  /// No description provided for @errorSettingPassword.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تعيين كلمة المرور'**
  String get errorSettingPassword;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح 🎉'**
  String get passwordChangedSuccess;

  /// No description provided for @loginWithNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة.'**
  String get loginWithNewPassword;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @enterPhoneToSendCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك أو بريدك المسجل لإرسال كود التحقق عبر الواتساب'**
  String get enterPhoneToSendCode;

  /// No description provided for @phoneOrUsernameHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف أو اسم المستخدم المسجل'**
  String get phoneOrUsernameHint;

  /// No description provided for @sendWhatsappCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال كود الواتساب'**
  String get sendWhatsappCode;

  /// No description provided for @codeSentToNumber.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال كود التحقق المكون من 6 أرقام إلى حساب الواتساب للرقم:\\n{param}'**
  String codeSentToNumber(String param);

  /// No description provided for @otpCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'كود التحقق (OTP)'**
  String get otpCodeHint;

  /// No description provided for @confirmCodeBtn.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الكود'**
  String get confirmCodeBtn;

  /// No description provided for @changePhoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الهاتف'**
  String get changePhoneNumber;

  /// No description provided for @enterNewPasswordToComplete.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور الجديدة وتأكيدها لاستكمال العملية'**
  String get enterNewPasswordToComplete;

  /// No description provided for @newPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPasswordHint;

  /// No description provided for @saveNewPasswordBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور الجديدة'**
  String get saveNewPasswordBtn;

  /// No description provided for @accountRegisteredOnAnotherDevice.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب مسجل على جهاز آخر. يرجى التواصل مع المدرس لإعادة تعيين الجهاز.'**
  String get accountRegisteredOnAnotherDevice;

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @registeredSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم التسجيل بنجاح'**
  String get registeredSuccessfully;

  /// No description provided for @accountUnderReview.
  ///
  /// In ar, this message translates to:
  /// **'حسابك قيد المراجعة حالياً، سيتم تفعيله قريباً بواسطة المعلم.'**
  String get accountUnderReview;

  /// No description provided for @redirectOnActivation.
  ///
  /// In ar, this message translates to:
  /// **'سيتم توجيهك تلقائياً عند التفعيل...'**
  String get redirectOnActivation;

  /// No description provided for @educationalStage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الدراسية'**
  String get educationalStage;

  /// No description provided for @byLoggingInYouAgree.
  ///
  /// In ar, this message translates to:
  /// **'بالدخول، أنت توافق على '**
  String get byLoggingInYouAgree;

  /// No description provided for @termsAndConditions.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsAndConditions;

  /// No description provided for @chooseStageFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر المرحلة الدراسية أولاً'**
  String get chooseStageFirst;

  /// No description provided for @rank1.
  ///
  /// In ar, this message translates to:
  /// **'ملازم'**
  String get rank1;

  /// No description provided for @rank2.
  ///
  /// In ar, this message translates to:
  /// **'ملازم أول'**
  String get rank2;

  /// No description provided for @rank3.
  ///
  /// In ar, this message translates to:
  /// **'نقيب'**
  String get rank3;

  /// No description provided for @rank4.
  ///
  /// In ar, this message translates to:
  /// **'رائد'**
  String get rank4;

  /// No description provided for @rank5.
  ///
  /// In ar, this message translates to:
  /// **'مقدم'**
  String get rank5;

  /// No description provided for @rank6.
  ///
  /// In ar, this message translates to:
  /// **'عقيد'**
  String get rank6;

  /// No description provided for @rank7.
  ///
  /// In ar, this message translates to:
  /// **'عميد'**
  String get rank7;

  /// No description provided for @rank8.
  ///
  /// In ar, this message translates to:
  /// **'لواء'**
  String get rank8;

  /// No description provided for @streakDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام حماس'**
  String get streakDays;

  /// No description provided for @medals.
  ///
  /// In ar, this message translates to:
  /// **'أوسمة'**
  String get medals;

  /// No description provided for @completedCourseBadge.
  ///
  /// In ar, this message translates to:
  /// **'كورس مكتمل'**
  String get completedCourseBadge;

  /// No description provided for @tournamentsHistoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'سجل البطولات'**
  String get tournamentsHistoryLabel;

  /// No description provided for @studyGroup.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة الدراسية'**
  String get studyGroup;

  /// No description provided for @changeGroupBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المجموعة'**
  String get changeGroupBtn;

  /// No description provided for @tapToSwitchAccount.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتبديل الحساب'**
  String get tapToSwitchAccount;

  /// No description provided for @addAnotherAccountBtn.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب آخر'**
  String get addAnotherAccountBtn;

  /// No description provided for @availableNumbersCount.
  ///
  /// In ar, this message translates to:
  /// **'{param} أرقام متاحة'**
  String availableNumbersCount(String param);

  /// No description provided for @forQuickInquiries.
  ///
  /// In ar, this message translates to:
  /// **'للاستفسارات السريعة'**
  String get forQuickInquiries;

  /// No description provided for @officialStudentsGroup.
  ///
  /// In ar, this message translates to:
  /// **'الجروب الرسمي للطلاب'**
  String get officialStudentsGroup;

  /// No description provided for @techSupportLabel.
  ///
  /// In ar, this message translates to:
  /// **'دعم فني'**
  String get techSupportLabel;

  /// No description provided for @darkModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkModeTitle;

  /// No description provided for @forAppOrVideoIssues.
  ///
  /// In ar, this message translates to:
  /// **'لمشاكل التطبيق أو الفيديوهات'**
  String get forAppOrVideoIssues;

  /// No description provided for @switchAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب'**
  String get switchAccountTitle;

  /// No description provided for @contactTeacherTitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع المستر'**
  String get contactTeacherTitle;

  /// No description provided for @supportAndAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعم والحساب'**
  String get supportAndAccountTitle;

  /// No description provided for @notObtained.
  ///
  /// In ar, this message translates to:
  /// **'لم يحصل عليها'**
  String get notObtained;

  /// No description provided for @oneTime.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get oneTime;

  /// No description provided for @twoTimes.
  ///
  /// In ar, this message translates to:
  /// **'مرتان'**
  String get twoTimes;

  /// No description provided for @timesCount.
  ///
  /// In ar, this message translates to:
  /// **'{param} مرات'**
  String timesCount(String param);

  /// No description provided for @timeCountSingle.
  ///
  /// In ar, this message translates to:
  /// **'{param} مرة'**
  String timeCountSingle(String param);

  /// No description provided for @leaderboardMedals.
  ///
  /// In ar, this message translates to:
  /// **'أوسمة الصدارة'**
  String get leaderboardMedals;

  /// No description provided for @firstPlace.
  ///
  /// In ar, this message translates to:
  /// **'مركز أول'**
  String get firstPlace;

  /// No description provided for @secondPlace.
  ///
  /// In ar, this message translates to:
  /// **'مركز ثاني'**
  String get secondPlace;

  /// No description provided for @thirdPlace.
  ///
  /// In ar, this message translates to:
  /// **'مركز ثالث'**
  String get thirdPlace;

  /// No description provided for @idealStudent.
  ///
  /// In ar, this message translates to:
  /// **'الطالب المثالي'**
  String get idealStudent;

  /// No description provided for @ranksPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار الرتب'**
  String get ranksPath;

  /// No description provided for @currentRankBadge.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get currentRankBadge;

  /// No description provided for @untitled.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get untitled;

  /// No description provided for @unspecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get unspecified;

  /// No description provided for @myCoursesTab.
  ///
  /// In ar, this message translates to:
  /// **'كورساتي'**
  String get myCoursesTab;

  /// No description provided for @allTab.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allTab;

  /// No description provided for @inProgressCountTab.
  ///
  /// In ar, this message translates to:
  /// **'قيد الدراسة ({param})'**
  String inProgressCountTab(String param);

  /// No description provided for @completedCountTab.
  ///
  /// In ar, this message translates to:
  /// **'المكتملة ({param})'**
  String completedCountTab(String param);

  /// No description provided for @noCourses.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كورسات'**
  String get noCourses;

  /// No description provided for @continueBtn.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueBtn;

  /// No description provided for @finishedStatus.
  ///
  /// In ar, this message translates to:
  /// **'تم الانتهاء'**
  String get finishedStatus;

  /// No description provided for @doneThanksGod.
  ///
  /// In ar, this message translates to:
  /// **'تم بحمد الله'**
  String get doneThanksGod;

  /// No description provided for @notAvailableVal.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get notAvailableVal;

  /// No description provided for @mistakesBank.
  ///
  /// In ar, this message translates to:
  /// **'بنك الأخطاء'**
  String get mistakesBank;

  /// No description provided for @congratsNoMistakes.
  ///
  /// In ar, this message translates to:
  /// **'مبروك! ليس لديك أي أخطاء '**
  String get congratsNoMistakes;

  /// No description provided for @questionNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'السؤال غير متوفر'**
  String get questionNotAvailable;

  /// No description provided for @optionsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخيارات:'**
  String get optionsLabel;

  /// No description provided for @yourAnswerVal.
  ///
  /// In ar, this message translates to:
  /// **'إجابتك: {param}'**
  String yourAnswerVal(String param);

  /// No description provided for @correctAnswerVal.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة الصحيحة: {param}'**
  String correctAnswerVal(String param);

  /// No description provided for @unknownVal.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get unknownVal;

  /// No description provided for @examIdVal.
  ///
  /// In ar, this message translates to:
  /// **'امتحان: {param}'**
  String examIdVal(String param);

  /// No description provided for @addedOnDate.
  ///
  /// In ar, this message translates to:
  /// **'أضيف في: {param}'**
  String addedOnDate(String param);

  /// No description provided for @noMistakesToReviewNow.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أخطاء عشان تراجعها دلوقتي 🎉'**
  String get noMistakesToReviewNow;

  /// No description provided for @failedToLoadReviewQ.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل أسئلة المراجعة'**
  String get failedToLoadReviewQ;

  /// No description provided for @startsSoon.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ قريباً'**
  String get startsSoon;

  /// No description provided for @alreadyStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدأ بالفعل'**
  String get alreadyStarted;

  /// No description provided for @startsInDays.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ بعد {param1} يوم{param2}'**
  String startsInDays(String param1, String param2);

  /// No description provided for @startsInHoursMins.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ بعد {param1} ساعة و {param2} دقيقة'**
  String startsInHoursMins(String param1, String param2);

  /// No description provided for @startsInHours.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ بعد {param1} ساعة{param2}'**
  String startsInHours(String param1, String param2);

  /// No description provided for @startsInMinutes.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ بعد {param} دقيقة'**
  String startsInMinutes(String param);

  /// No description provided for @startsNow.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ الآن'**
  String get startsNow;

  /// No description provided for @endsSoon.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي قريباً'**
  String get endsSoon;

  /// No description provided for @ended.
  ///
  /// In ar, this message translates to:
  /// **'انتهى'**
  String get ended;

  /// No description provided for @endsInDays.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {param} يوم'**
  String endsInDays(String param);

  /// No description provided for @endsInHoursMins.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {param1} ساعة و {param2} دقيقة'**
  String endsInHoursMins(String param1, String param2);

  /// No description provided for @endsInHours.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {param1} ساعة{param2}'**
  String endsInHours(String param1, String param2);

  /// No description provided for @endsInMinutes.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {param} دقيقة'**
  String endsInMinutes(String param);

  /// No description provided for @endsNow.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي الآن'**
  String get endsNow;

  /// No description provided for @startExamBtn.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الامتحان'**
  String get startExamBtn;

  /// No description provided for @newExamsTitle.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات جديدة'**
  String get newExamsTitle;

  /// No description provided for @pastExamsHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الامتحانات السابقة'**
  String get pastExamsHistory;

  /// No description provided for @examsTitle.
  ///
  /// In ar, this message translates to:
  /// **'امتحانات'**
  String get examsTitle;

  /// No description provided for @youHavePre.
  ///
  /// In ar, this message translates to:
  /// **'لديك '**
  String get youHavePre;

  /// No description provided for @mistakeCountQ.
  ///
  /// In ar, this message translates to:
  /// **'{param} سؤال'**
  String mistakeCountQ(String param);

  /// No description provided for @wrongSuf.
  ///
  /// In ar, this message translates to:
  /// **' خاطئ'**
  String get wrongSuf;

  /// No description provided for @congratsSuf.
  ///
  /// In ar, this message translates to:
  /// **'، مبروك!'**
  String get congratsSuf;

  /// No description provided for @examsCountStr.
  ///
  /// In ar, this message translates to:
  /// **'{param} امتحانات'**
  String examsCountStr(String param);

  /// No description provided for @questionsCountStr.
  ///
  /// In ar, this message translates to:
  /// **'{param} اسئلة'**
  String questionsCountStr(String param);

  /// No description provided for @questionsLabel.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة'**
  String get questionsLabel;

  /// No description provided for @examDurationLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة الامتحان'**
  String get examDurationLabel;

  /// No description provided for @submittedStatus.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get submittedStatus;

  /// No description provided for @examSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم تسليم الامتحان'**
  String get examSubmitted;

  /// No description provided for @startExamNowLabel.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الامتحان الآن'**
  String get startExamNowLabel;

  /// No description provided for @sinceDays.
  ///
  /// In ar, this message translates to:
  /// **'منذ {param} يوم'**
  String sinceDays(String param);

  /// No description provided for @sinceHours.
  ///
  /// In ar, this message translates to:
  /// **'منذ {param} ساعة'**
  String sinceHours(String param);

  /// No description provided for @sinceMinutes.
  ///
  /// In ar, this message translates to:
  /// **'منذ {param} دقيقة'**
  String sinceMinutes(String param);

  /// No description provided for @teacherRole.
  ///
  /// In ar, this message translates to:
  /// **'معلم'**
  String get teacherRole;

  /// No description provided for @cannotLoadData.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تحميل البيانات'**
  String get cannotLoadData;

  /// No description provided for @offlineMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع بدون إنترنت'**
  String get offlineMode;

  /// No description provided for @savedDataExpiredConnect.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية البيانات المحفوظة، يرجى الاتصال بالإنترنت'**
  String get savedDataExpiredConnect;

  /// No description provided for @connectToDownloadContent.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الاتصال بالإنترنت لتحميل المحتوى'**
  String get connectToDownloadContent;

  /// No description provided for @dataSavedDaysLeft.
  ///
  /// In ar, this message translates to:
  /// **'البيانات محفوظة، تبقى {param} يوم قبل انتهاء الصلاحية'**
  String dataSavedDaysLeft(String param);

  /// No description provided for @searchSubjectCourseHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مادة او كورس'**
  String get searchSubjectCourseHint;

  /// No description provided for @currentRankTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرتبه الحالية'**
  String get currentRankTitle;

  /// No description provided for @targetPrefix.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: '**
  String get targetPrefix;

  /// No description provided for @countVideosCourses.
  ///
  /// In ar, this message translates to:
  /// **'{param1} {param2}'**
  String countVideosCourses(String param1, String param2);

  /// No description provided for @youCanMakeUpForIt.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تعوض'**
  String get youCanMakeUpForIt;

  /// No description provided for @amazingPerformance.
  ///
  /// In ar, this message translates to:
  /// **'أداء مذهل! استمر في التألق! 🌟'**
  String get amazingPerformance;

  /// No description provided for @everyMistakeIsLesson.
  ///
  /// In ar, this message translates to:
  /// **'كل خطأ هو درس جديد. أنت قادر على فعلها! 💪'**
  String get everyMistakeIsLesson;

  /// No description provided for @viewResultBtn.
  ///
  /// In ar, this message translates to:
  /// **'عرض النتيجة'**
  String get viewResultBtn;

  /// No description provided for @suggestedCourses.
  ///
  /// In ar, this message translates to:
  /// **'الكورسات المقترحة'**
  String get suggestedCourses;

  /// No description provided for @noSearchResultsForQuery.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج بحث مطابقة لـ \"{param}\"'**
  String noSearchResultsForQuery(String param);

  /// No description provided for @subscribedCourses.
  ///
  /// In ar, this message translates to:
  /// **'الكورسات المشترك بها'**
  String get subscribedCourses;

  /// No description provided for @subscribeBtn.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك'**
  String get subscribeBtn;

  /// No description provided for @cannotVerifyRequest.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من الطلب'**
  String get cannotVerifyRequest;

  /// No description provided for @serverConnectionTookLong.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بالسيرفر استغرق وقتاً طويلاً. إذا تم خصم الكود فالكورس سيظهر في حساباتك — اسحب للأسفل لتحديث الصفحة.'**
  String get serverConnectionTookLong;

  /// No description provided for @refreshPage.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الصفحة'**
  String get refreshPage;

  /// No description provided for @cannotLoadTeachers.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قائمة المدرسين'**
  String get cannotLoadTeachers;

  /// No description provided for @errorLoadingTeachers.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل المدرسين: {param}'**
  String errorLoadingTeachers(String param);

  /// No description provided for @pleaseSelectTeacherFirst.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المدرس أولاً'**
  String get pleaseSelectTeacherFirst;

  /// No description provided for @teacherLiveChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة المدرس المباشرة'**
  String get teacherLiveChat;

  /// No description provided for @talkingToTeacher.
  ///
  /// In ar, this message translates to:
  /// **'تتحدث مع: {param}'**
  String talkingToTeacher(String param);

  /// No description provided for @askTeacherWillReply.
  ///
  /// In ar, this message translates to:
  /// **'اسأل وسيقوم المدرس بالرد عليك'**
  String get askTeacherWillReply;

  /// No description provided for @noTeachersAvailableNow.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مدرسون متاحون حالياً'**
  String get noTeachersAvailableNow;

  /// No description provided for @selectTeacherToChat.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدرس للمحادثة:'**
  String get selectTeacherToChat;

  /// No description provided for @noMessagesWithTeacher.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل مع المدرس بعد'**
  String get noMessagesWithTeacher;

  /// No description provided for @writeQuestionTeacherReply.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالك أو استفسارك وسيقوم المدرس بالرد عليك!'**
  String get writeQuestionTeacherReply;

  /// No description provided for @replyingToMessage.
  ///
  /// In ar, this message translates to:
  /// **'الرد على رسالة:'**
  String get replyingToMessage;

  /// No description provided for @writeMessageToTeacher.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالتك للمدرس...'**
  String get writeMessageToTeacher;

  /// No description provided for @noSearchMatchSlash.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج بحث مطابقة لـ \\\"'**
  String get noSearchMatchSlash;

  /// No description provided for @videosListLabel.
  ///
  /// In ar, this message translates to:
  /// **'فيديوهات'**
  String get videosListLabel;

  /// No description provided for @clearDrawingForPage.
  ///
  /// In ar, this message translates to:
  /// **'مسح الرسم لهذه الصفحة'**
  String get clearDrawingForPage;

  /// No description provided for @pageIndexLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {param}'**
  String pageIndexLabel(String param);

  /// No description provided for @noAccessTokenReceived.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم استلام رمز الدخول من الخادم'**
  String get noAccessTokenReceived;

  /// No description provided for @switchedToAccount.
  ///
  /// In ar, this message translates to:
  /// **'تم التبديل إلى {param}'**
  String switchedToAccount(String param);

  /// No description provided for @loginFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get loginFailed;

  /// No description provided for @deleteAccountBtn.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccountBtn;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف حساب {param} من القائمة؟'**
  String confirmDeleteAccount(String param);

  /// No description provided for @noSavedAccounts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حسابات محفوظة'**
  String get noSavedAccounts;

  /// No description provided for @activeAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب النشط'**
  String get activeAccount;

  /// No description provided for @addNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب جديد'**
  String get addNewAccount;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغة التطبيق'**
  String get chooseAppLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة التي تفضل استخدامها لتصفح الكورسات والمحتوى'**
  String get selectLanguageSubtitle;

  /// No description provided for @arabicLanguage.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabicLanguage;

  /// No description provided for @arabicSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك! تصفح التطبيق كاملاً باللغة العربية'**
  String get arabicSubtitle;

  /// No description provided for @englishLanguage.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @englishSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'Welcome! Browse the full app in English'**
  String get englishSubtitle;

  /// No description provided for @continueToApp.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة'**
  String get continueToApp;

  /// No description provided for @welcomeToPlatform.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في منصتنا'**
  String get welcomeToPlatform;

  /// No description provided for @onlinePaymentFawaterak.
  ///
  /// In ar, this message translates to:
  /// **'دفع اونلاين'**
  String get onlinePaymentFawaterak;

  /// No description provided for @activationCodeTab.
  ///
  /// In ar, this message translates to:
  /// **'كود تفعيل'**
  String get activationCodeTab;

  /// No description provided for @noPaymentMethodsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طرق دفع متاحة حالياً'**
  String get noPaymentMethodsAvailable;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الدفع المناسبة لك:'**
  String get selectPaymentMethod;

  /// No description provided for @goToPaymentNow.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال للدفع الآن'**
  String get goToPaymentNow;

  /// No description provided for @buyViaWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'الشراء والطلب عبر الواتساب'**
  String get buyViaWhatsapp;

  /// No description provided for @fawryPaymentCode.
  ///
  /// In ar, this message translates to:
  /// **'كود السداد (فوري / أمان)'**
  String get fawryPaymentCode;

  /// No description provided for @doneClose.
  ///
  /// In ar, this message translates to:
  /// **'تم / إغلاق'**
  String get doneClose;

  /// No description provided for @paymentPageOpenedSnackBar.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح صفحة الدفع الإلكتروني، يرجى الاستكمال عبر المتصفح'**
  String get paymentPageOpenedSnackBar;

  /// No description provided for @paymentInitiationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل بدء عملية الدفع'**
  String get paymentInitiationFailed;

  /// No description provided for @whatsappPurchaseMessage.
  ///
  /// In ar, this message translates to:
  /// **'السلام عليكم، أرغب في شراء وتفعيل كورس: {title}'**
  String whatsappPurchaseMessage(String title);

  /// No description provided for @paymentMethodFallback.
  ///
  /// In ar, this message translates to:
  /// **'طريقة دفع'**
  String get paymentMethodFallback;

  /// No description provided for @couldNotFetchPaymentMethods.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب طرق الدفع'**
  String get couldNotFetchPaymentMethods;

  /// No description provided for @fawryInstructionNote.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ بهذا الكود وتوجه لأقرب فرع لسداد قيمة الكورس ({title}):'**
  String fawryInstructionNote(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
