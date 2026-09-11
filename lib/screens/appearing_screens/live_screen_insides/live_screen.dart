import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/youtube_video_player.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

class LiveScreen extends StatefulWidget {
  final String streamId;
  final String courseId;

  const LiveScreen({
    super.key,
    required this.streamId,
    required this.courseId,
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isFullScreen = false;

  late IO.Socket socket;

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response =
          await _apiService.request("student/getuser", null, "GET");
      if (response != null && response.statusCode == 200) {
        setState(() {
          userData = response.data ?? {};
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching user data: $e");
    }
  }

  void _connectToSocket() {
    socket = IO.io(
      'https://atia.genuisweb.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io/')
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("🟢 Connected to Socket");
      print("📦 Joining room: ${widget.courseId}");
      socket.emit("joinLive", widget.courseId);
    });

    socket.onAny((event, data) {
      print("📥 Event: $event => $data");
    });

    socket.on("chatHistory", (data) {
      setState(() {
        _comments.clear();
        for (var msg in data) {
          _comments.add(_mapMessage(msg));
        }
      });
    });

    socket.on("receiveMessage", (msg) {
      setState(() {
        _comments.add(_mapMessage(msg));
      });
    });

    socket.on("messageDeleted", (messageId) {
      setState(() {
        _comments.removeWhere((msg) => msg["id"] == messageId);
      });
    });

    socket.on("liveNotFound", (data) => print("🚫 Live not found: $data"));
    socket.onConnectError((err) => print("❌ connect_error: $err"));
    socket.onDisconnect((_) => print("🔴 Disconnected from Socket"));
  }

  Map<String, dynamic> _mapMessage(dynamic msg) {
    if (msg["audioUrl"] != null && msg["audioUrl"].toString().isNotEmpty) {
      return {"type": "audio", "path": msg["audioUrl"], "id": msg["id"]};
    } else {
      return {"type": "text", "text": msg["message"], "id": msg["id"]};
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    _recorder?.closeRecorder();
    _recorder = null;
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _sendTextComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      final username =
          (userData["FirstName"] != null && userData["LastName"] != null)
              ? "${userData["FirstName"]} ${userData["LastName"]}"
              : AppLocalizations.of(context)!.userLabel;

      socket.emit("sendMessage", {
        "courseId": widget.courseId,
        "username": username,
        "userNumber":
            userData["mobile"] ?? AppLocalizations.of(context)!.noNumberLabel,
        "message": text,
        "audioUrl": ""
      });
      _commentController.clear();
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.audioNotSupportedWeb ?? "تسجيل الصوت غير متاح على المتصفح حالياً")),
      );
      return;
    }
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/live_comment_${DateTime.now().millisecondsSinceEpoch}.aac';

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingDuration++);
    });

    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
  }

  Future<void> _stopRecording() async {
    if (kIsWeb) return;
    if (_recorder != null && _isRecording) {
      final path = await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      setState(() => _isRecording = false);

      if (path != null && File(path).existsSync()) {
        final uploadedUrl = await uploadVoiceFile(File(path));
        if (uploadedUrl != null) {
          final username =
              (userData["FirstName"] != null && userData["LastName"] != null)
                  ? "${userData["FirstName"]} ${userData["LastName"]}"
                  : AppLocalizations.of(context)?.userRole ?? "مستخدم";

          socket.emit("sendMessage", {
            "courseId": widget.courseId,
            "username": username,
            "userNumber": userData["mobile"] ??
                AppLocalizations.of(context)!.noNumberLabel,
            "message": "",
            "audioUrl": uploadedUrl,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '✅ ${AppLocalizations.of(context)!.voiceUploadSuccess}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '❌ ${AppLocalizations.of(context)!.voiceUploadFailed}')),
          );
        }
      }
    }
  }

  Future<String?> uploadVoiceFile(File file) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType("audio", "aac"),
        ),
      });

      final response = await _apiService.request(
        "course/upload_audio/${widget.courseId}",
        formData,
        "POST",
      );

      if (response != null && response.statusCode == 200) {
        return response.data['audioUrl'];
      }
    } catch (e) {
      print("❌ Exception during upload: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.liveStreamTitle,
                  style: GoogleFonts.tajawal()),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      backgroundColor: Colors.black,
      body: _isFullScreen
          ? Stack(
              children: [
                Container(
                  color: Colors.black,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        YoutubeVideoPlayer(
                          videoUrl: widget.streamId,
                          watermarkText: "",
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen_exit,
                                color: Colors.white, size: 32),
                            onPressed: () {
                              setState(() => _isFullScreen = false);
                            },
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.liveLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 500, // Adjust height as needed
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Stack(
                      children: [
                        YoutubeVideoPlayer(
                          videoUrl: widget.streamId,
                          watermarkText: "",
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.liveLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen,
                                color: Colors.white, size: 30),
                            onPressed: () =>
                                setState(() => _isFullScreen = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child:
                              Text(AppLocalizations.of(context)!.commentsLabel,
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right),
                        ),
                        Expanded(
                          child: ListView(
                            reverse: true,
                            children: _comments.reversed.map((comment) {
                              if (comment["type"] == "audio") {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade800,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.mic,
                                              color: Colors.white70),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .voiceMessage,
                                            style: GoogleFonts.tajawal(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.play_circle_fill,
                                            color: Colors.lightGreenAccent,
                                            size: 30),
                                        onPressed: () async {
                                          final player = FlutterSoundPlayer();
                                          await player.openPlayer();
                                          await player.startPlayer(
                                              fromURI: comment["path"]);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  alignment: Alignment.centerRight,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    comment["text"] ?? "",
                                    style: GoogleFonts.tajawal(
                                        color: Colors.white, fontSize: 14),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              }
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .writeCommentHint,
                                    hintStyle:
                                        const TextStyle(color: Colors.white54),
                                    filled: true,
                                    fillColor: Colors.grey[850],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                ),
                              ),
                              if (_isRecording)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fiber_manual_record,
                                          color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${_recordingDuration}s',
                                          style: const TextStyle(
                                              color: Colors.red, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              GestureDetector(
                                onLongPress: _startRecording,
                                onLongPressUp: _stopRecording,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isRecording ? Icons.mic : Icons.mic_none,
                                    color: _isRecording
                                        ? Colors.red
                                        : Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon:
                                    const Icon(Icons.send, color: Colors.blue),
                                onPressed: _sendTextComment,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
