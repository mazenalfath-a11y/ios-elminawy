// // lib/utilities/encrypted_video_service.dart
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:encrypt/encrypt.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;

// class EncryptedVideoService {
//   static final _key =
//       Key.fromUtf8('My32CharSecretKeyMy32CharSecretKey'); // 32 chars
//   static final _iv = IV.fromLength(16);
//   static final _encrypter = Encrypter(AES(_key));

//   static Future<String> getEncryptedPath(String id) async {
//     final dir = await getApplicationDocumentsDirectory();
//     return '${dir.path}/$id.enc';
//   }

//   static Future<void> downloadAndEncrypt(String url, String id) async {
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final encrypted = _encrypter.encryptBytes(response.bodyBytes, iv: _iv);
//       final filePath = await getEncryptedPath(id);
//       final file = File(filePath);
//       await file.writeAsBytes(encrypted.bytes);
//     } else {
//       throw Exception("Failed to download video");
//     }
//   }

//   static Future<Uint8List> decryptVideo(String id) async {
//     final path = await getEncryptedPath(id);
//     final encryptedData = await File(path).readAsBytes();
//     final decrypted =
//         _encrypter.decryptBytes(Encrypted(encryptedData), iv: _iv);
//     return Uint8List.fromList(decrypted);
//   }
// }
