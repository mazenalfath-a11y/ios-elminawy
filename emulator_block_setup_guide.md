# 🛡️ دليل شامل لتطبيق حماية المحاكي ومنع التسجيل (Flutter - Android & iOS)

هذا الدليل يضم كل الأكواد والتغييرات المطلوبة لمنع تشغيل التطبيق على المحاكيات (Emulators / Simulators) ومنع تصوير أو تسجيل الشاشة على Android و iOS.

---

## 📋 الخطوات باختصار

| الخطوة | الملف | الوظيفة |
|--------|-------|---------|
| **0** | `pubspec.yaml` | إضافة مكتبة `device_info_plus` |
| **1** | `lib/utilities/emulator_checker.dart` | ملف Dart مسؤول عن الكشف في طبقة الفلاتر |
| **2** | `android/app/src/main/kotlin/.../MainActivity.kt` | كود Kotlin لحظر المحاكي ومنع التسجيل في Android |
| **3** | `ios/Runner/AppDelegate.swift` | كود Swift لحظر المحاكي ومنع التسجيل في iOS |
| **4** | `lib/main.dart` | استدعاء الحظر عند بداية تشغيل التطبيق |

---

## ⚙️ الخطوة 0: إضافة المكتبة في `pubspec.yaml`

في ملف `pubspec.yaml` تأكد من وجود مكتبة `device_info_plus`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  device_info_plus: ^11.3.0  # ← أضف هذا السطر
```

ثم شغل الأمر:
```bash
flutter pub get
```

---

## 📄 الخطوة 1: إنشاء ملف `lib/utilities/emulator_checker.dart`

قم بإنشاء هذا الملف وانسخ فيه الكود التالي:

```dart
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
```

---

## 🤖 الخطوة 2: تعديل `MainActivity.kt` (Android)

**المسار:** `android/app/src/main/kotlin/YOUR_PACKAGE_NAME/MainActivity.kt`

*(تأكد من ضبط اسم الـ `package` حسب مشروعك)*

```kotlin
package com.coursesappgenuiswebzmaster // ← استبدلها باسم package مشروعك

import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "space/emulator" // 🔗 اسم الـ Channel الموحد

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel ليتسنى لـ Dart الاستعلام عن المحاكي
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isEmulator") {
                result.success(isEmulator())
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🚫 1. حظر المحاكيات — إغلاق فوري للتطبيق في حال الكشف
        if (isEmulator()) {
            Toast.makeText(this, "هذا التطبيق لا يعمل على المحاكي", Toast.LENGTH_LONG).show()
            finishAffinity()
            exitProcess(0)
            return
        }

        // 🚫 2. منع تصوير الشاشة وتسجيل الفيديو
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun isEmulator(): Boolean {
        // 1️⃣ معمارية المعالج (ABI) - المحاكيات تستخدم x86 أو x86_64
        val primaryAbi = Build.SUPPORTED_ABIS.firstOrNull()?.lowercase() ?: ""
        if (primaryAbi.contains("x86")) {
            return true
        }

        // 2️⃣ ملفات طبقات الترجمة (ARM Translation Layers)
        val translationFiles = arrayOf(
            "/system/lib/libhoudini.so",
            "/system/lib/libndk_translation.so",
            "/system/lib64/libhoudini.so",
            "/system/lib64/libndk_translation.so",
            "/system/bin/houdini",
            "/system/bin/ndk_translation"
        )
        for (f in translationFiles) {
            try {
                if (File(f).exists()) return true
            } catch (_: Exception) {}
        }

        // 3️⃣ ملفات محاكيات مشهورة (Nox, BlueStacks, QEMU)
        val emulatorFiles = arrayOf(
            "/system/bin/nox-prop",
            "/system/bin/ldprop",
            "/system/bin/bluestacks-prop",
            "/system/xbin/nox-prop",
            "/dev/socket/qemud",
            "/dev/qemu_pipe"
        )
        for (f in emulatorFiles) {
            try {
                if (File(f).exists()) return true
            } catch (_: Exception) {}
        }

        // 4️⃣ فحوصات Build Properties
        val fp = Build.FINGERPRINT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        if (fp.startsWith("generic") || fp.startsWith("unknown") || fp.contains("emulator")) {
            return true
        }
        if (hardware.contains("goldfish") || hardware.contains("ranchu")) {
            return true
        }

        return false
    }
}
```

---

## 🍏 الخطوة 3: تعديل `AppDelegate.swift` (iOS)

**المسار:** `ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let CHANNEL = "space/emulator" // 🔗 اسم الـ Channel الموحد

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── MethodChannel: ليتسنى لـ Dart الاستعلام عن المحاكي ──
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: CHANNEL,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "isEmulator" {
          result(self?.isSimulator() ?? false)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // 🚫 حظر المحاكيات — إغلاق فوري للـ Simulator
    if isSimulator() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        let alert = UIAlertController(
          title: "غير مسموح",
          message: "هذا التطبيق لا يعمل على المحاكي\nيرجى استخدام جهاز حقيقي",
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "إغلاق", style: .destructive) { _ in
          exit(0)
        })
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
      }
      
      // إغلاق إجباري بعد 4 ثوانٍ
      DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        exit(0)
      }
    }

    // 🚫 منع وتسجيل الشاشة (Screen Recording Protection)
    preventScreenCapture()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── فحص الـ Simulator ──────────────────────────────────────────────────

  private func isSimulator() -> Bool {
    // 1️⃣ Compile-time check
    #if targetEnvironment(simulator)
      return true
    #endif

    // 2️⃣ Runtime check عبر متغيرات البيئة
    let env = ProcessInfo.processInfo.environment
    if env["SIMULATOR_DEVICE_NAME"] != nil { return true }
    if env["SIMULATOR_MODEL_IDENTIFIER"] != nil { return true }

    // 3️⃣ Runtime check عبر معمارية الجهاز
    var systemInfo = utsname()
    uname(&systemInfo)
    let machine = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingUTF8: $0) ?? "" }
    }
    if machine == "x86_64" || machine == "arm64" {
      return true
    }

    return false
  }

  // ── حماية تسجيل الشاشة (Screen Recording) ─────────────────────────────

  private func preventScreenCapture() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )

    if #available(iOS 11.0, *) {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleScreenCaptureStatusChange),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
      if UIScreen.main.isCaptured {
        applySecureOverlay(show: true)
      }
    }
  }

  @objc private func handleScreenshotTaken() {
    let alert = UIAlertController(
      title: "⚠️ تحذير",
      message: "تصوير الشاشة غير مسموح به في هذا التطبيق",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "حسناً", style: .default))
    window?.rootViewController?.present(alert, animated: true)
  }

  @available(iOS 11.0, *)
  @objc private func handleScreenCaptureStatusChange() {
    applySecureOverlay(show: UIScreen.main.isCaptured)
  }

  /// يغطي الشاشة بخلفية سوداء عند البدء في تسجيل الشاشة
  private func applySecureOverlay(show: Bool) {
    let tag = 99_999
    if show {
      guard window?.viewWithTag(tag) == nil else { return }
      let overlay = UIView(frame: window?.bounds ?? .zero)
      overlay.backgroundColor = .black
      overlay.tag = tag
      window?.addSubview(overlay)
      window?.bringSubviewToFront(overlay)
    } else {
      window?.viewWithTag(tag)?.removeFromSuperview()
    }
  }
}
```

---

## 🚀 الخطوة 4: تفعيل الحظر في `lib/main.dart`

أضف فحص المحاكي في أول دالة `main()` داخل مشروعك:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/emulator_checker.dart'; // ← استورد الملف

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚫 حظر المحاكيات من طبقة Flutter/Dart
  final isEmu = await EmulatorChecker.isEmulator();
  if (isEmu) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, color: Colors.red, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'غير مسموح',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'هذا التطبيق لا يعمل على المحاكي\nيرجى استخدام جهاز حقيقي',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return; // ✋ إيقاف استكمال تشغيل باقي التطبيق
  }

  // ... باقي كود main() الطبيعي الخاص بمشروعك ...
  runApp(const MyApp());
}
```

---

## 📌 المكونات والتفاصيل الهامة

1. **الـ MethodChannel name:** موحد باسم `"space/emulator"` في كل الملفات.
2. **الحظر ثنائي الطبقات:** 
   - **الطبقة الأولى (Native):** تُنفذ قبل بدء Flutter أساساً في `onCreate` (أندرويد) أو `didFinishLaunchingWithOptions` (آيفون).
   - **الطبقة الثانية (Dart):** تُنفذ في `main.dart` لمنع التطبيق إذا تخطى الـ Native بأي شكل.
3. **حماية الشاشة:**
   - **Android:** تم وضع `FLAG_SECURE` لتسويد الشاشة عند التقاط سكرين شوت أو فيديو.
   - **iOS:** تظهر شاشة سوداء تلقائياً فور بدء تسجيل الشاشة (Screen Recording).
