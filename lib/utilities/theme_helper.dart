import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeHelper {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getTextColor(BuildContext context) {
    return AppColors.getTextColor(isDarkMode(context));
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return AppColors.getTextSecondaryColor(isDarkMode(context));
  }

  static Color getTextHintColor(BuildContext context) {
    return AppColors.getTextHintColor(isDarkMode(context));
  }

  static Color getCardBackgroundColor(BuildContext context) {
    return AppColors.getCardBackgroundColor(isDarkMode(context));
  }

  static Color getSurfaceColor(BuildContext context) {
    return AppColors.getSurfaceColor(isDarkMode(context));
  }

  static Color getBorderColor(BuildContext context) {
    return AppColors.getBorderColor(isDarkMode(context));
  }

  static Color getDividerColor(BuildContext context) {
    return AppColors.getDividerColor(isDarkMode(context));
  }

  static Color getOverlayColor(BuildContext context) {
    return AppColors.getOverlayColor(isDarkMode(context));
  }

  static Color getShadowColor(BuildContext context) {
    return AppColors.getShadowColor(isDarkMode(context));
  }

  static Color getButtonBackgroundColor(BuildContext context) {
    return AppColors.getButtonBackgroundColor(isDarkMode(context));
  }

  static Color getButtonTextColor(BuildContext context) {
    return AppColors.getButtonTextColor(isDarkMode(context));
  }

  static Color getButtonBorderColor(BuildContext context) {
    return AppColors.getButtonBorderColor(isDarkMode(context));
  }

  static Color getTabBackgroundColor(BuildContext context) {
    return AppColors.getTabBackgroundColor(isDarkMode(context));
  }

  static Color getTabTextColor(BuildContext context) {
    return AppColors.getTabTextColor(isDarkMode(context));
  }

  static Color getSelectedTabColor(BuildContext context) {
    return AppColors.getSelectedTabColor(isDarkMode(context));
  }

  static Color getSelectedTabTextColor(BuildContext context) {
    return AppColors.getSelectedTabTextColor(isDarkMode(context));
  }

  static Color getDialogBackgroundColor(BuildContext context) {
    return AppColors.getDialogBackgroundColor(isDarkMode(context));
  }

  static Color getDialogTextColor(BuildContext context) {
    return AppColors.getDialogTextColor(isDarkMode(context));
  }

  static Color getListTileBackgroundColor(BuildContext context) {
    return AppColors.getListTileBackgroundColor(isDarkMode(context));
  }

  static Color getListTileTextColor(BuildContext context) {
    return AppColors.getListTileTextColor(isDarkMode(context));
  }

  static Color getListTileSubtitleColor(BuildContext context) {
    return AppColors.getListTileSubtitleColor(isDarkMode(context));
  }

  static Color getVideoPlayerBackgroundColor(BuildContext context) {
    return AppColors.getVideoPlayerBackgroundColor(isDarkMode(context));
  }

  static Color getVideoPlayerTextColor(BuildContext context) {
    return AppColors.getVideoPlayerTextColor(isDarkMode(context));
  }

  static Color getLiveScreenBackgroundColor(BuildContext context) {
    return AppColors.getLiveScreenBackgroundColor(isDarkMode(context));
  }

  static Color getLiveScreenTextColor(BuildContext context) {
    return AppColors.getLiveScreenTextColor(isDarkMode(context));
  }

  static Color getExamCardBackgroundColor(BuildContext context) {
    return AppColors.getExamCardBackgroundColor(isDarkMode(context));
  }

  static Color getExamCardTextColor(BuildContext context) {
    return AppColors.getExamCardTextColor(isDarkMode(context));
  }

  static Color getExamCardSubtitleColor(BuildContext context) {
    return AppColors.getExamCardSubtitleColor(isDarkMode(context));
  }

  static Color getPdfViewerBackgroundColor(BuildContext context) {
    return AppColors.getPdfViewerBackgroundColor(isDarkMode(context));
  }

  static Color getPdfViewerTextColor(BuildContext context) {
    return AppColors.getPdfViewerTextColor(isDarkMode(context));
  }

  static Color getImageViewerBackgroundColor(BuildContext context) {
    return AppColors.getImageViewerBackgroundColor(isDarkMode(context));
  }

  static Color getImageViewerIconColor(BuildContext context) {
    return AppColors.getImageViewerIconColor(isDarkMode(context));
  }

  static Color getInputBackgroundColor(BuildContext context) {
    return AppColors.getInputBackgroundColor(isDarkMode(context));
  }

  static Color getInputTextColor(BuildContext context) {
    return AppColors.getInputTextColor(isDarkMode(context));
  }

  static Color getInputHintColor(BuildContext context) {
    return AppColors.getInputHintColor(isDarkMode(context));
  }

  static Color getInputBorderColor(BuildContext context) {
    return AppColors.getInputBorderColor(isDarkMode(context));
  }

  static Color getIconColor(BuildContext context) {
    return AppColors.getIconColor(isDarkMode(context));
  }
}
