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

    // 🚫 منع تصوير وتسجيل الشاشة (Screen Recording & Screenshots Protection)
    window?.makeSecure()


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

}

// ── ملحق لتأمين النافذة ومنع التقاط الشاشة أو تسجيلها ────────────────
extension UIWindow {
    func makeSecure() {
        if #available(iOS 11.0, *) {
            let secureField = UITextField()
            secureField.isSecureTextEntry = true
            self.addSubview(secureField)
            secureField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            secureField.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            self.layer.superlayer?.addSublayer(secureField.layer)
            secureField.layer.sublayers?.last?.addSublayer(self.layer)
        }
    }
}
