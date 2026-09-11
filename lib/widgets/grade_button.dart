import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildGradeButton({
  required String grade,
  required String selectedGrade,
  required VoidCallback onSelect,
}) {
  final isSelected = selectedGrade == grade;
  return GestureDetector(
    onTap: onSelect,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.white54,
            width: 1),
        color: isSelected ? AppColors.primaryBlue : AppColors.black,
      ),
      child: Text(
        grade,
        style: GoogleFonts.tajawal(
            color: isSelected ? AppColors.white : AppColors.white70,
            fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    ),
  );
}
