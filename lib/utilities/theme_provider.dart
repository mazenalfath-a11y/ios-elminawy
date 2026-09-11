import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_config.dart';
import 'app_colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  Color _primaryColor = const Color(0XFF0084D1);
  Color get primaryColor => _primaryColor;

  Color _secondaryColor = const Color(0xFF1A37F7);
  Color get secondaryColor => _secondaryColor;

  Color _backgroundColor = const Color(0xFFF5F5F5);
  Color get backgroundColor => _backgroundColor;

  Color _surfaceColor = const Color(0xFFFFFFFF);
  Color get surfaceColor => _surfaceColor;

  Color _textPrimaryColor = const Color(0xFF212529);
  Color get textPrimaryColor => _textPrimaryColor;

  Color _textSecondaryColor = const Color(0xFF6C757D);
  Color get textSecondaryColor => _textSecondaryColor;

  Color _successColor = const Color(0xFF28A745);
  Color get successColor => _successColor;

  Color _errorColor = const Color(0xFFDC3545);
  Color get errorColor => _errorColor;

  ThemeMode get currentTheme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider({ThemeMode? initialThemeMode})
      : _isDarkMode = (initialThemeMode != null) 
            ? initialThemeMode == ThemeMode.dark 
            : AppConfig.defaultIsDarkMode {
    _loadThemeFromPrefs();
  }

  // Individual color setters
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    AppColors.primaryColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setSecondaryColor(Color color) {
    _secondaryColor = color;
    AppColors.secondaryColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    AppColors.backgroundColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setSurfaceColor(Color color) {
    _surfaceColor = color;
    AppColors.surfaceColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setTextPrimaryColor(Color color) {
    _textPrimaryColor = color;
    AppColors.textPrimaryColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setTextSecondaryColor(Color color) {
    _textSecondaryColor = color;
    AppColors.textSecondaryColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setSuccessColor(Color color) {
    _successColor = color;
    AppColors.successColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void setErrorColor(Color color) {
    _errorColor = color;
    AppColors.errorColor = color;
    notifyListeners();
    _saveThemeToPrefs();
  }

  // NEW: Set all colors from API response (Company Settings)
  void setColorsFromCompanySettings({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color success,
    required Color error,
  }) {
    _primaryColor = primary;
    _secondaryColor = secondary;
    _backgroundColor = background;
    _surfaceColor = surface;
    _textPrimaryColor = textPrimary;
    _textSecondaryColor = textSecondary;
    _successColor = success;
    _errorColor = error;

    // Sync with static AppColors
    AppColors.primaryColor = primary;
    AppColors.secondaryColor = secondary;
    AppColors.backgroundColor = background;
    AppColors.surfaceColor = surface;
    AppColors.textPrimaryColor = textPrimary;
    AppColors.textSecondaryColor = textSecondary;
    AppColors.successColor = success;
    AppColors.errorColor = error;

    notifyListeners();
    _saveThemeToPrefs();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveThemeToPrefs();
  }

  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('isDarkMode')) {
      _isDarkMode = prefs.getBool('isDarkMode') ?? _isDarkMode;
    }
    if (prefs.containsKey('primaryColor')) {
      final colorValue = prefs.getInt('primaryColor');
      if (colorValue != null) {
        _primaryColor = Color(colorValue);
        AppColors.primaryColor = _primaryColor;
      }
    }
    if (prefs.containsKey('secondaryColor')) {
      final colorValue = prefs.getInt('secondaryColor');
      if (colorValue != null) {
        _secondaryColor = Color(colorValue);
        AppColors.secondaryColor = _secondaryColor;
      }
    }
    if (prefs.containsKey('backgroundColor')) {
      final colorValue = prefs.getInt('backgroundColor');
      if (colorValue != null) {
        _backgroundColor = Color(colorValue);
        AppColors.backgroundColor = _backgroundColor;
      }
    }
    if (prefs.containsKey('surfaceColor')) {
      final colorValue = prefs.getInt('surfaceColor');
      if (colorValue != null) {
        _surfaceColor = Color(colorValue);
        AppColors.surfaceColor = _surfaceColor;
      }
    }
    if (prefs.containsKey('textPrimaryColor')) {
      final colorValue = prefs.getInt('textPrimaryColor');
      if (colorValue != null) {
        _textPrimaryColor = Color(colorValue);
        AppColors.textPrimaryColor = _textPrimaryColor;
      }
    }
    if (prefs.containsKey('textSecondaryColor')) {
      final colorValue = prefs.getInt('textSecondaryColor');
      if (colorValue != null) {
        _textSecondaryColor = Color(colorValue);
        AppColors.textSecondaryColor = _textSecondaryColor;
      }
    }
    if (prefs.containsKey('successColor')) {
      final colorValue = prefs.getInt('successColor');
      if (colorValue != null) {
        _successColor = Color(colorValue);
        AppColors.successColor = _successColor;
      }
    }
    if (prefs.containsKey('errorColor')) {
      final colorValue = prefs.getInt('errorColor');
      if (colorValue != null) {
        _errorColor = Color(colorValue);
        AppColors.errorColor = _errorColor;
      }
    }
    notifyListeners();
  }

  void _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    prefs.setInt('primaryColor', _primaryColor.value);
    prefs.setInt('secondaryColor', _secondaryColor.value);
    prefs.setInt('backgroundColor', _backgroundColor.value);
    prefs.setInt('surfaceColor', _surfaceColor.value);
    prefs.setInt('textPrimaryColor', _textPrimaryColor.value);
    prefs.setInt('textSecondaryColor', _textSecondaryColor.value);
    prefs.setInt('successColor', _successColor.value);
    prefs.setInt('errorColor', _errorColor.value);
  }
}
