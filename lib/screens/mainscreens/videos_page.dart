import 'package:flutter/material.dart';
import 'package:flutter_version/screens/appearing_screens/video_watch_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_version/screens/appearing_screens/search_results_page.dart';
import '../../l10n/app_localizations.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({Key? key}) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<Map<String, dynamic>> purchasedVideos = [];
  bool _isLoading = true;
  int streakCount = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(AppLocalizations.of(context)?.choiceA ?? "أ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA2 ?? "إ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterA3 ?? "آ",
            AppLocalizations.of(context)?.letterA1 ?? "ا")
        .replaceAll(AppLocalizations.of(context)?.letterTa ?? "ة",
            AppLocalizations.of(context)?.letterHa ?? "ه")
        .replaceAll(AppLocalizations.of(context)?.letterYa ?? "ى",
            AppLocalizations.of(context)?.letterYaa ?? "ي")
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _fetchPurchasedVideos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _normalize(_searchController.text);
      });
    });
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        streakCount = prefs.getInt('streak_count') ?? 0;
      });
    }
  }

  Future<void> _fetchPurchasedVideos() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> courseToSubject = {};
      try {
        final responses = await Future.wait([
          ApiService().request("student/course/getstudentcourses", null, "GET"),
          ApiService().request("student/course/getpaidcourses", null, "GET"),
        ]);
        for (final res in responses) {
          if (res != null && res.statusCode == 200 && res.data is List) {
            for (final course in res.data) {
              final title = course["title"] ?? "";
              final subject = course["subject"] ?? "";
              if (title.isNotEmpty && subject.isNotEmpty) {
                courseToSubject[title] = subject;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ Error fetching courses for subject mapping: $e");
      }

      final response = await ApiService().request(
        "student/video/getvideos",
        null,
        "GET",
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data is List) {
        final storage = const FlutterSecureStorage();
        final rawVideos = response.data as List;

        final videos = await Future.wait(
            rawVideos.map<Future<Map<String, dynamic>>>((video) async {
          final id = video["_id"] ?? "";
          final listenedLocal = await storage.read(key: "listened_$id");
          final double progressVal = (listenedLocal == "true") ? 1.0 : 0.0;
          final courseTitle = video["CourseName"] ?? "";
          return {
            "title": video["description"] ?? "",
            "thumbnail": video["photo"] ?? "",
            "videoUrl": video["videoURL"] ?? "",
            "courseTitle": courseTitle,
            "id": id,
            "additionalVideos": video["additionalVideos"] ?? [],
            "subject": video["subject"] ??
                video["Subject"] ??
                courseToSubject[courseTitle] ??
                "",
            "progress": progressVal,
            "bubbleMessage": video["bubbleMessage"] ?? "",
            "bubbleInterval": video["bubbleInterval"] ?? 0,
          };
        }));

        purchasedVideos = List<Map<String, dynamic>>.from(videos);
      }
    } catch (e) {
      debugPrint("❌ Error fetching videos: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          initialQuery: query,
          availableCourses: [], // Not available in this page
          myCourses: [], // Not available in this page
          videos: purchasedVideos,
          teachers: [], // Not available in this page
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: [
          _buildHeader(context, topPadding),
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.sky(isDark)))
                : RefreshIndicator(
                    onRefresh: _fetchPurchasedVideos,
                    child: Builder(
                      builder: (context) {
                        final filteredVideos = purchasedVideos.where((video) {
                          final title = _normalize(video["title"] ?? "");
                          final courseTitle =
                              _normalize(video["courseTitle"] ?? "");
                          final subject = _normalize(video["subject"] ?? "");
                          return title.contains(_searchQuery) ||
                              courseTitle.contains(_searchQuery) ||
                              subject.contains(_searchQuery);
                        }).toList();

                        if (filteredVideos.isEmpty) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        PhosphorIconsRegular.magnifyingGlass,
                                        size: 48,
                                        color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? AppLocalizations.of(context)!
                                              .noPurchasedVideos
                                          : AppLocalizations.of(context)
                                                  ?.noSearchMatchSlash ??
                                              "لا توجد نتائج بحث مطابقة لـ \"$_searchQuery\"",
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        color: AppColors.getTextSecondaryColor(
                                            isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final double screenWidth =
                            MediaQuery.of(context).size.width;
                        final int crossAxisCount = screenWidth >= 1100
                            ? 4
                            : screenWidth >= 750
                                ? 3
                                : 2;
                        final double aspectRatio =
                            screenWidth >= 750 ? 0.88 : 0.72;

                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  top: 24, left: 16, right: 16, bottom: 150),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: aspectRatio,
                              ),
                              itemCount: filteredVideos.length,
                              itemBuilder: (context, index) {
                                final video = filteredVideos[index];
                                return _buildVideoCard(video, isDark);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    final bool isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsFill.videoCamera,
                          color: Colors.white,
                          size: 28,
                          textDirection: TextDirection.ltr),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)?.videosListLabel ??
                            "فيديوهات",
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
                                color: AppColors.orangeStatus(isDark),
                                size: 18),
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
              // ── Search Bar copied from home_screen.dart ──
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)
                              ?.searchSubjectCourseHint ??
                          "ابحث عن مادة او كورس",
                      hintStyle: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass,
                          color: Colors.white.withOpacity(0.7), size: 24),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 24,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white70, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, bool isDark) {
    final double progressVal = (video["progress"] is num)
        ? (video["progress"] as num).toDouble()
        : 0.0;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
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
        if (result is Map && result["listened"] == true) {
          setState(() {
            video["progress"] = 1.0;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      video["thumbnail"],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        "assets/images/Group 1.png",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (video["subject"] != null &&
                      video["subject"].toString().isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getBackgroundColor(isDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video["subject"],
                          style: GoogleFonts.cairo(
                            color: AppColors.getTextHintColor(isDark),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video["title"],
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.getTextColor(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video["courseTitle"],
                    style: GoogleFonts.cairo(
                        color: AppColors.getTextHintColor(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
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
                        // Progress Fill
                        if (progressVal > 0)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: progressVal,
                                child: Container(
                                  color:
                                      AppColors.sky(isDark).withOpacity(0.15),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    AppLocalizations.of(context)?.continueBtn ??
                                        "متابعة",
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
                                "${(progressVal * 100).toInt()}%",
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
          ],
        ),
      ),
    );
  }
}
