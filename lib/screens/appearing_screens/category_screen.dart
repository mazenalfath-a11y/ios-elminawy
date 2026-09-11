import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/data/category_model.dart';
import 'package:flutter_version/screens/appearing_screens/course_details_page.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/navigation_animations.dart';
import 'package:flutter_version/utilities/theme_helper.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;
  final List<String> breadcrumb;
  final Set<String> purchasedCourseIds;
  final List<Map<String, dynamic>> purchasedCourses;

  const CategoryScreen({
    Key? key,
    required this.category,
    this.breadcrumb = const [],
    this.purchasedCourseIds = const {},
    this.purchasedCourses = const [],
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Category> childCategories = [];
  List<Map<String, dynamic>> coursesInCategory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Check if this category has children
      final childResponse =
          await _apiService.getChildCategories(widget.category.id);
      if (childResponse != null && childResponse.statusCode == 200) {
        final List childData = childResponse.data;
        childCategories = childData.map((c) => Category.fromJson(c)).toList();
      }

      // If no children (leaf category), fetch courses
      if (childCategories.isEmpty) {
        final coursesResponse =
            await _apiService.getCoursesInCategory(widget.category.id);
        if (coursesResponse != null && coursesResponse.statusCode == 200) {
          final List courseData = coursesResponse.data;
          coursesInCategory = courseData.map((c) {
            final courseId = c["_id"];
            final isPurchased = widget.purchasedCourseIds.contains(courseId);

            // If purchased, use full data from purchasedCourses
            if (isPurchased) {
              final purchasedCourse = widget.purchasedCourses.firstWhere(
                (pc) => pc["id"] == courseId,
                orElse: () => <String, dynamic>{},
              );
              if (purchasedCourse.isNotEmpty) {
                return purchasedCourse;
              }
            }

            // Otherwise use category API data
            return {
              "id": courseId,
              "Teacher": c["Teacher"],
              "title": c["title"] ?? "",
              "image": c["photo"] ?? "assets/images/Group 1.png",
              "price": c["price"] ?? 0,
              "subject":
                  c["subject"] ?? AppLocalizations.of(context)!.undefined,
              "videoslist": c["videoslist"] ?? [],
              "isPurchased": false,
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading category data: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    // final currentBreadcrumb = [...widget.breadcrumb, widget.category.name];

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        elevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.cairo(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 10),
                    // _buildBreadcrumb(currentBreadcrumb),
                    // const SizedBox(height: 20),
                    if (childCategories.isNotEmpty) ...[
                      _buildCategoriesSection(),
                    ] else ...[
                      _buildCoursesSection(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // Widget _buildBreadcrumb(List<String> breadcrumb) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     reverse: true, // RTL
  //     child: Row(
  //       children: [
  //         for (int i = 0; i < breadcrumb.length; i++) ...[
  //           Text(
  //             breadcrumb[breadcrumb.length - 1 - i],
  //             style: GoogleFonts.cairo(
  //               color: Theme.of(context)
  //                   .textTheme
  //                   .bodyMedium
  //                   ?.color
  //                   ?.withOpacity(0.7),
  //               fontSize: 14,
  //             ),
  //           ),
  //           if (i < breadcrumb.length - 1)
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 8),
  //               child: Icon(
  //                 Icons.arrow_back_ios,
  //                 size: 12,
  //                 color: Theme.of(context)
  //                     .textTheme
  //                     .bodyMedium
  //                     ?.color
  //                     ?.withOpacity(0.5),
  //               ),
  //             ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.categories,
          style: GoogleFonts.cairo(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: childCategories.length,
          itemBuilder: (context, index) {
            final category = childCategories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  createSlideRoute(
                    CategoryScreen(
                      category: category,
                      breadcrumb: [...widget.breadcrumb, widget.category.name],
                      purchasedCourseIds: widget.purchasedCourseIds,
                      purchasedCourses: widget.purchasedCourses,
                    ),
                  ),
                );
              },
              child: _buildCategoryCard(category),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.getShadowColor(context),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (category.photo != null && category.photo!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  category.photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Icon(
                      Icons.category,
                      size: 60,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.category,
                    size: 60,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            // Text overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  category.name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    if (coursesInCategory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            AppLocalizations.of(context)!.noCoursesAvailable,
            style: GoogleFonts.cairo(
              color: ThemeHelper.getTextHintColor(context),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.courses,
          style: GoogleFonts.cairo(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coursesInCategory.length,
          itemBuilder: (context, index) {
            final course = coursesInCategory[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    createSlideRoute(
                      CourseDetailsPage(
                        title: course["title"],
                        image: course["image"],
                        isPurchased: course["isPurchased"],
                        price: course["price"],
                        videoslist: course["videoslist"],
                        courseId: course["id"],
                      ),
                    ),
                  );
                },
                child: _buildCourseCard(course),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        border:
            Border.all(color: AppColors.getCardBorderColor(isDark), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.getShadowColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Image.network(
              course["image"],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                "assets/images/Group 1.png",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course["title"],
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!
                        .priceWithCurrency(course["price"] ?? 0),
                    style: GoogleFonts.cairo(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
