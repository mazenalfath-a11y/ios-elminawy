import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black26 = Color(0x42000000);
  static const Color black87 = Color(0xDD000000);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color green = Color(0xFF00FF00);
  static const Color green100 = Color(0xFF00FF00);
  static const Color green900 = Color(0xFF008000);
  static const Color greenAccent = Color(0xFF00FF00);
  static const Color greenSuccess = Color(0xFF00BC7D);
  static const Color grey = Color(0xFF808080);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey900 = Color(0xFF212121);
  static const Color blue = Color(0xFF0000FF);
  static const Color blueAccent = Color(0xFF0000FF);
  static const Color red = Color(0xFFFF0000);
  static const Color amber = Color(0xFFFFC107);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color sky1 = Color(0xFF155DFC);
  static const Color sky2 = Color(0xFF2B7FFF);
  static const Color lightGrad = Color(0xFFDBEAFE);
  static const Color lightIcon = Color(0xFF90A1B9);
  static const Color darkTextSecondaryColor = Color(0xFF90A1B9);

  // User Configurable Primary Color
  static const Color _defaultPrimary = Color(0xFF0084D1);
  static Color primaryColor = _defaultPrimary;

  static const Color _defaultSecondary = Color(0xFF90A1B9);
  static Color secondaryColor = _defaultSecondary;

  static const Color _defaultBackground = Color(0xFFF5F5F5);
  static Color backgroundColor = _defaultBackground;

  static const Color _defaultSurface = Color(0xFFFFFFFF);
  static Color surfaceColor = _defaultSurface;

  static const Color _defaultTextPrimary = Color(0x00000000);
  static Color textPrimaryColor = _defaultTextPrimary;

  static const Color _defaultTextSecondary = Color(0xFF62748E);
  static Color textSecondaryColor = _defaultTextSecondary;

  static const Color _defaultSuccess = Color(0xFF28A745);
  static Color successColor = _defaultSuccess;

  static const Color _defaultError = Color(0xFFDC3545);
  static Color errorColor = _defaultError;

  // Primary brand color (Getter for backward compatibility)
  static Color get primaryBlue => primaryColor;
  static Color get primaryBlueDark => primaryColor; // Simplification

  // Light theme colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFF0F0F0);
  static const Color lightCardBackground = Color(0xFFFAFAFA);
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightBorder = Color(0xFFE9ECEF);
  static const Color lightDivider = Color(0xFFDEE2E6);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F172B);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF020618);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF4F4F4F);

  // --- Internal Helpers for Consistency ---

  static Color _getCommonBackground(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : backgroundColor;

  static Color _getTextPrimary(bool isDark) =>
      isDark ? Colors.white : textPrimaryColor;

  static Color _getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondaryColor : textSecondaryColor;

  static Color _getBorder(bool isDark) =>
      isDark ? const Color(0xFF314158) : const Color(0xFFE2E8F0);

  // --- Public Getters (Simplified) ---
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  // Input Field Colors
  static Color getInputBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF1D293D) : surfaceColor;

  static Color getInputTextColor(bool isDark) => _getTextPrimary(isDark);
  static Color getInputHintColor(bool isDark) => _getTextSecondary(isDark);
  static Color getInputBorderColor(bool isDark) => _getBorder(isDark);

  // Generic Text
  static Color getTextColor(bool isDark) => _getTextPrimary(isDark);
  static Color getTextSecondaryColor(bool isDark) => _getTextSecondary(isDark);
  static Color getTextHintColor(bool isDark) => _getTextSecondary(isDark);

  // Structural
  static Color getCardBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF020618).withOpacity(0.8) : surfaceColor;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? const Color(0xFF1E1E1E) : surfaceColor;

  static Color getAnswerSelectedColor(bool isDark) =>
      isDark ? Color(0XFF2B7FFF1).withOpacity(0.1) : Color(0XFFEFF6FF);

  static Color getBorderColor(bool isDark) =>
      isDark ? const Color(0xFF404040) : const Color(0xFFE9ECEF);

  static Color getDividerColor(bool isDark) =>
      isDark ? const Color(0xFF1D293D) : const Color(0xFFDEE2E6);

  static Color getOverlayColor(bool isDark) =>
      isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1);

  static Color getShadowColor(bool isDark) =>
      isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);

  static Color getModalSheetColor(bool isDark) =>
      isDark ? Color(0XFF0F172B) : Color(0XFFF8FAFC);

  static Color getCardBorderColor(bool isDark) =>
      isDark ? const Color(0xFF314158) : const Color(0xFFE2E8F0);

  static Color sky(bool isDark) =>
      primaryColor != _defaultPrimary ? primaryColor : (isDark ? sky2 : sky1);

  // Icons
  static Color getIconColor(bool isDark) =>
      isDark ? Color(0XFF90A1B9) : Color(0XFF62748E);

  // Buttons
  static Color getButtonBackgroundColor(bool isDark) =>
      _getCommonBackground(isDark);
  static Color getButtonTextColor(bool isDark) => _getTextPrimary(isDark);
  static Color getButtonBorderColor(bool isDark) => _getBorder(isDark);

  // Tabs
  static Color getTabBackgroundColor(bool isDark) =>
      _getCommonBackground(isDark);
  static Color getTabTextColor(bool isDark) => _getTextSecondary(isDark);
  static Color getSelectedTabColor(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : secondaryColor.withOpacity(0.1);

  static Color getSelectedTabTextColor(bool isDark) =>
      isDark ? Colors.white : primaryColor;

  static Color getSecondHintColor(bool isDark) =>
      isDark ? Color(0XFF90A1B9) : Color(0XFF62748E);

  // Dialogs
  static Color getDialogBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : surfaceColor;
  static Color getDialogTextColor(bool isDark) => _getTextPrimary(isDark);

  // List tile colors
  static Color getListTileBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : surfaceColor;
  static Color getListTileTextColor(bool isDark) => _getTextPrimary(isDark);
  static Color getListTileSubtitleColor(bool isDark) =>
      _getTextSecondary(isDark);

  // Video player colors
  static Color getVideoPlayerBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : Colors.black;
  static Color getVideoPlayerTextColor(bool isDark) => Colors.white;

  // Live screen colors
  static Color getLiveScreenBackgroundColor(bool isDark) =>
      _getCommonBackground(isDark);
  static Color getLiveScreenTextColor(bool isDark) => _getTextPrimary(isDark);

  // Exam colors
  static Color getExamCardBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : surfaceColor;
  static Color getExamCardTextColor(bool isDark) => _getTextPrimary(isDark);
  static Color getExamCardSubtitleColor(bool isDark) =>
      _getTextSecondary(isDark);

  // PDF viewer colors
  static Color getPdfViewerBackgroundColor(bool isDark) =>
      _getCommonBackground(isDark);
  static Color getPdfViewerTextColor(bool isDark) => _getTextPrimary(isDark);

  // Gradient colors
  static List<Color> getLightGradient() => [
        const Color(0xFFE3F2FD),
        const Color(0xFFF3E5F5),
      ];

  static List<Color> getDarkGradient() => [
        const Color(0xFF232526),
        const Color(0xFF414345),
      ];

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0084D1), Color(0xFF1447E6)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // Status colors
  static Color get success => successColor;
  static Color get error => errorColor;
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Image viewer colors
  static Color getImageViewerBackgroundColor(bool isDark) =>
      isDark ? Colors.black : Colors.black;

  static Color getImageViewerIconColor(bool isDark) =>
      isDark ? Colors.white : Colors.white;

  static Color getCircleBackgroundColor(bool isDark) =>
      isDark ? const Color(0xFF1D293D) : const Color(0xFFF1F5F9);

  // Semantic Status Helpers (Controlled by Dashboard successColor and errorColor)
  static Color redStatus(bool isDark) => errorColor;
  static Color greenStatus(bool isDark) => successColor;
  static Color orangeStatus(bool isDark) => const Color(0xFFF59E0B);
  static List<Color> getBrandGradient() => [
        primaryColor,
        primaryColor.withOpacity(0.85),
        secondaryColor != _defaultSecondary
            ? secondaryColor
            : const Color(0xFF38BDF8),
      ];
}
