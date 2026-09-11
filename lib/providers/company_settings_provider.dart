import 'package:flutter/material.dart';
import 'package:flutter_version/models/company_settings_model.dart';
import 'package:flutter_version/data/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_version/data/app_config.dart';

class CompanySettingsProvider with ChangeNotifier {
  CompanySettingsModel? _settings;
  bool _isLoading = false;
  String? _error;

  // Getters
  CompanySettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters
  List<Level> get levels => _settings?.levels ?? [];
  List<Department> get departments => _settings?.departments ?? [];
  List<CombinedLevel> get combinedLevels => _settings?.combinedLevels ?? [];
  bool get useNestedLevels => _settings?.useNestedLevels ?? false;
  bool get useCustomLevels => _settings?.useCustomLevels ?? false;
  bool get useCustomDepartments => _settings?.useCustomDepartments ?? false;
  bool get requireParentPhone => _settings?.requireParentPhone ?? false;
  bool get requireStudentVerify => _settings?.requireStudentVerify ?? false;
  bool get enableOfflinePdf => _settings?.enableOfflinePdf ?? false;
  bool get enableOfflineVideo => _settings?.enableOfflineVideo ?? false;
  bool get enableOfflineCourses => _settings?.enableOfflineCourses ?? false;
  int get offlineCoursesDaysLimit => _settings?.offlineCoursesDaysLimit ?? 7;
  String? get teacherTitle => _settings?.teacherTitle;
  ContactInfo get contactInfo => _settings?.contactInfo ?? ContactInfo();
  OverlayIconDisplay get overlayIconDisplay =>
      _settings?.overlayIconDisplay ?? OverlayIconDisplay();
  bool get fawaterakEnabled => _settings?.fawaterakConfig.enabled ?? false;

  // Color getters
  Color? get primaryColor => _settings?.appColors.primary;
  Color? get secondaryColor => _settings?.appColors.secondary;
  Color? get backgroundColor => _settings?.appColors.background;
  Color? get surfaceColor => _settings?.appColors.surface;
  Color? get textPrimaryColor => _settings?.appColors.textPrimary;
  Color? get textSecondaryColor => _settings?.appColors.textSecondary;
  Color? get successColor => _settings?.appColors.success;
  Color? get errorColor => _settings?.appColors.error;

  // --------------------------------------------------------------------------
  // PUBLIC METHODS
  // --------------------------------------------------------------------------

  /// Inject a pre‑parsed settings object (e.g., from login response)
  Future<void> setSettings(CompanySettingsModel settings) async {
    _settings = settings;
    _error = null;
    _isLoading = false;
    await _saveSettingsLocally(settings);
    notifyListeners();
  }

  /// Ensures company settings exist locally and are not older than 3 days.
  /// If missing or >= 3 days old, fetches fresh settings from the API.
  Future<void> ensureFreshSettings({
    String? companyCode,
    String? companyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchStr = prefs.getString('company_settings_last_fetch');
      final settingsJson = prefs.getString('company_settings');

      bool needsRefresh = false;

      if (settingsJson == null || _settings == null) {
        needsRefresh = true;
      } else if (lastFetchStr == null) {
        needsRefresh = true;
      } else {
        try {
          final lastFetchDate = DateTime.parse(lastFetchStr);
          final diffInDays = DateTime.now().difference(lastFetchDate).inDays;
          if (diffInDays >= 3) {
            needsRefresh = true;
            debugPrint(
                "🔄 Company settings cache is $diffInDays days old (>= 3 days) -> refreshing from API");
          }
        } catch (_) {
          needsRefresh = true;
        }
      }

      if (_settings == null && settingsJson != null) {
        await _loadSettingsLocally();
      }

      if (needsRefresh) {
        const storage = FlutterSecureStorage();
        final code = (companyCode != null && companyCode.isNotEmpty)
            ? companyCode
            : (AppConfig.companyCode.isNotEmpty
                ? AppConfig.companyCode
                : (await storage.read(key: "companyCode") ?? ''));
        final id = (companyId != null && companyId.isNotEmpty)
            ? companyId
            : (_settings?.companyId.isNotEmpty == true
                ? _settings!.companyId
                : (await storage.read(key: "companyId") ?? ''));

        if (code.isNotEmpty || id.isNotEmpty) {
          debugPrint(
              "🔄 Fetching fresh company settings from API (code=$code, id=$id)...");
          await fetchCompanySettings(companyCode: code, companyId: id);
        } else {
          debugPrint(
              "⚠️ Cannot refresh company settings: companyCode and companyId are empty");
        }
      }
    } catch (e) {
      debugPrint("❌ Error in ensureFreshSettings: $e");
    }
  }

  /// Fetch settings from the API. Falls back to local cache on failure.
  Future<bool> fetchCompanySettings({
    required String companyCode,
    required String companyId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.request(
        'student/company/settings?companyCode=$companyCode&companyId=$companyId',
        null,
        'GET',
      );

      if (response != null && response.statusCode == 200) {
        try {
          debugPrint("🏢 response.data type: ${response.data.runtimeType}");
          final jsonData = response.data is String
              ? json.decode(response.data)
              : response.data;
          _settings = CompanySettingsModel.fromJson(jsonData);
          _isLoading = false;
          await _saveSettingsLocally(_settings!);
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint("🏢 ❌ Failed to parse settings: $e");
          _error = 'Failed to parse settings: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Failed to fetch settings: ${response?.statusCode}';
        _isLoading = false;
        // Try fallback
        await _loadSettingsLocally();
        notifyListeners();
        return _settings != null;
      }
    } catch (e) {
      _error = 'Exception: $e';
      _isLoading = false;
      await _loadSettingsLocally();
      notifyListeners();
      return _settings != null;
    }
  }

  /// Get departments that are allowed for a given level (when nested).
  List<Department> getDepartmentsForLevel(String levelCode) {
    if (!useNestedLevels) return departments;

    final level = levels.firstWhere(
      (l) => l.code == levelCode,
      orElse: () => Level(
        code: '',
        label: '',
        order: 0,
        linkedDepartments: [],
      ),
    );

    if (level.code.isEmpty) return [];

    return departments
        .where((d) => level.linkedDepartments.contains(d.code))
        .toList();
  }

  /// Get linked department codes for a given level (useful for filtering).
  List<String> getLinkedDepartmentsForLevel(String levelCode) {
    final level = levels.firstWhere(
      (l) => l.code == levelCode,
      orElse: () => Level(
        code: '',
        label: '',
        order: 0,
        linkedDepartments: [],
      ),
    );
    return level.linkedDepartments;
  }

  /// Clear all stored settings (e.g., on logout).
  Future<void> clearSettings() async {
    _settings = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('company_settings');
    await prefs.remove('company_settings_last_fetch');
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // PRIVATE HELPERS
  // --------------------------------------------------------------------------

  /// Save settings to SharedPreferences using the model's toJson().
  Future<void> _saveSettingsLocally(CompanySettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(settings.toJson());
      await prefs.setString('company_settings', jsonString);
      await prefs.setString(
          'company_settings_last_fetch', DateTime.now().toIso8601String());

      final apiService = ApiService();
      await apiService.saveOfflinePdfFlag(settings.enableOfflinePdf);
      await apiService.saveOfflineVideoFlag(settings.enableOfflineVideo);
      await apiService.saveOfflineCoursesSettings(
        enabled: settings.enableOfflineCourses,
        daysLimit: settings.offlineCoursesDaysLimit,
      );
    } catch (e) {
      debugPrint('Error saving settings locally: $e');
    }
  }

  /// Load settings from SharedPreferences and parse with fromJson.
  Future<void> _loadSettingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('company_settings');
      if (jsonString != null) {
        final jsonData = json.decode(jsonString);
        _settings = CompanySettingsModel.fromJson(jsonData);

        final apiService = ApiService();
        await apiService.saveOfflinePdfFlag(_settings!.enableOfflinePdf);
        await apiService.saveOfflineVideoFlag(_settings!.enableOfflineVideo);
        await apiService.saveOfflineCoursesSettings(
          enabled: _settings!.enableOfflineCourses,
          daysLimit: _settings!.offlineCoursesDaysLimit,
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings locally: $e');
    }
  }
}
