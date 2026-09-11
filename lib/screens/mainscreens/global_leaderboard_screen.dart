import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:flutter_version/data/api_service.dart';

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  State<GlobalLeaderboardScreen> createState() => _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _fallbackAvatars = [
    "assets/images/emojis/manStudent.gif",
    "assets/images/emojis/Student.gif",
    "assets/images/emojis/Scientist.gif",
    "assets/images/emojis/Astronaut.gif",
    "assets/images/emojis/Detective.gif",
    "assets/images/emojis/Judge.gif",
  ];

  List<Map<String, dynamic>> _allStudents = [];
  Map<String, dynamic> _currentUserData = {"rank": "-", "score": 0, "avatar": "assets/images/emojis/manStudent.gif"};
  List<Map<String, dynamic>> _fieldsToDisplay = [];

  int _currentPage = 1;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchLeaderboard(page: 1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchLeaderboard(page: _currentPage + 1);
    }
  }

  Future<void> _fetchLeaderboard({required int page}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      final response = await _apiService.request(
        "score/global_leaderboard?page=$page&limit=30",
        null,
        "GET",
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List rawList = data["data"] is List ? data["data"] : [];
        final Map<String, dynamic> currentUser =
            data["currentUser"] is Map ? Map<String, dynamic>.from(data["currentUser"]) : {};
        final List rawFields = data["fieldsToDisplay"] is List ? data["fieldsToDisplay"] : [];
        final bool hasMore = data["hasMore"] == true;

        final List<Map<String, dynamic>> parsedStudents = rawList.map((item) {
          final map = Map<String, dynamic>.from(item);
          final String photo = map["photo"] ?? "";
          String avatarAsset = _fallbackAvatars[0];
          if (photo.isEmpty) {
            final int r = map["rank"] ?? 1;
            avatarAsset = _fallbackAvatars[(r - 1) % _fallbackAvatars.length];
          }
          return {
            ...map,
            "avatar": photo.isNotEmpty ? photo : avatarAsset,
            "isNetworkImage": photo.isNotEmpty,
          };
        }).toList();

        setState(() {
          if (page == 1) {
            _allStudents = parsedStudents;
          } else {
            _allStudents.addAll(parsedStudents);
          }
          _currentPage = page;
          _hasMore = hasMore;
          _currentUserData = currentUser;
          _fieldsToDisplay = List<Map<String, dynamic>>.from(rawFields);
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching global leaderboard: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  Widget _buildAvatarWidget(Map<String, dynamic> student, {required double size}) {
    final bool isNetwork = student["isNetworkImage"] == true;
    final String path = student["avatar"] ?? "assets/images/emojis/manStudent.gif";

    if (isNetwork) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          "assets/images/emojis/manStudent.gif",
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final topThree = _allStudents.take(3).toList();
    final remainingStudents = _allStudents.length > 3 ? _allStudents.skip(3).toList() : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          // Premium Gamified Header
          _buildHeader(isDark),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sky(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchLeaderboard(page: 1),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Animated Premium Podium View
                          if (topThree.isNotEmpty) _buildPremiumPodiumView(topThree, isDark),
                          const SizedBox(height: 32),
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    PhosphorIconsFill.trophy,
                                    size: 20,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)?.leaderboardMedals ?? "قائمة الأبطال",
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Ranked Students List
                          if (remainingStudents.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: remainingStudents.length,
                              itemBuilder: (context, index) {
                                final student = remainingStudents[index];
                                return _buildRankItem(student, isDark);
                              },
                            ),
                          if (_isFetchingMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.sky(isDark),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      extendBody: true,
      bottomSheet: _buildCurrentUserStickyCard(_currentUserData, isDark),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.16,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.crown,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)?.leaderboardMedals ?? "الترتيب العالمي",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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

  // ─── PODIUM VIEW ─────────────────────────────────────────────────────────────

  Widget _buildPremiumPodiumView(List<Map<String, dynamic>> topThree, bool isDark) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Silver
          Expanded(
            child: second != null
                ? _buildPodiumPillar(
                    student: second,
                    rank: second["rank"] ?? 2,
                    height: 120,
                    badgeColor: const Color(0xFFC0C0C0),
                    pillarColors: const [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),
          // #1 Gold Center
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: first != null
                  ? _buildPodiumPillar(
                      student: first,
                      rank: first["rank"] ?? 1,
                      height: 170,
                      badgeColor: const Color(0xFFFFD700),
                      pillarColors: const [Color(0xFFFDE047), Color(0xFFEAB308)],
                      isCenter: true,
                      isDark: isDark,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // #3 Bronze
          Expanded(
            child: third != null
                ? _buildPodiumPillar(
                    student: third,
                    rank: third["rank"] ?? 3,
                    height: 90,
                    badgeColor: const Color(0xFFCD7F32),
                    pillarColors: const [Color(0xFFFDBA74), Color(0xFFEA580C)],
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required Map<String, dynamic> student,
    required int rank,
    required double height,
    required Color badgeColor,
    required List<Color> pillarColors,
    bool isCenter = false,
    required bool isDark,
  }) {
    final double avatarSize = isCenter ? 72 : 56;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCenter)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Icon(PhosphorIconsFill.crown, color: Color(0xFFFFD700), size: 36),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: pillarColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isCenter ? 36 : 28,
                backgroundColor: AppColors.getCardBackgroundColor(isDark),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: _buildAvatarWidget(student, size: avatarSize),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "#$rank",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          student["name"] ?? "",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(
            fontSize: isCenter ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${student["score"] ?? 0}",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                'assets/images/emojis/Star.gif',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutQuart,
          tween: Tween<double>(begin: 0, end: height),
          builder: (context, value, child) {
            return Container(
              width: double.infinity,
              height: value,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    pillarColors[0].withValues(alpha: 0.9),
                    pillarColors[1].withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(
                  color: pillarColors[0].withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── RANK ITEM ──────────────────────────────────────────────────────────────

  Widget _buildRankItem(Map<String, dynamic> student, bool isDark) {
    final int rank = student["rank"] ?? 0;

    Color rankColor = AppColors.getTextSecondaryColor(isDark);
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    else if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    else if (rank == 3) rankColor = const Color(0xFFCD7F32);

    List<Widget> extraChips = [];
    final studentData = student["studentData"] as Map?;
    for (var field in _fieldsToDisplay) {
      final fieldId = field["fieldId"];
      final label = field["label"];
      String? val;
      if (fieldId == "level") {
        val = student["level"];
      } else if (fieldId == "departement") {
        val = student["departement"];
      } else if (studentData != null) {
        val = studentData[fieldId]?.toString();
      }

      if (val != null && val.isNotEmpty) {
        extraChips.add(
          Container(
            margin: const EdgeInsets.only(top: 2, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.getInputBackgroundColor(isDark),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$label: $val",
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: AppColors.getTextSecondaryColor(isDark),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getCardBorderColor(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadowColor(isDark),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              "#$rank",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.getInputBackgroundColor(isDark),
              child: ClipOval(
                child: _buildAvatarWidget(student, size: 36),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student["name"] ?? "",
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (extraChips.isNotEmpty)
                  Wrap(
                    children: extraChips,
                  ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orangeStatus(isDark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orangeStatus(isDark).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  "${student["score"] ?? 0}",
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orangeStatus(isDark),
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/emojis/Star.gif',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STICKY USER RANK CARD ───────────────────────────────────────────────────

  Widget _buildCurrentUserStickyCard(Map<String, dynamic> currentUserData, bool isDark) {
    final dynamic rankVal = currentUserData["rank"] ?? "-";
    final dynamic scoreVal = currentUserData["score"] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.buttonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.getCardBackgroundColor(isDark),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/emojis/manStudent.gif",
                        width: 38,
                        height: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.currentRankTitle ?? "مركزك الحالي",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextSecondaryColor(isDark),
                      ),
                    ),
                    Text(
                      "#$rankVal",
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)?.pointsCount(scoreVal is int ? scoreVal : (int.tryParse(scoreVal.toString()) ?? 0)) ?? "$scoreVal نقطة",
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'assets/images/emojis/Star.gif',
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
