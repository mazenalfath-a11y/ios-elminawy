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
  final setA = Set.of(expandContractions(a).toLowerCase().split(RegExp(r'\W+'))
    ..removeWhere((e) => e.isEmpty));
  final setB = Set.of(expandContractions(b).toLowerCase().split(RegExp(r'\W+'))
    ..removeWhere((e) => e.isEmpty));

  final intersection = setA.intersection(setB).length;
  final union = setA.union(setB).length;

  if (union == 0) return 0.0;
  return intersection / union;
}

/// Result of grading a set of questions against student answers.
class GradeResult {
  final double score;
  final double maxMark;
  const GradeResult({required this.score, required this.maxMark});

  int get percentage => maxMark > 0 ? (score / maxMark * 100).round() : 0;
}

bool _isValidJson(dynamic data) {
  try {
    // ignore: unnecessary_import
    return true;
  } catch (_) {
    return false;
  }
}

/// Grades [questions] against a map of {questionId: rawAnswer}.
/// Mirrors the exact logic from ExamResultPage._fetchResults.
GradeResult gradeQuestions(
  List<Map<String, dynamic>> questions,
  Map<String, dynamic> studentAnswers,
) {
  double score = 0;
  double maxMark = 0;

  for (final q in questions) {
    final role = q["role"] ?? "choice";
    final questionId = q["_id"]?.toString() ?? '';
    final double qMark = (q["mark"] ?? 1).toDouble();
    maxMark += qMark;
    final answer = studentAnswers[questionId];

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
      isCorrect = jaccardSimilarity(q["answer_1"], answer) == 1.0;
    } else if (role == "dialogue") {
      final List completionSpaces = q["dialoguecompletionSpaces"] ?? [];
      final List<dynamic> userAnswers =
          answer is List ? answer : (answer == null ? [] : [answer]);
      final double spaceMark =
          completionSpaces.isEmpty ? 0 : qMark / completionSpaces.length;
      for (int i = 0; i < completionSpaces.length; i++) {
        final List possible = completionSpaces[i];
        final given = i < userAnswers.length ? userAnswers[i].toString() : '';
        for (final validAns in possible) {
          if (jaccardSimilarity(validAns, given) > 0.3) {
            score += spaceMark;
            break;
          }
        }
      }
      continue;
    } else if (role == "complete") {
      final List correctAnswers = q["correctcomplete"] ?? [];
      final List<dynamic> userAnswers =
          answer is List ? answer : (answer == null ? [] : [answer]);
      final double spaceMark =
          correctAnswers.isEmpty ? 0 : qMark / correctAnswers.length;
      for (int i = 0; i < correctAnswers.length; i++) {
        final expected = correctAnswers[i];
        final given = i < userAnswers.length ? userAnswers[i].toString() : '';
        if (jaccardSimilarity(expected, given) == 1.0) {
          score += spaceMark;
        }
      }
      continue;
    } else {
      isCorrect = answer == q["correctChoice"];
    }

    if (isCorrect) score += qMark;
  }

  return GradeResult(score: score, maxMark: maxMark);
}
