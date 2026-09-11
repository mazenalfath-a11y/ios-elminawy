import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter_version/l10n/app_localizations.dart';

class ExamReviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> studentAnswers;
  final bool isExercise;

  const ExamReviewPage({
    super.key,
    required this.questions,
    required this.studentAnswers,
    this.isExercise = false,
  });

  // ─── Helpers (same as original ExamResultPage) ────────────────────────────

  bool _isValidJson(dynamic data) {
    try {
      jsonDecode(data.toString());
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _getValidJson(dynamic data) {
    try {
      return jsonDecode(data.toString());
    } catch (_) {
      return data;
    }
  }

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

  // ─── Correctness check ────────────────────────────────────────────────────

  bool _isCorrect(Map<String, dynamic> q, dynamic answer) {
    final role = q["role"] ?? "choice";
    if (role == "boolean") return answer == q["correctBoolean"];
    if (role == "text") {
      final tries = [
        q["answer_1"],
        q["answer_2"],
        q["answer_3"],
        q["answer_4"]
      ];
      return tries.any((t) => _jaccardSimilarity(t, answer) > 0.7);
    }
    if (role == "correct") {
      final tries = [
        q["answer_1"],
        q["answer_2"],
        q["answer_3"],
        q["answer_4"]
      ].where((a) => a != null && a.toString().trim().isNotEmpty).toList();
      return tries.any((t) => _jaccardSimilarity(t, answer) == 1.0);
    }
    if (role == "dialogue") {
      final List completionSpaces = q["dialoguecompletionSpaces"] ?? [];
      final List<dynamic> userAnswers = answer is String
          ? List<String>.from(_getValidJson(answer))
          : (answer is List ? answer : []);
      return completionSpaces.asMap().entries.every((entry) {
        final List possible = entry.value;
        final given = entry.key < userAnswers.length
            ? userAnswers[entry.key].toString()
            : '';
        return possible.any((v) => _jaccardSimilarity(v, given) > 0.3);
      });
    }
    if (role == "complete") {
      final List correctAnswers = q["correctcomplete"] ?? [];
      final List<dynamic> userAnswers = answer is String
          ? List<String>.from(_getValidJson(answer))
          : (answer is List ? answer : []);
      return correctAnswers.asMap().entries.every((entry) {
        final given = entry.key < userAnswers.length
            ? userAnswers[entry.key].toString()
            : '';
        return _jaccardSimilarity(entry.value, given) == 1.0;
      });
    }
    return answer == q["correctChoice"];
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
              child: Row(
                children: [
                  // Back button
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
                            width: 1),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.arrowRight,
                        color: AppColors.getIconColor(isDark),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.reviewMistakesBtn ?? "مراجعة الأخطاء",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Question list ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(
                    context, questions[index], index, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Single question card ─────────────────────────────────────────────────

  Widget _buildQuestionCard(
    BuildContext context,
    Map<String, dynamic> q,
    int index,
    bool isDark,
  ) {
    final questionId = q["_id"]?.toString() ?? '';
    final role = q["role"] ?? "choice";
    final rawAnswer = studentAnswers[questionId];
    final answer = role == "choice" || role == "boolean"
        ? _isValidJson(rawAnswer)
            ? _getValidJson(rawAnswer)
            : rawAnswer
        : _getValidJson(rawAnswer);

    final bool correct = _isCorrect(q, answer);
    final double mark = (q["mark"] ?? 0).toDouble();

    final Color cardColor = correct
        ? AppColors.success.withOpacity(0.07)
        : AppColors.error.withOpacity(0.07);
    final Color accentColor = correct ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header: question number + result badge ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.questionIndex((index + 1).toString()) ?? "السؤال ${index + 1}",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextHintColor(isDark),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        correct
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsFill.xCircle,
                        textDirection: TextDirection.ltr,
                        color: accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        correct
                            ? '${mark.toInt()} / ${mark.toInt()}'
                            : '0 / ${mark.toInt()}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Optional image ───────────────────────────────────────────
          if (q["img"] != null && q["img"].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  q["img"],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

          // ── Question text ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              q["question"] ?? "",
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextColor(isDark),
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Divider(height: 1, color: accentColor.withOpacity(0.2)),
          ),

          // ── Your answer ──────────────────────────────────────────────
          _buildAnswerTile(
            context: context,
            label: AppLocalizations.of(context)!.yourAnswerLabel,
            value: _resolveDisplayAnswer(q, answer, context),
            color: accentColor,
            icon: correct
                ? PhosphorIconsFill.checkCircle
                : PhosphorIconsFill.xCircle,
            isDark: isDark,
          ),

          // ── Correct answer (only shown when wrong) ───────────────────
          if (!correct) ...[
            const SizedBox(height: 4),
            _buildAnswerTile(
              context: context,
              label: AppLocalizations.of(context)!.correctAnswerLabel,
              value: _resolveCorrectAnswer(q, context),
              color: AppColors.sky(isDark),
              icon: PhosphorIconsFill.lightbulb,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─── Answer tile ──────────────────────────────────────────────────────────

  Widget _buildAnswerTile({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.getTextHintColor(isDark),
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Icon(
            icon,
            color: color,
            size: 16,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ─── Display helpers ──────────────────────────────────────────────────────

  String _resolveDisplayAnswer(
      Map<String, dynamic> q, dynamic answer, BuildContext context) {
    if (answer == null) {
      return AppLocalizations.of(context)!.notAnswered;
    }
    final role = q["role"] ?? "choice";

    if (role == "choice" || role == "boolean" || role == "true_false") {
      final String raw = answer.toString().trim();
      return q[raw]?.toString() ?? raw;
    }

    if (role == "dialogue" || role == "complete") {
      final List<dynamic> list = answer is List
          ? answer
          : (answer is String ? _getValidJson(answer) : []);
      if (list is List) return list.join(' / ');
      return answer.toString();
    }

    return answer.toString();
  }

  String _resolveCorrectAnswer(Map<String, dynamic> q, BuildContext context) {
    final role = q["role"] ?? "choice";

    if (role == "choice") {
      final String key = (q["correctChoice"] ?? "").toString().trim();
      return q[key]?.toString() ??
          (key.isNotEmpty ? key : AppLocalizations.of(context)!.notAvailable);
    }
    if (role == "boolean" || role == "true_false") {
      final boolVal =
          q["correctBoolean"]?.toString() ?? q["correctChoice"]?.toString();
      if (boolVal == "answer_1" || boolVal == "true" || boolVal == "True") {
        return AppLocalizations.of(context)?.trueVal ?? "صح";
      }
      if (boolVal == "answer_2" || boolVal == "false" || boolVal == "False") {
        return AppLocalizations.of(context)?.falseVal ?? "خطأ";
      }
      return boolVal ?? AppLocalizations.of(context)!.notAvailable;
    }
    if (role == "text" || role == "correct") {
      final tries = [
        q["answer_1"],
        q["answer_2"],
        q["answer_3"],
        q["answer_4"]
      ].where((a) => a != null && a.toString().trim().isNotEmpty).toList();
      if (tries.isNotEmpty) {
        return tries.join(' / ');
      }
      return q["answer_1"]?.toString() ??
          AppLocalizations.of(context)!.notAvailable;
    }
    if (role == "complete") {
      final List list = q["correctcomplete"] ?? [];
      return list.join(' / ');
    }
    if (role == "dialogue") {
      final List spaces = q["dialoguecompletionSpaces"] ?? [];
      return spaces.map((s) => (s as List).first.toString()).join(' / ');
    }
    return AppLocalizations.of(context)!.notAvailable;
  }
}
