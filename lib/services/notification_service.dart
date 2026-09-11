// import 'package:flutter/foundation.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_version/data/api_service.dart';

// class NotificationService {
//   static final ApiService _apiService = ApiService();

//   static Future<void> init() async {
//     if (kIsWeb ||
//         defaultTargetPlatform == TargetPlatform.windows ||
//         defaultTargetPlatform == TargetPlatform.macOS ||
//         defaultTargetPlatform == TargetPlatform.linux) {
//       debugPrint("🌐 Running on Web/Desktop - FCM notification service skipped");
//       return;
//     }
//     await Firebase.initializeApp();

//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     await messaging.requestPermission();

//     String? fcmToken = await messaging.getToken();
//     print("📲 FCM Token: $fcmToken");

//     try {
//       // ✅ جلب بيانات المستخدم للحصول على الـ ID
//       final userResponse =
//           await _apiService.request("student/getuser", null, "GET");

//       if (userResponse != null &&
//           userResponse.statusCode == 200 &&
//           fcmToken != null) {
//         final userId = userResponse.data["_id"];

//         if (userId != null) {
//           final saveResponse = await _apiService.request(
//             "student/notification/savetoken/$userId",
//             {"fcmToken": fcmToken},
//             "POST",
//           );
//           if (saveResponse?.statusCode == 200) {
//             print("✅ Token saved successfully");
//           } else {
//             print("❌ error happened");
//           }
//         } else {
//           print("❌ No user ID found in response");
//         }
//       } else {
//         print("❌ Failed to get user data or FCM token is null");
//       }
//     } catch (e) {
//       print("❌ Error saving FCM token: $e");
//     }

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print("📨 Foreground notification: ${message.notification?.title}");
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print("📩 Notification clicked: ${message.notification?.title}");
//     });
//   }

//   static Future<void> backgroundHandler(RemoteMessage message) async {
//     await Firebase.initializeApp();
//     print("🔔 Background message: ${message.messageId}");
//   }
// }
