import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/exam_start_page.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/exam_result_page.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/mistakes_exam_page.dart';

// (MistakesBankPage is defined here – we include it again for completeness)
class MistakesBankPage extends StatelessWidget {
  final List<Map<String, dynamic>> mistakes;

  const MistakesBankPage({Key? key, required this.mistakes}) : super(key: key);

  String _resolveMistakeAnswerText(BuildContext context, Map<String, dynamic>? q, dynamic answerVal) {
    if (answerVal == null || answerVal.toString().isEmpty) return AppLocalizations.of(context)?.notAvailableVal ?? "غير متوفر";
    if (q == null) return answerVal.toString();
    final String raw = answerVal.toString().trim();
    return q[raw]?.toString() ?? raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.mistakesBank ?? "بنك الأخطاء",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.getBackgroundColor(isDark),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: mistakes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsFill.checkCircle,
                    color: AppColors.greenStatus(isDark),
                    size: 60,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.congratsNoMistakes ?? "مبروك! ليس لديك أي أخطاء ",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mistakes.length,
              itemBuilder: (ctx, index) {
                final mistake = mistakes[index];
                final question = mistake["questionId"] as Map<String, dynamic>?;
                final rawStudentAns = mistake["studentAnswer"];
                final rawCorrectAns = question?["correctChoice"];

                final studentAnswerText =
                    _resolveMistakeAnswerText(context, question, rawStudentAns);
                final correctAnswerText =
                    _resolveMistakeAnswerText(context, question, rawCorrectAns);
                final addedAt = (mistake["addedAt"] ?? "").toString();

                String questionText = AppLocalizations.of(context)?.questionNotAvailable ?? "السؤال غير متوفر";
                List<String> options = [];

                if (question != null) {
                  questionText = question["question"] ?? AppLocalizations.of(context)?.questionNotAvailable ?? "السؤال غير متوفر";
                  for (int i = 1; i <= 4; i++) {
                    final opt = question["answer_$i"];
                    if (opt != null && opt.isNotEmpty) {
                      options.add(opt);
                    }
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.getCardBackgroundColor(isDark),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.getCardBorderColor(isDark),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionText,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (options.isNotEmpty) ...[
                          Text(
                            AppLocalizations.of(context)?.optionsLabel ?? "الخيارات:",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...options.map((opt) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "• $opt",
                                  style: GoogleFonts.cairo(
                                    color:
                                        AppColors.getTextSecondaryColor(isDark),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)?.yourAnswerVal(studentAnswerText.toString()) ?? "إجابتك: $studentAnswerText",
                                    style: GoogleFonts.cairo(
                                      color: AppColors.redStatus(isDark),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)?.correctAnswerVal(correctAnswerText.toString()) ?? "الإجابة الصحيحة: $correctAnswerText",
                                    style: GoogleFonts.cairo(
                                      color: AppColors.greenStatus(isDark),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // if (examId != AppLocalizations.of(context)?.unknownVal ?? "غير معروف")
                            //   Text(
                            //     AppLocalizations.of(context)?.examIdVal(examId.toString()) ?? "امتحان: $examId",
                            //     style: GoogleFonts.cairo(
                            //       fontSize: 12,
                            //       color: AppColors.getTextHintColor(isDark),
                            //     ),
                            //   ),
                          ],
                        ),
                        if (addedAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              AppLocalizations.of(context)?.addedOnDate(_formatDate(addedAt).toString()) ?? "أضيف في: ${_formatDate(addedAt)}",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.getTextHintColor(isDark),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateStr;
    }
  }
}

class ExamsPage extends StatefulWidget {
  const ExamsPage({Key? key}) : super(key: key);

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int streakCount = 0;

  List<Map<String, dynamic>> currentExams = [];
  List<Map<String, dynamic>> upcomingExams = [];
  List<Map<String, dynamic>> pastExams = [];

  List<Map<String, dynamic>> _mistakes = [];
  bool _loadingMistakes = true;

  // ✅ FIX: the AppLocalizations.of(context)?.mistakesBank ?? "بنك الأخطاء" card and the review-exam question count were
  // computed differently — the card showed _mistakes.length (every mistake
  // *record*, one per wrong attempt) while the review exam deduped by
  // question _id. Getting the same question wrong twice, or a record with a
  // missing/malformed questionId, made the two numbers disagree. Now both
  // paths share this single source of truth.
  Map<String, Map<String, dynamic>> _uniqueMistakeQuestions() {
    final Map<String, Map<String, dynamic>> uniqueQuestions = {};
    for (final m in _mistakes) {
      final q = m["questionId"];
      if (q is Map<String, dynamic> && q["_id"] != null) {
        uniqueQuestions[q["_id"].toString()] = q;
      } else {
        debugPrint(
            "⚠️ Mistake record skipped (missing/invalid questionId): $m");
      }
    }
    return uniqueQuestions;
  }

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _fetchExams();
    _fetchMistakes();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        streakCount = prefs.getInt('streak_count') ?? 0;
      });
    }
  }

  void _onStartMistakesExam() {
    if (_mistakes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.noMistakesToReview ??
                    AppLocalizations.of(context)?.noMistakesToReviewNow ?? "مفيش أخطاء عشان تراجعها دلوقتي 🎉")),
      );
      return;
    }

    // Dedupe by question _id in case the same question appears more than once
    final uniqueQuestions = _uniqueMistakeQuestions();

    if (uniqueQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.failedToLoadReviewQuestions ??
                    AppLocalizations.of(context)?.failedToLoadReviewQ ?? "تعذر تحميل أسئلة المراجعة")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MistakesExamPage(questions: uniqueQuestions.values.toList()),
      ),
    );
  }

  Future<void> _fetchMistakes() async {
    setState(() => _loadingMistakes = true);
    try {
      final response = await _apiService.request(
        "student/mistakes-bank",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        final List data = response.data is List ? response.data : [];
        setState(() {
          _mistakes = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() {
          _mistakes = [];
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching mistakes: $e");
      setState(() {
        _mistakes = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingMistakes = false);
      }
    }
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.request(
        "student/exam/get_single_exam_student",
        null,
        "GET",
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        List<Map<String, dynamic>> realResults = [];
        try {
          final resultsResponse = await _apiService.request(
            "student/exam/get_all_studentresults_for_student",
            null,
            "GET",
          );
          if (resultsResponse != null && resultsResponse.statusCode == 200) {
            final List rawList =
                resultsResponse.data is List ? resultsResponse.data : [];
            realResults = List<Map<String, dynamic>>.from(rawList);
          }
        } catch (e) {
          debugPrint("❌ Error fetching exam results: $e");
        }

        final resultsMap = <String, Map<String, dynamic>>{};
        for (var r in realResults) {
          final examIdVal =
              r["exam_Id"] ?? r["exam_id"] ?? r["examId"] ?? r["_id"];
          if (examIdVal != null) {
            resultsMap[examIdVal.toString()] = r;
          }
        }

        currentExams = (data["examsOngoing"] as List)
            .map((exam) => {
                  "id": exam["_id"],
                  "title": exam["Teacher_Name"] ??
                      AppLocalizations.of(context)!.unknownExam,
                  "subject": exam["Subject_Name"] ?? exam["subject"] ?? "",
                  "teacher": exam["Teacher_Name"] ?? "",
                  "date": _formatDate(exam["start"]),
                  "endTime": exam["end"],
                  "questionsCount": exam["Questions_Count"] ??
                      exam["questionsCount"] ??
                      (exam["Questions"] is List
                          ? (exam["Questions"] as List).length
                          : null),
                  "durationMinutes": exam["duration"] ?? exam["Duration"],
                  "isCompleted":
                      resultsMap.containsKey(exam["_id"]?.toString() ?? ""),
                })
            .toList();

        upcomingExams = (data["examsNotStarted"] as List)
            .map((exam) => {
                  "id": exam["_id"],
                  "title": exam["Teacher_Name"] ??
                      AppLocalizations.of(context)!.unknownExam,
                  "subject": exam["Subject_Name"] ?? exam["subject"] ?? "",
                  "teacher": exam["Teacher_Name"] ?? "",
                  "date": _formatDate(exam["start"]),
                  "questionsCount": exam["Questions_Count"] ??
                      exam["questionsCount"] ??
                      (exam["Questions"] is List
                          ? (exam["Questions"] as List).length
                          : null),
                  "durationMinutes": exam["duration"] ?? exam["Duration"],
                  "startsAt": exam["start"],
                })
            .toList();

        pastExams = (data["examsEnded"] as List).map((exam) {
          final String examId = exam["_id"]?.toString() ?? "";
          final match = resultsMap[examId];

          int score = 0;
          int total = 20;
          bool hasResult = false;

          if (match != null) {
            hasResult = true;
            final resultVal = match["result"];
            if (resultVal is String) {
              if (resultVal.contains('/')) {
                final parts = resultVal.split('/');
                score = int.tryParse(parts[0].trim()) ?? 0;
                total = int.tryParse(parts[1].trim()) ?? 20;
              } else {
                score = int.tryParse(resultVal.trim()) ?? 0;
              }
            } else if (resultVal is num) {
              score = resultVal.toInt();
            }

            final rawScore = match["student_mark"];
            if (rawScore is num) {
              score = rawScore.toInt();
            } else if (rawScore is String) {
              score = int.tryParse(rawScore) ?? score;
            }

            final rawTotal = match["totalmark"] ?? match["totalMark"];
            if (rawTotal is num) {
              total = rawTotal.toInt();
            } else if (rawTotal is String) {
              total = int.tryParse(rawTotal) ?? total;
            }
          }

          final pct = total > 0 ? (score / total) : 0.0;
          final color = hasResult
              ? (pct >= 0.8
                  ? Colors.green
                  : (pct >= 0.5 ? Colors.orange : Colors.red))
              : Colors.grey;

          return {
            "id": examId,
            "title": exam["Teacher_Name"] ??
                AppLocalizations.of(context)!.unknownExam,
            "date": _formatDate(exam["start"]),
            "score": score,
            "total": total,
            "color": color,
            "hasResult": hasResult,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching exams: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ─── UPDATED: Starts exam with new timer logic ──────────────────────────

  Future<void> _startCurrentExam(String examId, String title) async {
    try {
      // 1. Find the exam to know if it has duration
      final examData = currentExams.firstWhere((e) => e["id"] == examId);

      // ✅ FIX: durationMinutes may come back from the API as int, double,
      // or String depending on how the backend serializes it. `as int?`
      // throws a TypeError on anything but a real int (e.g. 45.0 is a
      // double, not an int) — which was silently caught by the outer
      // catch and sent this exam down the "no duration" fallback path,
      // showing a countdown to `end` (days away) instead of the real
      // 45-minute duration. Parse defensively instead of casting.
      final rawDuration = examData["durationMinutes"];
      final int? duration = rawDuration is int
          ? rawDuration
          : rawDuration is num
              ? rawDuration.toInt()
              : int.tryParse(rawDuration?.toString() ?? '');

      String? startTime;

      // 2. If duration exists (>0), call the new start endpoint
      if (duration != null && duration > 0) {
        final startResponse = await _apiService.request(
          "student/exam/start/$examId",
          null,
          "POST",
        );
        if (startResponse != null && startResponse.statusCode == 200) {
          debugPrint("========== EXAM START ==========");
          debugPrint("Exam ID: $examId");
          debugPrint("Start Time: ${startResponse.data["startTime"]}");
          debugPrint("Duration: ${startResponse.data["duration"]}");
          debugPrint("Full Response: ${startResponse.data}");
          debugPrint("================================");

          startTime = startResponse.data["startTime"] as String?;
        } else {
          debugPrint("❌ Failed to start exam");
          debugPrint("Response: ${startResponse?.data}");

          startTime = null;
        }
      }

      // 3. Fetch the questions (as before)
      final response = await _apiService.request(
        "student/exam/get_quiz_now_for_student/$examId",
        null,
        "GET",
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final questions = List<Map<String, dynamic>>.from(data["Questions"]);
        final endTimeString = data["end"];

        // 4. Navigate to ExamStartPage with all info
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamStartPage(
              examId: examId,
              courseId: "0011223344",
              title: title,
              duration: duration ?? 0,
              endTime: endTimeString,
              questions: questions,
              startTime: startTime,
              hasDuration: duration != null && duration > 0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error starting current exam: $e");
      // If anything fails, fallback to the old flow (no start endpoint)
      // but we still need to get the questions. We'll just pass null startTime.
      try {
        final response = await _apiService.request(
          "student/exam/get_quiz_now_for_student/$examId",
          null,
          "GET",
        );
        if (response != null && response.statusCode == 200) {
          final data = response.data;
          final questions = List<Map<String, dynamic>>.from(data["Questions"]);
          final endTimeString = data["end"];
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamStartPage(
                examId: examId,
                courseId: "0011223344",
                title: title,
                duration: 0,
                endTime: endTimeString,
                questions: questions,
                startTime: null,
                hasDuration: false,
              ),
            ),
          );
        }
      } catch (e2) {
        debugPrint("❌ Fallback failed: $e2");
      }
    }
  }

  void _openPastExam(String examId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultPage(
          examId: examId,
          title: title,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(dateStr);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
          "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTimeRemaining(String? startsAt) {
    if (startsAt == null || startsAt.isEmpty) return AppLocalizations.of(context)?.startsSoon ?? "يبدأ قريباً";
    try {
      final start = DateTime.parse(startsAt);
      final now = DateTime.now();
      final diff = start.difference(now);
      if (diff.isNegative) return AppLocalizations.of(context)?.alreadyStarted ?? "بدأ بالفعل";
      if (diff.inDays > 0) {
        return AppLocalizations.of(context)?.startsInDays(diff.inDays.toString(), diff.inDays > 1 ? '' : ''.toString()) ?? "يبدأ بعد ${diff.inDays} يوم${diff.inDays > 1 ? '' : ''}";
      } else if (diff.inHours > 0) {
        final hours = diff.inHours;
        final minutes = diff.inMinutes.remainder(60);
        if (minutes > 0) {
          return AppLocalizations.of(context)?.startsInHoursMins(hours.toString(), minutes.toString()) ?? "يبدأ بعد $hours ساعة و $minutes دقيقة";
        } else {
          return AppLocalizations.of(context)?.startsInHours(hours.toString(), hours > 1 ? '' : ''.toString()) ?? "يبدأ بعد $hours ساعة${hours > 1 ? '' : ''}";
        }
      } else if (diff.inMinutes > 0) {
        return AppLocalizations.of(context)?.startsInMinutes(diff.inMinutes.toString()) ?? "يبدأ بعد ${diff.inMinutes} دقيقة";
      } else {
        return AppLocalizations.of(context)?.startsNow ?? "يبدأ الآن";
      }
    } catch (_) {
      return AppLocalizations.of(context)?.startsSoon ?? "يبدأ قريباً";
    }
  }

  String _formatEndTime(String? endsAt) {
    if (endsAt == null || endsAt.isEmpty) return AppLocalizations.of(context)?.endsSoon ?? "ينتهي قريباً";
    try {
      final end = DateTime.parse(endsAt);
      final now = DateTime.now();
      final diff = end.difference(now);
      if (diff.isNegative) return AppLocalizations.of(context)?.ended ?? "انتهى";
      if (diff.inDays > 0) {
        return AppLocalizations.of(context)?.endsInDays(diff.inDays.toString()) ?? "ينتهي بعد ${diff.inDays} يوم";
      } else if (diff.inHours > 0) {
        final hours = diff.inHours;
        final minutes = diff.inMinutes.remainder(60);
        if (minutes > 0) {
          return AppLocalizations.of(context)?.endsInHoursMins(hours.toString(), minutes.toString()) ?? "ينتهي بعد $hours ساعة و $minutes دقيقة";
        } else {
          return AppLocalizations.of(context)?.endsInHours(hours.toString(), hours > 1 ? '' : ''.toString()) ?? "ينتهي بعد $hours ساعة${hours > 1 ? '' : ''}";
        }
      } else if (diff.inMinutes > 0) {
        return AppLocalizations.of(context)?.endsInMinutes(diff.inMinutes.toString()) ?? "ينتهي بعد ${diff.inMinutes} دقيقة";
      } else {
        return AppLocalizations.of(context)?.endsNow ?? "ينتهي الآن";
      }
    } catch (_) {
      return AppLocalizations.of(context)?.endsSoon ?? "ينتهي قريباً";
    }
  }

  String _buildSubjectTeacherLine(Map<String, dynamic> exam) {
    final subject = (exam["subject"] as String?)?.trim() ?? "";
    final teacher = (exam["teacher"] as String?)?.trim() ?? "";
    if (subject.isNotEmpty && teacher.isNotEmpty) {
      return "$subject • $teacher";
    } else if (teacher.isNotEmpty) {
      return teacher;
    } else if (subject.isNotEmpty) {
      return subject;
    }
    return "";
  }

  void _onReviewMistakes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MistakesBankPage(mistakes: _mistakes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.sky(isDark),
            ))
          : RefreshIndicator(
              onRefresh: _fetchExams,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, topPadding),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildErrorBankCard(
                            isDark: isDark,
                            // ✅ FIX: was _mistakes.length (raw mistake
                            // records). Now shows the same deduplicated
                            // question count used to build the review exam,
                            // so the number the student sees always matches
                            // how many questions AppLocalizations.of(context)?.startExamBtn ?? "ابدأ الامتحان" will give them.
                            mistakeCount: _uniqueMistakeQuestions().length,
                            onReviewTap: _onReviewMistakes,
                            onStartTap: _onStartMistakesExam,
                            isLoading: _loadingMistakes,
                          ),
                          const SizedBox(height: 24),
                          if (currentExams.isNotEmpty ||
                              upcomingExams.isNotEmpty) ...[
                            _buildSectionHeader(context, AppLocalizations.of(context)?.newExamsTitle ?? "امتحانات جديدة",
                                currentExams.length + upcomingExams.length),
                            const SizedBox(height: 16),
                            if (currentExams.isNotEmpty)
                              ...currentExams
                                  .map((exam) => _buildNewExamCard(
                                        context,
                                        title: exam["title"],
                                        date: exam["date"],
                                        examId: exam["id"],
                                        subjectTeacherLine:
                                            _buildSubjectTeacherLine(exam),
                                        questionsCount: exam["questionsCount"],
                                        durationMinutes:
                                            exam["durationMinutes"],
                                        isCompleted:
                                            exam["isCompleted"] == true,
                                        endTime: exam["endTime"],
                                        isDark: isDark,
                                      ))
                                  .toList(),
                            if (upcomingExams.isNotEmpty)
                              ...upcomingExams
                                  .map((exam) => _buildUpcomingExamCard(
                                        context,
                                        title: exam["title"],
                                        date: exam["date"],
                                        examId: exam["id"],
                                        subjectTeacherLine:
                                            _buildSubjectTeacherLine(exam),
                                        questionsCount: exam["questionsCount"],
                                        durationMinutes:
                                            exam["durationMinutes"],
                                        startsAt: exam["startsAt"],
                                        isDark: isDark,
                                      ))
                                  .toList(),
                            const SizedBox(height: 24),
                          ],
                          if (pastExams.isNotEmpty) ...[
                            _buildSectionHeader(context,
                                AppLocalizations.of(context)?.pastExamsHistory ?? "سجل الامتحانات السابقة", pastExams.length),
                            const SizedBox(height: 16),
                            ...pastExams
                                .map((exam) => _buildPastExamCard(
                                      context,
                                      title: exam["title"] ?? "",
                                      date: exam["date"] ?? "",
                                      examId: exam["id"] ?? "",
                                      score: exam["score"] ?? 0,
                                      total: exam["total"] ?? 20,
                                      scoreColor: exam["color"] ?? Colors.grey,
                                      isDark: isDark,
                                    ))
                                .toList(),
                          ],
                          SizedBox(height: 30 + bottomPadding + 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return Container(
      padding: EdgeInsets.only(
          top: topPadding + 20, left: 20, right: 20, bottom: 24),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.exam, color: Colors.white, size: 32),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)?.exams ?? AppLocalizations.of(context)?.examsTitle ?? "امتحانات",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.fire,
                        color: AppColors.orangeStatus(isDark), size: 18),
                    const SizedBox(width: 5),
                    Text(
                      '$streakCount',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: const Icon(PhosphorIconsRegular.bell,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBankCard({
    required bool isDark,
    required int mistakeCount,
    required VoidCallback onReviewTap,
    required VoidCallback onStartTap,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.sky(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.sky(isDark).withOpacity(0.1),
                        width: 1)),
                child: Icon(PhosphorIconsFill.brain,
                    color: AppColors.sky(isDark), size: 28),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.mistakesBank ?? "بنك الأخطاء",
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context)?.youHavePre ?? "لديك ",
                        style: GoogleFonts.cairo(
                          color: AppColors.getTextHintColor(isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)?.mistakeCountQ(mistakeCount.toString()) ?? "$mistakeCount سؤال",
                            style: GoogleFonts.cairo(
                              color: mistakeCount > 0
                                  ? AppColors.redStatus(isDark)
                                  : AppColors.greenStatus(isDark),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: mistakeCount > 0 ? AppLocalizations.of(context)?.wrongSuf ?? " خاطئ" : AppLocalizations.of(context)?.congratsSuf ?? "، مبروك!",
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReviewTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.getInputBackgroundColor(isDark),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(isDark),
                          width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.reviewMistakesBtn ?? "مراجعة الأخطاء",
                          style: GoogleFonts.cairo(
                            color: AppColors.getTextHintColor(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(PhosphorIconsRegular.eye,
                            color: AppColors.getTextHintColor(isDark),
                            size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onStartTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.sky(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.startExamBtn ?? "ابدأ الامتحان",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(PhosphorIconsFill.sword,
                            textDirection: TextDirection.ltr,
                            color: Colors.white,
                            size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          PhosphorIconsFill.boxArrowDown,
          color: AppColors.getTextHintColor(isDark),
          size: 18,
        ),
        const SizedBox(width: 6.5),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: AppColors.getTextColor(isDark),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getCardBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.getCardBorderColor(isDark),
              width: 1,
            ),
          ),
          child: Text(
            AppLocalizations.of(context)?.examsCountStr(count.toString()) ?? "$count امتحانات",
            style: GoogleFonts.cairo(
              color: AppColors.getTextHintColor(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewExamCard(BuildContext context,
      {required String title,
      required String date,
      required String examId,
      required String subjectTeacherLine,
      dynamic questionsCount,
      dynamic durationMinutes,
      bool isCompleted = false,
      String? endTime,
      required bool isDark}) {
    final questionsLabel =
        questionsCount != null ? AppLocalizations.of(context)?.questionsCountStr(questionsCount.toString()) ?? "$questionsCount اسئلة" : AppLocalizations.of(context)?.questionsLabel ?? "أسئلة";
    final durationLabel =
        durationMinutes != null ? AppLocalizations.of(context)?.durationMinsLabel(durationMinutes.toString()) ?? "$durationMinutes دقيقة" : AppLocalizations.of(context)?.examDurationLabel ?? "مدة الامتحان";

    return GestureDetector(
      onTap: isCompleted
          ? () => _openPastExam(examId, title)
          : () => _startCurrentExam(examId, title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? null
              : LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: AppColors.getBrandGradient(),
                ),
          color: isCompleted
              ? AppColors.getCardBackgroundColor(isDark)
              : null,
          borderRadius: BorderRadius.circular(24),
          border: isCompleted
              ? Border.all(color: AppColors.getCardBorderColor(isDark))
              : null,
          boxShadow: isCompleted
              ? []
              : [
                  BoxShadow(
                    color: AppColors.sky(isDark).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orangeStatus(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "XP 500+",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(PhosphorIconsFill.gift,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenStatus(isDark).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)?.submittedStatus ?? "تم التسليم",
                          style: GoogleFonts.cairo(
                            color: AppColors.greenStatus(isDark),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(PhosphorIconsFill.checkCircle,
                            textDirection: TextDirection.ltr,
                            color: AppColors.greenStatus(isDark),
                            size: 12),
                      ],
                    ),
                  ),
                if (!isCompleted && endTime != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.redStatus(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatEndTime(endTime),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(PhosphorIconsRegular.clock,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.cairo(
                color:
                    isCompleted ? AppColors.getTextColor(isDark) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (subjectTeacherLine.isNotEmpty)
              Text(
                subjectTeacherLine,
                style: GoogleFonts.cairo(
                  color: isCompleted
                      ? AppColors.getTextHintColor(isDark)
                      : Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.getInputBackgroundColor(isDark)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(questionsLabel,
                          style: GoogleFonts.cairo(
                              color: isCompleted
                                  ? AppColors.getTextHintColor(isDark)
                                  : Colors.white,
                              fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(PhosphorIconsFill.question,
                          color: isCompleted
                              ? AppColors.getTextHintColor(isDark)
                              : Colors.white,
                          size: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.getInputBackgroundColor(isDark)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(durationLabel,
                          style: GoogleFonts.cairo(
                              color: isCompleted
                                  ? AppColors.getTextHintColor(isDark)
                                  : Colors.white,
                              fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(PhosphorIconsFill.clock,
                          color: isCompleted
                              ? AppColors.getTextHintColor(isDark)
                              : Colors.white,
                          size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color:
                    isCompleted ? AppColors.greenStatus(isDark).withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isCompleted
                    ? Border.all(color: AppColors.greenStatus(isDark).withOpacity(0.3))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCompleted ? AppLocalizations.of(context)?.viewResultBtn ?? "عرض النتيجة ومراجعة الأخطاء" : AppLocalizations.of(context)?.startExamNowLabel ?? "ابدأ الامتحان الآن",
                    style: GoogleFonts.cairo(
                      color:
                          isCompleted ? AppColors.greenStatus(isDark) : AppColors.sky(false),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isCompleted
                        ? PhosphorIconsFill.eye
                        : PhosphorIconsRegular.rocketLaunch,
                    color: isCompleted ? AppColors.greenStatus(isDark) : AppColors.sky(false),
                    textDirection: TextDirection.ltr,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExamCard(BuildContext context,
      {required String title,
      required String date,
      required String examId,
      required String subjectTeacherLine,
      dynamic questionsCount,
      dynamic durationMinutes,
      required String startsAt,
      required bool isDark}) {
    final questionsLabel =
        questionsCount != null ? AppLocalizations.of(context)?.questionsCountStr(questionsCount.toString()) ?? "$questionsCount اسئلة" : AppLocalizations.of(context)?.questionsLabel ?? "أسئلة";
    final durationLabel =
        durationMinutes != null ? AppLocalizations.of(context)?.durationMinsLabel(durationMinutes.toString()) ?? "$durationMinutes دقيقة" : AppLocalizations.of(context)?.examDurationLabel ?? "مدة الامتحان";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: AppColors.getTextColor(isDark),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (subjectTeacherLine.isNotEmpty)
            Text(
              subjectTeacherLine,
              style: GoogleFonts.cairo(
                color: AppColors.getTextColor(isDark),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.getInputBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getCardBorderColor(isDark), width: 1)),
                child: Row(
                  children: [
                    Text(questionsLabel,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextColor(isDark),
                            fontSize: 11)),
                    const SizedBox(width: 4),
                    Icon(PhosphorIconsFill.question,
                        color: AppColors.getIconColor(isDark), size: 14),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.getInputBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getCardBorderColor(isDark), width: 1)),
                child: Row(
                  children: [
                    Text(durationLabel,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextColor(isDark),
                            fontSize: 11)),
                    const SizedBox(width: 4),
                    Icon(PhosphorIconsFill.clock,
                        color: AppColors.getIconColor(isDark), size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.getInputBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.getCardBorderColor(isDark), width: 1)),
            child: Center(
              child: Text(
                _formatTimeRemaining(startsAt),
                style: GoogleFonts.cairo(
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastExamCard(BuildContext context,
      {required String title,
      required String date,
      required String examId,
      required int score,
      required int total,
      required Color scoreColor,
      required bool isDark}) {
    return GestureDetector(
      onTap: () => _openPastExam(examId, title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.05),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$score",
                        style: GoogleFonts.cairo(
                          color: scoreColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Container(
                          height: 1,
                          width: 20,
                          color: scoreColor.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(vertical: 2)),
                      Text(
                        "$total",
                        style: GoogleFonts.cairo(
                          color: scoreColor.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextColor(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      date,
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextSecondaryColor(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getInputBackgroundColor(isDark),
                border: Border.all(color: AppColors.getCardBorderColor(isDark)),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.eye,
                  color: AppColors.getTextHintColor(isDark), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
