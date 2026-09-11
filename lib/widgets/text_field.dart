import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:provider/provider.dart';

Widget buildTextField(
  BuildContext context,
  String hint,
  IconData icon,
  TextEditingController c, {
  bool isPassword = false,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDark = themeProvider.isDarkMode;

  return TextField(
    textAlign: TextAlign.end,
    controller: c,
    obscureText: isPassword,
    style: TextStyle(color: AppColors.getInputTextColor(isDark)),
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.getInputBackgroundColor(isDark),
      hintText: hint,
      hintStyle: GoogleFonts.tajawal(
        color: AppColors.getInputHintColor(isDark),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.getIconColor(isDark),
        size: 22,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.getInputBorderColor(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryBlue),
      ),
    ),
  );
}
