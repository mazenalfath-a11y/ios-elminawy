import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_version/data/app_config.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final _storage = const FlutterSecureStorage();
  static String? _cachedToken;

  final String baseUrl = AppConfig.apiBaseUrl;

  // ─── Token management ──────────────────────────────────────────────────

  static void setToken(String token) {
    _cachedToken = token;
  }

  // api_service.dart
  Future<void> saveToken(String token) async {
    await _storage.write(key: "userToken", value: token);
    _cachedToken =
        token; // saveToken now does what setToken used to have to do manually
  }

  Future<void> logout() async {
    await _storage.delete(key: "userToken");
    await _storage.delete(key: "enableOfflinePdf");
    await _storage.delete(key: "enableOfflineVideo");
    await _storage.delete(key: "offlineCoursesEnabled");
    await _storage.delete(key: "offlineCoursesDaysLimit");
    ApiService.clearToken(); // ✅ fix: clear cached token on logout
  }

  static void clearToken() {
    _cachedToken = null;
  }

  Future<String?> getUserToken() async {
    return await _storage.read(key: "userToken");
  }

  // ─── Offline flags ──────────────────────────────────────────────────────

  Future<void> saveOfflinePdfFlag(bool flag) async {
    await _storage.write(key: "enableOfflinePdf", value: flag.toString());
  }

  Future<bool> getOfflinePdfFlag() async {
    final value = await _storage.read(key: "enableOfflinePdf");
    return value == "true";
  }

  Future<void> saveOfflineVideoFlag(bool flag) async {
    await _storage.write(key: "enableOfflineVideo", value: flag.toString());
  }

  Future<bool> getOfflineVideoFlag() async {
    final value = await _storage.read(key: "enableOfflineVideo");
    return value == "true";
  }

  Future<void> saveOfflineCoursesSettings({
    required bool enabled,
    required int daysLimit,
  }) async {
    await _storage.write(
        key: "offlineCoursesEnabled", value: enabled.toString());
    await _storage.write(
        key: "offlineCoursesDaysLimit", value: daysLimit.toString());
  }

  Future<Map<String, dynamic>> getOfflineCoursesSettings() async {
    final enabled = await _storage.read(key: "offlineCoursesEnabled");
    final days = await _storage.read(key: "offlineCoursesDaysLimit");
    return {
      'enabled': enabled == 'true',
      'daysLimit': int.tryParse(days ?? '') ?? 7,
    };
  }

  // ─── General API Request ──────────────────────────────────────────────

  Future<Response?> request(
    String path,
    dynamic data,
    String method, {
    bool isFormData = false,
  }) async {
    // Use cached token synchronously
    String? token = _cachedToken;
    if (token == null) {
      token = await _storage.read(key: "userToken");
      if (token != null) _cachedToken = token;
    }

    try {
      print("📤 Sending request to: $baseUrl/$path");
      print("📤 Method: $method");
      print("📤 Is FormData: $isFormData");
      print("📤 Data: $data");
      print("🔑 Sending token: $token");

      final response = await _dio.request(
        "$baseUrl/$path",
        data: isFormData ? data : data,
        options: Options(
          method: method,
          contentType: isFormData ? "multipart/form-data" : "application/json",
          headers: {
            // ✅ Use Authorization header instead of Cookie
            if (token != null) "Authorization": "Bearer $token",
            "App-Version": "1.0.3",
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print("❌ API Error: ${e.response?.data ?? e.message}");
      print("❌ Dio Error Type: ${e.type}");
      print("❌ Dio Message: ${e.message}");
      if (e.response != null) {
        print("❌ Status code: ${e.response?.statusCode}");
        print("❌ Response data: ${e.response?.data}");
      } else {
        print("❌ No response returned from server");
      }
      return e.response;
    }
  }

  // ─── Category endpoints ────────────────────────────────────────────────

  Future<Response?> getCategoryTree() async {
    return await request("category/getcategorytree", null, "GET");
  }

  Future<Response?> getChildCategories(String parentId) async {
    return await request("category/getchildren/$parentId", null, "GET");
  }

  Future<Response?> getCoursesInCategory(String categoryId) async {
    return await request("category/getcourses/$categoryId", null, "GET");
  }

  // ─── Fawaterak Payment Endpoints ────────────────────────────────────────

  Future<Response?> getPaymentMethods() async {
    return await request("payment/methods", null, "GET");
  }

  Future<Response?> initiateCoursePayment({
    required String courseId,
    int? paymentMethodId,
    String? mobileWalletNumber,
    String? successUrl,
    String? failUrl,
  }) async {
    return await request(
      "payment/initiate",
      {
        "courseId": courseId,
        if (paymentMethodId != null) "paymentMethodId": paymentMethodId,
        if (mobileWalletNumber != null)
          "mobileWalletNumber": mobileWalletNumber,
        if (successUrl != null) "successUrl": successUrl,
        if (failUrl != null) "failUrl": failUrl,
      },
      "POST",
    );
  }

  Future<Response?> checkPaymentStatus(String transactionId) async {
    return await request("payment/status/$transactionId", null, "GET");
  }
}
