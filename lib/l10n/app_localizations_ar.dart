// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get myAccount => 'حسابي';

  @override
  String get exams => 'امتحانات';

  @override
  String get courses => 'كورساتي';

  @override
  String get videos => 'فيديوهات';

  @override
  String get home => 'الرئيسية';

  @override
  String get userName => 'اسم المستخدم';

  @override
  String get online => 'اونلاين';

  @override
  String get editGroup => 'تعديل المجموعة';

  @override
  String get save => 'حفظ';

  @override
  String get contactTeacherWhatsapp => 'عبر واتساب';

  @override
  String get contactTeacherFacebook => 'عبر فيسبوك';

  @override
  String get contactSupport => 'تواصل مع الدعم الفني';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get companyCodeNote => 'رقم المحاضر مثال \'110490\'';

  @override
  String get companyCodeNote1 => 'ليس الرقم الطويل المخصص لشراء الكورس';

  @override
  String get teacherWhatsappMessage => 'مرحباً مستر , أريد استفسار.';

  @override
  String get supportWhatsappMessage => 'مرحباً , أريد استفسار.';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get groupModifiedSuccess => 'تم تعديل المجموعة بنجاح ✅';

  @override
  String get reviewErrors => 'مراجعة الاخطاء';

  @override
  String get gradesHistory => 'سجل الدرجات';

  @override
  String get errorModifyingGroup => 'حدث خطأ أثناء تعديل المجموعة';

  @override
  String get pleaseEnterUsernamePassword =>
      'يرجى إدخال اسم المستخدم وكلمة المرور';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get invalidLogin => 'بيانات تسجيل الدخول غير صحيحة';

  @override
  String get welcome => 'مرحباً بك';

  @override
  String loginToPlatform(String appName) {
    return 'سجل الدخول للوصول إلي كورساتك';
  }

  @override
  String get username => 'اسم المستخدم';

  @override
  String get nameNote =>
      'الاسم الأول واسم العائلة يكونوا باللغة العربية أو الإنجليزية';

  @override
  String get usernameNote =>
      'اسم المستخدم يكون حروف وأرقام بالإنجليزية بدون مسافات';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get mobilePhoneNote => 'رقم الهاتف يجب أن يكون 11 رقمًا يبدأ بـ 01';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get createAccount => 'أنشئ حسابك الآن';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get companyCode => 'كود المحاضر';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get next => 'التالي';

  @override
  String get passwordMinLength =>
      'يجب ان يكون الرقم السري مكون من 8 أرقام على الأقل';

  @override
  String get fillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get companyCodeInvalid => 'كود المحاضر غير صحيح';

  @override
  String get companyCodeError => 'حدث خطأ في التحقق من كود المحاضر';

  @override
  String get companyCodeMinLength => 'كود المحاضر يجب أن يكون 3 أحرف على الأقل';

  @override
  String get usernameMinLength => 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';

  @override
  String get passwordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get usernameAlpha =>
      'اسم المستخدم يجب أن يحتوي على حرف واحد على الأقل';

  @override
  String errorOccurred(String param) {
    return 'حدث خطأ: $param';
  }

  @override
  String get studentPhone => 'رقم هاتف الطالب';

  @override
  String get parentPhone => 'رقم هاتف ولي الأمر';

  @override
  String get selectGroupOptional => 'اختر المجموعة (اختياري)';

  @override
  String get selectAcademicYear => 'اختر السنة الدراسية';

  @override
  String get noLevelsAvailable => 'لا توجد مستويات متاحة';

  @override
  String get accountCreatedSuccess => 'تم إنشاء الحساب بنجاح!';

  @override
  String get registerError => 'حدث خطأ في التسجيل';

  @override
  String get enterValidStudentPhone =>
      'يرجى إدخال رقم طالب صحيح مكون من 11 رقمًا';

  @override
  String get enterValidParentPhone =>
      'يرجى إدخال رقم ولي أمر صحيح مكون من 11 رقمًا';

  @override
  String get selectAcademicYearError => 'يرجى اختيار السنة الدراسية';

  @override
  String get loadingLevels => 'جاري تحميل المستويات';

  @override
  String get selected => 'تم اختيار';

  @override
  String get retrievePassword => 'استرجاع كلمة المرور';

  @override
  String get registeredPhone => 'رقم الهاتف المسجل';

  @override
  String get retrieve => 'استرجاع';

  @override
  String get passwordResetLinkSent => 'سيتم إرسال رابط استرجاع كلمة المرور';

  @override
  String get loading => 'جارِ التحميل...';

  @override
  String get user => 'مستخدم';

  @override
  String get updateRequired => 'تحديث مطلوب';

  @override
  String get updateRequiredMessage =>
      'يجب عليك تحديث التطبيق إلى أحدث إصدار لاستخدامه.';

  @override
  String get undefined => 'غير محدد';

  @override
  String get myCourses => 'كورساتي';

  @override
  String get categories => 'التصنيفات';

  @override
  String get availableCoursesForPurchase => 'كورسات متاحة للشراء';

  @override
  String get currentPoints => 'نقاطك الحالية';

  @override
  String pointsCount(int count) {
    return '$count نقطة';
  }

  @override
  String get examsResults => 'سجل الدرجات';

  @override
  String get teachers => 'المعلمين';

  @override
  String get noCoursesAvailable => 'لا توجد كورسات حالياً';

  @override
  String priceWithCurrency(Object price) {
    return '$price ج.م';
  }

  @override
  String teacherLabel(String name) {
    return 'مدرس';
  }

  @override
  String get noCoursesPurchased => 'لم تشترِ أي كورسات بعد';

  @override
  String get shortClips => 'مقاطع قصيرة';

  @override
  String selectedLabel(String label) {
    return 'تم اختيار: $label';
  }

  @override
  String get unknownExam => 'امتحان غير معروف';

  @override
  String get currentExams => 'الامتحانات الحالية';

  @override
  String get noCurrentExams => 'لا توجد امتحانات حالياً';

  @override
  String get upcomingExams => 'الامتحانات القادمة';

  @override
  String get noUpcomingExams => 'لا توجد امتحانات قادمة';

  @override
  String get pastExams => 'الامتحانات السابقة';

  @override
  String get noPastExams => 'لا توجد امتحانات سابقة';

  @override
  String get cannotEnterExamYet => 'لا يمكنك الدخول للامتحان بعد ✅';

  @override
  String get noTitle => 'بدون عنوان';

  @override
  String get noSubject => 'بدون مادة';

  @override
  String get unknown => 'غير معروف';

  @override
  String get noPurchasedCourses => 'لا توجد كورسات حالياً';

  @override
  String get purchasedVideos => 'الفيديوهات المشتراة';

  @override
  String get noPurchasedVideos => 'لا توجد فيديوهات مشتراة حالياً';

  @override
  String get lessons => 'الدروس';

  @override
  String get files => 'الملفات';

  @override
  String get live => 'لايف';

  @override
  String get rank => 'الترتيب';

  @override
  String get purchaseFailed => 'فشل في الشراء. تأكد من الكود.';

  @override
  String get failedToFetchRank => 'فشل في جلب بيانات الترتيب';

  @override
  String get ongoingExamsLabel => 'امتحانات جارية:';

  @override
  String get upcomingExamsLabel => 'امتحانات قادمة:';

  @override
  String get endedExamsLabel => 'امتحانات منتهية:';

  @override
  String get start => 'ابدأ';

  @override
  String get examEnded => 'الامتحان قد انتهى بالفعل';

  @override
  String get cannotStartExam => 'لا يمكن بدء الامتحان حالياً';

  @override
  String get courseContent => 'محتويات الكورس';

  @override
  String get noExamsAvailable => 'لا توجد امتحانات متاحة حالياً';

  @override
  String get soon => 'قريباً';

  @override
  String get noFilesAvailable => 'لا توجد ملفات حالياً';

  @override
  String get pdfFiles => 'ملفات PDF';

  @override
  String get pdfFile => 'ملف PDF';

  @override
  String get mustBuyCourseFirst => 'يجب شراء الكورس أولاً';

  @override
  String get imageGroups => 'مجموعات الصور';

  @override
  String get imageGroup => 'مجموعة صور';

  @override
  String get failedToLoadPdf => 'فشل تحميل ملف PDF';

  @override
  String get invalidFile => 'الملف غير صالح أو فارغ';

  @override
  String get student => 'طالب';

  @override
  String get exerciseNotAvailable => 'التمرين غير متاح حالياً';

  @override
  String get exercises => 'تمارين';

  @override
  String get comments => 'تعليقات';

  @override
  String get watchVideo => 'مشاهدة الفيديو';

  @override
  String get exercise => 'تمرين';

  @override
  String get typeQuestionHint => 'اكتب سؤالك هنا...';

  @override
  String get voiceMessage => 'رسالة صوتية';

  @override
  String teacherReply(String reply) {
    return 'رد المعلم: $reply';
  }

  @override
  String get noAdditionalVideos => 'لا توجد فيديوهات إضافية حالياً';

  @override
  String get mainVideo => 'الفيديو الرئيسي';

  @override
  String additionalVideoCount(int count) {
    return 'فيديو إضافي $count';
  }

  @override
  String get noExamsResultsYet => 'لا توجد نتائج اختبارات حتى الآن';

  @override
  String get generalExam => 'امتحان عام';

  @override
  String get test => 'اختبار';

  @override
  String yourScoreLabel(Object score) {
    return 'درجتك: $score';
  }

  @override
  String get details => 'تفاصيل';

  @override
  String get failedToDisplayAnswers => 'تعذر عرض الإجابات';

  @override
  String get examResultTitle => 'نتيجة الاختبار';

  @override
  String yourScoreWithTotal(Object score, Object total) {
    return 'نتيجتك: $score / $total';
  }

  @override
  String get notAnswered => 'لم تجب';

  @override
  String get notAvailable => 'غير متاحة';

  @override
  String get yourAnswerLabel => 'إجابتك:';

  @override
  String get correctAnswerLabel => 'الإجابة الصحيحة:';

  @override
  String questionScoreLabel(Object score, Object total) {
    return 'الدرجة: $score / $total';
  }

  @override
  String get failedToFetchServerTime => 'فشل في جلب توقيت السيرفر';

  @override
  String get remainingTimeLabel => 'الوقت المتبقي';

  @override
  String get timeSpentLabel => 'الوقت المستغرق';

  @override
  String get minutesShort => 'د';

  @override
  String get noQuestions => 'لا توجد أسئلة';

  @override
  String questionIndex(String param) {
    return 'السؤال $param';
  }

  @override
  String get failedToLoadImage => 'تعذر تحميل الصورة';

  @override
  String get trueValue => 'صح';

  @override
  String get falseValue => 'خطأ';

  @override
  String get enterAnswerHint => 'أدخل إجابتك هنا';

  @override
  String get completeAnswerHint => 'أكمل الإجابة...';

  @override
  String get typeDialogueHint => 'اكتب الحوار هنا...';

  @override
  String get previous => 'السابق';

  @override
  String get finish => 'تسليم الحل';

  @override
  String get noRanksAvailable => 'لا يوجد رتب حالياً';

  @override
  String yourCurrentPoints(Object points) {
    return 'نقاطك الحالية: $points';
  }

  @override
  String teacherCourses(String name) {
    return 'كورسات $name';
  }

  @override
  String get noCoursesForTeacher => 'لا توجد كورسات لهذا المعلم';

  @override
  String get liveStreamTitle => 'البث المباشر';

  @override
  String get liveLabel => 'مباشر';

  @override
  String get commentsLabel => 'التعليقات';

  @override
  String get writeCommentHint => 'اكتب تعليقك...';

  @override
  String get voiceUploadSuccess => 'تم رفع التعليق الصوتي بنجاح';

  @override
  String get voiceUploadFailed => 'فشل رفع الملف الصوتي!';

  @override
  String get userLabel => 'مستخدم';

  @override
  String get noNumberLabel => 'بدون رقم';

  @override
  String get whatsappError =>
      'لا يمكن فتح واتساب. تأكد من تثبيت التطبيق على جهازك.';

  @override
  String get whatsappNotSupported => 'واتساب غير مدعوم على هذا النظام.';

  @override
  String get technicalSupport => 'الدعم الفني';

  @override
  String get supportEmailBody => 'مرحباً، أحتاج مساعدة في ...';

  @override
  String get secondary => 'الثانوية';

  @override
  String get preparatory => 'الاعدادية';

  @override
  String get primary => 'الابتدائية';

  @override
  String get level1 => 'المستوى الأول';

  @override
  String get level2 => 'المستوى الثاني';

  @override
  String get level3 => 'المستوى الثالث';

  @override
  String get level4 => 'المستوى الرابع';

  @override
  String get level5 => 'المستوى الخامس';

  @override
  String get level6 => 'المستوى السادس';

  @override
  String pointsLabel(int points) {
    return 'نقاطك: $points';
  }

  @override
  String pointsTitle(int points) {
    return 'النقاط: $points';
  }

  @override
  String get accountInfo => 'معلومات الحساب';

  @override
  String get nameLabel => 'الاسم:';

  @override
  String get usernameLabel => 'اسم المستخدم:';

  @override
  String get phoneLabel => 'رقم الهاتف:';

  @override
  String get studentData => 'بيانات الطالب';

  @override
  String get loginData => 'بيانات الدخول';

  @override
  String get notAllowed => 'غير مسموح';

  @override
  String get emulatorBlockMessage =>
      'هذا التطبيق لا يعمل على المحاكي\nيرجى استخدام جهاز حقيقي';

  @override
  String get close => 'إغلاق';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get deleteMessageTitle => 'حذف الرسالة';

  @override
  String get deleteMessageConfirm => 'هل أنت متأكد من حذف هذه الرسالة؟';

  @override
  String get noTeachersAvailable => 'لا يوجد مدرسون متاحون حالياً';

  @override
  String get activateNow => 'تفعيل الآن';

  @override
  String get activateVideo => 'تفعيل الفيديو';

  @override
  String get noMistakesToReview => 'مفيش أخطاء عشان تراجعها دلوقتي 🎉';

  @override
  String get failedToLoadReviewQuestions => 'تعذر تحميل أسئلة المراجعة';

  @override
  String get tournamentsHistory => 'سجل البطولات';

  @override
  String get changeGroup => 'تغيير المجموعة';

  @override
  String get addAnotherAccount => 'إضافة حساب آخر';

  @override
  String get audioRecordingNotSupportedOnWeb =>
      'تسجيل الصوت غير متاح على المتصفح حالياً';

  @override
  String get failedToExtractVideoId => 'تعذّر استخراج معرّف الفيديو';

  @override
  String get downloadedWatchOffline =>
      '✅ تم التنزيل — يمكنك المشاهدة بدون إنترنت';

  @override
  String get cannotWatchVideoOffline => 'هذا الفيديو لا يمكن عرضه بدون إنترنت';

  @override
  String get savedOffline => 'محفوظ بدون إنترنت';

  @override
  String get downloadOffline => 'تنزيل بدون إنترنت';

  @override
  String get lessonCompletionQuiz => 'كويز إتمام الدرس';

  @override
  String get nextLectureAvailableNow => 'المحاضرة القادمة متاحة الآن';

  @override
  String get reviewMyMistakes => 'مراجعة اخطائي';

  @override
  String get nextLecture => 'المحاضرة التالية';

  @override
  String get examNotAvailableNow => 'الامتحان غير متاح حالياً';

  @override
  String get subscribed => 'تم الاشتراك';

  @override
  String get couldNotFindPdfFile => 'Could not find PDF file';

  @override
  String get failedToDownloadFile => 'Failed to download file';

  @override
  String get goToFirstUnansweredQuestion => 'روح لأول سؤال ناقص';

  @override
  String get submitNow => 'سلم دلوقتي';

  @override
  String get done => 'تم';

  @override
  String get noQuestionsToReview => 'مفيش أسئلة للمراجعة';

  @override
  String get notAllowedTxt => 'غير مسموح';

  @override
  String get emulatorError =>
      'هذا التطبيق لا يعمل على المحاكي\\nيرجى استخدام جهاز حقيقي';

  @override
  String get closeDialog => 'إغلاق';

  @override
  String get chat => 'الشات';

  @override
  String get unknownPerson => 'مجهول';

  @override
  String get studentRole => 'طالب';

  @override
  String get invalidCourseId => 'معرف الكورس غير صالح';

  @override
  String get noServerResponse => 'لا يوجد رد من الخادم';

  @override
  String get sessionExpired => 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً';

  @override
  String get failedToLoadMessages => 'فشل تحميل الرسائل';

  @override
  String get you => 'أنت';

  @override
  String failedToSendMsg(String param) {
    return 'فشل إرسال الرسالة: $param';
  }

  @override
  String errorSending(String param) {
    return 'حدث خطأ أثناء الإرسال: $param';
  }

  @override
  String get deleteMessageBtn => 'حذف الرسالة';

  @override
  String get confirmDeleteMsg => 'هل أنت متأكد من حذف هذه الرسالة؟';

  @override
  String get cancelBtn => 'إلغاء';

  @override
  String get deleteBtn => 'حذف';

  @override
  String get msgDeletedSuccess => 'تم حذف الرسالة';

  @override
  String get failedToDeleteMsg => 'فشل حذف الرسالة';

  @override
  String get errorDeleting => 'حدث خطأ أثناء الحذف';

  @override
  String hoursAgo(String param) {
    return '$param ساعة';
  }

  @override
  String minutesAgo(String param) {
    return '$param دقيقة';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get deletedMessage => 'رسالة محذوفة';

  @override
  String get sendFailedRetry => 'فشل الإرسال، اضغط لإعادة المحاولة';

  @override
  String get sendingMsg => 'جاري الإرسال...';

  @override
  String get cannotLoadMessages => 'تعذر تحميل الرسائل';

  @override
  String get retryBtn => 'إعادة المحاولة';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get beFirstToWrite => 'كن أول من يكتب!';

  @override
  String get replyingTo => 'الرد على:';

  @override
  String get writeMessageHint => 'اكتب رسالة...';

  @override
  String get examNotAvailable => 'الامتحان غير متاح حالياً';

  @override
  String get courseChat => 'شات الكورس';

  @override
  String lessonsCount(String param) {
    return '$param درس';
  }

  @override
  String filesCount(String param) {
    return '$param ملفات';
  }

  @override
  String get nextLesson => 'الدرس التالي';

  @override
  String priceEgp(String param) {
    return '$param ج.م';
  }

  @override
  String get totalPrice => 'السعر الإجمالي';

  @override
  String get subscribeNow => 'اشترك الآن';

  @override
  String get lessonLocked => 'الدرس مقفل';

  @override
  String get mustSolvePreviousVideoExam =>
      'عليك حل اختبار الفيديو السابق لتستطيع المشاهدة';

  @override
  String get okBtn => 'حسناً';

  @override
  String get completedStatus => 'مكتمل';

  @override
  String get buyVideo => 'اشترِ الفيديو';

  @override
  String get solveExamFirst => 'حل الاختبار أولاً';

  @override
  String get freeWatch => 'مجاني • مشاهدة';

  @override
  String get video45Mins => 'فيديو • 45 دقيقة';

  @override
  String get freeBadge => 'مجاني';

  @override
  String get purchaseBtn => 'شراء';

  @override
  String startsInExam(String param) {
    return 'تبدأ في: $param';
  }

  @override
  String get pdfFileLabel => 'ملف PDF';

  @override
  String get invalidOrEmptyFile => 'الملف غير صالح أو فارغ';

  @override
  String get localFileNotFound => 'لم يتم العثور على الملف المحلي';

  @override
  String get errorOpeningFile => 'حدث خطأ أثناء فتح الملف';

  @override
  String get invalidDownloadLink => 'الرابط غير صالح للتنزيل';

  @override
  String failedToDownloadPdfCode(String param) {
    return 'فشل تنزيل ملف PDF ($param)';
  }

  @override
  String get downloadedFileInvalid => 'الملف المٌنزَّل غير صالح';

  @override
  String get canSaveFromShare => '✅ يمكنك حفظ الملف من قائمة المشاركة';

  @override
  String get errorDownloadingFile => 'حدث خطأ أثناء تنزيل الملف';

  @override
  String get thirdSecGrade => 'الصف الثالث الثانوي';

  @override
  String get subscribedBadge => 'مشترك';

  @override
  String get coursePromo => 'اعلان الكورس';

  @override
  String get activateCourse => 'تفعيل الكورس';

  @override
  String get enterActivationCodeCourse =>
      'أدخل كود التفعيل لفتح محتويات الكورس.';

  @override
  String get activateNowBtn => 'تفعيل الآن';

  @override
  String get activateVideoBtn => 'تفعيل الفيديو';

  @override
  String get enterActivationCodeVideo => 'أدخل كود التفعيل لفتح هذا الفيديو.';

  @override
  String get invalidCode => 'الكود غير صالح!';

  @override
  String get checkCodeTypo =>
      'يرجى التأكد من كتابة الأرقام والحروف بشكل صحيح، أو أن الكود لم يتم استخدامه من قبل.';

  @override
  String get tryAgain => 'حاول مرة اخرى';

  @override
  String get contactSupportToSolve => 'تواصل مع الدعم الفني لحل المشكلة';

  @override
  String get activatedSuccessfully => 'تم التفعيل بنجاح';

  @override
  String get videoAddedSuccess => 'تم إضافة الفيديو إلى محتواك بنجاح.';

  @override
  String itemAddedSuccess(String param) {
    return 'تم إضافة \"$param\" إلى محتواك بنجاح.';
  }

  @override
  String get watchVideoBtn => 'مشاهدة الفيديو';

  @override
  String get goToCourseBtn => 'الذهاب للكورس';

  @override
  String get noLiveStreamNow => 'لا يوجد بث مباشر متاح حالياً';

  @override
  String get cannotShowStream => 'لا يمكن عرض البث';

  @override
  String get tapToOpenLive => 'اضغط لفتح البث المباشر';

  @override
  String get courseLiveChat => 'شات الكورس المباشر';

  @override
  String get questionsLessonsChat => 'محادثة الأسئلة والدروس';

  @override
  String outOfTotal(String param) {
    return 'من $param';
  }

  @override
  String get reviewMistakesBtn => 'مراجعة الأخطاء';

  @override
  String get backToHomeBtn => 'العودة إلي الرئيسية';

  @override
  String get trueVal => 'صح';

  @override
  String get falseVal => 'خطأ';

  @override
  String get questionsRemainingTitle => 'لسه فيه أسئلة متبقية';

  @override
  String mustAnswerAllQuestions(String param) {
    return 'لازم تحل كل الأسئلة قبل ما تقدر تسلم الامتحان.\\نباقيلك $param سؤال لسه محلتوش.';
  }

  @override
  String get goToFirstMissingQ => 'روح لأول سؤال ناقص';

  @override
  String get submitExamBtn => 'تسليم الامتحان';

  @override
  String get confirmSubmitExam => 'هل أنت متأكد إنك عايز تسلم الامتحان دلوقتي؟';

  @override
  String get goBackBtn => 'رجوع';

  @override
  String get submitBtn => 'تسليم';

  @override
  String progressPercentDone(String param) {
    return 'تم إنجاز $param%';
  }

  @override
  String get submittingExam => 'جاري تسليم الامتحان...';

  @override
  String get dontCloseApp => 'من فضلك متقفلش التطبيق';

  @override
  String get choiceA => 'أ';

  @override
  String get choiceB => 'ب';

  @override
  String get choiceC => 'ج';

  @override
  String get choiceD => 'د';

  @override
  String failedToSendExerciseResult(String param) {
    return 'فشل إرسال نتيجة التدريب (كود $param). حاول مرة أخرى.';
  }

  @override
  String get errorSendingExercise =>
      'حدث خطأ أثناء إرسال التدريب. حاول مرة أخرى.';

  @override
  String questionXOfY(String param1, String param2) {
    return 'السؤال $param1 من $param2';
  }

  @override
  String unansweredQuestionsOpt(String param) {
    return 'لسه محلتش $param سؤال. تقدر تكمل أو تسلم اللي حليته بس.';
  }

  @override
  String get submitNowBtn => 'سلم دلوقتي';

  @override
  String solvedCorrectXOfY(String param1, String param2) {
    return 'حليت صح $param1 من $param2';
  }

  @override
  String timeSpentFormat(String param) {
    return 'الوقت المستغرق: $param';
  }

  @override
  String get doneBtn => 'تم';

  @override
  String qXOfY(String param1, String param2) {
    return 'سؤال $param1 من $param2';
  }

  @override
  String get wrongChoice => 'غلط';

  @override
  String get typeAnswerHere => 'اكتب إجابتك هنا';

  @override
  String get completeSentence => 'أكمل الجملة';

  @override
  String get typeDialogue => 'اكتب الحوار';

  @override
  String get previousBtn => 'السابق';

  @override
  String get finishBtn => 'إنهاء';

  @override
  String get nextBtn => 'التالي';

  @override
  String get audioNotSupportedWeb => 'تسجيل الصوت غير متاح على المتصفح حالياً';

  @override
  String get userRole => 'مستخدم';

  @override
  String downloadedFileTitle(String param) {
    return 'ملف محمل: $param';
  }

  @override
  String get downloadedFilesOffline => 'الملفات المحملة (بدون إنترنت)';

  @override
  String get noDownloadedPdfs => 'لا توجد ملفات PDF تم تحميلها مسبقاً';

  @override
  String get availableOffline => 'متاح للاستخدام بدون إنترنت';

  @override
  String get failedToLoadRank => 'فشل تحميل بيانات الترتيب';

  @override
  String get letterA1 => 'ا';

  @override
  String get letterA2 => 'إ';

  @override
  String get letterA3 => 'آ';

  @override
  String get letterTa => 'ة';

  @override
  String get letterHa => 'ه';

  @override
  String get letterYa => 'ى';

  @override
  String get letterYaa => 'ي';

  @override
  String get coursesTab => 'الكورسات';

  @override
  String get videosTab => 'الفيديوهات';

  @override
  String get searchResults => 'نتائج البحث';

  @override
  String get searchForSomethingElse => 'ابحث عن شيء آخر...';

  @override
  String get isSubscribed => 'تم الاشتراك';

  @override
  String get noMatchingResults => 'لم نجد نتائج مطابقة لبحثك';

  @override
  String get tryDifferentWords => 'جرب البحث بكلمات مختلفة';

  @override
  String get videoPlayerTitle => 'مشغل الفيديو';

  @override
  String get videoViewCounted => '✅ تم احتساب مشاهدة الفيديو — +50 XP';

  @override
  String get cannotExtractVideoId => 'تعذّر استخراج معرّف الفيديو';

  @override
  String get failedToGetDownloadLink => 'فشل جلب رابط التنزيل';

  @override
  String get downloadFailed => 'فشل التنزيل';

  @override
  String get downloadSuccessOffline =>
      '✅ تم التنزيل — يمكنك المشاهدة بدون إنترنت';

  @override
  String errorDisplay(String param) {
    return '❌ خطأ: $param';
  }

  @override
  String get videoCannotBeOffline => 'هذا الفيديو لا يمكن عرضه بدون إنترنت';

  @override
  String get watchedBadge => 'تمت المشاهدة';

  @override
  String get alertTitle => 'تنبيه ';

  @override
  String get maxViewsReached =>
      'لقد وصلت للحد الأقصى من مشاهدات هذا الفيديو. تواصل مع المعلم لزيادة الحد.';

  @override
  String get returnBtn => 'العودة';

  @override
  String get teacherMohamed => 'أ. محمد عبد المعبود';

  @override
  String get watchForXp => 'للمشاهده +50 XP';

  @override
  String minutesWatchedNeeded(String param1, String param2) {
    return '$param1 / $param2 د';
  }

  @override
  String get watchProgress => 'تقدم المشاهدة';

  @override
  String get savedOfflineBadge => 'محفوظ بدون إنترنت';

  @override
  String downloadingPercent(String param) {
    return 'جارٍ التنزيل $param%';
  }

  @override
  String get downloadingDots => 'جارٍ التنزيل…';

  @override
  String get downloadOfflineBtn => 'تنزيل بدون إنترنت';

  @override
  String get mustPassQuizToUnlock => 'يلزم اجتياز الكويز لفتح الدرس التالي';

  @override
  String get htmlPageLabel => 'صفحة HTML';

  @override
  String questionsCountLabel(String param) {
    return '$param اسئلة';
  }

  @override
  String durationMinsLabel(String param) {
    return '$param دقيقة';
  }

  @override
  String passMarkPercent(String param) {
    return 'النجاح من $param%';
  }

  @override
  String get startExamNowBtn => 'ابدأ الاختبار الآن';

  @override
  String get nextLectureAvailable => 'المحاضرة القادمة متاحة الآن';

  @override
  String get nextLectureBtn => 'المحاضرة التالية';

  @override
  String get voiceMessageLabel => 'رسالة صوتية';

  @override
  String get enterPhoneOrEmail =>
      'يرجى إدخال رقم الهاتف أو البريد الإلكتروني المسجل';

  @override
  String get whatsappCodeSentSuccess =>
      'تم إرسال كود التحقق بنجاح على الواتساب';

  @override
  String get failedToSendCode => 'فشل إرسال الكود';

  @override
  String get errorConnectingToServer => 'حدث خطأ أثناء الاتصال بالخادم';

  @override
  String get enter6DigitCode => 'يرجى إدخال كود التحقق المكون من 6 أرقام';

  @override
  String get verifiedEnterNewPassword =>
      'تم التحقق بنجاح، أدخل كلمة المرور الجديدة';

  @override
  String get invalidVerificationCode => 'كود التحقق غير صحيح';

  @override
  String get errorVerifyingCode => 'حدث خطأ أثناء التحقق من الكود';

  @override
  String get passwordMinLength6 => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمة المرور وتأكيدها غير متطابقين';

  @override
  String get failedToChangePassword => 'فشل تغيير كلمة المرور';

  @override
  String get errorSettingPassword => 'حدث خطأ أثناء تعيين كلمة المرور';

  @override
  String get passwordChangedSuccess => 'تم تغيير كلمة المرور بنجاح 🎉';

  @override
  String get loginWithNewPassword =>
      'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة.';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get enterPhoneToSendCode =>
      'أدخل رقم هاتفك أو بريدك المسجل لإرسال كود التحقق عبر الواتساب';

  @override
  String get phoneOrUsernameHint => 'رقم الهاتف أو اسم المستخدم المسجل';

  @override
  String get sendWhatsappCode => 'إرسال كود الواتساب';

  @override
  String codeSentToNumber(String param) {
    return 'تم إرسال كود التحقق المكون من 6 أرقام إلى حساب الواتساب للرقم:\\n$param';
  }

  @override
  String get otpCodeHint => 'كود التحقق (OTP)';

  @override
  String get confirmCodeBtn => 'تأكيد الكود';

  @override
  String get changePhoneNumber => 'تغيير رقم الهاتف';

  @override
  String get enterNewPasswordToComplete =>
      'أدخل كلمة المرور الجديدة وتأكيدها لاستكمال العملية';

  @override
  String get newPasswordHint => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordHint => 'تأكيد كلمة المرور الجديدة';

  @override
  String get saveNewPasswordBtn => 'حفظ كلمة المرور الجديدة';

  @override
  String get accountRegisteredOnAnotherDevice =>
      'هذا الحساب مسجل على جهاز آخر. يرجى التواصل مع المدرس لإعادة تعيين الجهاز.';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get registeredSuccessfully => 'تم التسجيل بنجاح';

  @override
  String get accountUnderReview =>
      'حسابك قيد المراجعة حالياً، سيتم تفعيله قريباً بواسطة المعلم.';

  @override
  String get redirectOnActivation => 'سيتم توجيهك تلقائياً عند التفعيل...';

  @override
  String get educationalStage => 'المرحلة الدراسية';

  @override
  String get byLoggingInYouAgree => 'بالدخول، أنت توافق على ';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get chooseStageFirst => 'اختر المرحلة الدراسية أولاً';

  @override
  String get rank1 => 'ملازم';

  @override
  String get rank2 => 'ملازم أول';

  @override
  String get rank3 => 'نقيب';

  @override
  String get rank4 => 'رائد';

  @override
  String get rank5 => 'مقدم';

  @override
  String get rank6 => 'عقيد';

  @override
  String get rank7 => 'عميد';

  @override
  String get rank8 => 'لواء';

  @override
  String get streakDays => 'أيام حماس';

  @override
  String get medals => 'أوسمة';

  @override
  String get completedCourseBadge => 'كورس مكتمل';

  @override
  String get tournamentsHistoryLabel => 'سجل البطولات';

  @override
  String get studyGroup => 'المجموعة الدراسية';

  @override
  String get changeGroupBtn => 'تغيير المجموعة';

  @override
  String get tapToSwitchAccount => 'اضغط لتبديل الحساب';

  @override
  String get addAnotherAccountBtn => 'إضافة حساب آخر';

  @override
  String availableNumbersCount(String param) {
    return '$param أرقام متاحة';
  }

  @override
  String get forQuickInquiries => 'للاستفسارات السريعة';

  @override
  String get officialStudentsGroup => 'الجروب الرسمي للطلاب';

  @override
  String get techSupportLabel => 'دعم فني';

  @override
  String get darkModeTitle => 'الوضع الليلي';

  @override
  String get forAppOrVideoIssues => 'لمشاكل التطبيق أو الفيديوهات';

  @override
  String get switchAccountTitle => 'تبديل الحساب';

  @override
  String get contactTeacherTitle => 'تواصل مع المستر';

  @override
  String get supportAndAccountTitle => 'الدعم والحساب';

  @override
  String get notObtained => 'لم يحصل عليها';

  @override
  String get oneTime => 'مرة واحدة';

  @override
  String get twoTimes => 'مرتان';

  @override
  String timesCount(String param) {
    return '$param مرات';
  }

  @override
  String timeCountSingle(String param) {
    return '$param مرة';
  }

  @override
  String get leaderboardMedals => 'أوسمة الصدارة';

  @override
  String get firstPlace => 'مركز أول';

  @override
  String get secondPlace => 'مركز ثاني';

  @override
  String get thirdPlace => 'مركز ثالث';

  @override
  String get idealStudent => 'الطالب المثالي';

  @override
  String get ranksPath => 'مسار الرتب';

  @override
  String get currentRankBadge => 'الحالية';

  @override
  String get untitled => 'بدون عنوان';

  @override
  String get unspecified => 'غير محدد';

  @override
  String get myCoursesTab => 'كورساتي';

  @override
  String get allTab => 'الكل';

  @override
  String inProgressCountTab(String param) {
    return 'قيد الدراسة ($param)';
  }

  @override
  String completedCountTab(String param) {
    return 'المكتملة ($param)';
  }

  @override
  String get noCourses => 'لا توجد كورسات';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get finishedStatus => 'تم الانتهاء';

  @override
  String get doneThanksGod => 'تم بحمد الله';

  @override
  String get notAvailableVal => 'غير متوفر';

  @override
  String get mistakesBank => 'بنك الأخطاء';

  @override
  String get congratsNoMistakes => 'مبروك! ليس لديك أي أخطاء ';

  @override
  String get questionNotAvailable => 'السؤال غير متوفر';

  @override
  String get optionsLabel => 'الخيارات:';

  @override
  String yourAnswerVal(String param) {
    return 'إجابتك: $param';
  }

  @override
  String correctAnswerVal(String param) {
    return 'الإجابة الصحيحة: $param';
  }

  @override
  String get unknownVal => 'غير معروف';

  @override
  String examIdVal(String param) {
    return 'امتحان: $param';
  }

  @override
  String addedOnDate(String param) {
    return 'أضيف في: $param';
  }

  @override
  String get noMistakesToReviewNow => 'مفيش أخطاء عشان تراجعها دلوقتي 🎉';

  @override
  String get failedToLoadReviewQ => 'تعذر تحميل أسئلة المراجعة';

  @override
  String get startsSoon => 'يبدأ قريباً';

  @override
  String get alreadyStarted => 'بدأ بالفعل';

  @override
  String startsInDays(String param1, String param2) {
    return 'يبدأ بعد $param1 يوم$param2';
  }

  @override
  String startsInHoursMins(String param1, String param2) {
    return 'يبدأ بعد $param1 ساعة و $param2 دقيقة';
  }

  @override
  String startsInHours(String param1, String param2) {
    return 'يبدأ بعد $param1 ساعة$param2';
  }

  @override
  String startsInMinutes(String param) {
    return 'يبدأ بعد $param دقيقة';
  }

  @override
  String get startsNow => 'يبدأ الآن';

  @override
  String get endsSoon => 'ينتهي قريباً';

  @override
  String get ended => 'انتهى';

  @override
  String endsInDays(String param) {
    return 'ينتهي بعد $param يوم';
  }

  @override
  String endsInHoursMins(String param1, String param2) {
    return 'ينتهي بعد $param1 ساعة و $param2 دقيقة';
  }

  @override
  String endsInHours(String param1, String param2) {
    return 'ينتهي بعد $param1 ساعة$param2';
  }

  @override
  String endsInMinutes(String param) {
    return 'ينتهي بعد $param دقيقة';
  }

  @override
  String get endsNow => 'ينتهي الآن';

  @override
  String get startExamBtn => 'ابدأ الامتحان';

  @override
  String get newExamsTitle => 'امتحانات جديدة';

  @override
  String get pastExamsHistory => 'سجل الامتحانات السابقة';

  @override
  String get examsTitle => 'امتحانات';

  @override
  String get youHavePre => 'لديك ';

  @override
  String mistakeCountQ(String param) {
    return '$param سؤال';
  }

  @override
  String get wrongSuf => ' خاطئ';

  @override
  String get congratsSuf => '، مبروك!';

  @override
  String examsCountStr(String param) {
    return '$param امتحانات';
  }

  @override
  String questionsCountStr(String param) {
    return '$param اسئلة';
  }

  @override
  String get questionsLabel => 'أسئلة';

  @override
  String get examDurationLabel => 'مدة الامتحان';

  @override
  String get submittedStatus => 'تم التسليم';

  @override
  String get examSubmitted => 'تم تسليم الامتحان';

  @override
  String get startExamNowLabel => 'ابدأ الامتحان الآن';

  @override
  String sinceDays(String param) {
    return 'منذ $param يوم';
  }

  @override
  String sinceHours(String param) {
    return 'منذ $param ساعة';
  }

  @override
  String sinceMinutes(String param) {
    return 'منذ $param دقيقة';
  }

  @override
  String get teacherRole => 'معلم';

  @override
  String get cannotLoadData => 'لا يمكن تحميل البيانات';

  @override
  String get offlineMode => 'وضع بدون إنترنت';

  @override
  String get savedDataExpiredConnect =>
      'انتهت صلاحية البيانات المحفوظة، يرجى الاتصال بالإنترنت';

  @override
  String get connectToDownloadContent =>
      'يرجى الاتصال بالإنترنت لتحميل المحتوى';

  @override
  String dataSavedDaysLeft(String param) {
    return 'البيانات محفوظة، تبقى $param يوم قبل انتهاء الصلاحية';
  }

  @override
  String get searchSubjectCourseHint => 'ابحث عن مادة او كورس';

  @override
  String get currentRankTitle => 'الرتبه الحالية';

  @override
  String get targetPrefix => 'الهدف: ';

  @override
  String countVideosCourses(String param1, String param2) {
    return '$param1 $param2';
  }

  @override
  String get youCanMakeUpForIt => 'تقدر تعوض';

  @override
  String get amazingPerformance => 'أداء مذهل! استمر في التألق! 🌟';

  @override
  String get everyMistakeIsLesson =>
      'كل خطأ هو درس جديد. أنت قادر على فعلها! 💪';

  @override
  String get viewResultBtn => 'عرض النتيجة';

  @override
  String get suggestedCourses => 'الكورسات المقترحة';

  @override
  String noSearchResultsForQuery(String param) {
    return 'لا توجد نتائج بحث مطابقة لـ \"$param\"';
  }

  @override
  String get subscribedCourses => 'الكورسات المشترك بها';

  @override
  String get subscribeBtn => 'اشتراك';

  @override
  String get cannotVerifyRequest => 'تعذّر التحقق من الطلب';

  @override
  String get serverConnectionTookLong =>
      'الاتصال بالسيرفر استغرق وقتاً طويلاً. إذا تم خصم الكود فالكورس سيظهر في حساباتك — اسحب للأسفل لتحديث الصفحة.';

  @override
  String get refreshPage => 'تحديث الصفحة';

  @override
  String get cannotLoadTeachers => 'تعذر تحميل قائمة المدرسين';

  @override
  String errorLoadingTeachers(String param) {
    return 'حدث خطأ أثناء تحميل المدرسين: $param';
  }

  @override
  String get pleaseSelectTeacherFirst => 'يرجى اختيار المدرس أولاً';

  @override
  String get teacherLiveChat => 'محادثة المدرس المباشرة';

  @override
  String talkingToTeacher(String param) {
    return 'تتحدث مع: $param';
  }

  @override
  String get askTeacherWillReply => 'اسأل وسيقوم المدرس بالرد عليك';

  @override
  String get noTeachersAvailableNow => 'لا يوجد مدرسون متاحون حالياً';

  @override
  String get selectTeacherToChat => 'اختر المدرس للمحادثة:';

  @override
  String get noMessagesWithTeacher => 'لا توجد رسائل مع المدرس بعد';

  @override
  String get writeQuestionTeacherReply =>
      'اكتب سؤالك أو استفسارك وسيقوم المدرس بالرد عليك!';

  @override
  String get replyingToMessage => 'الرد على رسالة:';

  @override
  String get writeMessageToTeacher => 'اكتب رسالتك للمدرس...';

  @override
  String get noSearchMatchSlash => 'لا توجد نتائج بحث مطابقة لـ \\\"';

  @override
  String get videosListLabel => 'فيديوهات';

  @override
  String get clearDrawingForPage => 'مسح الرسم لهذه الصفحة';

  @override
  String pageIndexLabel(String param) {
    return 'صفحة $param';
  }

  @override
  String get noAccessTokenReceived => 'لم يتم استلام رمز الدخول من الخادم';

  @override
  String switchedToAccount(String param) {
    return 'تم التبديل إلى $param';
  }

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get deleteAccountBtn => 'حذف الحساب';

  @override
  String confirmDeleteAccount(String param) {
    return 'هل تريد حذف حساب $param من القائمة؟';
  }

  @override
  String get noSavedAccounts => 'لا توجد حسابات محفوظة';

  @override
  String get activeAccount => 'الحساب النشط';

  @override
  String get addNewAccount => 'إضافة حساب جديد';

  @override
  String get chooseAppLanguage => 'اختر لغة التطبيق';

  @override
  String get selectLanguageSubtitle =>
      'اختر اللغة التي تفضل استخدامها لتصفح الكورسات والمحتوى';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get arabicSubtitle => 'أهلاً بك! تصفح التطبيق كاملاً باللغة العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get englishSubtitle => 'Welcome! Browse the full app in English';

  @override
  String get continueToApp => 'المتابعة';

  @override
  String get welcomeToPlatform => 'مرحباً بك في منصتنا';

  @override
  String get onlinePaymentFawaterak => 'دفع اونلاين';

  @override
  String get activationCodeTab => 'كود تفعيل';

  @override
  String get noPaymentMethodsAvailable => 'لا توجد طرق دفع متاحة حالياً';

  @override
  String get selectPaymentMethod => 'اختر طريقة الدفع المناسبة لك:';

  @override
  String get goToPaymentNow => 'الانتقال للدفع الآن';

  @override
  String get buyViaWhatsapp => 'الشراء والطلب عبر الواتساب';

  @override
  String get fawryPaymentCode => 'كود السداد (فوري / أمان)';

  @override
  String get doneClose => 'تم / إغلاق';

  @override
  String get paymentPageOpenedSnackBar =>
      'تم فتح صفحة الدفع الإلكتروني، يرجى الاستكمال عبر المتصفح';

  @override
  String get paymentInitiationFailed => 'فشل بدء عملية الدفع';

  @override
  String whatsappPurchaseMessage(String title) {
    return 'السلام عليكم، أرغب في شراء وتفعيل كورس: $title';
  }

  @override
  String get paymentMethodFallback => 'طريقة دفع';

  @override
  String get couldNotFetchPaymentMethods => 'تعذر جلب طرق الدفع';

  @override
  String fawryInstructionNote(String title) {
    return 'احتفظ بهذا الكود وتوجه لأقرب فرع لسداد قيمة الكورس ($title):';
  }
}
