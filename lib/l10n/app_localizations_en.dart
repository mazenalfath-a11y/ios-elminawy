// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myAccount => 'My Account';

  @override
  String get exams => 'Exams';

  @override
  String get courses => 'Courses';

  @override
  String get videos => 'Videos';

  @override
  String get home => 'Home';

  @override
  String get userName => 'User Name';

  @override
  String get online => 'Online';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get save => 'Save';

  @override
  String get contactTeacherWhatsapp => 'Contact Teacher via WhatsApp';

  @override
  String get contactTeacherFacebook => 'Contact Teacher via Facebook';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get logout => 'Logout';

  @override
  String get companyCodeNote => 'رقم المحاضر مثال \'110490\'';

  @override
  String get companyCodeNote1 => 'ليس الرقم الطويل المخصص لشراء الكورس';

  @override
  String get teacherWhatsappMessage => 'Hello sir, I have an inquiry.';

  @override
  String get supportWhatsappMessage => 'Hello, I have an inquiry.';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get groupModifiedSuccess => 'Group modified successfully ✅';

  @override
  String get reviewErrors => 'Review Errors';

  @override
  String get gradesHistory => 'Grades History';

  @override
  String get errorModifyingGroup => 'Error modifying group';

  @override
  String get pleaseEnterUsernamePassword =>
      'Please enter username and password';

  @override
  String get loginSuccess => 'Login successful ✅';

  @override
  String get invalidLogin => 'Invalid login credentials ❌';

  @override
  String get welcome => 'Welcome';

  @override
  String loginToPlatform(String appName) {
    return 'Login to $appName platform';
  }

  @override
  String get username => 'Username';

  @override
  String get nameNote => 'First and Last names can be in Arabic or English';

  @override
  String get usernameNote =>
      'Username must be English letters and numbers without spaces';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get mobilePhoneNote =>
      'Phone number must be 11 digits starting with 01';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createAccount => 'Create Account';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get companyCode => 'Lecturer Code';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get next => 'Next';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get companyCodeInvalid => 'Invalid Lecturer Code';

  @override
  String get companyCodeError => 'Error verifying lecturer code';

  @override
  String get companyCodeMinLength =>
      'Lecturer code must be at least 3 characters';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get usernameAlpha => 'Username must contain at least one letter';

  @override
  String errorOccurred(String param) {
    return 'An error occurred: $param';
  }

  @override
  String get studentPhone => 'Student Phone Number';

  @override
  String get parentPhone => 'Parent Phone Number';

  @override
  String get selectGroupOptional => 'Select Group (Optional)';

  @override
  String get selectAcademicYear => 'Select Academic Year';

  @override
  String get noLevelsAvailable => 'No levels available';

  @override
  String get accountCreatedSuccess => 'Account created successfully!';

  @override
  String get registerError => 'Registration error';

  @override
  String get enterValidStudentPhone =>
      'Please enter a valid 11-digit student phone number';

  @override
  String get enterValidParentPhone =>
      'Please enter a valid 11-digit parent phone number';

  @override
  String get selectAcademicYearError => 'Please select an academic year';

  @override
  String get loadingLevels => 'Loading levels';

  @override
  String get selected => 'Selected';

  @override
  String get retrievePassword => 'Retrieve Password';

  @override
  String get registeredPhone => 'Registered Phone Number';

  @override
  String get retrieve => 'Retrieve';

  @override
  String get passwordResetLinkSent => 'A password reset link will be sent';

  @override
  String get loading => 'Loading...';

  @override
  String get user => 'User';

  @override
  String get updateRequired => 'Update Required';

  @override
  String get updateRequiredMessage =>
      'You must update the application to the latest version to use it.';

  @override
  String get undefined => 'Undefined';

  @override
  String get myCourses => 'My Courses';

  @override
  String get categories => 'Categories';

  @override
  String get availableCoursesForPurchase => 'Available Courses for Purchase';

  @override
  String get currentPoints => 'Your Current Points';

  @override
  String pointsCount(int count) {
    return '$count Points';
  }

  @override
  String get examsResults => 'Exams Results';

  @override
  String get teachers => 'Teachers';

  @override
  String get noCoursesAvailable => 'No courses available currently';

  @override
  String priceWithCurrency(Object price) {
    return 'Price: $price EGP';
  }

  @override
  String teacherLabel(String name) {
    return 'Teacher';
  }

  @override
  String get noCoursesPurchased => 'You haven\'t purchased any courses yet';

  @override
  String get shortClips => 'Short Clips';

  @override
  String selectedLabel(String label) {
    return 'Selected: $label';
  }

  @override
  String get unknownExam => 'Unknown Exam';

  @override
  String get currentExams => 'Current Exams';

  @override
  String get noCurrentExams => 'No exams currently';

  @override
  String get upcomingExams => 'Upcoming Exams';

  @override
  String get noUpcomingExams => 'No upcoming exams';

  @override
  String get pastExams => 'Past Exams';

  @override
  String get noPastExams => 'No past exams';

  @override
  String get cannotEnterExamYet => 'You cannot enter the exam yet ✅';

  @override
  String get noTitle => 'No Title';

  @override
  String get noSubject => 'No Subject';

  @override
  String get unknown => 'Unknown';

  @override
  String get noPurchasedCourses => 'No purchased courses currently';

  @override
  String get purchasedVideos => 'Purchased Videos';

  @override
  String get noPurchasedVideos => 'No purchased videos currently';

  @override
  String get lessons => 'Lessons';

  @override
  String get files => 'Files';

  @override
  String get live => 'Live';

  @override
  String get rank => 'Rank';

  @override
  String get purchaseFailed => 'Purchase failed. Check the code.';

  @override
  String get failedToFetchRank => 'Failed to fetch rank data';

  @override
  String get ongoingExamsLabel => 'Ongoing Exams:';

  @override
  String get upcomingExamsLabel => 'Upcoming Exams:';

  @override
  String get endedExamsLabel => 'Ended Exams:';

  @override
  String get start => 'Start';

  @override
  String get examEnded => 'Exam has already ended';

  @override
  String get cannotStartExam => 'Cannot start exam currently';

  @override
  String get courseContent => 'Course Content';

  @override
  String get noExamsAvailable => 'No exams available currently';

  @override
  String get soon => 'Soon';

  @override
  String get noFilesAvailable => 'No files currently';

  @override
  String get pdfFiles => 'PDF Files';

  @override
  String get pdfFile => 'PDF File';

  @override
  String get mustBuyCourseFirst => 'You must buy the course first';

  @override
  String get imageGroups => 'Image Groups';

  @override
  String get imageGroup => 'Image Group';

  @override
  String get failedToLoadPdf => 'Failed to load PDF file';

  @override
  String get invalidFile => 'File is invalid or empty';

  @override
  String get student => 'Student';

  @override
  String get exerciseNotAvailable => 'Exercise not available currently';

  @override
  String get exercises => 'Exercises';

  @override
  String get comments => 'Comments';

  @override
  String get watchVideo => 'Watch Video';

  @override
  String get exercise => 'Exercise';

  @override
  String get typeQuestionHint => 'Type your question here';

  @override
  String get voiceMessage => 'Voice Message';

  @override
  String teacherReply(String reply) {
    return 'Teacher\'s Reply: $reply';
  }

  @override
  String get noAdditionalVideos => 'No additional videos currently';

  @override
  String get mainVideo => 'Main Video';

  @override
  String additionalVideoCount(int count) {
    return 'Additional Video $count';
  }

  @override
  String get noExamsResultsYet => 'No exams results yet';

  @override
  String get generalExam => 'General Exam';

  @override
  String get test => 'Test';

  @override
  String yourScoreLabel(Object score) {
    return 'Your Score: $score';
  }

  @override
  String get details => 'Details';

  @override
  String get failedToDisplayAnswers => 'Failed to display answers';

  @override
  String get examResultTitle => 'Exam Result';

  @override
  String yourScoreWithTotal(Object score, Object total) {
    return 'Your Score: $score / $total';
  }

  @override
  String get notAnswered => 'Not answered';

  @override
  String get notAvailable => 'Not available';

  @override
  String get yourAnswerLabel => 'Your Answer:';

  @override
  String get correctAnswerLabel => 'Correct Answer:';

  @override
  String questionScoreLabel(Object score, Object total) {
    return 'Score: $score / $total';
  }

  @override
  String get failedToFetchServerTime => 'Failed to fetch server time';

  @override
  String get remainingTimeLabel => 'Remaining Time';

  @override
  String get timeSpentLabel => 'Time Spent';

  @override
  String get minutesShort => 'm';

  @override
  String get noQuestions => 'No questions';

  @override
  String questionIndex(String param) {
    return 'Question $param';
  }

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get trueValue => 'True';

  @override
  String get falseValue => 'False';

  @override
  String get enterAnswerHint => 'Enter your answer here';

  @override
  String get completeAnswerHint => 'Complete the answer...';

  @override
  String get typeDialogueHint => 'Type the dialogue here...';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get noRanksAvailable => 'No ranks available currently';

  @override
  String yourCurrentPoints(Object points) {
    return 'Your Current Points: $points';
  }

  @override
  String teacherCourses(String name) {
    return 'Courses of $name';
  }

  @override
  String get noCoursesForTeacher => 'No courses for this teacher';

  @override
  String get liveStreamTitle => 'Live Stream';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get commentsLabel => 'Comments';

  @override
  String get writeCommentHint => 'Write your comment...';

  @override
  String get voiceUploadSuccess => 'Voice comment uploaded successfully';

  @override
  String get voiceUploadFailed => 'Failed to upload voice file!';

  @override
  String get userLabel => 'User';

  @override
  String get noNumberLabel => 'No Number';

  @override
  String get whatsappError =>
      'Could not open WhatsApp. Make sure the app is installed.';

  @override
  String get whatsappNotSupported =>
      'WhatsApp is not supported on this system.';

  @override
  String get technicalSupport => 'Technical Support';

  @override
  String get supportEmailBody => 'Hello, I need help with...';

  @override
  String get secondary => 'Secondary';

  @override
  String get preparatory => 'Preparatory';

  @override
  String get primary => 'Primary';

  @override
  String get level1 => 'Level 1';

  @override
  String get level2 => 'Level 2';

  @override
  String get level3 => 'Level 3';

  @override
  String get level4 => 'Level 4';

  @override
  String get level5 => 'Level 5';

  @override
  String get level6 => 'Level 6';

  @override
  String pointsLabel(int points) {
    return 'Your Points: $points';
  }

  @override
  String pointsTitle(int points) {
    return 'Points: $points';
  }

  @override
  String get accountInfo => 'Account Info';

  @override
  String get nameLabel => 'Name:';

  @override
  String get usernameLabel => 'Username:';

  @override
  String get phoneLabel => 'Phone Number:';

  @override
  String get studentData => 'Student Data';

  @override
  String get loginData => 'Login Data';

  @override
  String get notAllowed => 'Not Allowed';

  @override
  String get emulatorBlockMessage =>
      'This app does not work on emulators.\nPlease use a physical device.';

  @override
  String get close => 'Close';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteMessageTitle => 'Delete Message';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get noTeachersAvailable => 'No teachers available at the moment';

  @override
  String get activateNow => 'Activate Now';

  @override
  String get activateVideo => 'Activate Video';

  @override
  String get noMistakesToReview => 'No mistakes to review right now 🎉';

  @override
  String get failedToLoadReviewQuestions => 'Failed to load review questions';

  @override
  String get tournamentsHistory => 'Tournaments History';

  @override
  String get changeGroup => 'Change Group';

  @override
  String get addAnotherAccount => 'Add Another Account';

  @override
  String get audioRecordingNotSupportedOnWeb =>
      'Audio recording is not supported on web currently';

  @override
  String get failedToExtractVideoId => 'Failed to extract video ID';

  @override
  String get downloadedWatchOffline => '✅ Downloaded — You can watch offline';

  @override
  String get cannotWatchVideoOffline =>
      'This video cannot be displayed offline';

  @override
  String get savedOffline => 'Saved Offline';

  @override
  String get downloadOffline => 'Download Offline';

  @override
  String get lessonCompletionQuiz => 'Lesson Completion Quiz';

  @override
  String get nextLectureAvailableNow => 'Next lecture is available now';

  @override
  String get reviewMyMistakes => 'Review my mistakes';

  @override
  String get nextLecture => 'Next Lecture';

  @override
  String get examNotAvailableNow => 'Exam is not available right now';

  @override
  String get subscribed => 'Subscribed';

  @override
  String get couldNotFindPdfFile => 'Could not find PDF file';

  @override
  String get failedToDownloadFile => 'Failed to download file';

  @override
  String get goToFirstUnansweredQuestion => 'Go to first unanswered question';

  @override
  String get submitNow => 'Submit Now';

  @override
  String get done => 'Done';

  @override
  String get noQuestionsToReview => 'No questions to review';

  @override
  String get notAllowedTxt => 'Not Allowed';

  @override
  String get emulatorError =>
      'This app does not work on emulators.\\nPlease use a real device.';

  @override
  String get closeDialog => 'Close';

  @override
  String get chat => 'Chat';

  @override
  String get unknownPerson => 'Unknown';

  @override
  String get studentRole => 'Student';

  @override
  String get invalidCourseId => 'Invalid Course ID';

  @override
  String get noServerResponse => 'No response from server';

  @override
  String get sessionExpired => 'Session expired, please login again';

  @override
  String get failedToLoadMessages => 'Failed to load messages';

  @override
  String get you => 'You';

  @override
  String failedToSendMsg(String param) {
    return 'Failed to send message: $param';
  }

  @override
  String errorSending(String param) {
    return 'Error while sending: $param';
  }

  @override
  String get deleteMessageBtn => 'Delete Message';

  @override
  String get confirmDeleteMsg =>
      'Are you sure you want to delete this message?';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get deleteBtn => 'Delete';

  @override
  String get msgDeletedSuccess => 'Message deleted';

  @override
  String get failedToDeleteMsg => 'Failed to delete message';

  @override
  String get errorDeleting => 'Error while deleting';

  @override
  String hoursAgo(String param) {
    return '$param hours';
  }

  @override
  String minutesAgo(String param) {
    return '$param minutes';
  }

  @override
  String get justNow => 'Now';

  @override
  String get deletedMessage => 'Deleted message';

  @override
  String get sendFailedRetry => 'Failed to send, tap to retry';

  @override
  String get sendingMsg => 'Sending...';

  @override
  String get cannotLoadMessages => 'Cannot load messages';

  @override
  String get retryBtn => 'Retry';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get beFirstToWrite => 'Be the first to write!';

  @override
  String get replyingTo => 'Replying to:';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get examNotAvailable => 'Exam is not available right now';

  @override
  String get courseChat => 'Course Chat';

  @override
  String lessonsCount(String param) {
    return '$param lessons';
  }

  @override
  String filesCount(String param) {
    return '$param files';
  }

  @override
  String get nextLesson => 'Next Lesson';

  @override
  String priceEgp(String param) {
    return '$param EGP';
  }

  @override
  String get totalPrice => 'Total Price';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get lessonLocked => 'Lesson Locked';

  @override
  String get mustSolvePreviousVideoExam =>
      'You must solve the previous video exam to watch';

  @override
  String get okBtn => 'OK';

  @override
  String get completedStatus => 'Completed';

  @override
  String get buyVideo => 'Buy Video';

  @override
  String get solveExamFirst => 'Solve the exam first';

  @override
  String get freeWatch => 'Free • Watch';

  @override
  String get video45Mins => 'Video • 45 mins';

  @override
  String get freeBadge => 'Free';

  @override
  String get purchaseBtn => 'Purchase';

  @override
  String startsInExam(String param) {
    return 'Starts in: $param';
  }

  @override
  String get pdfFileLabel => 'PDF File';

  @override
  String get invalidOrEmptyFile => 'Invalid or empty file';

  @override
  String get localFileNotFound => 'Local file not found';

  @override
  String get errorOpeningFile => 'Error opening file';

  @override
  String get invalidDownloadLink => 'Invalid download link';

  @override
  String failedToDownloadPdfCode(String param) {
    return 'Failed to download PDF ($param)';
  }

  @override
  String get downloadedFileInvalid => 'Downloaded file is invalid';

  @override
  String get canSaveFromShare => '✅ You can save the file from the share menu';

  @override
  String get errorDownloadingFile => 'Error downloading file';

  @override
  String get thirdSecGrade => '3rd Secondary Grade';

  @override
  String get subscribedBadge => 'Subscribed';

  @override
  String get coursePromo => 'Course Promo';

  @override
  String get activateCourse => 'Activate Course';

  @override
  String get enterActivationCodeCourse =>
      'Enter activation code to unlock course contents.';

  @override
  String get activateNowBtn => 'Activate Now';

  @override
  String get activateVideoBtn => 'Activate Video';

  @override
  String get enterActivationCodeVideo =>
      'Enter activation code to unlock this video.';

  @override
  String get invalidCode => 'Invalid code!';

  @override
  String get checkCodeTypo =>
      'Please ensure the numbers and letters are correct, or that the code hasn\'t been used before.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get contactSupportToSolve => 'Contact support to solve the issue';

  @override
  String get activatedSuccessfully => 'Activated Successfully';

  @override
  String get videoAddedSuccess => 'Video added to your content successfully.';

  @override
  String itemAddedSuccess(String param) {
    return '\"$param\" added to your content successfully.';
  }

  @override
  String get watchVideoBtn => 'Watch Video';

  @override
  String get goToCourseBtn => 'Go to Course';

  @override
  String get noLiveStreamNow => 'No live stream available now';

  @override
  String get cannotShowStream => 'Cannot show stream';

  @override
  String get tapToOpenLive => 'Tap to open live stream';

  @override
  String get courseLiveChat => 'Course Live Chat';

  @override
  String get questionsLessonsChat => 'Questions & Lessons Chat';

  @override
  String outOfTotal(String param) {
    return 'out of $param';
  }

  @override
  String get reviewMistakesBtn => 'Review Mistakes';

  @override
  String get backToHomeBtn => 'Back to Home';

  @override
  String get trueVal => 'True';

  @override
  String get falseVal => 'False';

  @override
  String get questionsRemainingTitle => 'Questions Remaining';

  @override
  String mustAnswerAllQuestions(String param) {
    return 'You must answer all questions before submitting.\\nYou have $param unanswered questions.';
  }

  @override
  String get goToFirstMissingQ => 'Go to first missing question';

  @override
  String get submitExamBtn => 'Submit Exam';

  @override
  String get confirmSubmitExam =>
      'Are you sure you want to submit the exam now?';

  @override
  String get goBackBtn => 'Back';

  @override
  String get submitBtn => 'Submit';

  @override
  String progressPercentDone(String param) {
    return '$param% Completed';
  }

  @override
  String get submittingExam => 'Submitting exam...';

  @override
  String get dontCloseApp => 'Please do not close the app';

  @override
  String get choiceA => 'A';

  @override
  String get choiceB => 'B';

  @override
  String get choiceC => 'C';

  @override
  String get choiceD => 'D';

  @override
  String failedToSendExerciseResult(String param) {
    return 'Failed to send exercise result (Code $param). Try again.';
  }

  @override
  String get errorSendingExercise => 'Error sending exercise. Try again.';

  @override
  String questionXOfY(String param1, String param2) {
    return 'Question $param1 of $param2';
  }

  @override
  String unansweredQuestionsOpt(String param) {
    return 'You haven\'t answered $param questions. You can continue or submit what you have.';
  }

  @override
  String get submitNowBtn => 'Submit Now';

  @override
  String solvedCorrectXOfY(String param1, String param2) {
    return 'You got $param1 out of $param2 correct';
  }

  @override
  String timeSpentFormat(String param) {
    return 'Time spent: $param';
  }

  @override
  String get doneBtn => 'Done';

  @override
  String qXOfY(String param1, String param2) {
    return 'Question $param1 of $param2';
  }

  @override
  String get wrongChoice => 'Wrong';

  @override
  String get typeAnswerHere => 'Type your answer here';

  @override
  String get completeSentence => 'Complete the sentence';

  @override
  String get typeDialogue => 'Type the dialogue';

  @override
  String get previousBtn => 'Previous';

  @override
  String get finishBtn => 'Finish';

  @override
  String get nextBtn => 'Next';

  @override
  String get audioNotSupportedWeb =>
      'Audio recording is not supported on web currently';

  @override
  String get userRole => 'User';

  @override
  String downloadedFileTitle(String param) {
    return 'Downloaded file: $param';
  }

  @override
  String get downloadedFilesOffline => 'Downloaded Files (Offline)';

  @override
  String get noDownloadedPdfs => 'No previously downloaded PDF files';

  @override
  String get availableOffline => 'Available for offline use';

  @override
  String get failedToLoadRank => 'Failed to load rank data';

  @override
  String get letterA1 => 'A';

  @override
  String get letterA2 => 'A';

  @override
  String get letterA3 => 'A';

  @override
  String get letterTa => 'Ta';

  @override
  String get letterHa => 'Ha';

  @override
  String get letterYa => 'Ya';

  @override
  String get letterYaa => 'Yaa';

  @override
  String get coursesTab => 'Courses';

  @override
  String get videosTab => 'Videos';

  @override
  String get searchResults => 'Search Results';

  @override
  String get searchForSomethingElse => 'Search for something else...';

  @override
  String get isSubscribed => 'Subscribed';

  @override
  String get noMatchingResults => 'No results matching your search';

  @override
  String get tryDifferentWords => 'Try searching with different words';

  @override
  String get videoPlayerTitle => 'Video Player';

  @override
  String get videoViewCounted => '✅ Video view counted — +50 XP';

  @override
  String get cannotExtractVideoId => 'Cannot extract video ID';

  @override
  String get failedToGetDownloadLink => 'Failed to fetch download link';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadSuccessOffline => '✅ Downloaded — You can watch offline';

  @override
  String errorDisplay(String param) {
    return '❌ Error: $param';
  }

  @override
  String get videoCannotBeOffline => 'This video cannot be viewed offline';

  @override
  String get watchedBadge => 'Watched';

  @override
  String get alertTitle => 'Alert';

  @override
  String get maxViewsReached =>
      'You have reached the maximum views for this video. Contact the teacher to increase the limit.';

  @override
  String get returnBtn => 'Return';

  @override
  String get teacherMohamed => 'Mr. Mohamed Abd El Maboud';

  @override
  String get watchForXp => 'Watch for +50 XP';

  @override
  String minutesWatchedNeeded(String param1, String param2) {
    return '$param1 / $param2 mins';
  }

  @override
  String get watchProgress => 'Watch Progress';

  @override
  String get savedOfflineBadge => 'Saved Offline';

  @override
  String downloadingPercent(String param) {
    return 'Downloading $param%';
  }

  @override
  String get downloadingDots => 'Downloading...';

  @override
  String get downloadOfflineBtn => 'Download for offline';

  @override
  String get mustPassQuizToUnlock =>
      'You must pass the quiz to unlock the next lesson';

  @override
  String get htmlPageLabel => 'HTML Page';

  @override
  String questionsCountLabel(String param) {
    return '$param Questions';
  }

  @override
  String durationMinsLabel(String param) {
    return '$param Minutes';
  }

  @override
  String passMarkPercent(String param) {
    return 'Passing mark $param%';
  }

  @override
  String get startExamNowBtn => 'Start Exam Now';

  @override
  String get nextLectureAvailable => 'Next lecture is available now';

  @override
  String get nextLectureBtn => 'Next Lecture';

  @override
  String get voiceMessageLabel => 'Voice Message';

  @override
  String get enterPhoneOrEmail =>
      'Please enter registered phone number or email';

  @override
  String get whatsappCodeSentSuccess =>
      'Verification code sent successfully on WhatsApp';

  @override
  String get failedToSendCode => 'Failed to send code';

  @override
  String get errorConnectingToServer => 'Error connecting to server';

  @override
  String get enter6DigitCode => 'Please enter the 6-digit verification code';

  @override
  String get verifiedEnterNewPassword =>
      'Verified successfully, enter new password';

  @override
  String get invalidVerificationCode => 'Invalid verification code';

  @override
  String get errorVerifyingCode => 'Error verifying code';

  @override
  String get passwordMinLength6 => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get failedToChangePassword => 'Failed to change password';

  @override
  String get errorSettingPassword => 'Error setting password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully 🎉';

  @override
  String get loginWithNewPassword =>
      'You can now login using the new password.';

  @override
  String get loginTitle => 'Login';

  @override
  String get enterPhoneToSendCode =>
      'Enter your registered phone or email to send verification code via WhatsApp';

  @override
  String get phoneOrUsernameHint => 'Registered phone number or username';

  @override
  String get sendWhatsappCode => 'Send WhatsApp Code';

  @override
  String codeSentToNumber(String param) {
    return 'A 6-digit verification code was sent to WhatsApp number:\\n$param';
  }

  @override
  String get otpCodeHint => 'Verification Code (OTP)';

  @override
  String get confirmCodeBtn => 'Confirm Code';

  @override
  String get changePhoneNumber => 'Change phone number';

  @override
  String get enterNewPasswordToComplete =>
      'Enter new password and confirm to complete';

  @override
  String get newPasswordHint => 'New Password';

  @override
  String get confirmNewPasswordHint => 'Confirm New Password';

  @override
  String get saveNewPasswordBtn => 'Save New Password';

  @override
  String get accountRegisteredOnAnotherDevice =>
      'This account is registered on another device. Please contact the teacher to reset the device.';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registeredSuccessfully => 'Registered Successfully';

  @override
  String get accountUnderReview =>
      'Your account is currently under review, it will be activated soon by the teacher.';

  @override
  String get redirectOnActivation =>
      'You will be redirected automatically upon activation...';

  @override
  String get educationalStage => 'Educational Stage';

  @override
  String get byLoggingInYouAgree => 'By logging in, you agree to ';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get chooseStageFirst => 'Choose educational stage first';

  @override
  String get rank1 => 'Lieutenant';

  @override
  String get rank2 => 'First Lieutenant';

  @override
  String get rank3 => 'Captain';

  @override
  String get rank4 => 'Major';

  @override
  String get rank5 => 'Lieutenant Colonel';

  @override
  String get rank6 => 'Colonel';

  @override
  String get rank7 => 'Brigadier General';

  @override
  String get rank8 => 'Major General';

  @override
  String get streakDays => 'Streak Days';

  @override
  String get medals => 'Medals';

  @override
  String get completedCourseBadge => 'Completed Course';

  @override
  String get tournamentsHistoryLabel => 'Tournaments History';

  @override
  String get studyGroup => 'Study Group';

  @override
  String get changeGroupBtn => 'Change Group';

  @override
  String get tapToSwitchAccount => 'Tap to switch account';

  @override
  String get addAnotherAccountBtn => 'Add another account';

  @override
  String availableNumbersCount(String param) {
    return '$param available numbers';
  }

  @override
  String get forQuickInquiries => 'For quick inquiries';

  @override
  String get officialStudentsGroup => 'Official students group';

  @override
  String get techSupportLabel => 'Technical Support';

  @override
  String get darkModeTitle => 'Dark Mode';

  @override
  String get forAppOrVideoIssues => 'For app or video issues';

  @override
  String get switchAccountTitle => 'Switch Account';

  @override
  String get contactTeacherTitle => 'Contact Teacher';

  @override
  String get supportAndAccountTitle => 'Support & Account';

  @override
  String get notObtained => 'Not obtained';

  @override
  String get oneTime => 'One time';

  @override
  String get twoTimes => 'Two times';

  @override
  String timesCount(String param) {
    return '$param times';
  }

  @override
  String timeCountSingle(String param) {
    return '$param time';
  }

  @override
  String get leaderboardMedals => 'Leaderboard Medals';

  @override
  String get firstPlace => '1st Place';

  @override
  String get secondPlace => '2nd Place';

  @override
  String get thirdPlace => '3rd Place';

  @override
  String get idealStudent => 'Ideal Student';

  @override
  String get ranksPath => 'Ranks Path';

  @override
  String get currentRankBadge => 'Current';

  @override
  String get untitled => 'Untitled';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get myCoursesTab => 'My Courses';

  @override
  String get allTab => 'All';

  @override
  String inProgressCountTab(String param) {
    return 'In Progress ($param)';
  }

  @override
  String completedCountTab(String param) {
    return 'Completed ($param)';
  }

  @override
  String get noCourses => 'No courses';

  @override
  String get continueBtn => 'Continue';

  @override
  String get finishedStatus => 'Finished';

  @override
  String get doneThanksGod => 'Done (Thanks to God)';

  @override
  String get notAvailableVal => 'Not available';

  @override
  String get mistakesBank => 'Mistakes Bank';

  @override
  String get congratsNoMistakes => 'Congratulations! You have no mistakes ';

  @override
  String get questionNotAvailable => 'Question not available';

  @override
  String get optionsLabel => 'Options:';

  @override
  String yourAnswerVal(String param) {
    return 'Your answer: $param';
  }

  @override
  String correctAnswerVal(String param) {
    return 'Correct answer: $param';
  }

  @override
  String get unknownVal => 'Unknown';

  @override
  String examIdVal(String param) {
    return 'Exam: $param';
  }

  @override
  String addedOnDate(String param) {
    return 'Added on: $param';
  }

  @override
  String get noMistakesToReviewNow => 'No mistakes to review now 🎉';

  @override
  String get failedToLoadReviewQ => 'Failed to load review questions';

  @override
  String get startsSoon => 'Starts soon';

  @override
  String get alreadyStarted => 'Already started';

  @override
  String startsInDays(String param1, String param2) {
    return 'Starts in $param1 days';
  }

  @override
  String startsInHoursMins(String param1, String param2) {
    return 'Starts in $param1 hours and $param2 minutes';
  }

  @override
  String startsInHours(String param1, String param2) {
    return 'Starts in $param1 hours';
  }

  @override
  String startsInMinutes(String param) {
    return 'Starts in $param minutes';
  }

  @override
  String get startsNow => 'Starts now';

  @override
  String get endsSoon => 'Ends soon';

  @override
  String get ended => 'Ended';

  @override
  String endsInDays(String param) {
    return 'Ends in $param days';
  }

  @override
  String endsInHoursMins(String param1, String param2) {
    return 'Ends in $param1 hours and $param2 minutes';
  }

  @override
  String endsInHours(String param1, String param2) {
    return 'Ends in $param1 hours';
  }

  @override
  String endsInMinutes(String param) {
    return 'Ends in $param minutes';
  }

  @override
  String get endsNow => 'Ends now';

  @override
  String get startExamBtn => 'Start Exam';

  @override
  String get newExamsTitle => 'New Exams';

  @override
  String get pastExamsHistory => 'Past Exams History';

  @override
  String get examsTitle => 'Exams';

  @override
  String get youHavePre => 'You have ';

  @override
  String mistakeCountQ(String param) {
    return '$param questions';
  }

  @override
  String get wrongSuf => ' wrong';

  @override
  String get congratsSuf => ', congratulations!';

  @override
  String examsCountStr(String param) {
    return '$param exams';
  }

  @override
  String questionsCountStr(String param) {
    return '$param questions';
  }

  @override
  String get questionsLabel => 'Questions';

  @override
  String get examDurationLabel => 'Exam Duration';

  @override
  String get submittedStatus => 'Submitted';

  @override
  String get examSubmitted => 'Exam submitted';

  @override
  String get startExamNowLabel => 'Start exam now';

  @override
  String sinceDays(String param) {
    return '$param days ago';
  }

  @override
  String sinceHours(String param) {
    return '$param hours ago';
  }

  @override
  String sinceMinutes(String param) {
    return '$param minutes ago';
  }

  @override
  String get teacherRole => 'Teacher';

  @override
  String get cannotLoadData => 'Cannot load data';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get savedDataExpiredConnect =>
      'Saved data expired, please connect to internet';

  @override
  String get connectToDownloadContent =>
      'Please connect to internet to load content';

  @override
  String dataSavedDaysLeft(String param) {
    return 'Data saved, $param days left before expiration';
  }

  @override
  String get searchSubjectCourseHint => 'Search for subject or course';

  @override
  String get currentRankTitle => 'Current Rank';

  @override
  String get targetPrefix => 'Target: ';

  @override
  String countVideosCourses(String param1, String param2) {
    return '$param1 $param2';
  }

  @override
  String get youCanMakeUpForIt => 'You can make up for it';

  @override
  String get amazingPerformance => 'Amazing performance! Keep shining! 🌟';

  @override
  String get everyMistakeIsLesson =>
      'Every mistake is a new lesson. You can do it! 💪';

  @override
  String get viewResultBtn => 'View Result';

  @override
  String get suggestedCourses => 'Suggested Courses';

  @override
  String noSearchResultsForQuery(String param) {
    return 'No search results matching \"$param\"';
  }

  @override
  String get subscribedCourses => 'Subscribed Courses';

  @override
  String get subscribeBtn => 'Subscribe';

  @override
  String get cannotVerifyRequest => 'Cannot verify request';

  @override
  String get serverConnectionTookLong =>
      'Server connection took a long time. If the code was deducted, the course will appear in your accounts — swipe down to refresh the page.';

  @override
  String get refreshPage => 'Refresh Page';

  @override
  String get cannotLoadTeachers => 'Cannot load teachers list';

  @override
  String errorLoadingTeachers(String param) {
    return 'Error loading teachers: $param';
  }

  @override
  String get pleaseSelectTeacherFirst => 'Please select teacher first';

  @override
  String get teacherLiveChat => 'Teacher Live Chat';

  @override
  String talkingToTeacher(String param) {
    return 'Talking to: $param';
  }

  @override
  String get askTeacherWillReply => 'Ask and the teacher will reply to you';

  @override
  String get noTeachersAvailableNow => 'No teachers available currently';

  @override
  String get selectTeacherToChat => 'Select teacher for chat:';

  @override
  String get noMessagesWithTeacher => 'No messages with teacher yet';

  @override
  String get writeQuestionTeacherReply =>
      'Write your question or inquiry and the teacher will reply!';

  @override
  String get replyingToMessage => 'Replying to message:';

  @override
  String get writeMessageToTeacher => 'Write your message to the teacher...';

  @override
  String get noSearchMatchSlash => 'No search results matching \\\"';

  @override
  String get videosListLabel => 'Videos';

  @override
  String get clearDrawingForPage => 'Clear drawing for this page';

  @override
  String pageIndexLabel(String param) {
    return 'Page $param';
  }

  @override
  String get noAccessTokenReceived => 'Access token not received from server';

  @override
  String switchedToAccount(String param) {
    return 'Switched to $param';
  }

  @override
  String get loginFailed => 'Login failed';

  @override
  String get deleteAccountBtn => 'Delete Account';

  @override
  String confirmDeleteAccount(String param) {
    return 'Do you want to delete $param account from the list?';
  }

  @override
  String get noSavedAccounts => 'No saved accounts';

  @override
  String get activeAccount => 'Active Account';

  @override
  String get addNewAccount => 'Add new account';

  @override
  String get chooseAppLanguage => 'Choose App Language';

  @override
  String get selectLanguageSubtitle =>
      'Select your preferred language to browse courses & content';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get arabicSubtitle => 'أهلاً بك! تصفح التطبيق كاملاً باللغة العربية';

  @override
  String get englishLanguage => 'English';

  @override
  String get englishSubtitle => 'Welcome! Browse the full app in English';

  @override
  String get continueToApp => 'Continue';

  @override
  String get welcomeToPlatform => 'Welcome to Our Platform';

  @override
  String get onlinePaymentFawaterak => 'Online Payment';

  @override
  String get activationCodeTab => 'Activation Code';

  @override
  String get noPaymentMethodsAvailable =>
      'No payment methods available currently';

  @override
  String get selectPaymentMethod => 'Select your preferred payment method:';

  @override
  String get goToPaymentNow => 'Proceed to Payment Now';

  @override
  String get buyViaWhatsapp => 'Buy & Order via WhatsApp';

  @override
  String get fawryPaymentCode => 'Payment Code (Fawry / Aman)';

  @override
  String get doneClose => 'Done / Close';

  @override
  String get paymentPageOpenedSnackBar =>
      'Online payment page opened, please complete in browser';

  @override
  String get paymentInitiationFailed => 'Failed to initiate payment';

  @override
  String whatsappPurchaseMessage(String title) {
    return 'Hello, I want to purchase and activate course: $title';
  }

  @override
  String get paymentMethodFallback => 'Payment Method';

  @override
  String get couldNotFetchPaymentMethods => 'Could not fetch payment methods';

  @override
  String fawryInstructionNote(String title) {
    return 'Keep this code and visit the nearest branch to pay for the course ($title):';
  }
}
