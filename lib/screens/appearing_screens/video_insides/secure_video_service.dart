import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:flutter_version/data/app_config.dart';

/// Handles encrypted offline download and secure local playback for Vimeo videos.
///
/// Flow:
///   1. Call [getVimeoMp4Url] → backend proxy fetches the Vimeo MP4 URL using
///      the company PAT stored server-side (PAT never reaches the device).
///   2. Download raw bytes from that URL.
///   3. Encrypt with AES-256-CBC and a per-device key stored in flutter_secure_storage.
///   4. Persist as `<docDir>/secure_videos/<videoId>.enc` (16-byte random IV + ciphertext).
///   5. [startDecryptionServer] decrypts in-memory and serves via a local HTTP server.
///   6. Feed the returned `http://127.0.0.1:<port>/video` URL to VideoPlayerController.
class SecureVideoService {
  static const _storage = FlutterSecureStorage();
  static const _aesKeyName = 'video_aes_key_v1';

  // -------------------------------------------------------------------------
  // 1. AES key management (generated once per device, stored securely)
  // -------------------------------------------------------------------------
  static Future<enc.Key> _getOrCreateKey() async {
    String? base64Key = await _storage.read(key: _aesKeyName);
    if (base64Key == null) {
      final key = enc.Key.fromSecureRandom(32); // 256-bit
      base64Key = key.base64;
      await _storage.write(key: _aesKeyName, value: base64Key);
    }
    return enc.Key.fromBase64(base64Key);
  }

  // -------------------------------------------------------------------------
  // 2. Private storage directory for .enc files
  // -------------------------------------------------------------------------
  static Future<String> _encDir() async {
    if (kIsWeb) return '';
    final dir = await getApplicationDocumentsDirectory();
    final encDir = Directory('${dir.path}/secure_videos');
    if (!await encDir.exists()) await encDir.create(recursive: true);
    return encDir.path;
  }

  static String _encFilePath(String dirPath, String videoId) =>
      '$dirPath/$videoId.enc';

  // -------------------------------------------------------------------------
  // 3. Check if a video is already downloaded
  // -------------------------------------------------------------------------
  static Future<bool> isDownloaded(String videoId) async {
    if (kIsWeb) return false;
    final dir = await _encDir();
    return File(_encFilePath(dir, videoId)).exists();
  }

  static Future<String> _getEncPath(String videoId) async {
    final dir = await _encDir();
    return _encFilePath(dir, videoId);
  }

  // -------------------------------------------------------------------------
  // 4. Backend proxy: get Vimeo MP4 download URL
  //    Requires the student's auth token (stored in flutter_secure_storage as
  //    "userToken" by ApiService).
  // -------------------------------------------------------------------------
  static Future<String?> getVimeoMp4Url({
    required String vimeoVideoId,
    required String userToken,
  }) async {
    try {
      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/student/vimeo/download-url/$vimeoVideoId');
      final resp = await http.get(uri, headers: {
        'Cookie': userToken,
        'App-Version': '1.0.3',
      });

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['downloadUrl'] as String?;
      } else {
        debugPrint('❌ Vimeo proxy error ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ getVimeoMp4Url: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 5. Download → encrypt → persist
  // -------------------------------------------------------------------------
  /// Returns the path of the encrypted file, or null on failure.
  static Future<String?> downloadAndEncrypt({
    required String mp4Url,
    required String videoId,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return null;
    try {
      // --- Download ----------------------------------------------------------
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(mp4Url));
      final streamedResp = await client.send(request);

      if (streamedResp.statusCode != 200) {
        debugPrint('❌ Download failed: ${streamedResp.statusCode}');
        return null;
      }

      final totalBytes = streamedResp.contentLength ?? 0;
      final buffer = BytesBuilder();
      int downloaded = 0;

      await for (final chunk in streamedResp.stream) {
        buffer.add(chunk);
        downloaded += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(downloaded / totalBytes);
        }
      }
      client.close();

      final rawBytes = buffer.toBytes();

      // --- Encrypt -----------------------------------------------------------
      final key = await _getOrCreateKey();
      final iv = enc.IV.fromSecureRandom(16); // random IV per video
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);

      // --- Persist (16-byte IV + ciphertext) ---------------------------------
      final encPath = await _getEncPath(videoId);
      final file = File(encPath);
      await file.writeAsBytes(Uint8List.fromList(iv.bytes + encrypted.bytes));

      debugPrint('✅ Encrypted video saved: $encPath');
      return encPath;
    } catch (e) {
      debugPrint('❌ downloadAndEncrypt: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 6. Local HTTP server — decrypts on-the-fly, never writes cleartext to disk
  // -------------------------------------------------------------------------
  /// Starts a loopback HTTP server and returns a URI like
  /// `http://127.0.0.1:<port>/video` that any video player can use.
  ///
  /// Call [server.close()] when done to free the port.
  static Future<({Uri uri, HttpServer server})> startDecryptionServer(
      String encryptedFilePath) async {
    if (kIsWeb)
      throw UnsupportedError('Local decryption server is not supported on Web');
    // Read encrypted file once
    final encBytes = await File(encryptedFilePath).readAsBytes();
    final iv = enc.IV(encBytes.sublist(0, 16));
    final cipherBytes = encBytes.sublist(16);

    final key = await _getOrCreateKey();

    // Lazy-decrypt cache (avoid re-decrypting on every range request)
    Uint8List? decryptedCache;
    Uint8List _decryptOnce() {
      decryptedCache ??= () {
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        final decrypted = encrypter.decryptBytes(
          enc.Encrypted(cipherBytes),
          iv: iv,
        );
        return Uint8List.fromList(decrypted);
      }();
      return decryptedCache!;
    }

    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    httpServer.listen((HttpRequest req) async {
      if (req.uri.path != '/video') {
        req.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final bytes = _decryptOnce();

      // Support range requests (required by some video players)
      final rangeHeader = req.headers.value(HttpHeaders.rangeHeader);
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final parts = rangeHeader.substring(6).split('-');
        final start = int.tryParse(parts[0]) ?? 0;
        final end = parts.length > 1 && parts[1].isNotEmpty
            ? int.tryParse(parts[1]) ?? (bytes.length - 1)
            : bytes.length - 1;
        final length = end - start + 1;

        req.response
          ..statusCode = HttpStatus.partialContent
          ..headers.contentType = ContentType('video', 'mp4')
          ..headers.set(HttpHeaders.contentRangeHeader,
              'bytes $start-$end/${bytes.length}')
          ..headers.set(HttpHeaders.contentLengthHeader, length)
          ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
          ..add(bytes.sublist(start, end + 1));
      } else {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('video', 'mp4')
          ..headers.set(HttpHeaders.contentLengthHeader, bytes.length)
          ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
          ..add(bytes);
      }

      await req.response.close();
    });

    final uri = Uri.parse('http://127.0.0.1:${httpServer.port}/video');
    debugPrint('✅ Decryption server started on $uri');
    return (uri: uri, server: httpServer);
  }

  // -------------------------------------------------------------------------
  // 7. Delete an encrypted file
  // -------------------------------------------------------------------------
  static Future<void> deleteEncrypted(String videoId) async {
    if (kIsWeb) return;
    final encPath = await _getEncPath(videoId);
    final file = File(encPath);
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑 Deleted encrypted video: $encPath');
    }
  }
}
