package com.coursesappgenuiswebatwan

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
