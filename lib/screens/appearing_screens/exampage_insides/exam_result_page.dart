import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/exam_review_page.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter_version/l10n/app_localizations.dart';

class ExamResultPage extends StatefulWidget {
  final String examId;
  final String title;
  final bool isExercise;

  const ExamResultPage({
    super.key,
    required this.examId,
    required this.title,
    this.isExercise = false,
  });

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> studentAnswers = {};
  double totalScore = 0;
  double totalMark = 0;

  // ─── Helpers (kept identical to original) ────────────────────────────────

  bool isValidJson(dynamic data) {
    try {
      jsonDecode(data.toString());
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic getValidJson(dynamic data) {
    try {
      return jsonDecode(data.toString());
    } catch (_) {
      return data;
    }
  }

  String expandContractions(String? input) {
    if (input == null) return "";
    final contractions = {
      "\"": "",
      "'s": " is",
      "'re": " are",
      "n't": " not",
      "I'm": "I am",
      "i'm": "I am",
      "I've": "I have",
      "i've": "I have",
      "I'd": "I would",
      "i'd": "I would",
      "can't": "cannot",
      "won't": "will not",
      "wasn't": "was not",
      "weren't": "were not",
      "hasn't": "has not",
      "haven't": "have not",
      "shouldn't": "should not",
      "doesn't": "does not",
      "don't": "do not",
      "didn't": "did not",
      "wouldn't": "would not",
      "can not": "cannot",
    };
    contractions.forEach((k, v) {
      input = input!.replaceAll(RegExp(k, caseSensitive: false), v);
    });
    return input!.replaceAll(RegExp(r'[.?,]'), '');
  }

  double jaccardSimilarity(String? a, String? b) {
    final setA = Set.of(
        expandContractions(a).toLowerCase().split(RegExp(r'\W+'))
          ..removeWhere((e) => e.isEmpty));
    final setB = Set.of(
        expandContractions(b).toLowerCase().split(RegExp(r'\W+'))
          ..removeWhere((e) => e.isEmpty));
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  // ─── Fetch (identical to original) ───────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final questionsRes = widget.isExercise
          ? await _apiService.request(
              "student/exam/get_exercise_in_video/${widget.examId}",
              null,
              "GET")
          : await _apiService.request(
              "student/exam/get_ended_exam/${widget.examId}", null, "GET");

      final answersRes = await _apiService.request(
          "student/exam/student_answers/${widget.examId}", null, "GET");

      if (questionsRes?.data != null && answersRes?.data != null) {
        final qList = List<Map<String, dynamic>>.from(
            questionsRes?.data?["Questions"] ?? []);
        final rawAnswerList =
            List<Map<String, dynamic>>.from(answersRes?.data?["Answers"] ?? []);

        final aList = {
          for (var item in rawAnswerList)
            if (item["_id"] != null)
              item["question_id"].toString(): item["answer"]
        };

        double score = 0;
        double maxMark = 0;

        for (final q in qList) {
          final role = q["role"] ?? "choice";
          final questionId = q["_id"]?.toString() ?? '';
          final double qMark = (q["mark"] ?? 1).toDouble();
          maxMark += qMark;
          final rawAnswer = aList[questionId];
          final answer = role == "choice" || role == "boolean"
              ? isValidJson(rawAnswer)
                  ? getValidJson(rawAnswer)
                  : rawAnswer
              : getValidJson(rawAnswer);

          bool isCorrect = false;

          if (role == "boolean") {
            isCorrect = answer == q["correctBoolean"];
          } else if (role == "text") {
            final tries = [
              q["answer_1"],
              q["answer_2"],
              q["answer_3"],
              q["answer_4"]
            ];
            isCorrect = tries.any((t) => jaccardSimilarity(t, answer) > 0.7);
          } else if (role == "correct") {
            final tries = [
              q["answer_1"],
              q["answer_2"],
              q["answer_3"],
              q["answer_4"]
            ].where((a) => a != null && a.toString().trim().isNotEmpty).toList();
            isCorrect = tries.any((t) => jaccardSimilarity(t, answer) == 1.0);
          } else if (role == "dialogue") {
            final List completionSpaces = q["dialoguecompletionSpaces"] ?? [];
            final List<dynamic> userAnswers = answer is String
                ? List<String>.from(getValidJson(answer))
                : (answer is List ? answer : []);
            final double spaceMark = qMark / completionSpaces.length;
            double partialScore = 0.0;
            for (int i = 0; i < completionSpaces.length; i++) {
              final List possible = completionSpaces[i];
              final given =
                  i < userAnswers.length ? userAnswers[i].toString() : '';
              for (final validAns in possible) {
                if (jaccardSimilarity(validAns, given) > 0.3) {
                  partialScore += spaceMark;
                  break;
                }
              }
            }
            score += partialScore;
            continue;
          } else if (role == "complete") {
            final List correctAnswers = q["correctcomplete"] ?? [];
            final List<dynamic> userAnswers = answer is String
                ? List<String>.from(getValidJson(answer))
                : (answer is List ? answer : []);
            final double spaceMark = qMark / correctAnswers.length;
            double partialScore = 0.0;
            for (int i = 0; i < correctAnswers.length; i++) {
              final expected = correctAnswers[i];
              final given =
                  i < userAnswers.length ? userAnswers[i].toString() : '';
              if (jaccardSimilarity(expected, given) == 1.0) {
                partialScore += spaceMark;
              }
            }
            score += partialScore;
            continue;
          } else {
            isCorrect = answer == q["correctChoice"];
          }

          if (isCorrect) score += qMark;
        }

        setState(() {
          questions = qList;
          studentAnswers = aList;
          totalScore = score;
          totalMark = maxMark;
        });
      } else {
        setState(() {
          questions = [];
          studentAnswers = {};
          totalScore = 0;
          totalMark = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDisplayAnswers),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching exam results: $e");
    }
    setState(() => _isLoading = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.sky(isDark)))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // ── Title ──────────────────────────────────────────
                      Text(
                        AppLocalizations.of(context)!.examResultTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Score image ────────────────────────────────────
                      _buildScoreImage(isDark),
                      const SizedBox(height: 60),

                      // ── Two action buttons ─────────────────────────────
                      _buildReviewButton(isDark),
                      const SizedBox(height: 20),
                      _buildHomeButton(isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Score image (identical to original) ─────────────────────────────────

  Widget _buildScoreImage(bool isDark) {
    final size = MediaQuery.of(context).size;
    final percentage =
        totalMark > 0 ? (totalScore / totalMark * 100).toInt() : 0;
    final isPass = percentage >= 50;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: size.height * 0.265,
          width: size.width * 0.545,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.getCardBorderColor(isDark), width: 2),
            image: DecorationImage(
              image: percentage > 99
                  ? const AssetImage("assets/images/prefect_std.jpg")
                  : percentage > 90
                      ? const AssetImage("assets/images/excellent_std.jpg")
                      : percentage > 80
                          ? const AssetImage("assets/images/good_std.jpg")
                          : percentage > 70
                              ? const AssetImage(
                                  "assets/images/over_average_std.jpg")
                              : percentage > 50
                                  ? const AssetImage(
                                      "assets/images/average_std.jpg")
                                  : const AssetImage(
                                      "assets/images/sad_std.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -28,
          right: -8,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPass ? AppColors.success : AppColors.error,
              border: Border.all(
                  color: AppColors.getCardBorderColor(isDark), width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalScore.toInt().toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    height: 1,
                    width: 22,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  Text(
                    AppLocalizations.of(context)?.outOfTotal(totalMark.toInt().toString()) ?? "من ${totalMark.toInt()}",
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Review button → ExamReviewPage ──────────────────────────────────────

  Widget _buildReviewButton(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamReviewPage(
              questions: questions,
              studentAnswers: studentAnswers,
              isExercise: widget.isExercise,
            ),
          ),
        );
      },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.sky(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)?.reviewMistakesBtn ?? "مراجعة الأخطاء",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsFill.eye, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Home button ──────────────────────────────────────────────────────────

  Widget _buildHomeButton(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)?.backToHomeBtn ?? "العودة إلي الرئيسية",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextHintColor(isDark),
              ),
            ),
            const SizedBox(width: 8),
            Icon(PhosphorIconsFill.house,
                color: AppColors.getIconColor(isDark), size: 20),
          ],
        ),
      ),
    );
  }
}
