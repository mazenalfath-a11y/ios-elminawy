import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 🚫 Emulator/Simulator detection utility
/// Uses Native MethodChannel for Android & iOS (most reliable)
/// Uses device_info_plus as a fallback
class EmulatorChecker {
  // 🔗 قناة الاتصال الموحدة مع الـ Native (Android & iOS)
  static const _channel = MethodChannel('space/emulator');
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns true if the app is running on an emulator/simulator
  static Future<bool> isEmulator() async {
    try {
      if (Platform.isAndroid) {
        // 1️⃣ فحص الـ Native أولاً (الأقوى والأدق)
        try {
          final bool result = await _channel.invokeMethod('isEmulator');
          return result;
        } catch (e) {
          debugPrint('MethodChannel failed, falling back to device_info_plus: $e');
        }

        // 2️⃣ فحص احترازي (Fallback)
        final androidInfo = await _deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) return true;

        final fp = androidInfo.fingerprint.toLowerCase();
        final hw = androidInfo.hardware.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        final model = androidInfo.model.toLowerCase();

        if (fp.startsWith('generic') || fp.startsWith('unknown')) return true;
        if (fp.contains('sdk_gphone') || fp.contains('sdk_gpc')) return true;
        if (hw.contains('goldfish') || hw.contains('ranchu')) return true;
        if (model.contains('sdk') || model == 'emulator') return true;
        if (product.contains('sdk_gphone') || product == 'sdk') return true;

        return false;
      } else if (Platform.isIOS) {
        // 1️⃣ فحص الـ Native أولاً
        try {
          final bool result = await _channel.invokeMethod('isEmulator');
          return result;
        } catch (e) {
          debugPrint('MethodChannel failed, falling back to device_info_plus: $e');
        }

        // 2️⃣ فحص احترازي (Fallback)
        final iosInfo = await _deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      debugPrint('EmulatorChecker error: $e');
      return false;
    }
  }
}
