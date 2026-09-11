import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/models/company_settings_model.dart'
    hide AppColors;
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
// import 'package:flutter_version/widgets/account_screen_widgets.dart';
// import 'package:flutter_version/widgets/level_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_version/main.dart';
// import 'package:flutter_version/utilities/theme_helper.dart';
import 'package:flutter_version/data/app_config.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/utilities/locale_provider.dart';
import 'package:flutter_version/widgets/account_switch_dialog.dart';
import 'package:flutter_version/screens/appearing_screens/offline_pdfs_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_version/screens/mainscreens/awards_history_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _enableOfflinePdf = false;
  Map<String, dynamic> userData = {};
  Map<String, dynamic>? companySettings;
  int studentScore = 0;
  final Set<String> _expandedContactChannels = {};

  bool _isEditingGroup = false;
  List<dynamic> allGroups = [];
  String? selectedGroupId;
  String? selectedGroupName;

  int _completedCourses = 0;
  int get _badges =>
      (userData["firstPlaceCount"] as num? ?? 0).toInt() +
      (userData["secondPlaceCount"] as num? ?? 0).toInt() +
      (userData["thirdPlaceCount"] as num? ?? 0).toInt();
  int _streakCount = 0;

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

  Map<String, dynamic> get _rankInfo {
    String currentRank = _rankTiers.first["name"] as String;
    String nextRank =
        _rankTiers.length > 1 ? _rankTiers[1]["name"] as String : currentRank;
    int goalPoints =
        _rankTiers.length > 1 ? _rankTiers[1]["threshold"] as int : 0;

    for (int i = _rankTiers.length - 1; i >= 0; i--) {
      if (studentScore >= (_rankTiers[i]["threshold"] as int)) {
        currentRank = _rankTiers[i]["name"] as String;
        if (i + 1 < _rankTiers.length) {
          nextRank = _rankTiers[i + 1]["name"] as String;
          goalPoints = _rankTiers[i + 1]["threshold"] as int;
        } else {
          nextRank = currentRank;
          goalPoints = _rankTiers[i]["threshold"] as int;
        }
        break;
      }
    }
    return {
      "currentRank": currentRank,
      "nextRank": nextRank,
      "goalPoints": goalPoints,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadOfflinePdfFlag(),
        _loadOfflineVideoFlag(),
        _fetchUserData(),
        _fetchStudentScore(),
        _fetchAllGroups(),
        _loadStreakCount(),
        _fetchCompletedCourses(),
        _fetchBadges(),
      ]);
    } catch (e) {
      debugPrint("❌ Error loading initial data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchBadges() async {
    try {
      final response = await _apiService.request("student/badges", null, "GET");
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map && mounted) {
          setState(() {
            userData["firstPlaceCount"] = data["firstPlace"] ?? 0;
            userData["secondPlaceCount"] = data["secondPlace"] ?? 0;
            userData["thirdPlaceCount"] = data["thirdPlace"] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching badges: $e");
    }
  }

  Future<void> _loadOfflinePdfFlag() async {
    final flag = await _apiService.getOfflinePdfFlag();
    if (mounted) setState(() => _enableOfflinePdf = flag);
  }

  Future<void> _fetchCompletedCourses() async {
    try {
      final userResponse =
          await _apiService.request("student/getuser", null, "GET");
      List<String> exercisesDone = [];
      if (userResponse != null && userResponse.statusCode == 200) {
        exercisesDone = (userResponse.data["exercises_done"] as List?)
                ?.map((e) => e["exercise_id"].toString())
                .toList() ??
            [];
      }

      final response = await _apiService.request(
        "student/course/getpaidcourses",
        null,
        "GET",
      );

      if (response != null && response.statusCode == 200) {
        final courses = response.data as List;
        int completed = 0;

        for (final course in courses) {
          final videos = course["videoslist"] as List? ?? [];
          if (videos.isEmpty) continue;

          final doneCount = videos
              .where(
                  (v) => exercisesDone.contains(v["exercise_id"]?.toString()))
              .length;
          final progress = doneCount / videos.length;

          if (progress >= 1.0) completed++;
        }

        if (mounted) setState(() => _completedCourses = completed);
      }
    } catch (e) {
      debugPrint("❌ Error fetching completed courses: $e");
    }
  }

  Future<void> _loadOfflineVideoFlag() async {}

  Future<void> _loadStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _streakCount = prefs.getInt('streak_count') ?? 0;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final response =
          await _apiService.request("student/getuser", null, "GET");
      if (response != null && response.statusCode == 200) {
        if (mounted) setState(() => userData = response.data ?? {});

        final companyId = userData["companyId"];
        final companyCode =
            userData["companyCode"]; // تأكد من اسم المفتاح الصحيح عندك
        if (companyId != null) {
          final settingsProvider =
              Provider.of<CompanySettingsProvider>(context, listen: false);

          await settingsProvider.fetchCompanySettings(
            companyCode: companyCode ?? '',
            companyId: companyId,
          );

          // اقرأ من الـ Provider نفسه بعد ما يتحدث
          final settings = settingsProvider.settings;
          if (settings != null) {
            await _apiService.saveOfflinePdfFlag(settings.enableOfflinePdf);
            if (mounted) {
              setState(() => _enableOfflinePdf = settings.enableOfflinePdf);
            }
            await _apiService.saveOfflineVideoFlag(settings.enableOfflineVideo);
            await _apiService.saveOfflineCoursesSettings(
              enabled: settings.enableOfflineCourses,
              daysLimit: settings.offlineCoursesDaysLimit,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching user data: $e");
    }
  }

  Future<void> _fetchAllGroups() async {
    try {
      final response =
          await _apiService.request("group/get_all_groups", null, "GET");
      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        if (mounted) {
          setState(() {
            allGroups = data;
            if (data.isNotEmpty) {
              selectedGroupId = data[0]["_id"];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching groups: $e");
    }
  }

  Future<void> openExternalLink(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Could not launch link: $e");
    }
  }

  Future<void> _saveGroupChange() async {
    if (selectedGroupId == null) return;
    try {
      final res = await _apiService.request(
        "student/changeStudentGroup",
        {"studentId": userData["_id"], "newGroupId": selectedGroupId},
        "POST",
      );
      if (res != null && res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.groupModifiedSuccess)),
          );
        }
        setState(() {
          _isEditingGroup = false;
          selectedGroupName = allGroups
              .firstWhere((g) => g["_id"] == selectedGroupId)["groupName"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res?.data ??
                  AppLocalizations.of(context)!.errorModifyingGroup)),
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving group change: $e");
    }
  }

  Future<void> _fetchStudentScore() async {
    try {
      final scoreResponse =
          await _apiService.request("score/get_student_score", null, "GET");
      if (scoreResponse != null && scoreResponse.statusCode == 200) {
        if (mounted) {
          setState(() => studentScore = scoreResponse.data?['score'] ?? 0);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching student score: $e");
    }
  }

  bool _looksLikeUrl(String value) {
    final v = value.trim();
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.');
  }

  Future<void> openPhoneOrDialer(String value) async {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleaned);
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint("❌ Could not launch phone dialer: $e");
    }
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.165,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.getBrandGradient(),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0, top: 32.0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(PhosphorIconsRegular.x,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(bool isDark) {
    const double avatarSize = 100;
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.getCircleBackgroundColor(isDark),
        border: Border.all(
            color: AppColors.getBorderColor(isDark), width: isDark ? 1 : 4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipOval(
          child: userData["avatar"] != null &&
                  userData["avatar"].toString().isNotEmpty
              ? Image.network(userData["avatar"], fit: BoxFit.contain)
              : Image.asset(
                  "assets/images/emojis/manStudent.gif",
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userData["FirstName"] ?? AppLocalizations.of(context)!.userName,
          style: GoogleFonts.cairo(
            color: AppColors.getTextColor(isDark),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getInputBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.getCardBorderColor(isDark), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.student,
                  color: AppColors.getSecondHintColor(isDark), size: 16),
              const SizedBox(width: 5.5),
              Text(
                userData["groupName"] ?? AppLocalizations.of(context)!.online,
                style: GoogleFonts.cairo(
                    color: AppColors.getSecondHintColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Stats card (overlaps header) ─────────────────────────────────────────
  Widget _buildStatsCard(bool isDark) {
    return Container(
      height: 111,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 3,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          _buildStat(
              PhosphorIconsFill.fire, '$_streakCount', AppLocalizations.of(context)?.streakDays ?? "أيام حماس", isDark,
              iconColor: AppColors.orangeStatus(isDark)),
          _buildStatDivider(isDark),
          _buildStat(PhosphorIconsFill.medal, '$_badges', AppLocalizations.of(context)?.medals ?? "أوسمة", isDark,
              iconColor: AppColors.orangeStatus(isDark)),
          _buildStatDivider(isDark),
          _buildStat(PhosphorIconsFill.books, '$_completedCourses',
              AppLocalizations.of(context)?.completedCourseBadge ?? "كورس مكتمل", isDark,
              iconColor: AppColors.greenStatus(isDark)),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, bool isDark,
      {Color? iconColor}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 24, color: iconColor ?? AppColors.getTextColor(isDark)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppColors.getSecondHintColor(isDark),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) => Container(
      width: 1, height: 40, color: AppColors.getCardBorderColor(isDark));

  // ─── Group + Rank row ─────────────────────────────────────────────────────
  Widget _buildGroupRankRow(bool isDark) {
    final size = MediaQuery.of(context).size;
    final rank = _rankInfo;
    final String currentRank = rank["currentRank"];
    // final String nextRank = rank["nextRank"];
    final int goalPoints = rank["goalPoints"];
    // final double progress =
    //     goalPoints > 0 ? (studentScore / goalPoints).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: size.height * 0.185),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.getBrandGradient(),
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.sky(isDark),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipOval(
                          child: Image.asset(
                            width: 32,
                            height: 26,
                            'assets/images/$currentRank.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                    child: Text('🏆',
                                        style: TextStyle(fontSize: 20))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentRank,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$goalPoints',
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky(isDark)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          '/ $studentScore',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AwardsHistoryPage()),
                        );
                      },
                      child: Container(
                        height: 27,
                        padding: const EdgeInsets.only(
                            top: 2, bottom: 2, right: 16, left: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                AppLocalizations.of(context)
                                        ?.tournamentsHistory ??
                                    AppLocalizations.of(context)?.tournamentsHistoryLabel ?? "سجل البطولات",
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(width: 5.15),
                            const Icon(PhosphorIconsRegular.caretUp,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: size.height * 0.185),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getInputBackgroundColor(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.getCardBorderColor(isDark), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.getInputBackgroundColor(isDark),
                        border: Border.all(
                            color: AppColors.getCardBorderColor(isDark),
                            width: 1),
                      ),
                      child: Icon(PhosphorIconsFill.usersThree,
                          size: 24, color: AppColors.getIconColor(isDark)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedGroupName ??
                          userData["groupName"] ??
                          AppLocalizations.of(context)!.online,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextColor(isDark)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.studyGroup ?? "المجموعة الدراسية",
                      style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondaryColor(isDark)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingGroup)
                      DropdownButton<String>(
                        value: selectedGroupId,
                        isExpanded: true,
                        underline:
                            Container(height: 2, color: AppColors.sky(isDark)),
                        dropdownColor:
                            AppColors.getInputBackgroundColor(isDark),
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextColor(isDark),
                            fontSize: 13),
                        items: allGroups.map<DropdownMenuItem<String>>((group) {
                          return DropdownMenuItem<String>(
                            value: group["_id"],
                            child: Text(group["groupName"],
                                textAlign: TextAlign.right),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => selectedGroupId = value),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() => _isEditingGroup = true);
                        },
                        child: Container(
                          height: 27,
                          padding: const EdgeInsets.only(
                              top: 2, bottom: 2, right: 16, left: 16),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBackgroundColor(isDark),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.getCardBorderColor(isDark),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppLocalizations.of(context)?.changeGroupBtn ?? "تغيير المجموعة",
                                  style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getSecondHintColor(
                                          isDark))),
                              const SizedBox(width: 5.15),
                              Icon(PhosphorIconsRegular.caretUp,
                                  size: 14,
                                  color: AppColors.getSecondHintColor(isDark)),
                            ],
                          ),
                        ),
                      ),
                    if (_isEditingGroup) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _saveGroupChange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.greenStatus(isDark).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save,
                                  size: 14, color: AppColors.greenStatus(isDark)),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.save,
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.greenStatus(isDark))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, top: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextColor(isDark))),
      ),
    );
  }

  // ─── Account switcher section ─────────────────────────────────────────────
  Widget _buildAccountSwitcher(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        ),
        child: Column(
          children: [
            _buildSwitcherRow(
              avatar:
                  'assets/images/emojis/manStudent.gif', // Placeholder avatar
              name: userData["FirstName"] ??
                  AppLocalizations.of(context)!.userName,
              subtitle: AppLocalizations.of(context)?.tapToSwitchAccount ?? "اضغط لتبديل الحساب",
              subtitleColor: AppColors.getTextColor(isDark),
              isActive: true,
              trailing: Icon(Icons.keyboard_arrow_up_rounded,
                  color: AppColors.getSecondHintColor(isDark), size: 20),
              isDark: isDark,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AccountSwitchDialog(),
                );
                if (mounted) {
                  // reset stale state before refetching so old data can't flash
                  setState(() {
                    userData = {};
                    companySettings = null;
                    studentScore = 0;
                    allGroups = [];
                    selectedGroupId = null;
                    selectedGroupName = null;
                  });
                  _loadAllData();
                }
              },
            ),
            Divider(height: 1, color: AppColors.getCardBorderColor(isDark)),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (context) => const AccountSwitchDialog(),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.getCardBorderColor(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.getCardBorderColor(isDark),
                            width: 1),
                      ),
                      child: Icon(PhosphorIconsRegular.plus,
                          color: AppColors.sky(isDark), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)?.addAnotherAccountBtn ?? "إضافة حساب آخر",
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sky(isDark))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcherRow({
    String? avatar,
    String? emoji,
    required String name,
    required String subtitle,
    required Color subtitleColor,
    required bool isActive,
    required Widget trailing,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.getInputBackgroundColor(isDark),
                    border: Border.all(
                        color: AppColors.getCardBorderColor(isDark), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipOval(
                      child: avatar != null && avatar.isNotEmpty
                          ? Image.asset(avatar, fit: BoxFit.cover)
                          : Center(
                              child: Text(emoji ?? '🧑‍🎓',
                                  style: const TextStyle(fontSize: 18))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.sky(isDark),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                if (isActive) trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContactRow({
    required Color iconBg,
    required Widget icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required bool isExpanded,
    required VoidCallback onTap,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1)),
                      child: Center(child: icon),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextColor(isDark))),
                        const SizedBox(height: 4),
                        if (subtitle != null)
                          Text(subtitle,
                              style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.getTextSecondaryColor(isDark))),
                      ],
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: isExpanded
                      ? 0.75
                      : 0, // caretRight → points down when open
                  duration: const Duration(milliseconds: 200),
                  child: Icon(PhosphorIconsRegular.caretRight,
                      color: AppColors.getSecondHintColor(isDark), size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(right: 50, left: 14, bottom: 10),
            child: Column(children: children),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildContactSubRow({
    required String displayName,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sky(isDark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(displayName,
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextColor(isDark))),
            ),
            Icon(PhosphorIconsRegular.arrowUpRight,
                size: 14, color: AppColors.getSecondHintColor(isDark)),
          ],
        ),
      ),
    );
  }

  // ─── Contact with teacher ──────────────────────────────────────────────────
  Widget _buildContactSection(bool isDark) {
    final settings = Provider.of<CompanySettingsProvider>(context);
    final info = settings.contactInfo;

    if (info.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];

    void addChannelRows({
      required String channelKey,
      required List<ContactEntry> entries,
      required Widget icon,
      required Color iconBg,
      required Color borderColor,
      required String fallbackTitle,
      String? subtitle,
      required void Function(ContactEntry entry) onEntryTap,
    }) {
      if (entries.isEmpty) return;

      if (entries.length == 1) {
        final entry = entries.first;
        rows.add(_buildActionRow(
          iconBg: iconBg,
          icon: icon,
          title:
              entry.displayName.isNotEmpty ? entry.displayName : fallbackTitle,
          subtitle: subtitle,
          isDark: isDark,
          onTap: () => onEntryTap(entry),
          borderColor: borderColor,
        ));
      } else {
        final isExpanded = _expandedContactChannels.contains(channelKey);
        rows.add(_buildExpandableContactRow(
          iconBg: iconBg,
          icon: icon,
          title: fallbackTitle,
          subtitle: AppLocalizations.of(context)?.availableNumbersCount(entries.length.toString()) ?? "${entries.length} أرقام متاحة",
          isDark: isDark,
          isExpanded: isExpanded,
          borderColor: borderColor,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedContactChannels.remove(channelKey);
              } else {
                _expandedContactChannels.add(channelKey);
              }
            });
          },
          children: entries
              .map((entry) => _buildContactSubRow(
                    displayName: entry.displayName.isNotEmpty
                        ? entry.displayName
                        : fallbackTitle,
                    isDark: isDark,
                    onTap: () => onEntryTap(entry),
                  ))
              .toList(),
        ));
      }
    }

    addChannelRows(
      channelKey: 'whatsapp',
      entries: info.whatsapp,
      icon: _buildWhatsAppIcon(),
      iconBg: AppColors.greenStatus(isDark).withOpacity(0.1),
      borderColor: AppColors.greenStatus(isDark).withOpacity(0.2),
      fallbackTitle: AppLocalizations.of(context)!.contactTeacherWhatsapp,
      subtitle: AppLocalizations.of(context)?.forQuickInquiries ?? "للاستفسارات السريعة",
      onEntryTap: (entry) => openWhatsAppChat(entry.value,
          message: AppLocalizations.of(context)!.teacherWhatsappMessage),
    );

    addChannelRows(
      channelKey: 'facebook',
      entries: info.facebook,
      icon: _buildFacebookIcon(),
      iconBg: AppColors.sky(isDark).withOpacity(0.1),
      borderColor: AppColors.sky(isDark).withOpacity(0.2),
      fallbackTitle: AppLocalizations.of(context)!.contactTeacherFacebook,
      subtitle: AppLocalizations.of(context)?.officialStudentsGroup ?? "الجروب الرسمي للطلاب",
      onEntryTap: (entry) => openFacebookPage(entry.value),
    );

    for (final entry in info.techSupport)
      _buildActionRow(
        iconBg: AppColors.getCircleBackgroundColor(isDark),
        icon: Icon(PhosphorIconsFill.headset,
            color: AppColors.getTextSecondaryColor(isDark), size: 24),
        title: entry.displayName.isNotEmpty ? entry.displayName : AppLocalizations.of(context)?.techSupportLabel ?? "دعم فني",
        isDark: isDark,
        onTap: () => _looksLikeUrl(entry.value)
            ? openExternalLink(entry.value)
            : openPhoneOrDialer(entry.value),
        borderColor: AppColors.getCardBorderColor(isDark),
      );

    return Padding(
      padding: const EdgeInsets.only(right: 20.0, left: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1)
                  Divider(
                      height: 1, color: AppColors.getCardBorderColor(isDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppIcon() => Icon(
        PhosphorIconsFill.whatsappLogo,
        size: 24,
        textDirection: TextDirection.ltr,
        color: AppColors.greenStatus(true),
      );
  Widget _buildFacebookIcon() => Icon(
        PhosphorIconsFill.facebookLogo,
        size: 24,
        textDirection: TextDirection.ltr,
        color: AppColors.sky(true),
      );

  // ─── Support & Account section ─────────────────────────────────────────────
  Widget _buildSupportSection(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildActionRow(
                iconBg: AppColors.sky(isDark).withOpacity(0.1),
                icon: Icon(PhosphorIconsRegular.globe,
                    color: AppColors.sky(isDark), size: 20),
                title: AppLocalizations.of(context)!.changeLanguage,
                isDark: isDark,
                borderColor: AppColors.getCardBorderColor(isDark),
                onTap: () {
                  final provider =
                      Provider.of<LocaleProvider>(context, listen: false);
                  provider.locale?.languageCode == 'en'
                      ? provider.setLocale(const Locale('ar'))
                      : provider.setLocale(const Locale('en'));
                },
              ),
              Divider(height: 1, color: AppColors.getCardBorderColor(isDark)),
              // // Night mode with toggle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.getCircleBackgroundColor(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.getCardBorderColor(isDark),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              PhosphorIconsFill.moon,
                              color: AppColors.getTextSecondaryColor(isDark),
                              size: 24,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)?.darkModeTitle ?? "الوضع الليلي",
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (val) => themeProvider.toggleTheme(),
                      activeColor: AppColors.sky(isDark),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.getCardBorderColor(isDark)),
              // Offline PDFs
              if (_enableOfflinePdf) ...[
                _buildActionRow(
                    iconBg: AppColors.getCircleBackgroundColor(isDark),
                    icon: Icon(Icons.picture_as_pdf,
                        color: AppColors.getTextSecondaryColor(isDark), size: 20),
                    title: AppLocalizations.of(context)?.downloadedFilesOffline ?? "الملفات المحملة (بدون إنترنت)",
                    isDark: isDark,
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OfflinePdfsPage()),
                        ),
                    borderColor: AppColors.getCardBorderColor(isDark)),
                Divider(height: 1, color: AppColors.getCardBorderColor(isDark)),
              ],
              // Technical support
              _buildActionRow(
                  iconBg: AppColors.getCircleBackgroundColor(isDark),
                  icon: Icon(
                    PhosphorIconsFill.headset,
                    color: AppColors.getTextSecondaryColor(isDark),
                    size: 24,
                    textDirection: TextDirection.ltr,
                  ),
                  title: AppLocalizations.of(context)!.contactSupport,
                  subtitle: AppLocalizations.of(context)?.forAppOrVideoIssues ?? "لمشاكل التطبيق أو الفيديوهات",
                  isDark: isDark,
                  onTap: () => openWhatsAppChat(AppConfig.suuportNumber,
                      message:
                          AppLocalizations.of(context)!.supportWhatsappMessage),
                  borderColor: AppColors.getCardBorderColor(isDark)),
              Divider(height: 1, color: AppColors.getCardBorderColor(isDark)),
              // Logout
              GestureDetector(
                onTap: () async {
                  await _apiService.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.redStatus(isDark).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.redStatus(isDark).withOpacity(0.2),
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(PhosphorIconsFill.signOut,
                              textDirection: TextDirection.ltr,
                              color: AppColors.redStatus(isDark),
                              size: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.logout,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.redStatus(isDark))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Generic action row ────────────────────────────────────────────────────
  Widget _buildActionRow({
    required Color iconBg,
    required Widget icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1)),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 4),
                    if (subtitle != null)
                      Text(subtitle,
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextSecondaryColor(isDark))),
                  ],
                ),
              ],
            ),
            Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.getSecondHintColor(isDark), size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppColors.getTextColor(isDark),
                  fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: 'All Rights Reserved '),
                TextSpan(
                    text: 'Space Stack',
                    style: TextStyle(
                        color: AppColors.sky(isDark),
                        fontWeight: FontWeight.w700)),
                TextSpan(text: ' ® 2026'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Version 2.0.0',
              style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppColors.getSecondHintColor(isDark),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      _buildHeader(isDark),
                      Positioned(
                        bottom: -46,
                        child: _buildAvatarCircle(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 58),
                  _buildUserInfoSection(isDark),
                  const SizedBox(height: 24),
                  _buildStatsCard(isDark),
                  const SizedBox(height: 24),
                  _buildGroupRankRow(isDark),
                  _buildSectionTitle(AppLocalizations.of(context)?.switchAccountTitle ?? "تبديل الحساب", isDark),
                  _buildAccountSwitcher(isDark),
                  _buildSectionTitle(AppLocalizations.of(context)?.contactTeacherTitle ?? "تواصل مع المستر", isDark),
                  _buildContactSection(isDark),
                  _buildSectionTitle(AppLocalizations.of(context)?.supportAndAccountTitle ?? "الدعم والحساب", isDark),
                  _buildSupportSection(isDark),
                  _buildFooter(isDark),
                ],
              ),
            ),
    );
  }
}

// ─── WhatsApp, Facebook & Email helpers ─────────────────────────────────────

bool _looksLikeUrl(String value) {
  final v = value.trim();
  return v.startsWith('http://') ||
      v.startsWith('https://') ||
      v.startsWith('www.');
}

Future<void> openWhatsAppChat(String phone, {String message = ""}) async {
  final trimmed = phone.trim();
  final Uri uri;

  if (_looksLikeUrl(trimmed)) {
    // Backend already gave a full wa.me / api.whatsapp.com link — use as-is
    uri = Uri.parse(trimmed);
  } else {
    final cleanPhone = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    uri = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
  }

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint("❌ Could not launch WhatsApp: $e");
    if (navigatorKey.currentContext != null) {
      final context = navigatorKey.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.whatsappError)),
      );
    }
  }
}

Future<void> openFacebookPage(String pageUrl) async {
  final trimmed = pageUrl.trim();
  final Uri uri = _looksLikeUrl(trimmed)
      ? Uri.parse(trimmed)
      : Uri.parse("https://facebook.com/$trimmed"); // treat as username/page id

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint("❌ Could not launch Facebook: $e");
  }
}

Future<void> openSupportEmail(String email) async {
  final context = navigatorKey.currentContext;
  final subject = context != null
      ? AppLocalizations.of(context)!.technicalSupport
      : "Technical Support";
  final body = context != null
      ? AppLocalizations.of(context)!.supportEmailBody
      : "Hello, I need help with...";
  final Uri uri = Uri(
    scheme: 'mailto',
    path: email,
    query: Uri.encodeFull("subject=$subject&body=$body"),
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint("❌ Could not launch email: $e");
  }
}
