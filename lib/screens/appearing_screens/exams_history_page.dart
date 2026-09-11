import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/theme_helper.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_version/utilities/app_colors.dart';
import 'exampage_insides/exam_result_page.dart';
import '../../l10n/app_localizations.dart';

class ExamsHistoryPage extends StatefulWidget {
  const ExamsHistoryPage({Key? key}) : super(key: key);

  @override
  State<ExamsHistoryPage> createState() => _ExamsHistoryPageState();
}

class _ExamsHistoryPageState extends State<ExamsHistoryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExamsHistory();
  }

  Future<void> _fetchExamsHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.request(
        "student/exam/get_all_studentresults_for_student",
        null,
        "GET",
      );
      print(response?.data);
      if (response != null && response.statusCode == 200) {
        _exams = List<Map<String, dynamic>>.from(response.data ?? []);
        _exams.removeWhere((exam) => exam['examname'] == 'exerciseinvideo');
      }
    } catch (e) {
      debugPrint("❌ Error fetching exams history: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.examsResults,
            style: GoogleFonts.cairo()),
        backgroundColor: AppColors.getBackgroundColor(isDark),
        foregroundColor: AppColors.getTextColor(isDark),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeHelper.getShadowColor(context),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.getBackgroundColor(isDark),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            "assets/images/Exams.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _exams.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.noExamsResultsYet,
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: AppColors.getTextColor(isDark)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            final exam = _exams[index];

                            if (exam["examname"] == "01010101") {
                              return const SizedBox.shrink();
                            }

                            final String title =
                                (exam["examname"] == "single_exam")
                                    ? AppLocalizations.of(context)!.generalExam
                                    : (exam["examname"] ??
                                        AppLocalizations.of(context)!.test);

                            return Card(
                              color: AppColors.getCardBackgroundColor(isDark),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.getTextColor(
                                                    isDark)),
                                            textAlign: TextAlign.right,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .yourScoreLabel(
                                                    exam["result"] ?? "-"),
                                            style: GoogleFonts.cairo(
                                              color: AppColors.sky(isDark),
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.sky(isDark),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ExamResultPage(
                                                examId: exam["exam_Id"] ??
                                                    exam["_id"],
                                                title: title,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.details,
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
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
              ],
            ),
    );
  }
}
