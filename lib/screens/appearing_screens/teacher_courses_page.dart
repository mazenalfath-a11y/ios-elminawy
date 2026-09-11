import 'package:flutter/material.dart';
import 'package:flutter_version/screens/appearing_screens/course_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class TeacherCoursesPage extends StatelessWidget {
  final String teacherName;
  final String teacherId;
  final List<Map<String, dynamic>> allCourses;

  const TeacherCoursesPage({
    Key? key,
    required this.teacherName,
    required this.teacherId,
    required this.allCourses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredCourses =
        allCourses.where((course) => course["Teacher"] == teacherId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teacherCourses(teacherName)),
      ),
      body: filteredCourses.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noCoursesForTeacher,
                style: GoogleFonts.cairo(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return ListTile(
                  title: Text(course["title"]),
                  subtitle: Text(course["subject"] ?? ""),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(course["image"]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsPage(
                          title: course["title"],
                          image: course["image"],
                          isPurchased: course["isPurchased"] ?? false,
                          videoslist: course["videoslist"],
                          price: course["price"] ?? 0,
                          courseId: course["id"],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
