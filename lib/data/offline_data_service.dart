import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for caching home screen and course details data locally,
/// so the app can work offline within the manager-set days limit.
class OfflineDataService {
  static const _storage = FlutterSecureStorage();

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _keyEnabled = 'offlineCoursesEnabled';
  static const _keyDaysLimit = 'offlineCoursesDaysLimit';
  static const _keyLastSync = 'offlineCoursesLastSync';
  static const _keyHomeData = 'offlineHomeData';
  static const _keyCoursePrefix = 'offlineCourse_'; // + courseId

  // ── Setting storage (called from account_page when settings arrive) ───────

  static Future<void> saveSettings({
    required bool enabled,
    required int daysLimit,
  }) async {
    await _storage.write(key: _keyEnabled, value: enabled.toString());
    await _storage.write(key: _keyDaysLimit, value: daysLimit.toString());
  }

  static Future<bool> isEnabled() async {
    final v = await _storage.read(key: _keyEnabled);
    return v == 'true';
  }

  static Future<int> getDaysLimit() async {
    final v = await _storage.read(key: _keyDaysLimit);
    return int.tryParse(v ?? '') ?? 7;
  }

  static Future<void> clearCache() async {
    await _storage.delete(key: _keyHomeData);
    await _storage.delete(key: _keyLastSync);
  }

  // ── Last sync timestamp ───────────────────────────────────────────────────

  static Future<void> updateLastSync() async {
    final ts = DateTime.now().toIso8601String();
    await _storage.write(key: _keyLastSync, value: ts);
  }

  /// Returns true if the cached data is still within the allowed days limit.
  static Future<bool> isCacheValid() async {
    final enabled = await isEnabled();
    if (!enabled) return false;

    final ts = await _storage.read(key: _keyLastSync);
    if (ts == null) return false;

    final lastSync = DateTime.tryParse(ts);
    if (lastSync == null) return false;

    final daysLimit = await getDaysLimit();
    final age = DateTime.now().difference(lastSync).inDays;
    return age < daysLimit;
  }

  /// Returns how many full days remain before the cache expires (for UI warnings).
  static Future<int> daysUntilExpiry() async {
    final ts = await _storage.read(key: _keyLastSync);
    if (ts == null) return 0;
    final lastSync = DateTime.tryParse(ts);
    if (lastSync == null) return 0;
    final daysLimit = await getDaysLimit();
    final age = DateTime.now().difference(lastSync).inDays;
    return (daysLimit - age).clamp(0, daysLimit);
  }

  // ── Home screen data ──────────────────────────────────────────────────────

  static Future<void> saveHomeData(Map<String, dynamic> data) async {
    try {
      await _storage.write(key: _keyHomeData, value: jsonEncode(data));
      await updateLastSync();
    } catch (e) {
      print("❌ saveHomeData jsonEncode failed: $e");
    }
  }

  static Future<Map<String, dynamic>?> loadHomeData() async {
    final raw = await _storage.read(key: _keyHomeData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Course details data ───────────────────────────────────────────────────

  static Future<void> saveCourseData(
      String courseId, Map<String, dynamic> data) async {
    await _storage.write(
        key: '$_keyCoursePrefix$courseId', value: jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadCourseData(String courseId) async {
    final raw = await _storage.read(key: '$_keyCoursePrefix$courseId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyDaysLimit);
    await _storage.delete(key: _keyLastSync);
    await _storage.delete(key: _keyHomeData);
    // Individual course keys are left; they're overwritten on next sync
  }
}
