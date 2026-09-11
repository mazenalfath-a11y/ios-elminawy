import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'exam_result_page.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

class ExerciseStartPage extends StatefulWidget {
  final String examId;
  final String courseId;
  final String title;
  final int duration; // in minutes
  final List<Map<String, dynamic>> questions;

  const ExerciseStartPage({
    super.key,
    required this.examId,
    required this.courseId,
    required this.title,
    required this.duration,
    required this.questions,
  });

  @override
  State<ExerciseStartPage> createState() => _ExerciseStartPageState();
}

class _ExerciseStartPageState extends State<ExerciseStartPage> {
  final ApiService _apiService = ApiService();
  late Timer _timer;
  Timer? _examDurationTimer;

  int currentQuestion = 0;
  int remainingSeconds = 0;
  int _examDurationMinutes = 0;
  Map<String, dynamic> answers = {}; // {questionId: String OR List<String>}

  // ✅ FIX: persistent controllers so multi-blank (dialogue/complete)
  // questions don't lose focus/cursor position on every rebuild.
  final Map<String, List<TextEditingController>> _multiControllers = {};

  bool _isSubmitting = false; // ✅ NEW: prevent double-submit / show state

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.duration * 60;
    _startTimer();
    _startExamDurationTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _examDurationTimer?.cancel();
    for (final list in _multiControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        markQuizAndSubmit();
      }
    });
  }

  void _startExamDurationTimer() {
    _examDurationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _examDurationMinutes++;
      });
      debugPrint("✅ Exam duration: $_examDurationMinutes minutes");
    });
  }

  void _saveAnswer(String questionId, String answerKey) {
    setState(() {
      answers[questionId] = answerKey;
    });
  }

  // ✅ FIX: dedicated setter for multi-blank answers (dialogue/complete).
  // Stores a List<String> per question instead of overwriting with a raw String,
  // which is what the grading logic (answer[i]) actually expects.
  void _saveMultiAnswer(
      String questionId, int index, String value, int length) {
    setState(() {
      final existing = answers[questionId];
      List<String> list;
      if (existing is List) {
        list = existing.map((e) => e?.toString() ?? "").toList();
      } else {
        list = List.filled(length, "", growable: true);
      }
      if (list.length < length) {
        list = List.of(list)..addAll(List.filled(length - list.length, ""));
      }
      list[index] = value;
      answers[questionId] = list;
    });
  }

  List<TextEditingController> _controllersFor(
      String questionId, int length, List<String?>? savedAnswer) {
    if (_multiControllers.containsKey(questionId) &&
        _multiControllers[questionId]!.length == length) {
      return _multiControllers[questionId]!;
    }
    final list = List<TextEditingController>.generate(length, (i) {
      final text = (savedAnswer != null && i < savedAnswer.length)
          ? (savedAnswer[i] ?? "")
          : "";
      return TextEditingController(text: text);
    });
    _multiControllers[questionId] = list;
    return list;
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

  Future<void> markQuizAndSubmit() async {
    if (_isSubmitting) return; // ✅ avoid double submission
    setState(() => _isSubmitting = true);

    _timer.cancel();
    _examDurationTimer?.cancel();

    try {
      double mark = 0;
      double totalMark = 0;
      int correct = 0;
      int wrong = 0;

      List<Map<String, dynamic>> result = [];

      for (final q in widget.questions) {
        final role = q["role"];
        final questionId = q["_id"];
        final String? questionRefranceId = q["refrence_id"] as String?;
        final double qMark = (q["mark"] ?? 1).toDouble();
        totalMark += qMark;
        final answer = answers[questionId];

        bool isCorrect = false;

        // ✅ FIX: role name now matches what the UI actually uses ("true_false"),
        // previously this checked "boolean" and never matched, so every
        // true/false question fell through to the wrong branch below.
        if (role == "true_false") {
          if (answer == q["correctBoolean"]) isCorrect = true;
        } else if (role == "text") {
          final tries = [
            q["answer_1"],
            q["answer_2"],
            q["answer_3"],
            q["answer_4"]
          ];
          if (tries.any((t) => jaccardSimilarity(t, answer) > 0.7)) {
            isCorrect = true;
          }
        } else if (role == "correct") {
          final tries = [
            q["answer_1"],
            q["answer_2"],
            q["answer_3"],
            q["answer_4"]
          ].where((a) => a != null && a.toString().trim().isNotEmpty).toList();
          if (tries.any((t) => jaccardSimilarity(t, answer) == 1)) {
            isCorrect = true;
          }
        } else if (role == "dialogue") {
          // ✅ FIX: answer is now guaranteed to be a List<String> (or null if
          // unanswered) instead of a raw String, so indexing no longer crashes.
          final List completionSpaces = q["dialoguecompletionSpaces"] ?? [];
          if (completionSpaces.isEmpty) continue;
          final double spaceMark = qMark / completionSpaces.length;
          final List? answerList = answer is List ? answer : null;

          for (int i = 0; i < completionSpaces.length; i++) {
            final List possible = completionSpaces[i];
            final String? givenAns =
                (answerList != null && i < answerList.length)
                    ? answerList[i]?.toString()
                    : null;

            bool blankCorrect = false;
            for (final validAns in possible) {
              if (jaccardSimilarity(validAns, givenAns) > 0.3) {
                blankCorrect = true;
                break;
              }
            }
            if (blankCorrect) {
              mark += spaceMark;
              correct++;
            } else {
              wrong++;
            }
          }
          result.add({
            "question_id": questionId,
            "questionRefranceId": questionRefranceId,
            "answer": answerList?.map((e) => e?.toString() ?? "").toList() ??
                <String>[],
          });
          continue;
        } else if (role == "complete") {
          final List correctAnswers = q["correctcomplete"] ?? [];
          if (correctAnswers.isEmpty) continue;
          final double spaceMark = qMark / correctAnswers.length;
          final List? answerList = answer is List ? answer : null;

          for (int i = 0; i < correctAnswers.length; i++) {
            final String? givenAns =
                (answerList != null && i < answerList.length)
                    ? answerList[i]?.toString()
                    : null;
            if (jaccardSimilarity(correctAnswers[i], givenAns) == 1) {
              mark += spaceMark;
              correct++;
            } else {
              wrong++;
            }
          }
          result.add({
            "question_id": questionId,
            "questionRefranceId": questionRefranceId,
            "answer": answerList?.map((e) => e?.toString() ?? "").toList() ??
                <String>[],
          });
          continue;
        } else {
          if (answer == q["correctChoice"]) isCorrect = true;
        }

        if (isCorrect) {
          mark += qMark;
          correct++;
        } else {
          wrong++;
        }

        result.add({
          "question_id": questionId,
          "questionRefranceId": questionRefranceId,
          "answer": answer is String ? answer : (answer?.toString() ?? ""),
        });
      }

      // ✅ FIX: guard against divide-by-zero producing NaN and crashing on .ceil()
      final int score = totalMark > 0 ? (mark / totalMark * 10).ceil() : 0;

      final data = {
        "exercise_id": widget.examId,
        "Answers": result,
        "student_mark": mark,
        "totalmark": totalMark,
        "correctanswer": correct,
        "wronganswer": wrong,
        "examname": widget.title,
        "timeConsume": _examDurationMinutes,
      };

      final endpoint = "student/exam/exercise_sumbit/11";

      debugPrint("📤 Submitting exercise: $data");
      final res = await _apiService.request(endpoint, data, "POST");
      debugPrint("📥 Submit response status: ${res?.statusCode}");

      if (res?.statusCode == 200) {
        final scoreRes = await _apiService.request(
            "score/add_score", {"score": score}, "POST");
        debugPrint("📥 score/add_score status: ${scoreRes?.statusCode}");

        if (widget.courseId.trim().isNotEmpty) {
          final courseScoreRes = await _apiService.request(
              "course_score/add_score",
              {"score": score, "courseId": widget.courseId},
              "POST");
          debugPrint(
              "📥 course_score/add_score status: ${courseScoreRes?.statusCode}");
        }

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ExamResultPage(
                  examId: widget.examId, title: "  ", isExercise: true),
            ),
          );
        }
      } else {
        // ✅ FIX: surface the failure instead of silently doing nothing.
        _showSubmitError(
            AppLocalizations.of(context)?.failedToSendExerciseResult(res?.statusCode?.toString() ?? "Unknown") ?? "فشل إرسال نتيجة التدريب (كود ${res?.statusCode}). حاول مرة أخرى.");
      }
    } catch (e, st) {
      // ✅ FIX: any exception (e.g. bad answer format) no longer aborts
      // silently — it's logged and the user is told, and can retry.
      debugPrint("❌ markQuizAndSubmit error: $e\n$st");
      _showSubmitError(AppLocalizations.of(context)?.errorSendingExercise ?? "حدث خطأ أثناء إرسال التدريب. حاول مرة أخرى.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmitError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: AppLocalizations.of(context)?.finish ?? AppLocalizations.of(context)?.retryBtn ?? "إعادة المحاولة",
          textColor: Colors.white,
          onPressed: markQuizAndSubmit,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = secs.toString().padLeft(2, '0');

    return hours > 0 ? "$hStr:$mStr:$sStr" : "$mStr:$sStr";
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final int numberOfQuestion = widget.questions.length;
    final int currentQuestionNow = currentQuestion + 1;
    final int progressPercent =
        ((currentQuestionNow / numberOfQuestion) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          Container(
            height: 149,
            width: double.infinity,
            decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(isDark),
                border: Border(
                    bottom: BorderSide(
                        color: isDark ? Color(0XFF1D293D) : Color(0XFFF1F5F9),
                        width: 2))),
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 52.0, right: 20.0, left: 20.0),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.getBackgroundColor(isDark),
                            border: Border.all(
                                color: AppColors.getCardBorderColor(isDark),
                                width: 1)),
                        child: Icon(
                          PhosphorIconsRegular.x,
                          color: AppColors.getIconColor(isDark),
                          size: 20,
                        ),
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 107,
                      decoration: BoxDecoration(
                          color: isDark
                              ? Color(0xFFFB2C36).withOpacity(0.1)
                              : Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: isDark
                                  ? Color(0xFFFB2C36).withOpacity(0.2)
                                  : Color(0xFFFFE2E2))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.timer,
                              textDirection: TextDirection.ltr,
                              color: Color(0xFFE7000B),
                            ),
                            SizedBox(width: 4),
                            Text(_formatTime(remainingSeconds),
                                style: GoogleFonts.cairo(
                                    color: Color(0xFFE7000B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700))
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.questionXOfY(currentQuestionNow.toString(), numberOfQuestion.toString()) ?? "السؤال $currentQuestionNow من $numberOfQuestion",
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getSecondHintColor(isDark)),
                        ),
                        Text(
                          AppLocalizations.of(context)?.progressPercentDone(progressPercent.toString()) ?? "تم إنجاز $progressPercent%",
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky(isDark)),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    _buildProgressBar(),
                  ],
                ),
              ]),
            ),
          ),
          Expanded(child: SingleChildScrollView(child: _buildQuestionCard())),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final progress = (currentQuestion + 1) / widget.questions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: AppColors.getCircleBackgroundColor(isDark),
      color: AppColors.sky(isDark),
      minHeight: 6,
      borderRadius: BorderRadius.circular(50),
    );
  }

  Widget _buildQuestionCard() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    if (widget.questions.isEmpty) {
      return Center(
          child: Text(
        AppLocalizations.of(context)!.noQuestions,
        style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(isDark)),
      ));
    }

    final q = widget.questions[currentQuestion];
    final questionId = q["_id"];
    final role = q["role"];
    final savedAnswer = answers[questionId];

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, right: 20.0, left: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q["img"] != null && q["img"].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  q["img"],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text(''));
                  },
                ),
              ),
            ),

          Text(
            q["question"] ?? "",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextColor(isDark),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 24),

          if (role == "choice") _buildChoiceAnswers(q, savedAnswer),
          // ✅ FIX: role check now matches the grader ("true_false")
          if (role == "true_false") _buildTrueFalse(q, savedAnswer),
          if (role == "text" || role == "correct") _buildTextAnswer(q, savedAnswer),
          if (role == "complete") _buildCompleteAnswer(q, savedAnswer),
          if (role == "dialogue") _buildDialogueAnswer(q, savedAnswer),
        ],
      ),
    );
  }

  Widget _buildChoiceAnswers(Map<String, dynamic> q, dynamic savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final answersList = [
      q["answer_1"],
      q["answer_2"],
      q["answer_3"],
      q["answer_4"]
    ];

    final arabicLetters = [AppLocalizations.of(context)?.choiceA ?? "أ", AppLocalizations.of(context)?.choiceB ?? "ب", AppLocalizations.of(context)?.choiceC ?? "ج", AppLocalizations.of(context)?.choiceD ?? "د"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: answersList
          .asMap()
          .entries
          .where((entry) => entry.value != null)
          .map((entry) {
        final index = entry.key;
        final ans = entry.value;
        final answerKey = "answer_${index + 1}";
        final isSelected = savedAnswer == answerKey;

        return GestureDetector(
          onTap: () => _saveAnswer(q["_id"], answerKey),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.getAnswerSelectedColor(isDark)
                  : isDark
                      ? Color(0XFF1D293D)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.sky(isDark)
                    : AppColors.getCardBorderColor(isDark),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.sky(isDark)
                          : AppColors.getInputBackgroundColor(isDark),
                      border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.getCardBorderColor(isDark))),
                  child: Text(
                    arabicLetters[index],
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.getTextColor(isDark)
                          : AppColors.getTextHintColor(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ans ?? "",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.getTextColor(isDark),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(Map<String, dynamic> q, dynamic savedAnswer) {
    final answersList = [
      AppLocalizations.of(context)!.trueValue,
      AppLocalizations.of(context)!.falseValue
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: answersList.map((ans) {
        final index = answersList.indexOf(ans);
        final answerKey = "answer_${index + 1}";
        final isSelected = savedAnswer == answerKey;
        return Expanded(
          child: GestureDetector(
            onTap: () => _saveAnswer(q["_id"], answerKey),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  ans,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.green[900] : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswer(Map<String, dynamic> q, dynamic savedAnswer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TextField(
            cursorColor: Colors.black,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14,
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterAnswerHint,
              border: const OutlineInputBorder(),
            ),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: savedAnswer is String ? savedAnswer : "",
                selection: TextSelection.collapsed(
                  offset: (savedAnswer is String ? savedAnswer.length : 0),
                ),
              ),
            ),
            onChanged: (val) => _saveAnswer(q["_id"], val),
          ),
        ),
      ),
    );
  }

  // ✅ FIX: now generates one field per blank (matching correctcomplete
  // length) and saves a List<String> instead of a single overwritten String.
  Widget _buildCompleteAnswer(Map<String, dynamic> q, dynamic savedAnswer) {
    final List correctAnswers = q["correctcomplete"] ?? [];
    final int length = correctAnswers.isEmpty ? 1 : correctAnswers.length;
    final List<String?>? saved = savedAnswer is List
        ? savedAnswer.map((e) => e?.toString()).toList()
        : null;
    final controllers = _controllersFor(q["_id"], length, saved);

    return Column(
      children: List.generate(length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: controllers[i],
            decoration: InputDecoration(
              hintText: length > 1
                  ? "${AppLocalizations.of(context)!.completeAnswerHint} ${i + 1}"
                  : AppLocalizations.of(context)!.completeAnswerHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => _saveMultiAnswer(q["_id"], i, val, length),
          ),
        );
      }),
    );
  }

  // ✅ FIX: now generates one field per blank (matching
  // dialoguecompletionSpaces length) and saves a List<String>.
  Widget _buildDialogueAnswer(Map<String, dynamic> q, dynamic savedAnswer) {
    final List spaces = q["dialoguecompletionSpaces"] ?? [];
    final int length = spaces.isEmpty ? 1 : spaces.length;
    final List<String?>? saved = savedAnswer is List
        ? savedAnswer.map((e) => e?.toString()).toList()
        : null;
    final controllers = _controllersFor(q["_id"], length, saved);

    return Column(
      children: List.generate(length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: controllers[i],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: length > 1
                  ? "${AppLocalizations.of(context)!.typeDialogueHint} ${i + 1}"
                  : AppLocalizations.of(context)!.typeDialogueHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => _saveMultiAnswer(q["_id"], i, val, length),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDark),
          border: Border(
              top: BorderSide(
                  color: AppColors.getCardBorderColor(isDark), width: 1))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            if (currentQuestion > 0)
              InkWell(
                onTap: () {
                  setState(() => currentQuestion--);
                },
                child: Container(
                    height: 56,
                    width: 180,
                    decoration: BoxDecoration(
                        color: AppColors.getBackgroundColor(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.getCardBorderColor(isDark),
                            width: 1)),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.previous,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextHintColor(isDark),
                        ),
                      ),
                    )),
              ),
            const Spacer(),
            InkWell(
              onTap: _isSubmitting
                  ? null
                  : () {
                      if (currentQuestion < widget.questions.length - 1) {
                        setState(() => currentQuestion++);
                      } else {
                        markQuizAndSubmit();
                      }
                    },
              child: Container(
                height: 56,
                width: 180,
                decoration: BoxDecoration(
                    color: AppColors.sky(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getCardBorderColor(isDark), width: 1)),
                child: Center(
                  child: _isSubmitting &&
                          currentQuestion == widget.questions.length - 1
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentQuestion == widget.questions.length - 1
                                  ? AppLocalizations.of(context)!.finish
                                  : AppLocalizations.of(context)!.next,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (currentQuestion ==
                                widget.questions.length - 1) ...[
                              const SizedBox(width: 4),
                              Icon(
                                PhosphorIconsRegular.checkCircle,
                                color: Colors.white,
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
