import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_version/l10n/app_localizations.dart';

class ExamStartPage extends StatefulWidget {
  final String examId;
  final String courseId;
  final String title;
  final int duration; // in minutes
  final String endTime; // fallback if no startTime (legacy)
  final List<Map<String, dynamic>> questions;
  final String? startTime; // from new endpoint
  final bool hasDuration; // if true, use startTime + duration

  const ExamStartPage({
    super.key,
    required this.examId,
    required this.courseId,
    required this.title,
    required this.duration,
    required this.endTime,
    required this.questions,
    this.startTime,
    this.hasDuration = true,
  });

  @override
  State<ExamStartPage> createState() => _ExamStartPageState();
}

class _ExamStartPageState extends State<ExamStartPage>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  late Timer _timer;
  Timer? _examDurationTimer;

  int currentQuestion = 0;
  int remainingSeconds = 0;
  int _examDurationMinutes = 0;
  late List<Map<String, dynamic>> shuffledQuestions;
  late List<String> originalOrder;
  Map<String, dynamic> answers = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    originalOrder = widget.questions.map((q) => q["_id"] as String).toList();
    shuffledQuestions = [...widget.questions]..shuffle();

    getServerTime().then((serverNow) {
      if (serverNow == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failedToFetchServerTime)));
        return;
      }
      _loadSavedData(serverNow).then((_) {
        if (remainingSeconds <= 0) {
          markQuizAndSubmit();
        } else {
          _startTimer();
          _startExamDurationTimer();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _examDurationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();

    if (state == AppLifecycleState.paused) {
      prefs.setInt(
          "pausedTime_${widget.examId}", DateTime.now().millisecondsSinceEpoch);
    } else if (state == AppLifecycleState.resumed) {
      final pausedMillis = prefs.getInt("pausedTime_${widget.examId}");
      if (pausedMillis != null) {
        final pausedTime = DateTime.fromMillisecondsSinceEpoch(pausedMillis);
        final serverNow = await getServerTime();
        if (serverNow != null) {
          final timeOutside = serverNow.difference(pausedTime).inSeconds;
          setState(() {
            remainingSeconds -= timeOutside;
            if (remainingSeconds < 0) remainingSeconds = 0;
          });
        }
        prefs.remove("pausedTime_${widget.examId}");
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
        _saveCurrentState();
      } else {
        markQuizAndSubmit();
      }
    });
  }

  void _startExamDurationTimer() {
    _examDurationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() => _examDurationMinutes++);
      _saveCurrentState();
    });
  }

  String get _storageKey => "exam_${widget.examId}_data";

  Future<void> _loadSavedData(DateTime serverNow) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    int calculatedRemaining;
    if (widget.hasDuration) {
      // ✅ FIX: previously required `hasDuration && startTime != null`.
      // If the start-session endpoint failed or didn't return startTime,
      // hasDuration stayed true but startTime was null, so this silently
      // fell through to the `endTime` branch below and counted down to
      // the exam's overall end (days away) instead of the real duration
      // (minutes). Now hasDuration alone decides which countdown mode to
      // use, and if startTime is missing we just start the clock from
      // the current server time instead of losing the duration entirely.
      final DateTime start = widget.startTime != null
          ? DateTime.parse(widget.startTime!)
          : serverNow;
      final elapsed = serverNow.difference(start).inSeconds;
      calculatedRemaining = (widget.duration * 60) - elapsed;
    } else {
      final end = DateTime.parse(widget.endTime);
      calculatedRemaining = end.difference(serverNow).inSeconds;
    }
    if (calculatedRemaining < 0) calculatedRemaining = 0;

    if (saved != null) {
      final decoded = json.decode(saved);
      setState(() {
        currentQuestion = decoded["currentQuestion"] ?? 0;
        remainingSeconds = calculatedRemaining;
        _examDurationMinutes = decoded["examDurationMinutes"] ?? 0;
        answers = Map<String, dynamic>.from(decoded["answers"] ?? {});
      });
    } else {
      setState(() {
        remainingSeconds = calculatedRemaining;
        _examDurationMinutes = 0;
        currentQuestion = 0;
        answers = {};
      });
    }
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      "currentQuestion": currentQuestion,
      "remainingSeconds": remainingSeconds,
      "examDurationMinutes": _examDurationMinutes,
      "answers": answers,
    };
    prefs.setString(_storageKey, json.encode(data));
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_storageKey);
  }

  Future<DateTime?> getServerTime() async {
    try {
      final res =
          await _apiService.request("student/exam/time/now", null, "GET");
      if (res?.statusCode == 200 && res?.data["serverTime"] != null) {
        return DateTime.parse(res?.data["serverTime"]);
      }
    } catch (e) {
      print("${AppLocalizations.of(context)!.failedToFetchServerTime}: $e");
    }
    return null;
  }

  void _saveAnswer(String questionId, dynamic answerKey) {
    setState(() => answers[questionId] = answerKey);
    _saveCurrentState();
  }

  List<int> get _unansweredIndexes {
    final list = <int>[];
    for (int i = 0; i < shuffledQuestions.length; i++) {
      if (!answers.containsKey(shuffledQuestions[i]["_id"])) {
        list.add(i);
      }
    }
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

  void _handleFinishTap() {
    if (_isSubmitting) return;
    final unanswered = _unansweredIndexes;
    if (unanswered.isNotEmpty) {
      _showMustAnswerAllDialog(unanswered);
      return;
    }
    _confirmAndSubmit();
  }

  void _showMustAnswerAllDialog(List<int> unanswered) {
    final ThemeProvider themeProvider =
        Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)?.questionsRemainingTitle ?? "لسه فيه أسئلة متبقية",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(isDark),
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          AppLocalizations.of(context)?.mustAnswerAllQuestions(unanswered.length.toString()) ?? "لازم تحل كل الأسئلة قبل ما تقدر تسلم الامتحان.\nباقيلك ${unanswered.length} سؤال لسه محلتوش.",
          style: GoogleFonts.cairo(color: AppColors.getTextHintColor(isDark)),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.okBtn ?? "حسناً",
              style: GoogleFonts.cairo(
                color: AppColors.getTextHintColor(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => currentQuestion = unanswered.first);
            },
            child: Text(
              AppLocalizations.of(context)?.goToFirstMissingQ ?? "روح لأول سؤال ناقص",
              style: GoogleFonts.cairo(
                color: AppColors.sky(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    final ThemeProvider themeProvider =
        Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)?.submitExamBtn ?? "تسليم الامتحان",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(isDark),
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          AppLocalizations.of(context)?.confirmSubmitExam ?? "هل أنت متأكد إنك عايز تسلم الامتحان دلوقتي؟",
          style: GoogleFonts.cairo(color: AppColors.getTextHintColor(isDark)),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of(context)?.goBackBtn ?? "رجوع",
              style: GoogleFonts.cairo(
                color: AppColors.getTextHintColor(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)?.submitBtn ?? "تسليم",
              style: GoogleFonts.cairo(
                color: AppColors.sky(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await markQuizAndSubmit();
    }
  }

  Future<void> markQuizAndSubmit() async {
    if (_isSubmitting) return;
    if (mounted) setState(() => _isSubmitting = true);

    _timer.cancel();
    _examDurationTimer?.cancel();

    double mark = 0;
    double totalMark = 0;
    int correct = 0;
    int wrong = 0;
    List<Map<String, dynamic>> result = [];

    for (final id in originalOrder) {
      final q = widget.questions.firstWhere((e) => e["_id"] == id);
      final role = q["role"];
      final questionId = q["_id"];
      final String? questionRefranceId = q["refrence_id"] as String?;
      final double qMark = (q["mark"] ?? 1).toDouble();
      totalMark += qMark;
      final answer = answers[questionId];
      bool isCorrect = false;

      if (role == "boolean") {
        if (answer == q["correctBoolean"]) isCorrect = true;
      } else if (role == "text") {
        final tries = [
          q["answer_1"],
          q["answer_2"],
          q["answer_3"],
          q["answer_4"]
        ];
        if (tries.any((t) => jaccardSimilarity(t, answer) > 0.7))
          isCorrect = true;
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
        final List completionSpaces = q["dialoguecompletionSpaces"] ?? [];
        final double spaceMark = qMark / completionSpaces.length;
        for (int i = 0; i < completionSpaces.length; i++) {
          final List possible = completionSpaces[i];
          for (final validAns in possible) {
            if (jaccardSimilarity(validAns, answer[i]) > 0.3) {
              mark += spaceMark;
              correct++;
              break;
            } else {
              wrong++;
            }
          }
        }
        continue;
      } else if (role == "complete") {
        final List correctAnswers = q["correctcomplete"] ?? [];
        final double spaceMark = qMark / correctAnswers.length;
        for (int i = 0; i < correctAnswers.length; i++) {
          if (jaccardSimilarity(correctAnswers[i], answer[i]) == 1) {
            mark += spaceMark;
            correct++;
          } else {
            wrong++;
          }
        }
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
        "answer": answer is String ? answer : answer.toString(),
      });
    }

    final score = (mark / totalMark * 10).ceil();
    final data = {
      "exam_id": widget.examId,
      "Answers": result,
      "student_mark": mark,
      "totalmark": totalMark,
      "correctanswer": correct,
      "wronganswer": wrong,
      "examname": widget.title,
      "timeConsume": _examDurationMinutes,
    };

    final endpoint = widget.courseId == "0011223344"
        ? "student/exam/single_sumbit"
        : "student/exam/sumbit/${widget.courseId}";

    final res = await _apiService.request(endpoint, data, "POST");
    if (res?.statusCode == 200) {
      await _apiService.request("score/add_score", {"score": score}, "POST");
    }
    if (res?.statusCode == 200 && widget.courseId != "0011223344") {
      await _apiService.request("course_score/add_score",
          {"score": score, "courseId": widget.courseId}, "POST");
    }

    await _clearSavedState();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("pausedTime_${widget.examId}");

    if (mounted) {
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
    }
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
    final int numberOfQuestion = shuffledQuestions.length;
    final int currentQuestionNow = currentQuestion + 1;
    final int progressPercent =
        ((currentQuestionNow / numberOfQuestion) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDark),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF1D293D)
                          : const Color(0xFFF1F5F9),
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 52, right: 20, left: 20, bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.getBackgroundColor(isDark),
                                border: Border.all(
                                  color: AppColors.getCardBorderColor(isDark),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                PhosphorIconsRegular.x,
                                color: AppColors.getIconColor(isDark),
                                size: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextColor(isDark),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            height: 36,
                            constraints: const BoxConstraints(minWidth: 107),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFFB2C36).withOpacity(0.1)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFB2C36).withOpacity(0.2)
                                    : const Color(0xFFFFE2E2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    PhosphorIconsFill.timer,
                                    textDirection: TextDirection.ltr,
                                    color: Color(0xFFE7000B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(remainingSeconds),
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFFE7000B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.questionXOfY(
                                currentQuestionNow.toString(), numberOfQuestion.toString()),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getSecondHintColor(isDark),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)?.progressPercentDone(progressPercent.toString()) ?? "تم إنجاز $progressPercent%",
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildProgressBar(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(child: _buildQuestionCard()),
              ),
              _buildQuestionCircles(),
              _buildNavigationButtons(),
            ],
          ),
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: AppColors.getBackgroundColor(isDark).withOpacity(0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sky(isDark).withOpacity(0.1),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.sky(isDark),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)?.submittingExam ?? "جاري تسليم الامتحان...",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)?.dontCloseApp ?? "من فضلك متقفلش التطبيق",
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextHintColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final progress = (currentQuestion + 1) / shuffledQuestions.length;
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

    if (shuffledQuestions.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noQuestions,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(isDark),
          ),
        ),
      );
    }

    final q = shuffledQuestions[currentQuestion];
    final questionId = q["_id"];
    final role = q["role"];
    final savedAnswer = answers[questionId];

    return Padding(
      padding: const EdgeInsets.only(top: 24, right: 20, left: 20),
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
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(''),
                  ),
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
          if (role == "true_false") _buildTrueFalse(q, savedAnswer),
          if (role == "text" || role == "correct") _buildTextAnswer(q, savedAnswer),
          if (role == "complete") _buildCompleteAnswer(q, savedAnswer),
          if (role == "dialogue") _buildDialogueAnswer(q, savedAnswer),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceAnswers(Map<String, dynamic> q, String? savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final answersList = [
      q["answer_1"],
      q["answer_2"],
      q["answer_3"],
      q["answer_4"],
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
                      ? const Color(0xFF1D293D)
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
                          : AppColors.getCardBorderColor(isDark),
                    ),
                  ),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextColor(isDark),
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

  Widget _buildTrueFalse(Map<String, dynamic> q, String? savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final answersList = [
      AppLocalizations.of(context)!.trueValue,
      AppLocalizations.of(context)!.falseValue,
    ];

    return Row(
      children: answersList.map((ans) {
        final index = answersList.indexOf(ans);
        final answerKey = "answer_${index + 1}";
        final isSelected = savedAnswer == answerKey;

        return Expanded(
          child: GestureDetector(
            onTap: () => _saveAnswer(q["_id"], answerKey),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.getAnswerSelectedColor(isDark)
                    : isDark
                        ? const Color(0xFF1D293D)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.sky(isDark)
                      : AppColors.getCardBorderColor(isDark),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  ans,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswer(Map<String, dynamic> q, String? savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          style: GoogleFonts.cairo(
            color: AppColors.getTextColor(isDark),
            fontSize: 14,
          ),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterAnswerHint,
            hintStyle: TextStyle(color: AppColors.getTextHintColor(isDark)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: savedAnswer ?? "",
              selection:
                  TextSelection.collapsed(offset: (savedAnswer ?? "").length),
            ),
          ),
          onChanged: (val) => _saveAnswer(q["_id"], val),
        ),
      ),
    );
  }

  Widget _buildCompleteAnswer(Map<String, dynamic> q, String? savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: TextEditingController(text: savedAnswer),
          style: GoogleFonts.cairo(
            color: AppColors.getTextColor(isDark),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.completeAnswerHint,
            hintStyle: TextStyle(color: AppColors.getTextHintColor(isDark)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (val) => _saveAnswer(q["_id"], val),
        ),
      ),
    );
  }

  Widget _buildDialogueAnswer(Map<String, dynamic> q, String? savedAnswer) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: TextEditingController(text: savedAnswer),
          maxLines: 4,
          style: GoogleFonts.cairo(
            color: AppColors.getTextColor(isDark),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.typeDialogueHint,
            hintStyle: TextStyle(color: AppColors.getTextHintColor(isDark)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (val) => _saveAnswer(q["_id"], val),
        ),
      ),
    );
  }

  Widget _buildQuestionCircles() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.getCardBorderColor(isDark),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: shuffledQuestions.length,
        itemBuilder: (context, index) {
          final isAnswered =
              answers.containsKey(shuffledQuestions[index]["_id"]);
          final isCurrent = index == currentQuestion;

          return GestureDetector(
            onTap: _isSubmitting
                ? null
                : () => setState(() => currentQuestion = index),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.sky(isDark)
                    : isAnswered
                        ? AppColors.sky(isDark).withOpacity(0.2)
                        : AppColors.getCircleBackgroundColor(isDark),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.sky(isDark)
                      : isAnswered
                          ? AppColors.sky(isDark)
                          : AppColors.getCardBorderColor(isDark),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                            ? AppColors.sky(isDark)
                            : AppColors.getTextHintColor(isDark),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isLast = currentQuestion == shuffledQuestions.length - 1;

    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getCardBorderColor(isDark),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (currentQuestion > 0)
              InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => currentQuestion--),
                child: Container(
                  height: 56,
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppColors.getBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getCardBorderColor(isDark),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.previous,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextHintColor(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            InkWell(
              onTap: _isSubmitting
                  ? null
                  : () {
                      if (!isLast) {
                        setState(() => currentQuestion++);
                      } else {
                        _handleFinishTap();
                      }
                    },
              child: Container(
                height: 56,
                width: 160,
                decoration: BoxDecoration(
                  color: AppColors.sky(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getCardBorderColor(isDark),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast
                            ? AppLocalizations.of(context)!.finish
                            : AppLocalizations.of(context)!.next,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (isLast) ...[
                        const SizedBox(width: 4),
                        const Icon(
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
