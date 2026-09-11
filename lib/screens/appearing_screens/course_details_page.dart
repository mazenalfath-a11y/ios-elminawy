import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_version/screens/appearing_screens/pdf_editor_page.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/image_viewer_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'live_screen_insides/live_screen.dart';
import 'video_watch_page.dart';
import 'exampage_insides/exam_start_page.dart';
import 'exampage_insides/exercise_start_page.dart';
import 'exampage_insides/exam_result_page.dart';
import 'rank_tab_widget.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/youtube_video_player.dart';
import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_version/data/offline_data_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'course_chat_tab.dart';

class CourseDetailsPage extends StatefulWidget {
  final String title;
  final String image;
  final bool isPurchased;
  final dynamic videoslist;
  final int? price;
  final String courseId;
  final String? teacherName;
  final String? subject;
  final String? userGroupName;
  final ScrollController? scrollController;
  final bool useSections; // NEW: flag to enable section grouping
  final bool freecourse; // NEW: true = no code required, subscribe directly

  const CourseDetailsPage({
    super.key,
    required this.title,
    required this.image,
    required this.isPurchased,
    required this.videoslist,
    this.price,
    required this.courseId,
    this.teacherName,
    this.subject,
    this.userGroupName,
    this.scrollController,
    this.useSections = true,
    this.freecourse = false,
  });

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final ApiService _apiService = ApiService();

  int _selectedTabIndex = 0;
  List<String> get visibleTabs {
    if (!widget.isPurchased) return [AppLocalizations.of(context)!.lessons];
    return [
      AppLocalizations.of(context)!.lessons,
      AppLocalizations.of(context)!.files,
      AppLocalizations.of(context)!.exams,
      AppLocalizations.of(context)!.live,
      AppLocalizations.of(context)!.rank,
    ];
  }

  List<Map<String, dynamic>> lessons = [];
  bool _isLoadingExams = true;
  List<Map<String, dynamic>> ongoingExams = [];
  List<Map<String, dynamic>> notStartedExams = [];
  List<Map<String, dynamic>> endedExams = [];
  List<Map<String, dynamic>> pdfs = [];
  List<Map<String, dynamic>> imagesGroups = [];
  List<String> exerciseArr = [];
  List<String> listenedVideos = [];
  String? liveData;
  bool _isLoadingLive = false;

  bool isLoadingRank = false;
  String? rankError;
  int? myRank;
  List<Map<String, dynamic>> top10 = [];

  final Set<String> _collapsedSections = {};

  String? _currentStudentId;

  @override
  void initState() {
    super.initState();

    if (widget.isPurchased && widget.courseId != '') {
      _fetchCompletedExercises().then((_) {
        _fetchListenedVideos().then((_) {
          _rebuildLessonsWithListenedFlag();
          _fetchAllApis();
        });
      });
    } else if (!widget.isPurchased && widget.courseId != '') {
      // Build initial lessons (unpurchased) – include section info
      lessons = List<Map<String, dynamic>>.from(widget.videoslist.map((video) {
        return {
          "title": video["description"] ?? "",
          "videoUrl": video["videoURL"] ?? "",
          "type": video["type"] ?? "",
          "id": video["id"] ?? "",
          "exerciseId": "",
          "additionalVideos": video["additionalVideos"] ?? [],
          "files": video["files"] ?? [],
          "isLockedByExercise": false,
          "isDone": false,
          "sectionName": video["sectionName"] ?? "",
          "sectionOrder": video["sectionOrder"] ?? 0,
        };
      }));
    }
  }

  // ─── Fetch listened videos ────────────────────────────────────────────────

  Future<void> _fetchListenedVideos() async {
    try {
      final response = await _apiService.request(
        "student/listened_videos",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey("videos")) {
          final rawList = data["videos"];
          setState(() {
            listenedVideos = List<String>.from(
              (rawList as List).map((e) =>
                  (e is Map ? (e["_id"] ?? e["id"] ?? e.toString()) : e)
                      .toString()),
            );
          });
        } else if (data is List) {
          setState(() {
            listenedVideos = List<String>.from(
              data.map((e) =>
                  (e is Map ? (e["_id"] ?? e["id"] ?? e.toString()) : e)
                      .toString()),
            );
          });
        }
      } else {
        listenedVideos = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching listened videos: $e");
      listenedVideos = [];
    }
  }

  void _rebuildLessonsWithListenedFlag() {
    final rawLessons =
        List<Map<String, dynamic>>.from(widget.videoslist.map((video) {
      final videoId = video["id"]?.toString() ?? "";
      final exerciseId = video["exercise_id"]?.toString() ?? "";
      final currentSection = video["sectionName"]?.toString() ?? "";

      final exerciseDone =
          exerciseId.isNotEmpty && exerciseArr.contains(exerciseId);
      final videoWatched = listenedVideos.contains(videoId);
      final isDone = exerciseDone || videoWatched;

      return {
        "title": video["description"] ?? "",
        "videoUrl": video["videoURL"] ?? "",
        "type": video["type"] ?? "",
        "id": videoId,
        "exerciseId": exerciseId,
        "files": video["files"] ?? [],
        "additionalVideos": video["additionalVideos"] ?? [],
        "bubbleMessage": (video["bubbleMessage"] ?? "").toString(),
        "bubbleInterval":
            int.tryParse((video["bubbleInterval"] ?? 0).toString()) ?? 0,
        "isDone": isDone,
        "exerciseDone": exerciseDone,
        "sectionName": currentSection,
        "sectionOrder": video["sectionOrder"] ?? 0,
        "inVideoQuestions": video["inVideoQuestions"] ?? [],
        "isLockedByExercise": false,
      };
    }));

    // Group lessons by section to apply locking independently per section
    final Map<String, List<Map<String, dynamic>>> sectionGroups = {};
    for (var lesson in rawLessons) {
      final sec = lesson["sectionName"] as String;
      sectionGroups.putIfAbsent(sec, () => []).add(lesson);
    }

    // Process each section independently
    for (var secList in sectionGroups.values) {
      bool lockNext = false;
      for (var lesson in secList) {
        if (lockNext) {
          lesson["isLockedByExercise"] = true;
        } else {
          lesson["isLockedByExercise"] = false;
        }

        final exerciseId = lesson["exerciseId"] as String;
        final exerciseDone = lesson["exerciseDone"] as bool;
        final bool shouldLockNext = exerciseId.isNotEmpty && !exerciseDone;

        if (shouldLockNext) {
          lockNext = true;
        }
      }
    }

    setState(() => lessons = rawLessons);
  }

  // ─── APIs ─────────────────────────────────────────────────────────────────

  Future<void> _fetchCompletedExercises() async {
    try {
      final response =
          await _apiService.request("student/getuser", null, "GET");
      if (response != null && response.statusCode == 200) {
        setState(() {
          _currentStudentId = response.data["_id"]?.toString();
        });
        final exercises = List<Map<String, dynamic>>.from(
            response.data["exercises_done"] ?? []);
        exerciseArr =
            exercises.map((e) => e["exercise_id"].toString()).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching completed exercises: $e");
    }
  }

  Future<void> _fetchLive() async {
    setState(() => _isLoadingLive = true);
    try {
      final response = await _apiService.request(
        "student/course/get_live_link/${widget.courseId}",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        setState(() => liveData = response.data?.toString());
      } else {
        setState(() => liveData = null);
      }
    } catch (e) {
      setState(() => liveData = null);
    }
    setState(() => _isLoadingLive = false);
  }

  Future<void> _fetchAllApis() async {
    await Future.wait([
      _fetchPdfs(),
      _fetchExams(),
      _fetchImages(),
      _fetchLive(),
      _fetchRank(),
    ]);
  }

  Future<void> _handleCoursePurchase(String code) async {
    try {
      debugPrint("🛒 [COURSE PURCHASE] Starting purchase...");
      debugPrint("🛒 [COURSE PURCHASE] courseId: ${widget.courseId}");
      debugPrint("🛒 [COURSE PURCHASE] code: $code");

      final response = await _apiService.request(
        "student/course/buycourse/${widget.courseId}",
        {"code": code},
        "POST",
      );

      debugPrint(
          "🛒 [COURSE PURCHASE] response statusCode: ${response?.statusCode}");
      debugPrint("🛒 [COURSE PURCHASE] response data: ${response?.data}");

      final httpStatus = response?.statusCode ?? 0;
      final bodyStatus = response?.data?["status"];
      debugPrint("🛒 [COURSE PURCHASE] httpStatus: $httpStatus");
      debugPrint("🛒 [COURSE PURCHASE] bodyStatus: $bodyStatus");

      final success = (httpStatus >= 200 && httpStatus < 300) ||
          (bodyStatus != null && bodyStatus.toString() == "200");
      debugPrint("🛒 [COURSE PURCHASE] success: $success");

      if (!mounted) return;
      if (response != null && success) {
        debugPrint("✅ [COURSE PURCHASE] Purchase confirmed — showing success");
        _showSuccessDialog(isVideoPurchase: false);
        return;
      }
      debugPrint(
          "❌ [COURSE PURCHASE] Purchase failed — verifying with server...");
      await _verifyCoursePurchaseOrShowError();
    } catch (e) {
      debugPrint("💥 [COURSE PURCHASE] Exception thrown: $e");
      await _verifyCoursePurchaseOrShowError();
    }
  }

  Future<void> _verifyCoursePurchaseOrShowError() async {
    try {
      final check = await _apiService.request(
        "student/course/getpaidcourses",
        null,
        "GET",
      );
      if (check != null && check.statusCode == 200) {
        final List paid = check.data as List;
        final alreadyPurchased =
            paid.any((c) => c["_id"]?.toString() == widget.courseId);
        if (alreadyPurchased) {
          if (mounted) _showSuccessDialog(isVideoPurchase: false);
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Course purchase verification error: $e");
    }
    if (mounted) {
      _showInvalidCodeDialog();
    }
  }

  Future<void> _handleVideoPurchase(String code, String videoID) async {
    try {
      debugPrint("🛒 [VIDEO PURCHASE] Starting purchase...");
      debugPrint("🛒 [VIDEO PURCHASE] videoID: $videoID");
      debugPrint("🛒 [VIDEO PURCHASE] code: $code");

      final response = await _apiService.request(
        "student/video/buyvideo/$videoID",
        {"code": code},
        "POST",
      );

      debugPrint(
          "🛒 [VIDEO PURCHASE] response statusCode: ${response?.statusCode}");
      debugPrint("🛒 [VIDEO PURCHASE] response data: ${response?.data}");

      final httpStatus = response?.statusCode ?? 0;

      if (response != null && httpStatus >= 200 && httpStatus < 300) {
        Navigator.pop(context);
        _showSuccessDialog(isVideoPurchase: true);
        await _fetchCompletedExercises();
        await _fetchListenedVideos();
        _rebuildLessonsWithListenedFlag();
        return;
      }
      debugPrint("❌ [VIDEO PURCHASE] Purchase failed — showing error");
      _showErrorSnackBar(AppLocalizations.of(context)!.purchaseFailed);
    } catch (e) {
      debugPrint("💥 [VIDEO PURCHASE] Exception thrown: $e");
      _showErrorSnackBar(AppLocalizations.of(context)!.errorOccurred(""));
    }
  }

  // ─── فتح امتحان مرتبط بدرس نوعه "exam" مباشرة ────────────────────────────
  Future<void> goToExerciseById(String exerciseId) async {
    try {
      final res = await _apiService.request(
        "student/exam/get_exercise_in_video/$exerciseId",
        null,
        "GET",
      );
      if (res != null && res.statusCode == 200 && mounted) {
        final exam = res.data;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              // duration من الـ API (بالدقائق) — fallback: 120 دقيقة أو عدد الأسئلة × 5 دقائق (أيهما أكبر)
              final questions =
                  List<Map<String, dynamic>>.from(exam["Questions"] ?? []);
              final int apiDuration = (exam["duration"] ?? 0) is int
                  ? (exam["duration"] ?? 0)
                  : int.tryParse(exam["duration"]?.toString() ?? "0") ?? 0;
              final int calculatedFallback =
                  (questions.length * 5).clamp(60, 300);
              final int finalDuration = apiDuration > 0
                  ? apiDuration
                  : (calculatedFallback > 120 ? calculatedFallback : 120);

              return ExerciseStartPage(
                examId: exam["_id"],
                courseId: widget.courseId,
                title: exam["title"] ?? "",
                questions: questions,
                duration: finalDuration,
              );
            },
          ),
        ).then((_) {
          _fetchCompletedExercises()
              .then((_) => _fetchListenedVideos())
              .then((_) => _rebuildLessonsWithListenedFlag());
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)?.examNotAvailableNow ??
                      AppLocalizations.of(context)?.examNotAvailable ??
                      "الامتحان غير متاح حالياً",
                  style: GoogleFonts.cairo(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading exam: $e");
    }
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoadingExams = true);
    try {
      final response = await _apiService.request(
        "student/exam/get_exam_student/${widget.courseId}",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        ongoingExams =
            List<Map<String, dynamic>>.from(response.data["examsOngoing"]);
        notStartedExams =
            List<Map<String, dynamic>>.from(response.data["examsNotStarted"]);
        endedExams =
            List<Map<String, dynamic>>.from(response.data["examsEnded"]);
      }
    } catch (e) {
      debugPrint("❌ Error fetching exams: $e");
    }
    setState(() => _isLoadingExams = false);
  }

  Future<void> _fetchRank() async {
    setState(() {
      isLoadingRank = true;
      rankError = null;
    });
    try {
      final response = await _apiService.request(
        "student/exam/get_ranks_for_course/${widget.courseId}",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        myRank = data["myRank"];
        top10 = List<Map<String, dynamic>>.from(data["top10"] ?? []);
      } else {
        rankError = AppLocalizations.of(context)!.failedToFetchRank;
      }
    } catch (e) {
      rankError = AppLocalizations.of(context)!.failedToFetchRank;
    }
    setState(() => isLoadingRank = false);
  }

  Future<Map<String, dynamic>?> _startExam(String examId) async {
    try {
      final response = await _apiService.request(
        "student/exam/get_quiz_now_for_student/$examId",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Error starting exam: $e");
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
    ));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.getModalSheetColor(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildNotchHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.only(right: 20, left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoHeader(),
                        const SizedBox(height: 16),
                        _buildCourseInfo(theme),
                        const SizedBox(height: 4),
                        _buildStatsRow(isDark),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.courseContent,
                                style: GoogleFonts.cairo(
                                  color: AppColors.getTextColor(isDark),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 1,
                                width:
                                    MediaQuery.of(context).size.width * 0.285,
                                decoration: BoxDecoration(
                                  color: AppColors.getTextColor(isDark),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTabs(),
                        const SizedBox(height: 16),
                        _buildTabContent(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(isDark),
            ),
            if (widget.isPurchased)
              Positioned(
                bottom: 100,
                left: 20,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showCourseChatModal(context, isDark),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsFill.chatsCircle,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.courseChat ??
                                "شات الكورس",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildNotchHandle() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: isDark ? const Color(0XFF45556C) : const Color(0XFFCAD5E2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xff1D293D)
                      : const Color(0xffF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: AppColors.getTextColor(isDark),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _buildStatBadge(
            AppLocalizations.of(context)
                    ?.lessonsCount(lessons.length.toString()) ??
                "${lessons.length} درس",
            PhosphorIconsFill.videoCamera,
            isDark,
            const Color(0XFF2B7FFF)),
        const SizedBox(width: 10),
        _buildStatBadge(
            AppLocalizations.of(context)?.filesCount(pdfs.length.toString()) ??
                "${pdfs.length} ملفات",
            PhosphorIconsFill.filePdf,
            isDark,
            const Color(0XFFFB2C36)),
      ],
    );
  }

  Widget _buildStatBadge(
      String label, IconData icon, bool isDark, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1D293D) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? const Color(0xff314158) : const Color(0XFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18, color: iconColor, textDirection: TextDirection.ltr),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0XFFCAD5E2) : const Color(0XFF45556C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    if (widget.isPurchased) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xff2B7FFF).withOpacity(0.1)
                : const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? const Color(0xff2B7FFF).withOpacity(0.2)
                    : const Color(0xFF3B82F6).withOpacity(0.1)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              int firstUncompleted =
                  lessons.indexWhere((l) => !(l["isDone"] ?? false));
              if (firstUncompleted != -1) {
                final lesson = lessons[firstUncompleted];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoWatchPage(
                      videoTitle: lesson["title"],
                      videoUrl: lesson["videoUrl"],
                      v_id: lesson["id"],
                      exerciseId: lesson["exerciseId"] ?? "",
                      files: lesson["files"],
                      additionalVideos: lesson["additionalVideos"] ?? [],
                      courseId: widget.courseId,
                      exerciseArr: exerciseArr,
                      userGroupName: widget.userGroupName,
                      bubbleMessage: lesson["bubbleMessage"],
                      bubbleInterval: lesson["bubbleInterval"],
                    ),
                  ),
                ).then((_) {
                  _fetchCompletedExercises().then((_) {
                    _fetchListenedVideos()
                        .then((_) => _rebuildLessonsWithListenedFlag());
                  });
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsFill.playCircle,
                    color: Color(0xFF3B82F6),
                    size: 24,
                    textDirection: TextDirection.ltr),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.nextLesson ?? "الدرس التالي",
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF3B82F6),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)
                        ?.priceEgp((widget.price ?? 0).toString()) ??
                    "${widget.price ?? 0} ج.م",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                AppLocalizations.of(context)?.totalPrice ?? "السعر الإجمالي",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sky(isDark).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _showPurchaseDialog,
              child: Text(
                AppLocalizations.of(context)?.subscribeNow ?? "اشترك الآن",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildLessonsTab();
      case 1:
        return widget.isPurchased ? _buildFilesTab() : const SizedBox();
      case 2:
        return widget.isPurchased ? _buildExamsTab() : const SizedBox();
      case 3:
        return widget.isPurchased ? _buildLiveTab() : const SizedBox();
      case 4:
        return widget.isPurchased
            ? _buildRankTab(widget.courseId)
            : const SizedBox();
      default:
        return const SizedBox();
    }
  }

  // ─── UPDATED: Lessons tab with optional section grouping ────────────────

  Widget _buildLessonsTab() {
    if (lessons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Find the first uncompleted lesson (used for "current" indicator)
    int currentLessonIndex = -1;
    if (widget.isPurchased) {
      for (int i = 0; i < lessons.length; i++) {
        if (!(lessons[i]["isDone"] ?? false)) {
          currentLessonIndex = i;
          break;
        }
      }
    }

    // If sections are used, group lessons by sectionName
    if (widget.useSections) {
      // Group by sectionName (preserve order by sectionOrder)
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final List<String> sectionOrder = [];

      for (var lesson in lessons) {
        final section = lesson["sectionName"]?.toString() ?? '';
        if (!grouped.containsKey(section)) {
          grouped[section] = [];
          sectionOrder.add(section);
        }
        grouped[section]!.add(lesson);
      }

      // Sort sections by the first lesson's sectionOrder (or by the order they appear)
      // We'll use the sectionOrder from the first video in each section.
      // We'll sort the sectionOrder keys by the minimum sectionOrder in that group.
      final Map<String, int> sectionMinOrder = {};
      grouped.forEach((section, list) {
        int minOrder = list.fold<int>(
            999999,
            (prev, e) => (e["sectionOrder"] ?? 0) < prev
                ? (e["sectionOrder"] ?? 0)
                : prev);
        sectionMinOrder[section] = minOrder;
      });
      sectionOrder
          .sort((a, b) => sectionMinOrder[a]!.compareTo(sectionMinOrder[b]!));

      // Build column with section accordion headers and lesson cards
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionOrder.map((section) {
          final lessonList = grouped[section]!;
          final isCollapsed = _collapsedSections.contains(section);
          final completedCount =
              lessonList.where((l) => l["isDone"] == true).length;
          final totalCount = lessonList.length;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_collapsedSections.contains(section)) {
                        _collapsedSections.remove(section);
                      } else {
                        _collapsedSections.add(section);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff1D293D)
                          : const Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xff314158)
                            : const Color(0xffE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsFill.folderSimple,
                                size: 20,
                                color: AppColors.sky(isDark),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  section,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextColor(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isCollapsed
                              ? PhosphorIconsFill.caretDown
                              : PhosphorIconsFill.caretUp,
                          size: 18,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (!isCollapsed)
                ...lessonList.asMap().entries.map((entry) {
                  final lesson = entry.value;
                  final isFree =
                      (lesson["type"] ?? "").toString().toLowerCase() == "free";
                  final isDone = lesson["isDone"] ?? false;
                  final isCurrent = widget.isPurchased &&
                      lessons.indexOf(lesson) == currentLessonIndex;

                  return _buildLessonCard(
                    lesson["title"],
                    lesson["videoUrl"],
                    lesson["id"],
                    lesson["exerciseId"] ?? "",
                    lesson["files"],
                    lesson["additionalVideos"] ?? [],
                    widget.courseId,
                    isFree: isFree,
                    isLockedByExercise: lesson["isLockedByExercise"] ?? false,
                    index:
                        lessons.indexOf(lesson), // overall index for numbering
                    isDone: isDone,
                    isCurrent: isCurrent,
                    bubbleMessage: lesson["bubbleMessage"],
                    bubbleInterval: lesson["bubbleInterval"],
                    inVideoQuestions: lesson["inVideoQuestions"],
                  );
                }).toList(),
            ],
          );
        }).toList(),
      );
    } else {
      // Original flat list
      return Column(
        children: lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final isFree =
              (lesson["type"] ?? "").toString().toLowerCase() == "free";
          final isDone = lesson["isDone"] ?? false;
          final isCurrent = widget.isPurchased && index == currentLessonIndex;

          return _buildLessonCard(
            lesson["title"],
            lesson["videoUrl"],
            lesson["id"],
            lesson["exerciseId"] ?? "",
            lesson["files"],
            lesson["additionalVideos"] ?? [],
            widget.courseId,
            isFree: isFree,
            isLockedByExercise: lesson["isLockedByExercise"] ?? false,
            index: index,
            isDone: isDone,
            isCurrent: isCurrent,
            bubbleMessage: lesson["bubbleMessage"],
            bubbleInterval: lesson["bubbleInterval"],
            inVideoQuestions: lesson["inVideoQuestions"],
          );
        }).toList(),
      );
    }
  }

  // ─── Lesson card (unchanged) ─────────────────────────────────────────────

  Widget _buildLessonCard(
    String title,
    String videoUrl,
    id,
    exerciseId,
    files,
    additionalVideos,
    courseId, {
    required bool isFree,
    required bool isLockedByExercise,
    int index = 0,
    bool isDone = false,
    bool isCurrent = false,
    String? bubbleMessage,
    int? bubbleInterval,
    List<dynamic>? inVideoQuestions,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isLockedByPurchase = !widget.isPurchased && !isFree;
    final isLocked = isLockedByPurchase || isLockedByExercise;

    return GestureDetector(
      onTap: () {
        if (isLockedByPurchase) {
          _showPurchaseVideoDialog(id);
        } else if (isLockedByExercise) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor: AppColors.getInputBackgroundColor(isDark),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF6900).withOpacity(0.12),
                      ),
                      child: const Center(
                        child: Icon(PhosphorIconsFill.lock,
                            color: Color(0xFFFF6900),
                            size: 32,
                            textDirection: TextDirection.ltr),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.lessonLocked ??
                          "الدرس مقفل",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)
                              ?.mustSolvePreviousVideoExam ??
                          "عليك حل اختبار الفيديو السابق لتستطيع المشاهدة",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextSecondaryColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6900),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)?.okBtn ?? "حسناً",
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // ─── exam entry: open the exam directly ───────────────────────
          if (videoUrl == "exam" &&
              exerciseId != null &&
              exerciseId.isNotEmpty) {
            goToExerciseById(exerciseId);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoWatchPage(
                  videoTitle: title,
                  videoUrl: videoUrl,
                  v_id: id,
                  exerciseId: exerciseId,
                  files: files,
                  additionalVideos: additionalVideos ?? [],
                  courseId: courseId,
                  exerciseArr: exerciseArr,
                  teacherName: widget.teacherName,
                  bubbleMessage: bubbleMessage,
                  bubbleInterval: bubbleInterval,
                  inVideoQuestions: inVideoQuestions,
                ),
              ),
            ).then((_) {
              _fetchCompletedExercises().then((_) {
                _fetchListenedVideos()
                    .then((_) => _rebuildLessonsWithListenedFlag());
              });
            });
          }
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF3B82F6).withOpacity(0.3)
                : AppColors.getCardBorderColor(isDark),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (isCurrent)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF00C875).withOpacity(0.15)
                            : isCurrent
                                ? const Color(0xFF3B82F6)
                                : isLocked
                                    ? Colors.grey.withOpacity(0.15)
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(PhosphorIconsRegular.check,
                                textDirection: TextDirection.ltr,
                                color: Color(0xFF00C875),
                                size: 24)
                            : isCurrent
                                ? const Icon(PhosphorIconsFill.play,
                                    color: Colors.white,
                                    size: 22,
                                    textDirection: TextDirection.ltr)
                                : isLocked
                                    ? Icon(
                                        isLockedByPurchase
                                            ? PhosphorIconsFill.lockKey
                                            : PhosphorIconsFill.lock,
                                        color: Colors.grey,
                                        size: 20,
                                        textDirection: TextDirection.ltr,
                                      )
                                    : Text(
                                        "${index + 1}",
                                        style: GoogleFonts.cairo(
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: AppColors.getTextColor(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            isDone
                                ? AppLocalizations.of(context)
                                        ?.completedStatus ??
                                    "مكتمل"
                                : isLockedByPurchase
                                    ? AppLocalizations.of(context)?.buyVideo ??
                                        "اشترِ الفيديو"
                                    : isLockedByExercise
                                        ? AppLocalizations.of(context)
                                                ?.solveExamFirst ??
                                            "حل الاختبار أولاً"
                                        : isFree
                                            ? AppLocalizations.of(context)
                                                    ?.freeWatch ??
                                                "مجاني • مشاهدة"
                                            : AppLocalizations.of(context)
                                                    ?.video45Mins ??
                                                "فيديو • 45 دقيقة",
                            style: GoogleFonts.cairo(
                              color: isDone
                                  ? const Color(0xFF00C875)
                                  : isLockedByExercise || isLockedByPurchase
                                      ? Colors.grey
                                      : AppColors.getTextSecondaryColor(isDark),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isFree && !widget.isPurchased)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C875).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.freeBadge ?? "مجاني",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00C875),
                          ),
                        ),
                      )
                    else if (isLockedByPurchase)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sky(isDark).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.purchaseBtn ?? "شراء",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sky(isDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(
    Map<String, dynamic> exam,
    String buttonText,
    VoidCallback? onPressed, {
    String? subtitle,
  }) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0XFFFF6900).withOpacity(0.1)
                    : const Color(0XFFFFF7ED),
                border: Border.all(
                    color: isDark
                        ? const Color(0XFFFF6900).withOpacity(0.2)
                        : const Color(0XFFFFEDD4),
                    width: 1),
              ),
              child: const Center(
                child: Icon(PhosphorIconsFill.exam,
                    textDirection: TextDirection.ltr,
                    size: 22,
                    color: Color(0XFFFF6900)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              exam["title"] ?? AppLocalizations.of(context)!.exams,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: AppColors.getTextColor(isDark),
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.cairo(
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontSize: 10,
                ),
                textAlign: TextAlign.right,
              )
            : null,
        trailing: buttonText.isNotEmpty
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: onPressed != null
                      ? theme.colorScheme.secondary
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: GoogleFonts.cairo(
                    color: AppColors.getButtonTextColor(
                        theme.brightness == Brightness.dark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0XFF0F172B).withOpacity(0.5)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                          isDark ? const Color(0XFF314158) : Colors.transparent,
                      width: 1),
                ),
                child: Icon(PhosphorIconsRegular.caretLeft,
                    textDirection: TextDirection.ltr,
                    color: isDark
                        ? const Color(0XFF62748E)
                        : const Color(0XFF45556C)),
              ),
        onTap: onPressed,
      ),
    );
  }

  Widget _buildExamsTab() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    if (_isLoadingExams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ongoingExams.isEmpty && notStartedExams.isEmpty && endedExams.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noExamsAvailable,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextSecondaryColor(isDark),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ongoingExams.isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.ongoingExamsLabel,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 10),
          ...ongoingExams
              .map((exam) => _buildExamCard(
                    exam,
                    AppLocalizations.of(context)!.start,
                    () async {
                      final data = await _startExam(exam["_id"]);
                      if (data != null) {
                        final endTime = DateTime.parse(data["end"]);
                        final duration =
                            endTime.difference(DateTime.now()).inMinutes;
                        if (duration < 0) {
                          _showErrorSnackBar(
                              AppLocalizations.of(context)!.examEnded);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamStartPage(
                              examId: exam["_id"],
                              courseId: widget.courseId,
                              title: exam["title"],
                              questions: List<Map<String, dynamic>>.from(
                                  data["Questions"]),
                              endTime: data["end"],
                              duration: duration,
                            ),
                          ),
                        );
                      } else {
                        _showErrorSnackBar(
                            AppLocalizations.of(context)!.cannotStartExam);
                      }
                    },
                  ))
              .toList(),
        ],
        if (notStartedExams.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.upcomingExamsLabel,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 10),
          ...notStartedExams
              .map((exam) => _buildExamCard(
                    exam,
                    AppLocalizations.of(context)!.soon,
                    null,
                    subtitle: AppLocalizations.of(context)
                            ?.startsInExam(exam["start"].toString()) ??
                        "تبدأ في: ${exam["start"]}",
                  ))
              .toList(),
        ],
        if (endedExams.isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.endedExamsLabel,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 10),
          ...endedExams
              .map((exam) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamResultPage(
                          examId: exam["_id"],
                          title: exam["title"],
                        ),
                      ),
                    ),
                    child: _buildExamCard(exam, "", null),
                  ))
              .toList(),
        ],
      ],
    );
  }

  // ─── BUG 5 FIX: Files tab — invalid color literals ───────────────────────
  // Color(0XFF) and BoxBorder.all don't exist — fixed below

  Widget _buildFilesTab() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    if (pdfs.isEmpty && imagesGroups.isEmpty) {
      return Center(
          child: Text(
        AppLocalizations.of(context)!.noFilesAvailable,
        style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextSecondaryColor(isDark)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pdfs.isNotEmpty) ...[
          ...pdfs.map((pdf) {
            // --- NEW LOGIC START ---
            // 1. Check if allowDownload is explicitly true
            final bool allowDownload = pdf["allowDownload"] == true;
            // 2. Fallback: check allowedStudents
            final List<String> allowedStudents = List<String>.from(
                (pdf["allowedStudents"] ?? []).map((id) => id.toString()));
            final bool isInAllowedList = _currentStudentId != null &&
                allowedStudents.contains(_currentStudentId);
            // Combined: downloadable if allowDownload true OR (in allowed list)
            final bool isDownloadable = allowDownload || isInAllowedList;
            // --- NEW LOGIC END ---

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.getInputBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.getCardBorderColor(isDark), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getTextSecondaryColor(isDark)
                        .withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0XFFFB2C36).withOpacity(0.1)
                        : const Color(0XFFFEF2F2),
                    border: Border.all(
                        color: isDark
                            ? const Color(0XFFFB2C36).withOpacity(0.2)
                            : const Color(0XFFFFC9C9),
                        width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsFill.filePdf,
                      textDirection: TextDirection.ltr,
                      color: Color(0XFFFB2C36),
                      size: 20,
                    ),
                  ),
                ),
                title: Text(
                  pdf["name"] ?? AppLocalizations.of(context)!.pdfFile,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                trailing: isDownloadable && widget.isPurchased
                    ? Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                            color: AppColors.getBackgroundColor(isDark)
                                .withOpacity(0.5),
                            border: Border.all(
                                color: AppColors.getCardBorderColor(isDark),
                                width: 1),
                            shape: BoxShape.circle),
                        child: InkWell(
                          onTap: () => downloadPdf(pdf),
                          child: Icon(PhosphorIconsFill.download,
                              color: AppColors.getIconColor(isDark), size: 18),
                        ),
                      )
                    : Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                            color: AppColors.getBackgroundColor(isDark)
                                .withOpacity(0.5),
                            border: Border.all(
                                color: AppColors.getCardBorderColor(isDark),
                                width: 1),
                            shape: BoxShape.circle),
                        child: Icon(PhosphorIconsRegular.eye,
                            size: 20, color: AppColors.getIconColor(isDark)),
                      ),
                onTap: () {
                  if (widget.isPurchased) {
                    openPdf(pdf);
                  } else {
                    _showErrorSnackBar(
                        AppLocalizations.of(context)!.mustBuyCourseFirst);
                  }
                },
              ),
            );
          }).toList(),
        ],
        const SizedBox(height: 20),
        if (imagesGroups.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!.imageGroups,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...imagesGroups.map((group) {
            final groupName =
                group["group_name"] ?? AppLocalizations.of(context)!.imageGroup;
            final images = List<String>.from((group["images"] ?? [])
                .map((img) => img["url"] ?? "")
                .where((url) => url.toString().trim().isNotEmpty));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final img = entry.value;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerPage(
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          img,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ],
    );
  }

  Future<void> openPdf(Map<String, dynamic> pdf) async {
    final pdfUrl = pdf["pdf"] ?? "";
    final pdfId = pdf["_id"]?.toString() ?? pdf["name"] ?? "pdf_annotate";
    final pdfName =
        pdf["name"] ?? AppLocalizations.of(context)?.pdfFileLabel ?? "ملف PDF";

    try {
      if (kIsWeb) {
        if (pdfUrl.isNotEmpty) {
          await launchUrl(Uri.parse(pdfUrl),
              mode: LaunchMode.externalApplication);
        }
        return;
      }
      String localPath = pdfUrl;

      if (pdfUrl.startsWith("http")) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$pdfId.pdf');

        if (!await file.exists()) {
          final response = await http.get(Uri.parse(pdfUrl));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            _showErrorSnackBar(AppLocalizations.of(context)?.failedToLoadPdf ??
                "فشل تحميل ملف PDF");
            return;
          }
        }

        if (!await file.exists() || await file.length() < 1024) {
          _showErrorSnackBar(AppLocalizations.of(context)?.invalidOrEmptyFile ??
              "الملف غير صالح أو فارغ");
          return;
        }

        localPath = file.path;
      } else {
        final localFile = File(pdfUrl);
        if (!await localFile.exists()) {
          _showErrorSnackBar(AppLocalizations.of(context)?.localFileNotFound ??
              "لم يتم العثور على الملف المحلي");
          return;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfEditorPage(
            title: pdfName,
            pdfPath: localPath,
            pdfId: pdfId,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)?.errorOpeningFile ??
          "حدث خطأ أثناء فتح الملف");
    }
  }

  Future<void> downloadPdf(Map<String, dynamic> pdf) async {
    final pdfUrl = pdf["pdf"] ?? "";
    final pdfName =
        (pdf["name"] ?? AppLocalizations.of(context)?.pdfFileLabel ?? "ملف PDF")
            .toString();

    try {
      if (!pdfUrl.startsWith("http")) {
        _showErrorSnackBar(AppLocalizations.of(context)?.invalidDownloadLink ??
            "الرابط غير صالح للتنزيل");
        return;
      }

      if (kIsWeb) {
        await launchUrl(Uri.parse(pdfUrl),
            mode: LaunchMode.externalApplication);
        return;
      }

      final dir = await getTemporaryDirectory();
      final safeName = pdfName
          .replaceAll(RegExp(r'[^\w\u0600-\u06FF\s\-.]'), '_')
          .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      final file = File("${dir.path}/$safeName.pdf");

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        _showErrorSnackBar(AppLocalizations.of(context)
                ?.failedToDownloadPdfCode(response.statusCode.toString()) ??
            "فشل تنزيل ملف PDF (${response.statusCode})");
        return;
      }

      await file.writeAsBytes(response.bodyBytes);

      if (!await file.exists() || await file.length() < 512) {
        _showErrorSnackBar(
            AppLocalizations.of(context)?.downloadedFileInvalid ??
                "الملف المٌنزَّل غير صالح");
        return;
      }

      final xFile =
          XFile(file.path, mimeType: 'application/pdf', name: '$safeName.pdf');

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 100, 100);

      final result = await Share.shareXFiles(
        [xFile],
        subject: pdfName,
        sharePositionOrigin: origin,
      );

      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        _showSuccessSnackBar(AppLocalizations.of(context)?.canSaveFromShare ??
            "✅ يمكنك حفظ الملف من قائمة المشاركة");
      }
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)?.errorDownloadingFile ??
          "حدث خطأ أثناء تنزيل الملف");
    }
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(visibleTabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.getInputBackgroundColor(isDark)
                    : (isDark
                        ? const Color(0xff0F172B)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        width: 1, color: AppColors.getCardBorderColor(isDark))
                    : Border.all(
                        width: 1,
                        color: isDark
                            ? const Color(0xFF1D293D)
                            : Colors.transparent),
              ),
              child: Text(
                visibleTabs[index],
                style: GoogleFonts.cairo(
                  color: isSelected
                      ? AppColors.getTextColor(isDark)
                      : AppColors.getTextSecondaryColor(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _fetchPdfs() async {
    try {
      final response = await _apiService.request(
        "pdf/both/get_pdfs/${widget.courseId}",
        null,
        "GET",
      );
      if (response == null) {
        if (await OfflineDataService.isCacheValid()) {
          final cached =
              await OfflineDataService.loadCourseData(widget.courseId);
          if (cached != null && cached['pdfs'] != null && mounted) {
            setState(() {
              pdfs = List<Map<String, dynamic>>.from((cached['pdfs'] as List)
                  .map((e) => Map<String, dynamic>.from(e)));
            });
          }
        }
        return;
      }
      if (response.statusCode == 200 && mounted) {
        setState(() {
          pdfs = List<Map<String, dynamic>>.from(response.data);
        });
        final cached =
            await OfflineDataService.loadCourseData(widget.courseId) ?? {};
        cached['pdfs'] = pdfs;
        await OfflineDataService.saveCourseData(widget.courseId, cached);
      }
    } catch (e) {
      debugPrint("❌ Error fetching PDFs: $e");
    }
  }

  Future<void> _fetchImages() async {
    try {
      final response = await _apiService.request(
        "pdf/both/get_imgs/${widget.courseId}",
        null,
        "GET",
      );
      if (response == null) {
        if (await OfflineDataService.isCacheValid()) {
          final cached =
              await OfflineDataService.loadCourseData(widget.courseId);
          if (cached != null && cached['imagesGroups'] != null && mounted) {
            setState(() {
              imagesGroups = List<Map<String, dynamic>>.from(
                  (cached['imagesGroups'] as List)
                      .map((e) => Map<String, dynamic>.from(e)));
            });
          }
        }
        return;
      }
      if (response.statusCode == 200 && mounted) {
        setState(() {
          imagesGroups = List<Map<String, dynamic>>.from(response.data);
        });
        final cached =
            await OfflineDataService.loadCourseData(widget.courseId) ?? {};
        cached['imagesGroups'] = imagesGroups;
        await OfflineDataService.saveCourseData(widget.courseId, cached);
      }
    } catch (e) {
      debugPrint("❌ Error fetching images: $e");
    }
  }

  Widget _buildCourseInfo(ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getInputTextColor(isDark),
                ),
              ),
            ),
            if (!widget.isPurchased)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xffFF6900).withOpacity(0.1)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xffFF6900).withOpacity(0.2)
                          : const Color(0XFFFFEDD4),
                      width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.gift,
                        color: Color(0XFFF54900), size: 20),
                    const SizedBox(width: 5.5),
                    Text(
                      "+XP 500",
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFF54900),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(PhosphorIconsFill.userSound,
                color: AppColors.getIconColor(isDark), size: 18),
            const SizedBox(width: 4),
            Text(
              (widget.teacherName != null && widget.teacherName!.isNotEmpty)
                  ? widget.teacherName!
                  : "",
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextSecondaryColor(isDark),
              ),
            ),
            const SizedBox(width: 8),
            Container(
                height: 12,
                width: 1,
                color: AppColors.getTextSecondaryColor(isDark)),
            const SizedBox(width: 8),
            Text(
              widget.userGroupName ??
                  AppLocalizations.of(context)?.thirdSecGrade ??
                  "الصف الثالث الثانوي",
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextSecondaryColor(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoHeader() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(widget.image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: widget.isPurchased
                ? Container(
                    height: 27,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenStatus(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.checkCircle,
                            color: Colors.white,
                            size: 14,
                            textDirection: TextDirection.ltr),
                        const SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(context)?.subscribedBadge ??
                              "مشترك",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 27,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0XFF314158),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.coursePromo ??
                          "اعلان الكورس",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(PhosphorIconsFill.play,
                  color: Colors.white,
                  size: 40,
                  textDirection: TextDirection.ltr),
            ),
          ),
        ],
      ),
    );
  }

  void _showFawryCodeDialog(String code) {
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
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!
                      .fawryInstructionNote(widget.title),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
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
                      style: GoogleFonts.cairo(
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

  void _showPurchaseDialog() {
    // ─── freecourse: اشتراك مباشر بدون كود ───
    if (widget.freecourse) {
      _handleCoursePurchase("");
      return;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                          errorBuilder: (context, error, stackTrace) => Icon(
                            PhosphorIconsFill.creditCard,
                            size: 34,
                            color: AppColors.sky(isDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)?.activateCourse ??
                          "تفعيل وشراء الكورس",
                      style: GoogleFonts.cairo(
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
                                      AppLocalizations.of(context)!
                                          .onlinePaymentFawaterak,
                                      style: GoogleFonts.cairo(
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
                                      AppLocalizations.of(context)!
                                          .activationCodeTab,
                                      style: GoogleFonts.cairo(
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
                            style: GoogleFonts.cairo(
                                color: Colors.red, fontSize: 12))
                      else if (paymentMethods.isEmpty)
                        Text(
                          AppLocalizations.of(context)!
                              .noPaymentMethodsAvailable,
                          style: GoogleFonts.cairo(
                              color: Colors.red, fontSize: 12),
                        )
                      else ...[
                        Text(
                          AppLocalizations.of(context)!.selectPaymentMethod,
                          style: GoogleFonts.cairo(
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
                                            errorWidget: (_, __, ___) => Icon(
                                                PhosphorIconsFill.creditCard,
                                                size: 20,
                                                color: AppColors
                                                    .getTextSecondaryColor(
                                                        isDark)),
                                          )
                                        else
                                          const Icon(
                                              PhosphorIconsFill.creditCard,
                                              size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            pmName,
                                            style: GoogleFonts.cairo(
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
                            gradient: AppColors.buttonGradient,
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
                                        courseId: widget.courseId,
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
                                              fawryCode.toString());
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
                                    style: GoogleFonts.cairo(
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
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172B)
                              : const Color(0XFFF8FAFC),
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
                              color: isDark
                                  ? const Color(0XFF45556C)
                                  : const Color(0XFFCAD5E2),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF155DFC), Color(0xFF00A6F4)],
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
                            await _handleCoursePurchase(code);
                          },
                          child: Text(
                            AppLocalizations.of(context)?.activateNow ??
                                AppLocalizations.of(context)?.activateNowBtn ??
                                "تفعيل الآن",
                            style: GoogleFonts.cairo(
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
                                .whatsappPurchaseMessage(widget.title);
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
                            style: GoogleFonts.cairo(
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

  void _showPurchaseVideoDialog(String videoID) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
        final bool isDark = themeProvider.isDarkMode;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          color: AppColors.getTextHintColor(isDark), size: 16),
                    ),
                  ),
                ),
                Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sky(isDark).withOpacity(0.2),
                        border: Border.all(
                            color: AppColors.sky(isDark).withOpacity(0.1),
                            width: 1)),
                    child: Center(
                        child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset('assets/images/creditCard.png',
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.video_library,
                              size: 40,
                              color: Colors.blue)),
                    ))),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.activateVideoBtn ??
                      "تفعيل الفيديو",
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.enterActivationCodeVideo ??
                      "أدخل كود التفعيل لفتح هذا الفيديو.",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextSecondaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172B)
                          : const Color(0XFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(isDark),
                          width: 2)),
                  child: TextField(
                    controller: codeController,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.getInputTextColor(isDark)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "XXXX-XXXX-XXXX",
                      hintStyle: GoogleFonts.bioRhyme(
                          color: isDark
                              ? const Color(0XFF45556C)
                              : const Color(0XFFCAD5E2),
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
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
                      // ✅ BUG 2 FIX: don't pop here — _handleVideoPurchase
                      // pops after confirming success to avoid double-pop
                      await _handleVideoPurchase(code, videoID);
                    },
                    child: Text(
                        AppLocalizations.of(context)?.activateVideo ??
                            AppLocalizations.of(context)?.activateVideoBtn ??
                            "تفعيل الفيديو",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
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
    showDialog(
      context: context,
      builder: (context) {
        final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
        final bool isDark = themeProvider.isDarkMode;
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
                    color: const Color(0xFFFF6467).withOpacity(0.2),
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
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.checkCodeTypo ??
                      "يرجى التأكد من كتابة الأرقام والحروف بشكل صحيح، أو أن الكود لم يتم استخدامه من قبل.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
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
                          color: isDark
                              ? const Color(0XFF45556C)
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.tryAgain ??
                              "حاول مرة اخرى",
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? const Color(0XFFCAD5E2)
                                : const Color(0xFF45556C),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(PhosphorIconsRegular.arrowClockwise,
                            color: isDark
                                ? const Color(0XFFCAD5E2)
                                : const Color(0xFF45556C),
                            size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.contactSupportToSolve ??
                      "تواصل مع الدعم الفني لحل المشكلة",
                  style: GoogleFonts.cairo(
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

  void _showSuccessDialog({required bool isVideoPurchase}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                  CustomPaint(
                    size: const Size(double.infinity, 90),
                    painter: SunburstPainter(),
                  ),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0XFF00BC7D).withOpacity(0.1)
                            : const Color(0xFFE6F9F0),
                        border: Border.all(
                            color: isDark
                                ? const Color(0XFF00BC7D).withOpacity(0.2)
                                : Colors.white,
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
              const SizedBox(height: 50),
              Text(
                AppLocalizations.of(context)?.activatedSuccessfully ??
                    "تم التفعيل بنجاح",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0XFF00BC7D)
                      : const Color(0xFF009966),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isVideoPurchase
                      ? AppLocalizations.of(context)?.videoAddedSuccess ??
                          "تم إضافة الفيديو إلى محتواك بنجاح."
                      : AppLocalizations.of(context)
                              ?.itemAddedSuccess(widget.title.toString()) ??
                          'تم إضافة "${widget.title}" إلى محتواك بنجاح.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0XFF90A1B9)
                        : const Color(0xFF64748B),
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
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (isVideoPurchase) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          "/home",
                          (r) => false,
                        );
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BC7D), Color(0xFF00BBA7)],
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
                              isVideoPurchase
                                  ? AppLocalizations.of(context)
                                          ?.watchVideoBtn ??
                                      "مشاهدة الفيديو"
                                  : AppLocalizations.of(context)
                                          ?.goToCourseBtn ??
                                      "الذهاب للكورس",
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(PhosphorIconsFill.playCircle,
                                color: Colors.white, size: 24),
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

  Widget _buildLiveTab() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    if (_isLoadingLive) {
      return const Center(child: CircularProgressIndicator());
    }
    if (liveData == null || liveData!.isEmpty) {
      return Center(
          child: Text(
        AppLocalizations.of(context)?.noLiveStreamNow ??
            "لا يوجد بث مباشر متاح حالياً",
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.getTextSecondaryColor(isDark),
        ),
      ));
    }

    String extractYoutubeId(String input) {
      final RegExp regExp = RegExp(
        r'(?:v=|\/live\/|youtu\.be\/|embed\/|\/v\/|\/shorts\/|\/watch\?v=|^)([\w-]{11})',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(input);
      if (match != null && match.groupCount >= 1) return match.group(1)!;
      return input;
    }

    final String streamId = extractYoutubeId(liveData!);

    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LiveScreen(streamId: streamId, courseId: widget.courseId),
          ),
        ),
        child: Card(
          color: AppColors.getInputBackgroundColor(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: streamId.isNotEmpty
                        ? YoutubeVideoPlayer(
                            videoUrl: streamId, watermarkText: "")
                        : Center(
                            child: Text(
                              AppLocalizations.of(context)?.cannotShowStream ??
                                  "لا يمكن عرض البث",
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppColors.getTextSecondaryColor(isDark)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.tapToOpenLive ??
                      "اضغط لفتح البث المباشر",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.getTextSecondaryColor(isDark)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankTab(courseId) {
    return SizedBox(
      height: 350,
      child: RankTabWidget(courseId: courseId),
    );
  }

  // ─── Course Chat Modal ───────────────────────────────────────────

  void _showCourseChatModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Container(
          height: MediaQuery.of(bottomCtx).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Modal Header Container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1D4ED8),
                      Color(0xFF3B82F6),
                      Color(0xFF38BDF8)
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: const Icon(PhosphorIconsFill.chatsCircle,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.courseLiveChat ??
                                "شات الكورس المباشر",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.title.isNotEmpty
                                ? widget.title
                                : AppLocalizations.of(context)
                                        ?.questionsLessonsChat ??
                                    "محادثة الأسئلة والدروس",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(bottomCtx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Body with dynamic keyboard inset
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(bottomCtx).viewInsets.bottom,
                  ),
                  child: CourseChatTab(courseId: widget.courseId),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFCFF3E3),
    );
    final paint = Paint()
      ..color = const Color(0xFFB4E8D3)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 1.5;
    for (int i = 0; i < 18; i++) {
      if (i % 2 == 0) continue;
      final startAngle = (i * 10) * 3.14159265359 / 180;
      final sweepAngle = 10 * 3.14159265359 / 180;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius),
            startAngle - 3.14159265359, sweepAngle, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
