import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import '../../utilities/theme_provider.dart';
import '../../utilities/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../appearing_screens/course_details_page.dart';
import '../appearing_screens/video_watch_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final List<Map<String, dynamic>> availableCourses;
  final List<Map<String, dynamic>> myCourses;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> teachers;

  const SearchResultsPage({
    Key? key,
    required this.initialQuery,
    required this.availableCourses,
    required this.myCourses,
    required this.videos,
    required this.teachers,
  }) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late TextEditingController _searchController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchQuery = _normalize(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(AppLocalizations.of(context)?.choiceA ?? "أ", AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA2 ?? "إ", AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA3 ?? "آ", AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterTa ?? "ة", AppLocalizations.of(context)?.letterHa ?? "ه")
        .replaceAll(AppLocalizations.of(context)?.letterYa ?? "ى", AppLocalizations.of(context)?.letterYaa ?? "ي")
        .trim();
  }

  List<Map<String, dynamic>> get _filteredCourses {
    final all = [...widget.myCourses, ...widget.availableCourses];
    if (_searchQuery.isEmpty) return all;
    return all.where((c) {
      final title = _normalize(c["title"] ?? "");
      final subject = _normalize(c["subject"] ?? "");
      final teacher = _normalize(c["teacher"] ?? "");
      return title.contains(_searchQuery) ||
          subject.contains(_searchQuery) ||
          teacher.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredVideos {
    if (_searchQuery.isEmpty) return widget.videos;
    return widget.videos.where((v) {
      final title = _normalize(v["title"] ?? "");
      final course = _normalize(v["courseTitle"] ?? "");
      final subject = _normalize(v["subject"] ?? "");
      return title.contains(_searchQuery) ||
          course.contains(_searchQuery) ||
          subject.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final topPadding = MediaQuery.of(context).padding.top;

    final courses = _filteredCourses;
    final videos = _filteredVideos;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          _buildHeader(context, topPadding, isDark),
          Expanded(
            child: (courses.isEmpty && videos.isEmpty)
                ? _buildEmptyState(isDark)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (courses.isNotEmpty) ...[
                        _buildSectionHeader(AppLocalizations.of(context)?.coursesTab ?? "الكورسات", courses.length, isDark),
                        const SizedBox(height: 16),
                        ...courses.map((c) => _buildCourseCard(c, isDark)),
                        const SizedBox(height: 24),
                      ],
                      if (videos.isNotEmpty) ...[
                        _buildSectionHeader(
                            AppLocalizations.of(context)?.videosTab ?? "الفيديوهات", videos.length, isDark),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: videos.length,
                          itemBuilder: (context, index) =>
                              _buildVideoCard(videos[index], isDark),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
          top: topPadding + 10, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: AppColors.getBrandGradient(),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.searchResults ?? "نتائج البحث",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 40), // spacer for balance
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.searchForSomethingElse ?? "ابحث عن شيء آخر...",
                  hintStyle: GoogleFonts.cairo(
                      color: Colors.white.withOpacity(0.6), fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                      color: Colors.white, size: 22),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white70, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = _normalize(val)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
              color: AppColors.getTextColor(isDark),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.sky(isDark).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$count",
            style: GoogleFonts.cairo(
                color: AppColors.sky(isDark),
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, bool isDark) {
    final bool isPurchased = course["isPurchased"] ?? false;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailsPage(
              title: course["title"],
              image: course["image"],
              isPurchased: isPurchased,
              videoslist: course["videoslist"],
              courseId: course["id"],
              price: course["price"],
              teacherName: course["teacher"],
              subject: course["subject"],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(20)),
              child: Image.network(
                course["image"],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                    "assets/images/Group 1.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      course["title"],
                      style: GoogleFonts.cairo(
                          color: AppColors.getTextColor(isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course["subject"] ?? "",
                      style: GoogleFonts.cairo(
                          color: AppColors.getTextSecondaryColor(isDark),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isPurchased)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(AppLocalizations.of(context)?.isSubscribed ?? "تم الاشتراك",
                                style: GoogleFonts.cairo(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          )
                        else
                          Text(
                            AppLocalizations.of(context)!
                                .priceWithCurrency(course["price"] ?? 0),
                            style: GoogleFonts.cairo(
                                color: AppColors.sky(isDark),
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        const Icon(Icons.arrow_back_ios,
                            size: 12, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoWatchPage(
              videoTitle: video["title"],
              videoUrl: video["videoUrl"],
              v_id: video["id"],
              exerciseId: video["exerciseId"] ?? "",
              additionalVideos: video["additionalVideos"] ?? [],
              courseId: "",
              files: [],
              exerciseArr: [],
              bubbleMessage: video["bubbleMessage"],
              bubbleInterval: video["bubbleInterval"],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  video["thumbnail"] ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                      "assets/images/Group 1.png",
                      fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    video["title"],
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    video["courseTitle"] ?? "",
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.getTextSecondaryColor(isDark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.magnifyingGlass,
              size: 64,
              color: AppColors.getTextSecondaryColor(isDark).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noMatchingResults ?? "لم نجد نتائج مطابقة لبحثك",
            style: GoogleFonts.cairo(
                color: AppColors.getTextSecondaryColor(isDark),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          Text(
            AppLocalizations.of(context)?.tryDifferentWords ?? "جرب البحث بكلمات مختلفة",
            style: GoogleFonts.cairo(
                color: AppColors.getTextSecondaryColor(isDark).withOpacity(0.7),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
