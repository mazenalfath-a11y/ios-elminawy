import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/appearing_screens/course_details_page.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> purchasedCourses = [];
  int streakCount = 0;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _fetchPurchasedCourses();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        streakCount = prefs.getInt('streak_count') ?? 0;
      });
    }
  }

  Future<void> _fetchPurchasedCourses() async {
    setState(() => _isLoading = true);

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
        purchasedCourses = (response.data as List).map((course) {
          final videos = course["videoslist"] as List? ?? [];
          double progress = 0.0;
          if (videos.isNotEmpty) {
            int completed = videos
                .where(
                    (v) => exercisesDone.contains(v["exercise_id"]?.toString()))
                .length;
            progress = completed / videos.length;
          }

          return {
            "_id": course["_id"],
            "title": course["title"] ?? AppLocalizations.of(context)?.untitled ?? "بدون عنوان",
            "subject": course["subject"] ?? AppLocalizations.of(context)?.unspecified ?? "غير محدد",
            "image": course["photo"] ?? "https://via.placeholder.com/150",
            "isPurchased": true,
            "isCompleted": progress >= 1.0 && videos.isNotEmpty,
            "teacher": course["Teachername"] ?? AppLocalizations.of(context)?.unknownPerson ?? "مجهول",
            "videoslist": videos,
            "progress": progress,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("❌ Error fetching purchased courses: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;

    List<Map<String, dynamic>> filteredCourses = [];
    if (selectedTabIndex == 0) {
      filteredCourses = purchasedCourses;
    } else if (selectedTabIndex == 1) {
      filteredCourses =
          purchasedCourses.where((c) => c["isCompleted"] == false).toList();
    } else {
      filteredCourses =
          purchasedCourses.where((c) => c["isCompleted"] == true).toList();
    }

    final int completedCount =
        purchasedCourses.where((c) => c["isCompleted"] == true).length;
    final int inProgressCount =
        purchasedCourses.where((c) => c["isCompleted"] == false).length;

    final double screenWidth = size.width;
    final int crossAxisCount = screenWidth >= 1100
        ? 4
        : screenWidth >= 750
            ? 3
            : 2;
    final double aspectRatio = screenWidth >= 750 ? 0.85 : 0.65;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
                top: topPadding + 20, left: 20, right: 20, bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: AppColors.getBrandGradient(),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsFill.bookOpen,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)?.courses ?? AppLocalizations.of(context)?.myCoursesTab ?? "كورساتي",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2), width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsFill.fire,
                                      color: AppColors.orangeStatus(isDark), size: 18),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$streakCount',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2), width: 1),
                              ),
                              child: const Icon(PhosphorIconsRegular.bell,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildTab(0, AppLocalizations.of(context)?.allTab ?? "الكل"),
                        const SizedBox(width: 12),
                        _buildTab(1, AppLocalizations.of(context)?.inProgressCountTab(inProgressCount.toString()) ?? "قيد الدراسة ($inProgressCount)"),
                        const SizedBox(width: 12),
                        _buildTab(2, AppLocalizations.of(context)?.completedCountTab(completedCount.toString()) ?? "المكتملة ($completedCount)"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body Section
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    color: AppColors.sky(isDark),
                  ))
                : filteredCourses.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)?.noPurchasedCourses ??
                              AppLocalizations.of(context)?.noCourses ?? "لا توجد كورسات",
                          style: GoogleFonts.cairo(
                            color: AppColors.getTextSecondaryColor(isDark),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: GridView.builder(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 24, bottom: 150),
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = filteredCourses[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailsPage(
                                        title: course["title"],
                                        image: course["image"],
                                        isPurchased: course["isPurchased"],
                                        videoslist: course["videoslist"],
                                        courseId: course["_id"],
                                        teacherName: course["teacher"],
                                      ),
                                    ),
                                  );
                                },
                                child: _buildCourseCard(
                                  context: context,
                                  img: course["image"],
                                  title: course["title"],
                                  subject: "${course["subject"]}",
                                  teacher: "${course["teacher"]}",
                                  isCompleted: course["isCompleted"],
                                  progress: course["progress"] ?? 0.0,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isSelected ? AppColors.sky(isDark) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String img,
    required String title,
    required String subject,
    required String teacher,
    required bool isCompleted,
    double progress = 0.0,
  }) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadowColor(isDark),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(
          color: AppColors.getCardBorderColor(isDark),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/images/Group 1.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: AppColors.getTextColor(isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextSecondaryColor(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        height: 40,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.getCircleBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    color: AppColors.sky(isDark).withOpacity(0.15),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsFill.playCircle,
                                        color: AppColors.sky(isDark),
                                        textDirection: TextDirection.ltr,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 5.5),
                                      Text(
                                        AppLocalizations.of(context)?.continueBtn ?? "متابعة",
                                        style: GoogleFonts.cairo(
                                          height: 1.3,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.sky(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sky(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Completed Stamp overlay
          if (isCompleted)
            Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: -0.2, // Tilted stamp
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.redStatus(isDark).withOpacity(0.8), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.getBackgroundColor(isDark).withOpacity(0.8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.finishedStatus ?? "تم الانتهاء",
                          style: GoogleFonts.cairo(
                            color: AppColors.redStatus(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)?.doneThanksGod ?? "تم بحمد الله",
                          style: GoogleFonts.cairo(
                            color: AppColors.redStatus(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
