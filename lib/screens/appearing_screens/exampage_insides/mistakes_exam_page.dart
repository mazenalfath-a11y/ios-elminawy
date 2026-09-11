import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

/// A "review your mistakes" exam page.
///
/// Unlike [ExamStartPage], this is NOT a scheduled/real exam:
/// - No countdown, no server-time sync, no start/end window — just a
///   count-up stopwatch so the user can see how long they took.
/// - Finishing does NOT touch score/XP endpoints.
/// - It best-effort notifies the backend which mistakes were answered
///   correctly this time (so they can be flagged as "resolved"), but the
///   mistakes are intentionally NOT removed from the bank here.
class MistakesExamPage extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const MistakesExamPage({Key? key, required this.questions}) : super(key: key);

  @override
  State<MistakesExamPage> createState() => _MistakesExamPageState();
}

class _MistakesExamPageState extends State<MistakesExamPage> {
  final ApiService _apiService = ApiService();
  late Timer _stopwatchTimer;
  int elapsedSeconds = 0;

  int currentQuestion = 0;
  late List<Map<String, dynamic>> shuffledQuestions;
  final Map<String, dynamic> answers = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    shuffledQuestions = [...widget.questions]..shuffle();
    _startStopwatch();
  }

  @override
  void dispose() {
    _stopwatchTimer.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => elapsedSeconds++);
    });
  }

  void _saveAnswer(String questionId, dynamic answerKey) {
    setState(() => answers[questionId] = answerKey);
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

  // ─── Grading helpers (same logic as ExamStartPage) ──────────────────

  String _expandContractions(String? input) {
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

  double _jaccardSimilarity(String? a, String? b) {
    final setA = Set.of(
        _expandContractions(a).toLowerCase().split(RegExp(r'\W+'))
          ..removeWhere((e) => e.isEmpty));
    final setB = Set.of(
        _expandContractions(b).toLowerCase().split(RegExp(r'\W+'))
          ..removeWhere((e) => e.isEmpty));
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
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

  // ─── Finish flow ─────────────────────────────────────────────────────

  void _handleFinishTap() {
    if (_isSubmitting) return;
    final unanswered = _unansweredIndexes;
    if (unanswered.isNotEmpty) {
      _confirmFinishWithUnanswered(unanswered);
    } else {
      _finishAndShowResults();
    }
  }

  void _confirmFinishWithUnanswered(List<int> unanswered) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)?.questionsRemainingTitle ?? "لسه فيه أسئلة متبقية",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: AppColors.getTextColor(isDark)),
          textAlign: TextAlign.right,
        ),
        content: Text(
          AppLocalizations.of(context)?.unansweredQuestionsOpt(unanswered.length.toString()) ?? "لسه محلتش ${unanswered.length} سؤال. تقدر تكمل أو تسلم اللي حليته بس.",
          style: GoogleFonts.cairo(color: AppColors.getTextHintColor(isDark)),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => currentQuestion = unanswered.first);
            },
            child: Text(
                AppLocalizations.of(context)?.goToFirstUnansweredQuestion ??
                    AppLocalizations.of(context)?.goToFirstMissingQ ?? "روح لأول سؤال ناقص",
                style: GoogleFonts.cairo(
                    color: AppColors.sky(isDark), fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishAndShowResults();
            },
            child: Text(
                AppLocalizations.of(context)?.submitNow ?? AppLocalizations.of(context)?.submitNowBtn ?? "سلم دلوقتي",
                style: GoogleFonts.cairo(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishAndShowResults() async {
    setState(() => _isSubmitting = true);
    _stopwatchTimer.cancel();

    final List<Map<String, dynamic>> resolvedResults = [];
    int correctCount = 0;

    for (final q in shuffledQuestions) {
      final questionId = q["_id"];
      final role = q["role"] ?? "choice";
      final answer = answers[questionId];
      bool isCorrect = false;

      if (answer == null) {
        isCorrect = false;
      } else if (role == "boolean" || role == "true_false") {
        isCorrect = answer == q["correctBoolean"];
      } else if (role == "text") {
        final tries = [
          q["answer_1"],
          q["answer_2"],
          q["answer_3"],
          q["answer_4"]
        ];
        isCorrect = tries.any((t) => _jaccardSimilarity(t, answer) > 0.7);
      } else if (role == "correct") {
        final tries = [
          q["answer_1"],
          q["answer_2"],
          q["answer_3"],
          q["answer_4"]
        ].where((a) => a != null && a.toString().trim().isNotEmpty).toList();
        isCorrect = tries.any((t) => _jaccardSimilarity(t, answer) == 1);
      } else if (role == "complete") {
        final List correctAnswers = q["correctcomplete"] ?? [];
        bool allCorrect = correctAnswers.isNotEmpty;
        for (int i = 0; i < correctAnswers.length; i++) {
          final ansAtI =
              (answer is List && i < answer.length) ? answer[i] : null;
          if (_jaccardSimilarity(correctAnswers[i], ansAtI) != 1)
            allCorrect = false;
        }
        isCorrect = allCorrect;
      } else if (role == "dialogue") {
        final List spaces = q["dialoguecompletionSpaces"] ?? [];
        bool allCorrect = spaces.isNotEmpty;
        for (int i = 0; i < spaces.length; i++) {
          final List possible = spaces[i];
          final ansAtI =
              (answer is List && i < answer.length) ? answer[i] : null;
          if (!possible.any((v) => _jaccardSimilarity(v, ansAtI) > 0.3))
            allCorrect = false;
        }
        isCorrect = allCorrect;
      } else {
        isCorrect = answer == q["correctChoice"];
      }

      if (isCorrect) correctCount++;
      resolvedResults.add({"questionId": questionId, "isCorrect": isCorrect});
    }

    // Best-effort: tell the backend which mistakes were answered correctly
    // this time so they can be flagged as "resolved". This does NOT remove
    // them from the mistakes bank and does NOT affect score/XP.
    // TODO: confirm the real endpoint path/shape with your backend.
    try {
      await _apiService.request(
        "student/mistakes-bank/mark-resolved",
        {"results": resolvedResults},
        "POST",
      );
    } catch (e) {
      debugPrint("❌ Error marking mistakes resolved: $e");
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showResultsSheet(correctCount, resolvedResults);
  }

  void _showResultsSheet(int correctCount, List<Map<String, dynamic>> results) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final total = shuffledQuestions.length;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: AppColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Icon(
                  correctCount == total
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsFill.chartBar,
                  color: AppColors.sky(isDark),
                  size: 48,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)?.solvedCorrectXOfY(correctCount.toString(), total.toString()) ?? "حليت صح $correctCount من $total",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark)),
              ),
              Text(
                AppLocalizations.of(context)?.timeSpentFormat(_formatTime(elapsedSeconds).toString()) ?? "الوقت المستغرق: ${_formatTime(elapsedSeconds)}",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.getTextHintColor(isDark)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: shuffledQuestions.length,
                  itemBuilder: (ctx, i) {
                    final q = shuffledQuestions[i];
                    final isCorrect = results[i]["isCorrect"] == true;
                    return Card(
                      color: AppColors.getCardBackgroundColor(isDark),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: AppColors.getCardBorderColor(isDark)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? PhosphorIconsFill.checkCircle
                                  : PhosphorIconsFill.xCircle,
                              textDirection: TextDirection.ltr,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q["question"] ?? "",
                                style: GoogleFonts.cairo(
                                    color: AppColors.getTextColor(isDark),
                                    fontSize: 13),
                                textAlign: TextAlign.right,
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // close sheet
                  Navigator.pop(context); // close exam page, back to Exams
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sky(isDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)?.done ?? AppLocalizations.of(context)?.doneBtn ?? "تم",
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (shuffledQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        body: Center(
          child: Text(
              AppLocalizations.of(context)?.noQuestionsToReview ??
                  AppLocalizations.of(context)?.noQuestionsToReview ?? "مفيش أسئلة للمراجعة",
              style: GoogleFonts.cairo(color: AppColors.getTextColor(isDark))),
        ),
      );
    }

    final numberOfQuestions = shuffledQuestions.length;
    final currentQuestionNow = currentQuestion + 1;
    final int progressPercent =
        ((currentQuestionNow / numberOfQuestions) * 100).round();
    final isLast = currentQuestion == shuffledQuestions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.getBackgroundColor(isDark),
              border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1D293D)
                        : const Color(0xFFF1F5F9),
                    width: 2),
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
                        onTap:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.getBackgroundColor(isDark),
                            border: Border.all(
                                color: AppColors.getCardBorderColor(isDark),
                                width: 1),
                          ),
                          child: Icon(PhosphorIconsRegular.x,
                              color: AppColors.getIconColor(isDark), size: 20),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.reviewMistakesBtn ?? "مراجعة الأخطاء",
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        height: 36,
                        constraints: const BoxConstraints(minWidth: 90),
                        decoration: BoxDecoration(
                          color: AppColors.sky(isDark).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.sky(isDark).withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsFill.timer,
                                  color: AppColors.sky(isDark),
                                  textDirection: TextDirection.ltr),
                              const SizedBox(width: 4),
                              Text(_formatTime(elapsedSeconds),
                                  style: GoogleFonts.cairo(
                                      color: AppColors.sky(isDark),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
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
                      Text(AppLocalizations.of(context)?.qXOfY(currentQuestionNow.toString(), numberOfQuestions.toString()) ?? "سؤال $currentQuestionNow من $numberOfQuestions",
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getSecondHintColor(isDark))),
                      Text(AppLocalizations.of(context)?.progressPercentDone(progressPercent.toString()) ?? "تم إنجاز $progressPercent%",
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky(isDark))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: currentQuestionNow / numberOfQuestions,
                    backgroundColor: AppColors.getCircleBackgroundColor(isDark),
                    color: AppColors.sky(isDark),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(child: _buildQuestionCard(isDark))),
          _buildQuestionCircles(isDark),
          _buildNavigationButtons(isDark, isLast),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    final q = shuffledQuestions[currentQuestion];
    final questionId = q["_id"];
    final role = q["role"] ?? "choice";
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
                color: AppColors.getTextColor(isDark)),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 24),
          if (role == "choice")
            _buildChoiceAnswers(q, savedAnswer, isDark),
          if (role == "true_false" || role == "boolean")
            _buildTrueFalse(q, savedAnswer, isDark),
          if (role == "text" || role == "correct") _buildTextAnswer(q, savedAnswer, isDark),
          if (role == "complete") _buildCompleteAnswer(q, savedAnswer, isDark),
          if (role == "dialogue") _buildDialogueAnswer(q, savedAnswer, isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceAnswers(
      Map<String, dynamic> q, dynamic savedAnswer, bool isDark) {
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
          .where((entry) =>
              entry.value != null && entry.value.toString().isNotEmpty)
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
                            : AppColors.getCardBorderColor(isDark)),
                  ),
                  child: Text(
                    arabicLetters[index],
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.getTextColor(isDark)
                            : AppColors.getTextHintColor(isDark)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ans ?? "",
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(isDark)),
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

  Widget _buildTrueFalse(
      Map<String, dynamic> q, dynamic savedAnswer, bool isDark) {
    final answersList = [AppLocalizations.of(context)?.trueVal ?? "صح", AppLocalizations.of(context)?.wrongChoice ?? "غلط"];

    return Row(
      children: answersList.asMap().entries.map((entry) {
        final index = entry.key;
        final ans = entry.value;
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
                      color: AppColors.getTextColor(isDark)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswer(
      Map<String, dynamic> q, dynamic savedAnswer, bool isDark) {
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
              color: AppColors.getTextColor(isDark), fontSize: 14),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.typeAnswerHere ?? "اكتب إجابتك هنا",
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

  Widget _buildCompleteAnswer(
      Map<String, dynamic> q, dynamic savedAnswer, bool isDark) {
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
              color: AppColors.getTextColor(isDark), fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.completeSentence ?? "أكمل الجملة",
            hintStyle: TextStyle(color: AppColors.getTextHintColor(isDark)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (val) => _saveAnswer(q["_id"], val),
        ),
      ),
    );
  }

  Widget _buildDialogueAnswer(
      Map<String, dynamic> q, dynamic savedAnswer, bool isDark) {
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
              color: AppColors.getTextColor(isDark), fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.typeDialogue ?? "اكتب الحوار",
            hintStyle: TextStyle(color: AppColors.getTextHintColor(isDark)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (val) => _saveAnswer(q["_id"], val),
        ),
      ),
    );
  }

  Widget _buildQuestionCircles(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: AppColors.getCardBorderColor(isDark), width: 1))),
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

  Widget _buildNavigationButtons(bool isDark, bool isLast) {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(isDark),
        border: Border(
            top: BorderSide(
                color: AppColors.getCardBorderColor(isDark), width: 1)),
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
                        color: AppColors.getCardBorderColor(isDark), width: 1),
                  ),
                  child: Center(
                    child: Text(
                        AppLocalizations.of(context)?.previous ?? AppLocalizations.of(context)?.previousBtn ?? "السابق",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextHintColor(isDark))),
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
                      color: AppColors.getCardBorderColor(isDark), width: 1),
                ),
                child: Center(
                  child: _isSubmitting && isLast
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLast ? AppLocalizations.of(context)?.finishBtn ?? "إنهاء" : AppLocalizations.of(context)?.nextBtn ?? "التالي",
                                style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            if (isLast) ...[
                              const SizedBox(width: 4),
                              const Icon(PhosphorIconsRegular.checkCircle,
                                  color: Colors.white,
                                  textDirection: TextDirection.ltr),
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
