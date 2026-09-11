import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/appearing_screens/exams_history_page.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/exam_result_page.dart';
import 'package:flutter_version/screens/mainscreens/account_page.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/theme_helper.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/data/category_model.dart';
import 'package:flutter_version/screens/appearing_screens/category_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/screens/appearing_screens/course_details_page.dart';
import 'package:flutter_version/screens/appearing_screens/reelsPlayerPage.dart';
import 'package:flutter_version/screens/appearing_screens/search_results_page.dart';
import 'package:flutter_version/utilities/navigation_animations.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/data/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/data/offline_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/screens/mainscreens/global_leaderboard_screen.dart';

class _AppFonts {
  static final Map<String, TextStyle> _cache = {};

  static TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    final key = '$fontSize-$fontWeight-${color?.value}-$height-$decoration';
    return _cache.putIfAbsent(
      key,
      () => GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool isOffline = false;

  static const double _collapseStart = 40.0;
  static const double _collapseEnd = 140.0;

  String userName = "";
  String userGroupName = "";
  int studentScore = 0;
  int streakCount = 0;
  int firstPlaceCount = 0;
  int secondPlaceCount = 0;
  int thirdPlaceCount = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(AppLocalizations.of(context)?.choiceA ?? "أ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA2 ?? "إ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA3 ?? "آ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterTa ?? "ة",
            AppLocalizations.of(context)?.letterHa ?? "ه")
        .replaceAll(AppLocalizations.of(context)?.letterYa ?? "ى",
            AppLocalizations.of(context)?.letterYaa ?? "ي")
        .trim();
  }

  List<Map<String, dynamic>> availableCourses = [];
  List<Map<String, dynamic>> myCourses = [];
  List<Map<String, dynamic>> teachersList = [];
  List<Category> rootCategories = [];
  List<String> realsUrls = [];

  Map<String, dynamic>? _lastQuizResult;
  bool _quizCardDismissed = false;
  String? _selectedTeacherId;

  bool _shouldShowLastQuiz() {
    if (_lastQuizResult == null) return false;
    if (_selectedTeacherId == null) return true;

    final selectedTeacher = teachersList.firstWhere(
      (t) => t["_id"] == _selectedTeacherId,
      orElse: () => {},
    );
    if (selectedTeacher.isEmpty) return true;

    final quizTeacherId = _lastQuizResult!["teacherId"]?.toString();
    if (quizTeacherId != null && quizTeacherId.isNotEmpty) {
      if (quizTeacherId == _selectedTeacherId) {
        return true;
      }
    }

    final teacherName = _normalize(selectedTeacher["name"].toString());
    final quizTeacher = _normalize(_lastQuizResult!["teacherName"].toString());

    String cleanName(String name) {
      return name
          .replaceAll(
              RegExp(r'^(ا\.|ا/|استاذ\s|الاستاذ\s|د\.|دكتور\s|م\.|مهندس\s)'),
              '')
          .trim();
    }

    final cleanedTeacherName = cleanName(teacherName);
    final cleanedQuizTeacher = cleanName(quizTeacher);

    if (quizTeacher != "space") {
      if (cleanedQuizTeacher.contains(cleanedTeacherName) ||
          cleanedTeacherName.contains(cleanedQuizTeacher)) {
        return true;
      }

      final teacherWords = cleanedTeacherName
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();
      final quizWords = cleanedQuizTeacher
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();

      for (var tw in teacherWords) {
        if (quizWords.contains(tw)) {
          return true;
        }
      }
    }

    final quizCourseId = _lastQuizResult!["courseId"]?.toString();
    if (quizCourseId != null && quizCourseId.isNotEmpty) {
      final course = [...myCourses, ...availableCourses].firstWhere(
        (c) => c["id"]?.toString() == quizCourseId,
        orElse: () => {},
      );
      if (course.isNotEmpty) {
        final courseTeacherId = course["Teacher"]?.toString();
        if (courseTeacherId != null && courseTeacherId == _selectedTeacherId) {
          return true;
        }
      }
    }

    if (quizTeacher == "space") {
      final quizTitle = _normalize(_lastQuizResult!["title"].toString());
      final teacherCourses = [...myCourses, ...availableCourses].where(
        (c) => c["Teacher"]?.toString() == _selectedTeacherId,
      );
      for (var c in teacherCourses) {
        final courseTitle = _normalize(c["title"]?.toString() ?? "");
        final subject = _normalize(c["subject"]?.toString() ?? "");
        if (quizTitle.contains(subject) || subject.contains(quizTitle)) {
          return true;
        }
        final courseWords = courseTitle
            .split(RegExp(r'\s+'))
            .where((w) => w.length > 2)
            .toList();
        for (var cw in courseWords) {
          if (quizTitle.contains(cw)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // void _launchPhone(String phone) async {
  //   final Uri uri = Uri(scheme: 'tel', path: phone);
  //   try {
  //     await launchUrl(uri);
  //   } catch (e) {
  //     debugPrint("❌ Could not launch phone dialer: $e");
  //   }
  // }

  Future<void> _launchWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // إذا كان رقم مصري محلي يبدأ بـ 01
    if (cleanPhone.startsWith('01')) {
      cleanPhone = '2$cleanPhone';
    }

    final uri = Uri.parse("https://wa.me/$cleanPhone");

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Could not launch WhatsApp: $e");
    }
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Could not launch URL: $e");
    }
  }

  // void _launchPhone(String phone) async {
  //   final Uri uri = Uri(scheme: 'tel', path: phone);
  //   try {
  //     await launchUrl(uri);
  //   } catch (e) {
  //     debugPrint("❌ Could not launch phone dialer: $e");
  //   }
  // }

  Widget _buildFloatingContactButtons() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Consumer<CompanySettingsProvider>(
      builder: (context, provider, child) {
        final overlay = provider.overlayIconDisplay;
        final contact = provider.contactInfo;

        final buttons = <Widget>[];

        if (overlay.whatsapp && contact.whatsapp.isNotEmpty) {
          buttons.add(_buildFloatingButton(
            icon: PhosphorIconsFill.whatsappLogo,
            color: AppColors.greenStatus(isDark),
            tooltip: 'WhatsApp',
            onPressed: () => _launchWhatsApp(contact.whatsapp.first.value),
          ));
        }

        if (overlay.facebook && contact.facebook.isNotEmpty) {
          buttons.add(_buildFloatingButton(
            icon: PhosphorIconsFill.facebookLogo,
            color: AppColors.sky(isDark),
            tooltip: 'Facebook',
            onPressed: () => _launchUrl(contact.facebook.first.value),
          ));
        }

        if (overlay.techSupport && contact.techSupport.isNotEmpty) {
          buttons.add(_buildFloatingButton(
            icon: PhosphorIconsFill.headset,
            color: AppColors.getTextSecondaryColor(isDark),
            tooltip: 'Support',
            onPressed: () {
              final value = contact.techSupport.first.value;
              debugPrint("Tech support value = '$value'");

              if (value.trim().startsWith('http') ||
                  value.trim().startsWith('www.')) {
                _launchUrl(value);
              } else {
                _launchWhatsApp(value);
              }
            },
          ));
        }

        if (buttons.isEmpty) return const SizedBox.shrink();

        return Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: buttons,
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FloatingActionButton(
        heroTag: tooltip ?? icon.toString(),
        mini: true,
        backgroundColor: AppColors.getBackgroundColor(isDark),
        elevation: 4,
        onPressed: onPressed,
        tooltip: tooltip ?? '',
        child: Icon(icon,
            color: color, size: 24, textDirection: TextDirection.ltr),
      ),
    );
  }

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> get _rankTiers => [
        {
          "threshold": 0,
          "name": AppLocalizations.of(context)?.rank1 ?? "ملازم"
        },
        {
          "threshold": 100,
          "name": AppLocalizations.of(context)?.rank2 ?? "ملازم أول"
        },
        {
          "threshold": 300,
          "name": AppLocalizations.of(context)?.rank3 ?? "نقيب"
        },
        {
          "threshold": 600,
          "name": AppLocalizations.of(context)?.rank4 ?? "رائد"
        },
        {
          "threshold": 1000,
          "name": AppLocalizations.of(context)?.rank5 ?? "مقدم"
        },
        {
          "threshold": 1500,
          "name": AppLocalizations.of(context)?.rank6 ?? "عقيد"
        },
        {
          "threshold": 2200,
          "name": AppLocalizations.of(context)?.rank7 ?? "عميد"
        },
        {
          "threshold": 3000,
          "name": AppLocalizations.of(context)?.rank8 ?? "لواء"
        },
      ];

  Map<String, dynamic> get _rankInfo {
    String currentRank = _rankTiers.first["name"] as String;
    String nextRank =
        _rankTiers.length > 1 ? _rankTiers[1]["name"] as String : currentRank;
    int goalPoints =
        _rankTiers.length > 1 ? _rankTiers[1]["threshold"] as int : 0;

    for (int i = _rankTiers.length - 1; i >= 0; i--) {
      if (studentScore >= (_rankTiers[i]["threshold"] as int)) {
        currentRank = _rankTiers[i]["name"] as String;
        if (i + 1 < _rankTiers.length) {
          nextRank = _rankTiers[i + 1]["name"] as String;
          goalPoints = _rankTiers[i + 1]["threshold"] as int;
        } else {
          nextRank = currentRank;
          goalPoints = _rankTiers[i]["threshold"] as int;
        }
        break;
      }
    }
    return {
      "currentRank": currentRank,
      "nextRank": nextRank,
      "goalPoints": goalPoints,
    };
  }

  @override
  void initState() {
    super.initState();
    _checkAndUpdateStreak();
    _fetchHomeData();
    _fetchTeachersData();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          initialQuery: query,
          availableCourses: availableCourses,
          myCourses: myCourses,
          videos: [],
          teachers: teachersList,
        ),
      ),
    );
  }

  Future<void> _checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login_date');
    final today = DateTime.now().toString().split(' ')[0];
    final savedStreak = prefs.getInt('streak_count') ?? 0;

    if (lastLogin != today) {
      int newStreak = savedStreak;
      if (lastLogin != null) {
        final lastDate = DateTime.parse(lastLogin);
        final diff = DateTime.now().difference(lastDate).inDays;
        if (diff == 1) {
          newStreak = savedStreak + 1;
        } else if (diff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
      await prefs.setString('last_login_date', today);
      await prefs.setInt('streak_count', newStreak);
      if (mounted) setState(() => streakCount = newStreak);
    } else {
      if (mounted) setState(() => streakCount = savedStreak);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Data fetching
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchHomeData() async {
    if (mounted) setState(() => _isLoading = true);
    print("🔍 About to call getuser");

    // ─── Ensure company settings exist locally & refresh if >= 3 days old ────
    try {
      final companySettingsProvider =
          Provider.of<CompanySettingsProvider>(context, listen: false);
      await companySettingsProvider.ensureFreshSettings();
    } catch (e) {
      debugPrint("⚠️ Error checking company settings freshness: $e");
    }

    try {
      final userResponse =
          await _apiService.request("student/getuser", null, "GET");
      List<String> exercisesDone = [];
      if (userResponse == null) {
        debugPrint(
            "⚠️ getuser: no response (network/exception) — falling back to offline cache");
        await _handleOfflineFallback();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (userResponse.statusCode == 401 || userResponse.statusCode == 403) {
        debugPrint(
            "⚠️ getuser: status ${userResponse.statusCode} — session expired (handled by ApiService)");
        if (mounted) setState(() => _isLoading = false);
        return;
      } else if (userResponse.statusCode != 200) {
        debugPrint(
            "⚠️ getuser: unexpected status ${userResponse.statusCode} — falling back to offline cache");
        await _handleOfflineFallback();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (userResponse.statusCode == 200) {
        userName = userResponse.data["FirstName"] ??
            AppLocalizations.of(context)!.user;
        userGroupName = userResponse.data["groupName"] ?? "";
        firstPlaceCount = userResponse.data["firstPlaceCount"] ?? 0;
        secondPlaceCount = userResponse.data["secondPlaceCount"] ?? 0;
        thirdPlaceCount = userResponse.data["thirdPlaceCount"] ?? 0;
        exercisesDone = (userResponse.data["exercises_done"] as List?)
                ?.map((e) => e["exercise_id"].toString())
                .toList() ??
            [];
        await _storage.write(
            key: "savedUserNum", value: userResponse.data["parentPhoneNumber"]);
        if (!isOffline &&
            userResponse.data["appVersion"] != AppConfig.appVersion) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return WillPopScope(
                  onWillPop: () async => false,
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.updateRequired,
                        textAlign: TextAlign.center),
                    content: Text(
                      AppLocalizations.of(context)!.updateRequiredMessage,
                      textAlign: TextAlign.center,
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                  ),
                );
              },
            );
          }
        }
      }

      final myCourseResponse = await _apiService.request(
          "student/course/getpaidcourses", null, "GET");

      if (myCourseResponse != null && myCourseResponse.statusCode == 200) {
        myCourses = (myCourseResponse.data as List)
            .map((c) => {
                  "id": c["_id"],
                  "Teacher": c["Teacher"],
                  "title": c["title"] ?? "",
                  "image": c["photo"] ?? "assets/images/Group 1.png",
                  "price": c["price"] ?? 0,
                  "teacher": c["Teachername"] ?? "",
                  "subject":
                      c["subject"] ?? AppLocalizations.of(context)!.undefined,
                  "videoslist": c["videoslist"] ?? [],
                  "isPurchased": true,
                  "progress": (c["videoslist"] as List?) != null &&
                          (c["videoslist"] as List).isNotEmpty
                      ? (c["videoslist"] as List)
                              .where((v) => exercisesDone
                                  .contains(v["exercise_id"]?.toString()))
                              .length /
                          (c["videoslist"] as List).length
                      : 0.0,
                })
            .toList();
      } else {
        debugPrint(
            "⚠️ getpaidcourses failed: status ${myCourseResponse?.statusCode}");
      }

      final courseResponse = await _apiService.request(
          "student/course/getstudentcourses", null, "GET");
      if (courseResponse != null && courseResponse.statusCode == 200) {
        final purchasedIds = myCourses.map((c) => c["id"]).toSet();
        availableCourses = (courseResponse.data as List)
            .map((c) => {
                  "id": c["_id"],
                  "Teacher": c["Teacher"],
                  "title": c["title"] ?? "",
                  "image": c["photo"] ?? "assets/images/Group 1.png",
                  "price": c["price"] ?? 0,
                  "teacher": c["Teachername"] ?? "",
                  "subject":
                      c["subject"] ?? AppLocalizations.of(context)!.undefined,
                  "videoslist": c["videoslist"] ?? [],
                  "isPurchased": purchasedIds.contains(c["_id"]),
                  "freecourse": c["freecourse"] == true,
                  "progress": (c["videoslist"] as List?) != null &&
                          (c["videoslist"] as List).isNotEmpty
                      ? (c["videoslist"] as List)
                              .where((v) => exercisesDone
                                  .contains(v["exercise_id"]?.toString()))
                              .length /
                          (c["videoslist"] as List).length
                      : 0.0,
                })
            .toList();
      } else {
        debugPrint(
            "⚠️ getstudentcourses failed: status ${courseResponse?.statusCode}");
      }

      final categoryResponse = await _apiService.getCategoryTree();
      if (categoryResponse != null && categoryResponse.statusCode == 200) {
        final List categoryData = categoryResponse.data;
        rootCategories = categoryData.map((c) => Category.fromJson(c)).toList();
      }

      final realsResponse =
          await _apiService.request("reals/get_all_reals", null, "GET");
      if (realsResponse != null && realsResponse.statusCode == 200) {
        final List data = realsResponse.data;
        realsUrls = data
            .map((item) => item["realUrl"]?.toString() ?? "")
            .where((url) => url.isNotEmpty)
            .toList();
      }

      final scoreResponse =
          await _apiService.request("score/get_student_score", null, "GET");
      if (scoreResponse?.statusCode == 200) {
        final data = scoreResponse?.data;
        dynamic rawScore;
        if (data is Map) {
          rawScore = data["score"];
        } else if (data is List && data.isNotEmpty && data.first is Map) {
          rawScore =
              data.first["score"]; // handle a list-wrapped response defensively
        }
        if (rawScore is int) {
          studentScore = rawScore;
        } else if (rawScore is String) {
          studentScore = int.tryParse(rawScore) ?? 0;
        } else {
          studentScore = 0;
        }
      } else {
        studentScore = 0;
      }

      // ─── Fetch Student Badges from dedicated endpoint ─────────────

      try {
        final badgesResponse = await _apiService.request(
          "student/badges",
          null,
          "GET",
        );
        if (badgesResponse != null && badgesResponse.statusCode == 200) {
          final data = badgesResponse.data;
          if (data is Map) {
            setState(() {
              firstPlaceCount = data["firstPlace"] ?? 0;
              secondPlaceCount = data["secondPlace"] ?? 0;
              thirdPlaceCount = data["thirdPlace"] ?? 0;
            });
            debugPrint(
                "✅ Badges updated: first=$firstPlaceCount, second=$secondPlaceCount, third=$thirdPlaceCount");
          }
        } else {
          debugPrint(
              "⚠️ Badges endpoint returned status ${badgesResponse?.statusCode} – keeping fallback values");
        }
      } catch (e) {
        debugPrint("❌ Error fetching badges: $e – keeping fallback values");
      }

      // ─── Last Exam Result ─────────────────────────

      _lastQuizResult = null;
      _quizCardDismissed = false;

      try {
        final lastResultResponse = await _apiService.request(
          "student/exam/last-result",
          null,
          "GET",
        );


        if (lastResultResponse != null &&
            lastResultResponse.statusCode == 200 &&
            lastResultResponse.data != null) {
          final data = lastResultResponse.data;
          if (data is Map && data.isNotEmpty) {
            final String title = data["examname"] ?? data["examTitle"] ?? "";

            int score = 0;
            int total = 20;
            final resultVal = data["result"];
            if (resultVal is String && resultVal.contains('/')) {
              final parts = resultVal.split('/');
              score = int.tryParse(parts[0].trim()) ?? 0;
              total = int.tryParse(parts[1].trim()) ?? 20;
            } else {
              final rawScore = data["result"] ?? data["student_mark"];
              if (rawScore is num) {
                score = rawScore.toInt();
              } else if (rawScore is String) {
                score = int.tryParse(rawScore) ?? 0;
              }
              final rawTotal =
                  data["totalmark"] ?? data["total"] ?? data["totalMark"];
              if (rawTotal is num) {
                total = rawTotal.toInt();
              } else if (rawTotal is String) {
                total = int.tryParse(rawTotal) ?? 20;
              }
            }

            final teacherName = data["teacherName"] ??
                data["TeacherName"] ??
                data["Teacher_Name"] ??
                data["Teachername"] ??
                data["teacher"] ??
                "";

            final teacherId = data["teacherId"] ??
                data["TeacherId"] ??
                data["teacher"] ??
                data["Teacher"] ??
                "";

            final courseId =
                data["course_Id"] ?? data["courseId"] ?? data["course"] ?? "";

            final examId = data["exam_Id"] ?? data["examId"] ?? data["_id"] ?? "";

            String timeAgo = "";
            if (data["createdAt"] != null) {
              try {
                final created = DateTime.parse(data["createdAt"]);
                final now = DateTime.now();
                final diff = now.difference(created);
                if (diff.inDays > 0) {
                  timeAgo = AppLocalizations.of(context)
                          ?.sinceDays(diff.inDays.toString()) ??
                      "منذ ${diff.inDays} يوم";
                } else if (diff.inHours > 0) {
                  timeAgo = AppLocalizations.of(context)
                          ?.sinceHours(diff.inHours.toString()) ??
                      "منذ ${diff.inHours} ساعة";
                } else if (diff.inMinutes > 0) {
                  timeAgo = AppLocalizations.of(context)
                          ?.sinceMinutes(diff.inMinutes.toString()) ??
                      "منذ ${diff.inMinutes} دقيقة";
                } else {
                  timeAgo = AppLocalizations.of(context)?.justNow ?? "الآن";
                }
              } catch (_) {
                timeAgo = "";
              }
            }

            _lastQuizResult = {
              "title": title,
              "teacherName": teacherName,
              "teacherId": teacherId,
              "courseId": courseId,
              "score": score,
              "total": total,
              "timeAgo": timeAgo,
              "examId": examId,
            };
            _quizCardDismissed = false;
          }
        } else if (lastResultResponse != null &&
            lastResultResponse.statusCode == 404) {
          debugPrint(
              "ℹ️ No last exam result found (404) – student has no history");
          _lastQuizResult = null;
          _quizCardDismissed = false;
        }
      } catch (e) {
        debugPrint("❌ Error fetching last exam result: $e");
        _lastQuizResult = null;
        _quizCardDismissed = false;
      }


      // ─── Save offline cache (isolated — must never trigger the offline fallback) ──

      // ─── Save offline cache (isolated — must never affect what's shown) ──
      try {
        await OfflineDataService.saveHomeData({
          'userName': userName,
          'myCourses': myCourses,
          'availableCourses': availableCourses,
          'categories': rootCategories.map((c) => c.toJson()).toList(),
          'realsUrls': realsUrls,
          'studentScore': studentScore,
          'firstPlaceCount': firstPlaceCount,
          'secondPlaceCount': secondPlaceCount,
          'thirdPlaceCount': thirdPlaceCount,
        });
      } catch (e) {
        debugPrint("⚠️ Failed to save offline cache (non-fatal): $e");
      }
      if (mounted) {
        setState(() {
          isOffline = false;
          _offlineExpired = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching home data: $e");
      await _handleOfflineFallback();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleOfflineFallback() async {
    final valid = await OfflineDataService.isCacheValid();
    if (valid) {
      final cached = await OfflineDataService.loadHomeData();
      if (cached != null && mounted) {
        final daysLeft = await OfflineDataService.daysUntilExpiry();
        _loadCachedHomeData(cached);
        setState(() {
          isOffline = true;
          _offlineDaysLeft = daysLeft;
          _offlineExpired = false;
        });
      }
    } else {
      final enabled = await OfflineDataService.isEnabled();
      if (mounted) {
        setState(() {
          isOffline = true;
          _offlineEnabled = enabled;
          _offlineExpired = true;
        });
      }
    }
  }

  // ✅ FIX: state for the redesigned offline banner (replaces ugly SnackBar)
  int? _offlineDaysLeft;
  bool _offlineExpired = false;
  bool _offlineEnabled = true;

  void _loadCachedHomeData(Map<String, dynamic> cached) {
    setState(() {
      userName = cached['userName'] as String? ?? '';
      studentScore = (cached['studentScore'] as num?)?.toInt() ?? 0;
      firstPlaceCount = (cached['firstPlaceCount'] as num?)?.toInt() ?? 0;
      secondPlaceCount = (cached['secondPlaceCount'] as num?)?.toInt() ?? 0;
      thirdPlaceCount = (cached['thirdPlaceCount'] as num?)?.toInt() ?? 0;
      myCourses = List<Map<String, dynamic>>.from(
          (cached['myCourses'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e)));
      final purchasedIds = myCourses.map((c) => c["id"].toString()).toSet();
      availableCourses = List<Map<String, dynamic>>.from(
          (cached['availableCourses'] as List? ?? []).map((e) {
        final course = Map<String, dynamic>.from(e);
        course["isPurchased"] = purchasedIds.contains(course["id"].toString());
        return course;
      }));
      realsUrls = List<String>.from(cached['realsUrls'] as List? ?? []);
      rootCategories = ((cached['categories'] as List?) ?? [])
          .map((c) => Category.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupCoursesBySubject(
      List<Map<String, dynamic>> courses) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var course in courses) {
      final subject =
          course["subject"] ?? AppLocalizations.of(context)!.undefined;
      if (!grouped.containsKey(subject)) {
        grouped[subject] = [];
      }
      grouped[subject]!.add(course);
    }
    return grouped;
  }

  Future<void> _fetchTeachersData() async {
    try {
      final response =
          await _apiService.request("teacher/getalluser", null, "GET");
      if (response != null && response.statusCode == 200) {
        final List users = response.data;
        final fetched = users.map<Map<String, dynamic>>((teacher) {
          final photo = teacher["photo"];
          final image = (photo != null && photo.toString().startsWith("http"))
              ? photo
              : "assets/images/prof.png";
          final String firstName =
              teacher["FirstName"]?.toString().trim() ?? "";
          final String lastName = teacher["LastName"]?.toString().trim() ?? "";
          final String fullName = "$firstName $lastName".trim();
          return {
            "_id": teacher["_id"],
            "name": fullName.isNotEmpty
                ? fullName
                : AppLocalizations.of(context)?.teacherRole ?? "معلم",
            "image": image,
          };
        }).toList();
        if (mounted) setState(() => teachersList = fetched);
      }
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double expandedHeight = size.height * 0.36;
    final double collapsedContentHeight = size.height * 0.153;
    final double fixedToolbarHeight = topPadding + collapsedContentHeight;

    final expandedHeader = _buildExpandedHeader(expandedHeight);
    final collapsedHeader =
        _buildCollapsedHeader(topPadding, fixedToolbarHeight);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.sky(isDark)))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchHomeData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: expandedHeight,
                        pinned: true,
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        toolbarHeight: fixedToolbarHeight,
                        flexibleSpace: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _scrollController,
                            builder: (context, _) {
                              final double offset = _scrollController.hasClients
                                  ? _scrollController.offset
                                      .clamp(0.0, double.infinity)
                                  : 0.0;
                              final double p = ((offset - _collapseStart) /
                                      (_collapseEnd - _collapseStart))
                                  .clamp(0.0, 1.0);
                              final double ep = Curves.easeOut.transform(p);
                              final double expOp =
                                  (1.0 - (ep / 0.6)).clamp(0.0, 1.0);
                              final double colOp =
                                  ((ep - 0.5) / 0.5).clamp(0.0, 1.0);

                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  IgnorePointer(
                                    ignoring: expOp < 0.5,
                                    child: Opacity(
                                      opacity: expOp,
                                      child: FlexibleSpaceBar(
                                        collapseMode: CollapseMode.none,
                                        background: expandedHeader,
                                      ),
                                    ),
                                  ),
                                  IgnorePointer(
                                    ignoring: colOp < 0.5,
                                    child: Opacity(
                                      opacity: colOp,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: collapsedHeader,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, _) {
                            if (!AppConfig.showRankCard) {
                              return const SizedBox.shrink();
                            }
                            final double offset = _scrollController.hasClients
                                ? _scrollController.offset
                                    .clamp(0.0, double.infinity)
                                : 0.0;
                            final double p = ((offset - _collapseStart) /
                                    (_collapseEnd - _collapseStart))
                                .clamp(0.0, 1.0);
                            return SizedBox(height: (1.0 - p) * 75.0);
                          },
                        ),
                      ),
                      if (isOffline)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            child: _buildOfflineBanner(),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildHomeSections(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (AppConfig.showRankCard)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _scrollController,
                      builder: (context, child) {
                        final double offset = _scrollController.hasClients
                            ? _scrollController.offset
                                .clamp(0.0, double.infinity)
                            : 0.0;
                        final double p = ((offset - _collapseStart) /
                                (_collapseEnd - _collapseStart))
                            .clamp(0.0, 1.0);
                        final double ep = Curves.easeOut.transform(p);
                        final double opacity =
                            (1.0 - (ep / 0.6)).clamp(0.0, 1.0);

                        if (opacity <= 0) return const SizedBox.shrink();

                        return Transform.translate(
                          offset: Offset(0.0, expandedHeight - 44.0 - offset),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Opacity(
                                  opacity: opacity,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: RepaintBoundary(child: _buildRankCard()),
                    ),
                  ),
                _buildFloatingContactButtons(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DYNAMIC HOME SECTIONS BUILDER
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildHomeSections() {
    final List<Widget> sections = [];

    for (final section in AppConfig.homeSectionOrder) {
      final isVisible = AppConfig.homeSectionVisibility[section] ?? true;
      if (!isVisible) continue;

      Widget? widget;
      double bottomSpacing = 40.0;

      switch (section) {
        case HomeSection.teachers:
          widget = _buildTeachersSection();
          bottomSpacing = 20.0;
          break;
        case HomeSection.lastQuiz:
          if (_shouldShowLastQuiz()) {
            widget = !_quizCardDismissed
                ? _buildLastQuizCard()
                : _buildMotivationCard();
          }
          break;
        case HomeSection.reels:
          widget = _buildReelsSection();
          bottomSpacing = 15.0;
          break;
        case HomeSection.myCourses:
          widget = _buildMyCourses();
          break;
        case HomeSection.availableCourses:
          widget = _buildAvailableCourses();
          break;
        case HomeSection.categories:
          widget = _buildCategoriesSection();
          break;
      }

      if (widget != null) {
        if (widget is SizedBox && widget.height == 0 && widget.width == 0) {
          continue;
        }
        sections.add(widget);
        if (bottomSpacing > 0) {
          sections.add(SizedBox(height: bottomSpacing));
        }
      }
    }

    sections.add(const SizedBox(height: 135));
    return sections;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OFFLINE BANNER (redesigned — replaces the ugly SnackBar)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOfflineBanner() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bool expired = _offlineExpired;
    final Color accent =
        expired ? AppColors.redStatus(isDark) : AppColors.orangeStatus(isDark);
    final IconData icon =
        expired ? PhosphorIconsFill.wifiSlash : PhosphorIconsFill.cloudSlash;

    final String title = expired
        ? AppLocalizations.of(context)?.cannotLoadData ??
            "لا يمكن تحميل البيانات"
        : AppLocalizations.of(context)?.offlineMode ?? "وضع بدون إنترنت";
    final String subtitle = expired
        ? (_offlineEnabled
            ? AppLocalizations.of(context)?.savedDataExpiredConnect ??
                "انتهت صلاحية البيانات المحفوظة، يرجى الاتصال بالإنترنت"
            : AppLocalizations.of(context)?.connectToDownloadContent ??
                "يرجى الاتصال بالإنترنت لتحميل المحتوى")
        : AppLocalizations.of(context)
                ?.dataSavedDaysLeft((_offlineDaysLeft ?? 0).toString()) ??
            "البيانات محفوظة، تبقى ${_offlineDaysLeft ?? 0} يوم قبل انتهاء الصلاحية";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? accent.withOpacity(0.1) : accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _fetchHomeData,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(PhosphorIconsRegular.arrowClockwise,
                  color: accent, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _AppFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: _AppFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  EXPANDED HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildExpandedHeader(double totalHeight) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: AppColors.getBrandGradient(),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, right: 20, left: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context, createSlideRoute(const AccountPage())),
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.sky(isDark), width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.sky(isDark),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Image.asset(
                                    'assets/images/emojis/manStudent.gif',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.welcome,
                              style: _AppFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName.isEmpty ? "" : userName,
                              style: _AppFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: size.height * 0.0425,
                              width: size.width * 0.335,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildMedalItem(
                                        "assets/images/1st place medal.png",
                                        firstPlaceCount),
                                    const SizedBox(width: 9),
                                    _buildMedalItem(
                                        "assets/images/2nd place medal.png",
                                        secondPlaceCount),
                                    const SizedBox(width: 9),
                                    _buildMedalItem(
                                        "assets/images/3rd place medal.png",
                                        thirdPlaceCount),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 38,
                        width: 57,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIconsFill.fire,
                                color: AppColors.orangeStatus(isDark),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$streakCount',
                                style: _AppFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: const Center(
                          child: Icon(
                            PhosphorIconsRegular.bell,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: size.height * 0.07,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: _AppFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: Colors.white,
                    onChanged: (value) =>
                        setState(() => _searchQuery = _normalize(value)),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)
                              ?.searchSubjectCourseHint ??
                          "ابحث عن مادة او كورس",
                      hintStyle: _AppFonts.cairo(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                          PhosphorIconsRegular.magnifyingGlass,
                          color: Colors.white,
                          size: 24),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 24,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white70, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                    ),
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedalItem(String assetPath, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          assetPath,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: -2,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 13,
              minHeight: 13,
            ),
            child: Center(
              child: Text(
                '$count',
                style: _AppFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedHeader(double topPadding, double totalHeight) {
    final ThemeProvider provider = Provider.of<ThemeProvider>(context);
    final isDark = provider.isDarkMode;
    final rank = _rankInfo;
    final int goalPoints = rank["goalPoints"] as int;
    final String currentRank = rank["currentRank"] as String;
    final double progress =
        goalPoints > 0 ? (studentScore / goalPoints).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 29,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: AppColors.getBrandGradient(),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topPadding),
              Padding(
                padding: const EdgeInsets.only(
                    left: 28, right: 28, top: 8, bottom: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, createSlideRoute(const AccountPage())),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.sky(isDark), width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: AppColors.sky(isDark),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset(
                                'assets/images/emojis/manStudent.gif',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.right,
                            style: _AppFonts.cairo(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.white,
                            onChanged: (value) => setState(
                                () => _searchQuery = _normalize(value)),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)
                                      ?.searchSubjectCourseHint ??
                                  "ابحث عن مادة او كورس",
                              hintStyle: _AppFonts.cairo(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                  PhosphorIconsRegular.magnifyingGlass,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 20,
                              ),
                            ),
                            onSubmitted: _onSearchSubmitted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.getInputBackgroundColor(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getShadowColor(isDark),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentRank,
                          style: _AppFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/emojis/Star.gif',
                          width: 20,
                          height: 20,
                        ),
                        Image.asset(
                          'assets/images/emojis/Star.gif',
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.orangeStatus(isDark),
                                      AppColors.orangeStatus(isDark)
                                          .withOpacity(0.4),
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          "$goalPoints",
                          style: _AppFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        Text(
                          " / $studentScore",
                          style: _AppFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RANK CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRankCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;
    final rank = _rankInfo;
    final int goalPoints = rank["goalPoints"] as int;
    final String currentRank = rank["currentRank"] as String;
    final String nextRank = rank["nextRank"] as String;
    final double progress =
        goalPoints > 0 ? (studentScore / goalPoints).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadowColor(isDark),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/$currentRank.png',
                    width: 55,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            AppColors.orangeStatus(isDark).withOpacity(0.2),
                        child: const Text("🏆", style: TextStyle(fontSize: 24)),
                      );
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.currentRankTitle ??
                            "الرتبه الحالية",
                        style: _AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            currentRank,
                            style: _AppFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/emojis/Star.gif',
                            width: 20,
                            height: 20,
                          ),
                          Image.asset(
                            'assets/images/emojis/Star.gif',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)?.targetPrefix ?? "الهدف: ",
                        style: _AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                      Text(
                        nextRank,
                        style: _AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sky(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "$goalPoints",
                        style: _AppFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                      Text(
                        " / $studentScore",
                        style: _AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orangeStatus(isDark),
                          AppColors.orangeStatus(isDark).withOpacity(0.4),
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          if (AppConfig.showGlobalLeaderboardButton) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  createSlideRoute(const GlobalLeaderboardScreen()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sky(isDark).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/emojis/Star.gif',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)?.leaderboardMedals ??
                          "لوحة الأبطال والترتيب العالمي",
                      style: _AppFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      PhosphorIconsBold.caretRight,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SECTION HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count, {String? imageUrl}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: _AppFonts.cairo(
                color: AppColors.getTextColor(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (imageUrl != null) ...[
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getInputBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.getCardBorderColor(isDark)),
          ),
          child: Text(
            AppLocalizations.of(context)?.countVideosCourses(
                    count.toString(),
                    title.contains('مقاطع')
                        ? AppLocalizations.of(context)?.videosListLabel ??
                            "فيديوهات"
                        : 'كورسات'.toString()) ??
                "$count ${title.contains('مقاطع') ? AppLocalizations.of(context)?.videosListLabel ?? "فيديوهات" : 'كورسات'}",
            style: _AppFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextSecondaryColor(isDark),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LAST QUIZ CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLastQuizCard() {
    final quiz = _lastQuizResult!;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final int score = quiz["score"] as int;
    final int total = quiz["total"] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.getCardBorderColor(isDark),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orangeStatus(isDark)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.orangeStatus(isDark)
                                    .withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                          ?.youCanMakeUpForIt ??
                                      "تقدر تعوض",
                                  style: _AppFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.orangeStatus(isDark),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                CachedNetworkImage(
                                    height: 16,
                                    width: 16,
                                    imageUrl:
                                        'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Flexed%20Biceps.png'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            quiz["timeAgo"] ?? "",
                            style: _AppFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextSecondaryColor(isDark),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _quizCardDismissed = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz["title"] ?? "",
                            style: _AppFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "أ. ${quiz["teacherName"]}",
                            style: _AppFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.getTextSecondaryColor(isDark),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.getCircleBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.getCardBorderColor(isDark),
                            width: 1,
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "$score ",
                                style: _AppFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orangeStatus(isDark),
                                ),
                              ),
                              TextSpan(
                                text: "/ $total",
                                style: _AppFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.getTextSecondaryColor(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 41,
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sky(isDark).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final eId = quiz["examId"]?.toString() ?? "";
                                if (eId.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExamResultPage(
                                        examId: eId,
                                        title: quiz["title"] ?? "",
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExamsHistoryPage(),
                                    ),
                                  );
                                }
                              },
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!.reviewErrors,
                                  style: _AppFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 41,
                          decoration: BoxDecoration(
                            color: AppColors.sky(isDark).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.sky(isDark).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ExamsHistoryPage())),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.listDashes,
                                    size: 18,
                                    color: AppColors.sky(isDark),
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppLocalizations.of(context)!.gradesHistory,
                                    style: _AppFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.sky(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    final quiz = _lastQuizResult!;
    final int score = quiz["score"] as int;
    final int total = quiz["total"] as int;
    final double percentage = (score / total) * 100;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isEn = Localizations.localeOf(context).languageCode == 'en';

    String motivationText;
    if (percentage >= 80) {
      motivationText = isEn
          ? "Amazing work! Keep shining! 🌟"
          : AppLocalizations.of(context)?.amazingPerformance ??
              "أداء مذهل! استمر في التألق! 🌟";
    } else {
      motivationText = isEn
          ? "Every mistake is a lesson. You've got this! 💪"
          : AppLocalizations.of(context)?.everyMistakeIsLesson ??
              "كل خطأ هو درس جديد. أنت قادر على فعلها! 💪";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getCardBorderColor(isDark).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              motivationText,
              style: _AppFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => setState(() => _quizCardDismissed = false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.sky(isDark).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isEn
                  ? "View Result"
                  : AppLocalizations.of(context)?.viewResultBtn ??
                      "عرض النتيجة",
              style: _AppFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.sky(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CATEGORIES — ✅ FIX: 2-column grid
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategoriesSection() {
    final filteredCategories = rootCategories.where((category) {
      if (_selectedTeacherId == null) return true;
      return availableCourses.any((c) =>
          c["Teacher"] == _selectedTeacherId &&
          _normalize(c["title"] ?? "").contains(_normalize(category.name)));
    }).toList();

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1100
        ? 5
        : screenWidth >= 850
            ? 4
            : screenWidth >= 600
                ? 3
                : 2;
    final double aspectRatio = screenWidth >= 850 ? 1.35 : 1.25;

    return Column(
      children: [
        _buildSectionHeader(
            AppLocalizations.of(context)!.categories, filteredCategories.length,
            imageUrl:
                'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Fire.png'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredCategories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final category = filteredCategories[index];

            int displayPrice = category.price ?? 0;
            if (displayPrice == 0) {
              final matchingCourse = availableCourses.firstWhere(
                (c) => c["title"] == category.name,
                orElse: () => {},
              );
              if (matchingCourse.isNotEmpty) {
                displayPrice = matchingCourse["price"] ?? 0;
              }
            }

            return GestureDetector(
              onTap: () {
                final purchasedIds =
                    myCourses.map((c) => c["id"] as String).toSet();
                Navigator.push(
                  context,
                  createSlideRoute(CategoryScreen(
                    category: category,
                    breadcrumb: [],
                    purchasedCourseIds: purchasedIds,
                    purchasedCourses: myCourses,
                  )),
                );
              },
              child: _buildCategoryCard(
                category,
                AppLocalizations.of(context)!.priceWithCurrency(displayPrice),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: category.photo != null && category.photo!.isNotEmpty
              ? AspectRatio(
                  aspectRatio: 1.25,
                  child: Image.network(
                    category.photo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Icon(Icons.category,
                          size: 48, color: theme.iconTheme.color),
                    ),
                  ),
                )
              : AspectRatio(
                  aspectRatio: 1.25,
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Icon(Icons.category,
                        size: 48, color: theme.iconTheme.color),
                  ),
                ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            category.name,
            style: _AppFonts.cairo(
              color: AppColors.getTextColor(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      )
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  AVAILABLE COURSES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAvailableCourses() {
    final filteredCourses = availableCourses.where((course) {
      if (_selectedTeacherId != null && course["Teacher"] != _selectedTeacherId)
        return false;
      if (course["isPurchased"] == true) return false;
      return true;
    }).toList();

    if (filteredCourses.isEmpty) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      final isDark = themeProvider.isDarkMode;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              _buildSectionHeader(
                AppLocalizations.of(context)?.suggestedCourses ??
                    "الكورسات المقترحة",
                0,
                imageUrl:
                    'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png',
              ),
              const SizedBox(height: 44),
              Icon(PhosphorIconsRegular.magnifyingGlass,
                  size: 48, color: AppColors.getTextHintColor(isDark)),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? AppLocalizations.of(context)!.noCoursesAvailable
                    : AppLocalizations.of(context)?.noSearchResultsForQuery(
                            _searchQuery.toString()) ??
                        'لا توجد نتائج بحث مطابقة لـ "$_searchQuery"',
                style: _AppFonts.cairo(
                  color: AppColors.getTextHintColor(isDark),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedCourses = _groupCoursesBySubject(filteredCourses);
    final subjects = groupedCourses.keys.toList();
    final totalCount = filteredCourses.length;

    return _AvailableCoursesTabs(
      subjects: subjects,
      groupedCourses: groupedCourses,
      totalCount: totalCount,
      buildSectionHeader: _buildSectionHeader,
      buildCourseCard: _buildCourseCard,
      showPurchaseDialog: _showPurchaseDialog,
      teachersList: teachersList,
      userGroupName: userGroupName,
      myCourses: myCourses,
      availableCourses: availableCourses,
      normalize: _normalize,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MY COURSES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMyCourses() {
    final filtered = myCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          AppLocalizations.of(context)?.subscribedCourses ??
              "الكورسات المشترك بها",
          filtered.length,
          imageUrl:
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Star.png',
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 275,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final course = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailsPage(
                        title: course["title"],
                        image: course["image"],
                        isPurchased: true,
                        videoslist: course["videoslist"],
                        courseId: course["id"],
                        teacherName: course["teacher"],
                        subject: course["subject"],
                        userGroupName: userGroupName,
                      ),
                    ),
                  ),
                  child: _buildCourseCard(
                    course["image"],
                    course["title"],
                    course["teacher"] ?? "",
                    subjectTag: course["subject"],
                    isPurchased: true,
                    progress: course["progress"] ?? 0.0,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  COURSE CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCourseCard(
    String image,
    String title,
    String subtitle, {
    String? subjectTag,
    bool isPurchased = false,
    bool isHot = false,
    double? progress,
    VoidCallback? onSubscribe,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: image.startsWith("http")
                    ? CachedNetworkImage(
                        imageUrl: image,
                        height: 144,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 520,
                        memCacheHeight: 288,
                        errorWidget: (_, __, ___) => Image.asset(
                          "assets/images/Group 1.png",
                          height: 144,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        image.isNotEmpty ? image : "assets/images/Group 1.png",
                        height: 144,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/images/Group 1.png",
                          height: 144,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              if (subjectTag != null && subjectTag.isNotEmpty && !isPurchased)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.getInputBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subjectTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _AppFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: _AppFonts.cairo(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isPurchased) ...[
                  const SizedBox(height: 6),
                  Consumer<CompanySettingsProvider>(
                    builder: (context, provider, child) {
                      final teacherTitle = provider.teacherTitle ?? "";
                      final displayName = teacherTitle.isNotEmpty
                          ? "$teacherTitle $subtitle"
                          : subtitle;

                      return Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _AppFonts.cairo(
                          color: AppColors.getTextSecondaryColor(isDark),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
                if (isPurchased && progress != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.getCircleBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                color: AppColors.sky(isDark).withOpacity(0.15),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsFill.playCircle,
                                size: 22,
                                color: AppColors.sky(isDark),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)?.continueBtn ??
                                      "متابعة",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _AppFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sky(isDark),
                                  ),
                                ),
                              ),
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: _AppFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sky(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isPurchased) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: subtitle.split(' ').first,
                                style: _AppFonts.cairo(
                                  color: AppColors.getTextColor(isDark),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: subtitle.contains(' ')
                                    ? ' ${subtitle.split(' ').skip(1).join(' ')}'
                                    : '',
                                style: _AppFonts.cairo(
                                  color:
                                      AppColors.getTextSecondaryColor(isDark),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        height: 37,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: onSubscribe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.subscribeBtn ??
                                  "اشتراك",
                              style: _AppFonts.cairo(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  REELS SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReelsSection() {
    final size = MediaQuery.of(context).size;
    if (realsUrls.isEmpty) return const SizedBox.shrink();

    final bool isDesktop = size.width >= 600;
    final double reelCardWidth = isDesktop ? 170.0 : size.width * 0.45;
    final double reelsContainerHeight = isDesktop ? 280.0 : size.height * 0.35;

    return Column(
      children: [
        _buildSectionHeader(
          '${AppLocalizations.of(context)!.shortClips}',
          realsUrls.length,
          imageUrl:
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/High%20Voltage.png',
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: reelsContainerHeight,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: realsUrls.length,
              itemBuilder: (context, index) {
                final url = realsUrls[index];
                final videoId =
                    YoutubePlayerController.convertUrlToId(url) ?? "";
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ReelsPlayerPage(
                              reels: realsUrls, initialIndex: index))),
                  child: Container(
                    width: reelCardWidth,
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: ThemeHelper.getVideoPlayerBackgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://img.youtube.com/vi/$videoId/0.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(PhosphorIconsFill.play,
                                textDirection: TextDirection.ltr,
                                color: Colors.white,
                                size: 30),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Text(
                            "00:30",
                            style: _AppFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TEACHERS SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTeachersSection() {
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (teachersList.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size.height * 0.135,
          child: Center(
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: teachersList.length,
              itemBuilder: (context, index) {
                final teacher = teachersList[index];
                final isSelected = _selectedTeacherId == teacher["_id"];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedTeacherId == teacher["_id"]) {
                              _selectedTeacherId = null;
                            } else {
                              _selectedTeacherId = teacher["_id"];
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.getCircleBackgroundColor(isDark),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.sky(isDark)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.sky(isDark)
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: CachedNetworkImage(
                              imageUrl: teacher["image"]
                                      .toString()
                                      .startsWith("http")
                                  ? teacher["image"]
                                  : 'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Teacher.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Consumer<CompanySettingsProvider>(
                        builder: (context, provider, child) {
                          final title = provider.teacherTitle ?? '';
                          final displayName = title.isNotEmpty
                              ? '$title ${teacher["name"]}'
                              : teacher["name"];
                          return Text(
                            displayName,
                            style: _AppFonts.cairo(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.sky(isDark)
                                  : AppColors.getTextColor(isDark),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PURCHASE LOGIC — Fawaterak Online Payment & Code Activation
  // ─────────────────────────────────────────────────────────────────────────

  void _showFawryCodeDialog(String code, String courseTitle) {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.getInputBackgroundColor(isDark),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.2),
                  ),
                  child: const Center(
                    child: Icon(PhosphorIconsFill.receipt,
                        color: Colors.amber, size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.fawryPaymentCode,
                  style: _AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!
                      .fawryInstructionNote(courseTitle),
                  textAlign: TextAlign.center,
                  style: _AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.getCircleBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sky(isDark), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        code,
                        style: GoogleFonts.bioRhyme(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.sky(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.doneClose,
                      style: _AppFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPurchaseDialog(String courseId, String courseTitle) {
    final course = availableCourses.firstWhere(
      (c) => (c["id"] ?? c["_id"])?.toString() == courseId,
      orElse: () => {},
    );
    final bool isFree = course["freecourse"] == true;

    if (isFree) {
      _handleCoursePurchase(courseId, "", courseTitle);
      return;
    }

    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final companySettingsProvider =
        Provider.of<CompanySettingsProvider>(context, listen: false);
    final bool fawaterakEnabled =
        companySettingsProvider.settings?.fawaterakConfig.enabled ?? false;
    final String purchaseWhatsApp =
        (companySettingsProvider.settings?.purchaseWhatsAppNumber ?? '').trim();
    final bool hasWhatsAppPurchase = purchaseWhatsApp.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController codeController = TextEditingController();
        int selectedTab = fawaterakEnabled ? 0 : 1; // 0: Online, 1: Code
        bool isLoadingMethods = fawaterakEnabled;
        List<dynamic> paymentMethods = [];
        int? selectedMethodId;
        bool isInitiating = false;
        String? fetchError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void loadMethods() {
              if (!fawaterakEnabled) return;
              _apiService.getPaymentMethods().then((res) {
                if (res != null && res.statusCode == 200 && res.data != null) {
                  final methods = res.data["methods"] ?? [];
                  setDialogState(() {
                    paymentMethods = List.from(methods);
                    if (paymentMethods.isNotEmpty) {
                      selectedMethodId = paymentMethods[0]["paymentId"];
                    }
                    isLoadingMethods = false;
                  });
                } else {
                  setDialogState(() {
                    isLoadingMethods = false;
                    fetchError = AppLocalizations.of(context)!
                        .couldNotFetchPaymentMethods;
                  });
                }
              }).catchError((e) {
                setDialogState(() {
                  isLoadingMethods = false;
                  fetchError = e.toString();
                });
              });
            }

            if (fawaterakEnabled &&
                isLoadingMethods &&
                fetchError == null &&
                paymentMethods.isEmpty) {
              loadMethods();
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              backgroundColor: AppColors.getInputBackgroundColor(isDark),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBackgroundColor(isDark),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIconsRegular.x,
                              color: AppColors.getTextHintColor(isDark),
                              size: 16),
                        ),
                      ),
                    ),
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sky(isDark).withOpacity(0.2),
                        border: Border.all(
                          color: AppColors.sky(isDark).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/creditCard.png',
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.credit_card,
                            size: 36,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)?.activateCourse ??
                          "تفعيل وشراء الكورس",
                      style: _AppFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab selector ONLY if fawaterak is enabled
                    if (fawaterakEnabled) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.getCircleBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedTab = 0),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 0
                                        ? AppColors.sky(isDark)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                              ?.onlinePaymentFawaterak ??
                                          "دفع اونلاين",
                                      style: _AppFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: selectedTab == 0
                                            ? Colors.white
                                            : AppColors.getTextSecondaryColor(
                                                isDark),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedTab = 1),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 1
                                        ? AppColors.sky(isDark)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                              ?.activationCodeTab ??
                                          "كود تفعيل",
                                      style: _AppFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: selectedTab == 1
                                            ? Colors.white
                                            : AppColors.getTextSecondaryColor(
                                                isDark),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // TAB 0: ONLINE PAYMENT (FAWATERAK)
                    if (fawaterakEnabled && selectedTab == 0) ...[
                      if (isLoadingMethods)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (fetchError != null)
                        Text(fetchError!,
                            style: _AppFonts.cairo(
                                color: Colors.red, fontSize: 12))
                      else if (paymentMethods.isEmpty)
                        Text(
                          AppLocalizations.of(context)
                                  ?.noPaymentMethodsAvailable ??
                              "لا توجد طرق دفع متاحة حالياً",
                          style:
                              _AppFonts.cairo(color: Colors.red, fontSize: 12),
                        )
                      else ...[
                        Text(
                          AppLocalizations.of(context)?.selectPaymentMethod ??
                              "اختر طريقة الدفع المناسبة لك:",
                          style: _AppFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            child: Column(
                              children: paymentMethods.map((m) {
                                final pmId = m["paymentId"];
                                final isEn = Localizations.localeOf(context)
                                        .languageCode ==
                                    'en';
                                final pmName = (isEn
                                        ? m["name_en"] ?? m["name_ar"]
                                        : m["name_ar"] ?? m["name_en"]) ??
                                    (AppLocalizations.of(context)
                                            ?.paymentMethodFallback ??
                                        "طريقة دفع");
                                final pmLogo = m["logo"] ?? "";
                                final isSelected = selectedMethodId == pmId;

                                return GestureDetector(
                                  onTap: () => setDialogState(
                                      () => selectedMethodId = pmId),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.sky(isDark)
                                              .withOpacity(0.15)
                                          : AppColors.getCircleBackgroundColor(
                                              isDark),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.sky(isDark)
                                            : AppColors.getCardBorderColor(
                                                isDark),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (pmLogo
                                            .toString()
                                            .startsWith("http"))
                                          CachedNetworkImage(
                                            imageUrl: pmLogo.toString(),
                                            width: 32,
                                            height: 24,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                                    PhosphorIconsFill
                                                        .creditCard,
                                                    size: 20),
                                          )
                                        else
                                          const Icon(
                                              PhosphorIconsFill.creditCard,
                                              size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            pmName,
                                            style: _AppFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: AppColors.getTextColor(
                                                  isDark),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle,
                                              color: AppColors.sky(isDark),
                                              size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.getBrandGradient(),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isInitiating
                                ? null
                                : () async {
                                    setDialogState(() => isInitiating = true);
                                    try {
                                      final initRes = await _apiService
                                          .initiateCoursePayment(
                                        courseId: courseId,
                                        paymentMethodId: selectedMethodId,
                                      );
                                      setDialogState(
                                          () => isInitiating = false);

                                      if (initRes != null &&
                                          (initRes.statusCode == 200 ||
                                              initRes.statusCode == 201)) {
                                        final pData = initRes.data;
                                        final paymentUrl = pData["paymentUrl"];
                                        final fawryCode = pData["fawryCode"];

                                        Navigator.pop(context);

                                        if (paymentUrl != null &&
                                            paymentUrl.toString().isNotEmpty) {
                                          final uri =
                                              Uri.parse(paymentUrl.toString());
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  AppLocalizations.of(context)!
                                                      .paymentPageOpenedSnackBar,
                                                  style: GoogleFonts.cairo()),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        } else if (fawryCode != null &&
                                            fawryCode.toString().isNotEmpty) {
                                          _showFawryCodeDialog(
                                              fawryCode.toString(),
                                              courseTitle);
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                initRes?.data?["error"] ??
                                                    AppLocalizations.of(
                                                            context)!
                                                        .paymentInitiationFailed,
                                                style: GoogleFonts.cairo()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(
                                          () => isInitiating = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(e.toString(),
                                                style: GoogleFonts.cairo()),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                            child: isInitiating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    AppLocalizations.of(context)!
                                        .goToPaymentNow,
                                    style: _AppFonts.cairo(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ],

                    // TAB 1: ACTIVATION CODE
                    if (!fawaterakEnabled || selectedTab == 1) ...[
                      Text(
                        AppLocalizations.of(context)
                                ?.enterActivationCodeCourse ??
                            "أدخل كود التفعيل لفتح محتويات الكورس.",
                        style: _AppFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getCircleBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.getCardBorderColor(isDark),
                              width: 2),
                        ),
                        child: TextField(
                          controller: codeController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.getInputTextColor(isDark)),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "XXXX-XXXX-XXXX",
                            hintStyle: GoogleFonts.bioRhyme(
                              color: AppColors.getTextSecondaryColor(isDark),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.getBrandGradient(),
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final code = codeController.text.trim();
                            if (code.isEmpty) return;
                            Navigator.pop(context);
                            await _handleCoursePurchase(
                                courseId, code, courseTitle);
                          },
                          child: Text(
                            AppLocalizations.of(context)?.activateNow ??
                                AppLocalizations.of(context)?.activateNowBtn ??
                                "تفعيل الآن",
                            style: _AppFonts.cairo(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (hasWhatsAppPurchase) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final cleanNum = purchaseWhatsApp.replaceAll(
                                RegExp(r'[^0-9+]'), '');
                            final message = AppLocalizations.of(context)!
                                .whatsappPurchaseMessage(courseTitle);
                            final encodedMsg = Uri.encodeComponent(message);
                            final waUri = Uri.parse(
                                "https://wa.me/$cleanNum?text=$encodedMsg");
                            if (await canLaunchUrl(waUri)) {
                              await launchUrl(waUri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(PhosphorIconsFill.whatsappLogo,
                              color: Colors.white, size: 22),
                          label: Text(
                            AppLocalizations.of(context)!.buyViaWhatsapp,
                            style: _AppFonts.cairo(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCoursePurchase(
      String courseId, String code, String courseTitle) async {
    try {
      final response = await _apiService.request(
        "student/course/buycourse/$courseId",
        {"code": code},
        "POST",
      );
      final httpStatus = response?.statusCode ?? 0;
      final bodyStatus = response?.data?["status"];
      final success = (httpStatus >= 200 && httpStatus < 300) ||
          (bodyStatus != null && bodyStatus.toString() == "200");

      if (response != null && success) {
        _showSuccessDialog(courseTitle);
        await _fetchHomeData();
        return;
      }

      // Got a response but it wasn't success — wrong code
      if (response != null) {
        if (mounted) _showInvalidCodeDialog();
        return;
      }

      // No response at all (timeout/network) — verify then show network error
      await _verifyCoursePurchaseOrShowError(courseId, courseTitle);
    } catch (e) {
      debugPrint("⚠️ Course purchase error: $e");
      await _verifyCoursePurchaseOrShowError(courseId, courseTitle);
    }
  }

  Future<void> _verifyCoursePurchaseOrShowError(
      String courseId, String courseTitle) async {
    try {
      final check = await _apiService.request(
        "student/course/getpaidcourses",
        null,
        "GET",
      );
      if (check != null && check.statusCode == 200) {
        final List paid = check.data as List;
        final alreadyPurchased =
            paid.any((c) => c["_id"]?.toString() == courseId);
        if (alreadyPurchased) {
          _showSuccessDialog(courseTitle);
          await _fetchHomeData();
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Course purchase verification error: $e");
    }

    // ✅ FIX: distinguish between "wrong code" and "server timeout"
    if (mounted) {
      _showNetworkErrorDialog();
    }
  }

  void _showNetworkErrorDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.getInputBackgroundColor(isDark),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orangeStatus(isDark).withOpacity(0.15),
                  ),
                  child: Center(
                    child: Icon(PhosphorIconsFill.wifiSlash,
                        color: AppColors.orangeStatus(isDark), size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.cannotVerifyRequest ??
                      "تعذّر التحقق من الطلب",
                  style: _AppFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.serverConnectionTookLong ??
                      "الاتصال بالسيرفر استغرق وقتاً طويلاً. إذا تم خصم الكود فالكورس سيظهر في حساباتك — اسحب للأسفل لتحديث الصفحة.",
                  textAlign: TextAlign.center,
                  style: _AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 24),
                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _fetchHomeData();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.arrowClockwise,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.refreshPage ??
                              "تحديث الصفحة",
                          style: _AppFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Dismiss button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)?.closeDialog ?? "إغلاق",
                      style: _AppFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextSecondaryColor(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInvalidCodeDialog() {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.getInputBackgroundColor(isDark),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.getInputBackgroundColor(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIconsRegular.x,
                          color: AppColors.getTextSecondaryColor(isDark),
                          size: 16),
                    ),
                  ),
                ),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.redStatus(isDark).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Image.network(
                      "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Frowning%20Face.png",
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.invalidCode ??
                      "الكود غير صالح!",
                  style: _AppFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.redStatus(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.checkCodeTypo ??
                      "يرجى التأكد من كتابة الأرقام والحروف بشكل صحيح، أو أن الكود لم يتم استخدامه من قبل.",
                  textAlign: TextAlign.center,
                  style: _AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBorderColor(isDark),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(isDark),
                          width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.tryAgain ??
                              "حاول مرة اخرى",
                          style: _AppFonts.cairo(
                            color: AppColors.getTextColor(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(PhosphorIconsRegular.arrowClockwise,
                            color: AppColors.getTextColor(isDark), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.contactSupportToSolve ??
                      "تواصل مع الدعم الفني لحل المشكلة",
                  style: _AppFonts.cairo(
                    color: AppColors.sky(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String courseTitle) {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          backgroundColor: AppColors.getInputBackgroundColor(isDark),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 90),
                        painter: SunburstPainter(isDark: isDark),
                      );
                    },
                  ),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenStatus(isDark).withOpacity(0.1),
                        border: Border.all(
                            color:
                                AppColors.greenStatus(isDark).withOpacity(0.2),
                            width: isDark ? 1 : 4),
                      ),
                      child: Center(
                        child: Image.network(
                          "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Activities/Party%20Popper.png",
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)?.activatedSuccessfully ??
                    "تم التفعيل بنجاح",
                style: _AppFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenStatus(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'تم إضافة "$courseTitle" إلى محتواك بنجاح.',
                  textAlign: TextAlign.center,
                  style: _AppFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/home",
                        (r) => false,
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.greenStatus(isDark),
                            AppColors.greenStatus(isDark).withOpacity(0.85),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 28),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.goToCourseBtn ??
                                  "الذهاب للكورس",
                              style: _AppFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              PhosphorIconsFill.playCircle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class SunburstPainter extends CustomPainter {
  final bool isDark;
  SunburstPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.greenStatus(isDark)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = AppColors.greenStatus(isDark));

    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 1.5;

    for (int i = 0; i < 18; i++) {
      if (i % 2 == 0) continue;
      final startAngle = (i * 10) * 3.14159265359 / 180;
      final sweepAngle = 10 * 3.14159265359 / 180;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle - 3.14159265359,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AvailableCoursesTabs extends StatefulWidget {
  final List<String> subjects;
  final Map<String, List<Map<String, dynamic>>> groupedCourses;
  final int totalCount;
  final Widget Function(String, int, {String? imageUrl}) buildSectionHeader;
  final Widget Function(
    String image,
    String title,
    String subtitle, {
    String? subjectTag,
    bool isPurchased,
    bool isHot,
    double? progress,
    VoidCallback? onSubscribe,
  }) buildCourseCard;
  final void Function(String courseId, String courseTitle) showPurchaseDialog;
  final List<Map<String, dynamic>> teachersList;
  final String userGroupName;
  final List<Map<String, dynamic>> myCourses;
  final List<Map<String, dynamic>> availableCourses;
  final String Function(String) normalize;

  const _AvailableCoursesTabs({
    required this.subjects,
    required this.groupedCourses,
    required this.totalCount,
    required this.buildSectionHeader,
    required this.buildCourseCard,
    required this.showPurchaseDialog,
    required this.teachersList,
    required this.userGroupName,
    required this.myCourses,
    required this.availableCourses,
    required this.normalize,
  });

  @override
  State<_AvailableCoursesTabs> createState() => _AvailableCoursesTabsState();
}

class _AvailableCoursesTabsState extends State<_AvailableCoursesTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final selectedSubject = widget.subjects[_selectedIndex];
    final courses = widget.groupedCourses[selectedSubject] ?? [];
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.buildSectionHeader(
          AppLocalizations.of(context)?.suggestedCourses ?? "الكورسات المقترحة",
          widget.totalCount,
          imageUrl:
              'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.subjects.length,
            itemBuilder: (context, index) {
              final subject = widget.subjects[index];
              final isSelected = index == _selectedIndex;
              final count = widget.groupedCourses[subject]?.length ?? 0;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sky(isDark)
                        : AppColors.getInputBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.sky(isDark)
                          : AppColors.getCardBorderColor(isDark),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject,
                        style: _AppFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : AppColors.getCardBorderColor(isDark),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "$count",
                          style: _AppFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: (size.height * 0.27).clamp(260.0, 320.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: GestureDetector(
                  onTap: () {
                    final teacher = widget.teachersList.firstWhere(
                      (t) => t["_id"] == course["Teacher"],
                      orElse: () => {"name": ""},
                    );
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withOpacity(0.3),
                      builder: (context) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.66,
                          minChildSize: 0.4,
                          maxChildSize: 1.0,
                          expand: false,
                          builder: (context, scrollController) =>
                              CourseDetailsPage(
                            title: course["title"],
                            image: course["image"],
                            isPurchased: course["isPurchased"],
                            price: course["price"],
                            videoslist: course["videoslist"],
                            courseId: course["id"],
                            teacherName: teacher["name"],
                            subject: selectedSubject,
                            userGroupName: widget.userGroupName,
                            scrollController: scrollController,
                          ),
                        ),
                      ),
                    );
                  },
                  child: widget.buildCourseCard(
                    course["image"],
                    course["title"],
                    AppLocalizations.of(context)!
                        .priceWithCurrency(course["price"]),
                    subjectTag: selectedSubject,
                    isPurchased: course["isPurchased"],
                    isHot: index == courses.length - 1,
                    onSubscribe: () => widget.showPurchaseDialog(
                      course["id"],
                      course["title"],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
