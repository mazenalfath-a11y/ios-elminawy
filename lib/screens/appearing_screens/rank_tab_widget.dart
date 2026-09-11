import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

class RankTabWidget extends StatefulWidget {
  final String courseId;

  const RankTabWidget({super.key, required this.courseId});

  @override
  State<RankTabWidget> createState() => _RankTabWidgetState();
}

class _RankTabWidgetState extends State<RankTabWidget> {
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;
  int? myScore;
  List<Map<String, dynamic>> top10 = [];

  @override
  void initState() {
    super.initState();
    _loadRankingData();
  }

  Future<void> _loadRankingData() async {
    try {
      final top10Res = await _apiService.request(
        "course_score/top10/${widget.courseId}",
        null,
        "GET",
      );
      final myScoreRes = await _apiService.request(
        "course_score/get_score/${widget.courseId}",
        null,
        "GET",
      );

      if (top10Res != null && top10Res.statusCode == 200) {
        final List data = top10Res.data;
        setState(() {
          top10 = List<Map<String, dynamic>>.from(data.map((entry) => {
                "rank": data.indexOf(entry) + 1,
                "name":
                    "${entry['student']['FirstName']} ${entry['student']['LastName']}",
                "score": entry['score'],
              }));
        });
      }

      if (myScoreRes != null &&
          myScoreRes.statusCode == 200 &&
          myScoreRes.data != null) {
        setState(() {
          myScore = myScoreRes.data['score'];
        });
      }
    } catch (e) {
      setState(() {
        // errorMessage = AppLocalizations.of(context)?.failedToLoadRank ?? "فشل تحميل بيانات الترتيب";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noRanksAvailable,
          style: GoogleFonts.cairo(
            color: AppColors.getTextSecondaryColor(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final int displayMyScore = myScore ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.getInputBackgroundColor(isDark),
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .yourCurrentPoints(displayMyScore),
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextColor(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.star, color: AppColors.warning),
                  ],
                ),
              ),
            ),
            // FIX: this list used to be wrapped in `Expanded`, but its parent
            // (this Column) sits inside a SingleChildScrollView, which gives
            // unbounded height — `Expanded` has nothing to expand into in
            // that context. That mismatch was what hung the tab. Since the
            // outer SingleChildScrollView already handles scrolling, this
            // list just needs to size itself to its content instead of
            // trying to scroll/expand independently.
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: top10.length,
              itemBuilder: (context, index) {
                final student = top10[index];
                Widget rankIcon;
                if (index == 0) {
                  rankIcon = const Icon(Icons.emoji_events,
                      color: AppColors.amber, size: 22);
                } else if (index == 1) {
                  rankIcon = const Icon(Icons.emoji_events,
                      color: AppColors.grey, size: 22);
                } else if (index == 2) {
                  rankIcon = const Icon(Icons.emoji_events,
                      color: AppColors.bronze, size: 22);
                } else {
                  rankIcon = const SizedBox.shrink();
                }
                return Card(
                  color: AppColors.getInputBackgroundColor(isDark),
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.sky(isDark),
                          child: Text(
                            student['rank'].toString(),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(top: -2, right: -2, child: rankIcon),
                      ],
                    ),
                    title: Text(
                      student['name'] ?? '',
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextColor(isDark),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    trailing: Text(
                      student['score'].toString(),
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextColor(isDark),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
