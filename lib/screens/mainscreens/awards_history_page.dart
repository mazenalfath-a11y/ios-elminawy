import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

class AwardsHistoryPage extends StatefulWidget {
  const AwardsHistoryPage({Key? key}) : super(key: key);

  @override
  State<AwardsHistoryPage> createState() => _AwardsHistoryPageState();
}

class _AwardsHistoryPageState extends State<AwardsHistoryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  int _studentScore = 0;
  int _firstPlaceCount = 0;
  int _secondPlaceCount = 0;
  int _thirdPlaceCount = 0;
  int _idealStudentCount = 0;

  List<Map<String, dynamic>> get _rankTiers => [
    {"threshold": 0, "name": AppLocalizations.of(context)?.rank1 ?? "ملازم"},
    {"threshold": 100, "name": AppLocalizations.of(context)?.rank2 ?? "ملازم أول"},
    {"threshold": 300, "name": AppLocalizations.of(context)?.rank3 ?? "نقيب"},
    {"threshold": 600, "name": AppLocalizations.of(context)?.rank4 ?? "رائد"},
    {"threshold": 1000, "name": AppLocalizations.of(context)?.rank5 ?? "مقدم"},
    {"threshold": 1500, "name": AppLocalizations.of(context)?.rank6 ?? "عقيد"},
    {"threshold": 2200, "name": AppLocalizations.of(context)?.rank7 ?? "عميد"},
    {"threshold": 3000, "name": AppLocalizations.of(context)?.rank8 ?? "لواء"},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // First, get the badges from the new endpoint
      final badgesRes =
          await _apiService.request('student/badges', null, 'GET');
      if (badgesRes != null && badgesRes.statusCode == 200) {
        final data = badgesRes.data;
        setState(() {
          _firstPlaceCount = (data['firstPlace'] as num?)?.toInt() ?? 0;
          _secondPlaceCount = (data['secondPlace'] as num?)?.toInt() ?? 0;
          _thirdPlaceCount = (data['thirdPlace'] as num?)?.toInt() ?? 0;
          _idealStudentCount = (data['idealStudent'] as num?)?.toInt() ?? 0;
        });
      } else {
        // Fallback to getuser if badges endpoint fails
        final userRes =
            await _apiService.request('student/getuser', null, 'GET');
        if (userRes != null && userRes.statusCode == 200) {
          final data = userRes.data;
          setState(() {
            _firstPlaceCount = (data['firstPlaceCount'] as num?)?.toInt() ?? 0;
            _secondPlaceCount =
                (data['secondPlaceCount'] as num?)?.toInt() ?? 0;
            _thirdPlaceCount = (data['thirdPlaceCount'] as num?)?.toInt() ?? 0;
            _idealStudentCount =
                (data['idealStudentCount'] as num?)?.toInt() ?? 0;
          });
        }
      }

      // Score (unchanged)
      final scoreRes =
          await _apiService.request('score/get_student_score', null, 'GET');
      if (scoreRes != null && scoreRes.statusCode == 200) {
        setState(() {
          _studentScore = (scoreRes.data?['score'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading awards data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimes(int count) {
    if (count == 0) return AppLocalizations.of(context)?.notObtained ?? "لم يحصل عليها";
    if (count == 1) return AppLocalizations.of(context)?.oneTime ?? "مرة واحدة";
    if (count == 2) return AppLocalizations.of(context)?.twoTimes ?? "مرتان";
    if (count >= 3 && count <= 10) return AppLocalizations.of(context)?.timesCount(count.toString()) ?? "$count مرات";
    return AppLocalizations.of(context)?.timeCountSingle(count.toString()) ?? "$count مرة";
  }

  String _getCurrentRankName() {
    String currentRank = _rankTiers.first["name"] as String;
    for (int i = _rankTiers.length - 1; i >= 0; i--) {
      if (_studentScore >= (_rankTiers[i]["threshold"] as int)) {
        currentRank = _rankTiers[i]["name"] as String;
        break;
      }
    }
    return currentRank;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.sky(isDark)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        top: 24.0, right: 20.0, left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              height: 24,
                              width: 24,
                              imageUrl:
                                  'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Activities/Military%20Medal.png',
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)?.leaderboardMedals ?? "أوسمة الصدارة",
                              style: GoogleFonts.cairo(
                                color: AppColors.getTextColor(isDark),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 14.0, left: 14.0),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              _buildMedalCard(
                                title: AppLocalizations.of(context)?.firstPlace ?? "مركز أول",
                                countStr: _formatTimes(_firstPlaceCount),
                                imagePath: 'assets/images/1st place medal.png',
                                countColor: AppColors.orangeStatus(isDark),
                              ),
                              _buildMedalCard(
                                title: AppLocalizations.of(context)?.secondPlace ?? "مركز ثاني",
                                countStr: _formatTimes(_secondPlaceCount),
                                imagePath: 'assets/images/2nd place medal.png',
                                countColor: AppColors.sky(isDark),
                              ),
                              _buildMedalCard(
                                title: AppLocalizations.of(context)?.thirdPlace ?? "مركز ثالث",
                                countStr: _formatTimes(_thirdPlaceCount),
                                imagePath: 'assets/images/3rd place medal.png',
                                countColor: AppColors.redStatus(isDark),
                              ),
                              _buildMedalCard(
                                title: AppLocalizations.of(context)?.idealStudent ?? "الطالب المثالي",
                                countStr: _formatTimes(_idealStudentCount),
                                imagePath: 'assets/images/trophy.png',
                                countColor: AppColors.orangeStatus(isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                                height: 24,
                                width: 24,
                                imageUrl:
                                    'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Shield.png'),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)?.ranksPath ?? "مسار الرتب",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          itemCount: _rankTiers.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            final rank = _rankTiers[index];
                            final threshold = rank["threshold"] as int;
                            final name = rank["name"] as String;
                            final currentRankName = _getCurrentRankName();

                            final isCurrent = name == currentRankName;
                            final isCompleted =
                                _studentScore >= threshold && !isCurrent;
                            final isLocked = _studentScore < threshold;

                            return _buildRankCardItem(
                              name: name,
                              threshold: threshold,
                              isCurrent: isCurrent,
                              isCompleted: isCompleted,
                              isLocked: isLocked,
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.15,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.getCardBorderColor(isDark), width: 1),
          )),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.getCircleBackgroundColor(isDark),
                      border: Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(PhosphorIconsRegular.arrowRight,
                        color: AppColors.getTextSecondaryColor(isDark), size: 20),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsFill.trophy,
                        color: AppColors.getTextColor(isDark), size: 32),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.tournamentsHistoryLabel ?? "سجل البطولات",
                      style: GoogleFonts.cairo(
                        color: AppColors.getTextColor(isDark),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
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

  Widget _buildMedalCard({
    required String title,
    required String countStr,
    required String imagePath,
    required Color countColor,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const Spacer(flex: 2),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 24),
                child: Image.asset(
                  'assets/images/Ellipse.png',
                  height: 16,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Image.asset(imagePath,
                  width: 48, height: 48, fit: BoxFit.contain),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: countColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countStr,
              style: GoogleFonts.cairo(
                color: countColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRankCardItem({
    required String name,
    required int threshold,
    required bool isCurrent,
    required bool isCompleted,
    required bool isLocked,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    Color borderColor = AppColors.getCardBorderColor(isDark);
    Color bgColor = AppColors.getCardBackgroundColor(isDark);

    if (isCurrent) {
      borderColor = AppColors.sky(isDark).withOpacity(0.5);
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
            boxShadow: [
              if (!isLocked && !isCurrent)
                BoxShadow(
                  color: AppColors.getShadowColor(isDark),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              if (isCurrent)
                BoxShadow(
                  color: AppColors.sky(isDark).withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLocked)
                Container(
                  width: 76,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.sky(isDark)
                        : AppColors.getTextSecondaryColor(isDark),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isCurrent ? AppColors.sky(isDark) : AppColors.getTextSecondaryColor(isDark))
                                .withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                )
              else
                const SizedBox(height: 4),
              const Spacer(flex: 2),
              Opacity(
                opacity: isLocked ? 0.3 : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, 36),
                      child: Image.asset(
                        'assets/images/Ellipse.png',
                        height: 16,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Image.asset(
                      'assets/images/$name.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          PhosphorIconsFill.shield,
                          size: 64,
                          color: AppColors.getTextSecondaryColor(isDark)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                name,
                style: GoogleFonts.cairo(
                  color:
                      isLocked ? AppColors.getTextSecondaryColor(isDark) : AppColors.getTextColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenStatus(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.completedStatus ?? "مكتمل",
                    style: GoogleFonts.cairo(
                      color: AppColors.greenStatus(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sky(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.currentRankBadge ?? "الحالية",
                    style: GoogleFonts.cairo(
                      color: AppColors.sky(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (isLocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.getInputBackgroundColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$threshold XP',
                    style: GoogleFonts.cairo(
                      color: AppColors.getTextSecondaryColor(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
        if (isLocked)
          Positioned(
            top: 12,
            right: 12,
            child: Icon(
              PhosphorIconsFill.lockKey,
              color: AppColors.getTextSecondaryColor(isDark),
              size: 16,
            ),
          ),
      ],
    );
  }
}
