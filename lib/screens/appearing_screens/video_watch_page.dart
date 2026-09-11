import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/appearing_screens/exampage_insides/exercise_start_page.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/secure_video_service.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'exampage_insides/exam_result_page.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/youtube_video_player.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/drive_video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/screens/appearing_screens/html_viewer_page.dart';
import 'package:flutter_version/screens/appearing_screens/pdf_editor_page.dart';
import 'package:flutter_version/widgets/video_overlay_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_version/utilities/quiz_grading.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1565C0);
const _kGreen = Color(0xFF00C853);
const _kGreenDark = Color(0xFF00A846);

// ─── Listen threshold: 1 chunk × 3 min = 3 minutes ─────────────────────────
const int _kListenThresholdChunks = 1;
bool _isLoadingScore = false;
GradeResult? _exerciseGrade;
Map<String, dynamic>? _exerciseData;
bool _isLoadingExerciseInfo = false;

class VideoWatchPage extends StatefulWidget {
  final String videoTitle;
  final String videoUrl;
  final String v_id;
  final List<dynamic> files;
  final List<dynamic> additionalVideos;
  final String exerciseId;
  final String watermarkText;
  final String courseId;
  final List<String> exerciseArr;
  final String? teacherName;
  final String? userGroupName;
  final String? bubbleMessage;
  final int? bubbleInterval;
  final List<dynamic>? inVideoQuestions;

  const VideoWatchPage(
      {super.key,
      required this.videoTitle,
      required this.videoUrl,
      required this.v_id,
      required this.files,
      required this.additionalVideos,
      required this.exerciseId,
      required this.courseId,
      this.watermarkText = "Watermark",
      required this.exerciseArr,
      this.teacherName,
      this.userGroupName,
      this.bubbleMessage,
      this.bubbleInterval,
      this.inVideoQuestions});

  @override
  State<VideoWatchPage> createState() => _VideoWatchPageState();
}

class _VideoWatchPageState extends State<VideoWatchPage>
    with SingleTickerProviderStateMixin {
  // ── Watch time tracking ────────────────────────────────────────────────────
  Timer? _watchTimer;
  int _watchedChunks = 0;
  bool _isMarkedAsListened = false;

  // ── Bubble Notification Overlay ────────────────────────────────────────────
  Timer? _bubbleInitialTimer;
  Timer? _bubbleTimer;
  Timer? _bubbleHideTimer;
  bool _showBubble = false;
  String _currentBubbleMessage = "";

  int _selectedTabIndex = 0;
  List<_TabItem> tabs = [];
  bool isExerciseAnswered = false;
  final ScrollController _watchPageScrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];

  late final ApiService apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _parentNumber;

  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  flutter_sound.FlutterSoundRecorder? _recorder;

  String _currentVideoUrl = "";

  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isDownloaded = false;
  Uri? localServerUri;
  HttpServer? _localServer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _enableOfflineVideo = false;
  bool _isOffline = false;

  bool quizPassed = false;

  // ──────────────────────────────────────────────────────────────────────────

  /// Load the already-listened state from local storage (instant) then
  /// confirm with the server in the background.
  Future<void> _loadListenedState() async {
    // 1️⃣ Local storage first — instant, no network needed, no flicker
    final local = await _storage.read(key: "listened_${widget.v_id}");
    if (local == "true") {
      if (mounted) setState(() => _isMarkedAsListened = true);
      return; // already confirmed locally, skip server call
    }

    // 2️⃣ Server check (only if local says not listened yet)
    try {
      final res = await apiService.request(
        "tracktime/is_listened/${widget.v_id}",
        null,
        "GET",
      );
      if (res != null && res.statusCode == 200) {
        final listened = res.data["listened"] == true;
        if (listened) {
          // Keep local storage in sync for future offline access
          await _storage.write(key: "listened_${widget.v_id}", value: "true");
        }
        if (mounted) setState(() => _isMarkedAsListened = listened);
      }
    } catch (e) {
      debugPrint("❌ Error loading listened state from server: $e");
    }
  }

  Future<void> _fetchExerciseInfo() async {
    if (widget.exerciseId.isEmpty || isExerciseAnswered) return;
    setState(() => _isLoadingExerciseInfo = true);
    try {
      final res = await apiService.request(
        "student/exam/get_exercise_in_video/${widget.exerciseId}",
        null,
        "GET",
      );
      if (res != null && res.statusCode == 200 && mounted) {
        setState(() => _exerciseData = res.data);
      }
    } catch (e) {
      debugPrint("❌ Error fetching exercise info: $e");
    }
    if (mounted) setState(() => _isLoadingExerciseInfo = false);
  }

  Future<void> _fetchExerciseScore() async {
    if (widget.exerciseId.isEmpty) return;
    setState(() => _isLoadingScore = true);
    try {
      final questionsRes = await apiService.request(
          "student/exam/get_exercise_in_video/${widget.exerciseId}",
          null,
          "GET");
      final answersRes = await apiService.request(
          "student/exam/student_answers/${widget.exerciseId}", null, "GET");

      if (questionsRes?.data != null && answersRes?.data != null) {
        final qList = List<Map<String, dynamic>>.from(
            questionsRes?.data?["Questions"] ?? []);
        final rawAnswerList =
            List<Map<String, dynamic>>.from(answersRes?.data?["Answers"] ?? []);

        final aMap = {
          for (var item in rawAnswerList)
            if (item["question_id"] != null)
              item["question_id"].toString(): item["answer"]
        };

        final result = gradeQuestions(qList, aMap);
        if (mounted) setState(() => _exerciseGrade = result);
      }
    } catch (e) {
      debugPrint("❌ Error fetching exercise score: $e");
    }
    if (mounted) setState(() => _isLoadingScore = false);
  }

  /// Mark the video as listened:
  /// 1. Optimistic UI update
  /// 2. Persist to local storage (survives offline / app restart)
  /// 3. Notify server
  /// 4. Show success snackbar
  Future<void> _markVideoAsListened() async {
    if (_isMarkedAsListened) return;

    // Optimistic update — UI reacts immediately
    setState(() => _isMarkedAsListened = true);

    // Persist locally so it survives hot-restart or no network
    await _storage.write(key: "listened_${widget.v_id}", value: "true");

    // Notify server
    try {
      final res = await apiService.request(
        "tracktime/mark_listened/${widget.v_id}",
        {"videoname": widget.videoTitle},
        "POST",
      );
      debugPrint(
          "✅ mark_listened status=${res?.statusCode} body=${res?.data}  v_id=${widget.v_id}");
    } catch (e) {
      // Local storage already saved — will be consistent next time
      debugPrint("❌ Error marking as listened on server: $e");
    }

    // Show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.videoViewCounted ?? "✅ تم احتساب مشاهدة الفيديو — +50 XP",
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: _kGreenDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _comments.add({"type": "image", "data": picked.path}));
    }
  }

  Future<void> startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.audioRecordingNotSupportedOnWeb ??
                    AppLocalizations.of(context)?.audioNotSupportedWeb ?? "تسجيل الصوت غير متاح على المتصفح حالياً")),
      );
      return;
    }
    if (_recorder == null) {
      _recorder = flutter_sound.FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;
    setState(() => _isRecording = true);
    final path =
        '/sdcard/Download/comment_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!
        .startRecorder(toFile: path, codec: flutter_sound.Codec.aacADTS);
  }

  Future<void> stopRecording() async {
    if (kIsWeb) return;
    if (_recorder != null && _isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        if (path != null) _comments.add({"type": "audio", "data": path});
      });
    }
  }

  Future<void> openPdfFile(Map<String, dynamic> file) async {
    final pdfUrl = file["fileURL"] ?? "";
    final pdfId = file["_id"]?.toString() ?? "unnamed_pdf";
    try {
      if (kIsWeb) {
        if (pdfUrl.isNotEmpty) {
          await launchUrl(Uri.parse(pdfUrl),
              mode: LaunchMode.externalApplication);
        }
        return;
      }
      String localPath = pdfUrl;
      if (pdfUrl.startsWith("http")) {
        final dir = await getApplicationDocumentsDirectory();
        final fileOnDisk = File('${dir.path}/$pdfId.pdf');
        if (!await fileOnDisk.exists()) {
          final response = await http.get(Uri.parse(pdfUrl));
          if (response.statusCode == 200) {
            await fileOnDisk.writeAsBytes(response.bodyBytes);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.failedToLoadPdf)));
            }
            return;
          }
        }
        if (!await fileOnDisk.exists() || await fileOnDisk.length() < 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.invalidFile)));
          }
          return;
        }
        localPath = fileOnDisk.path;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfEditorPage(
              title: AppLocalizations.of(context)!.pdfFile,
              pdfPath: localPath,
              pdfId: pdfId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ PDF open error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred(""))));
      }
    }
  }

  Future<void> openHtmlFile(String url, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HtmlViewerPage(url: url, title: title)),
    );
  }

  Future<void> sendTextComment(String message) async {
    try {
      final response = await apiService.request(
        "chat/add_comment/${widget.v_id}",
        {"message": message, "videoname": widget.videoTitle},
        "POST",
      );
      if (response != null && response.statusCode == 200) {
        setState(() {
          _comments.add({"type": "text", "data": message});
          _commentController.clear();
        });
      }
    } catch (e) {
      debugPrint("❌ Error sending comment: $e");
    }
  }

  Future<void> fetchAllComments() async {
    try {
      final response = await apiService.request(
        "chat/show_comments_in_video/${widget.v_id}",
        null,
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          setState(() {
            _comments.clear();
            for (var item in data) {
              _comments.add({
                "type": "text",
                "data": item["message"] ?? "",
                "name": item["studentname"] ??
                    AppLocalizations.of(context)!.student,
                "reply": item["reply"] ?? "",
                "replyUrl": item["replyUrl"] ?? "",
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching comments: $e");
    }
  }

  Future<void> goToExercise() async {
    try {
      final res = await apiService.request(
        "student/exam/get_exercise_in_video/${widget.exerciseId}",
        null,
        "GET",
      );
      if (res != null && res.statusCode == 200) {
        final exam = res.data;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseStartPage(
                examId: exam["_id"],
                courseId: widget.courseId,
                title: exam["title"],
                questions: List<Map<String, dynamic>>.from(exam["Questions"]),
                duration: 120,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.exerciseNotAvailable)));
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading exercise: $e");
    }
  }

  Future<void> _loadParentNumber() async {
    final number = await _storage.read(key: "savedUserNum");
    if (mounted) setState(() => _parentNumber = number ?? "");
  }

  Future<void> _loadOfflineVideoFlag() async {
    final flag = await apiService.getOfflineVideoFlag();
    if (mounted) setState(() => _enableOfflineVideo = flag);
  }

  bool get _isVimeo => _currentVideoUrl.toLowerCase().contains('vimeo');

  String? _extractVimeoId(String url) {
    final regex = RegExp(r'vimeo\.com/(?:video/)?([0-9]+)');
    return regex.firstMatch(url)?.group(1);
  }

  Future<void> _checkIfDownloaded() async {
    final id = _extractVimeoId(_currentVideoUrl);
    if (id == null) return;
    final downloaded = await SecureVideoService.isDownloaded(id);
    if (downloaded && mounted) {
      setState(() => _isDownloaded = true);
      await _startLocalServer(id);
    }
  }

  Future<void> _startLocalServer(String videoId) async {
    final dir = await getApplicationDocumentsDirectory();
    final encPath = '${dir.path}/secure_videos/$videoId.enc';
    final result = await SecureVideoService.startDecryptionServer(encPath);
    _localServer = result.server;
    final ctrl = VideoPlayerController.networkUrl(result.uri);
    await ctrl.initialize();
    final chewie = ChewieController(
      videoPlayerController: ctrl,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
    );
    if (mounted) {
      setState(() {
        localServerUri = result.uri;
        _videoController = ctrl;
        _chewieController = chewie;
      });
    }
  }

  Future<void> _downloadVideo() async {
    final id = _extractVimeoId(_currentVideoUrl);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.failedToExtractVideoId ??
              AppLocalizations.of(context)?.cannotExtractVideoId ?? "تعذّر استخراج معرّف الفيديو")));
      return;
    }
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    try {
      final userToken = await apiService.getUserToken();
      if (userToken == null) throw Exception('Not logged in');
      final mp4Url = await SecureVideoService.getVimeoMp4Url(
          vimeoVideoId: id, userToken: userToken);
      if (mp4Url == null) throw Exception(AppLocalizations.of(context)?.failedToGetDownloadLink ?? "فشل جلب رابط التنزيل");
      final encPath = await SecureVideoService.downloadAndEncrypt(
        mp4Url: mp4Url,
        videoId: id,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (encPath == null) throw Exception(AppLocalizations.of(context)?.downloadFailed ?? "فشل التنزيل");
      setState(() => _isDownloaded = true);
      await _startLocalServer(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.downloadedWatchOffline ??
              AppLocalizations.of(context)?.downloadSuccessOffline ?? "✅ تم التنزيل — يمكنك المشاهدة بدون إنترنت"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint('❌ _downloadVideo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.errorDisplay(e.toString()) ?? "❌ خطأ: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _triggerBubble() {
    if (!mounted) return;
    setState(() => _showBubble = true);
    _bubbleHideTimer?.cancel();
    _bubbleHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  Widget _buildBubbleNotificationOverlay(bool isDark) {
    if (!_showBubble || _currentBubbleMessage.isEmpty) return const SizedBox.shrink();

    final skyColor = AppColors.sky(isDark);

    return Positioned(
      top: 14,
      left: 20,
      right: 20,
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          shadowColor: skyColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF0F7FF)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: skyColor.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: skyColor.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: skyColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: skyColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _currentBubbleMessage,
                    style: GoogleFonts.cairo(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (mounted) setState(() => _showBubble = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.getTextSecondaryColor(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoWithShell() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Stack(
      children: [
        _VideoShell(child: _buildVideoArea()),
        if (_showBubble) _buildBubbleNotificationOverlay(isDark),
      ],
    );
  }

  Widget _buildVideoArea() {
    if (_chewieController != null) {
      return AspectRatio(
          aspectRatio: 16 / 9, child: Chewie(controller: _chewieController!));
    }
    if (_isOffline) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)?.videoCannotBeOffline ?? "هذا الفيديو لا يمكن عرضه بدون إنترنت",
                    style:
                        GoogleFonts.cairo(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }
    final isDrive = _currentVideoUrl.toLowerCase().contains('drive.google.com') ||
        _currentVideoUrl.toLowerCase().contains('docs.google.com');

    final effectiveWatermark = (_parentNumber != null && _parentNumber!.isNotEmpty)
        ? _parentNumber!
        : widget.watermarkText;

    if (isDrive) {
      return DriveVideoPlayer(
        key: ValueKey("$_currentVideoUrl$effectiveWatermark"),
        videoUrl: _currentVideoUrl,
        watermarkText: effectiveWatermark,
        bubbleMessage: widget.bubbleMessage,
        bubbleInterval: widget.bubbleInterval,
        onFloatPressed: () {
          VideoOverlayManager().show(
            context,
            videoUrl: _currentVideoUrl,
            videoTitle: widget.videoTitle,
            watermarkText: effectiveWatermark,
            startAt: 0,
            vId: widget.v_id,
            exerciseId: widget.exerciseId,
            courseId: widget.courseId,
            files: widget.files,
            additionalVideos: widget.additionalVideos,
            exerciseArr: widget.exerciseArr,
            bubbleMessage: widget.bubbleMessage,
            bubbleInterval: widget.bubbleInterval,
          );
          Navigator.pop(context);
        },
      );
    }

    return YoutubeVideoPlayer(
      key: ValueKey("$_currentVideoUrl$effectiveWatermark"),
      videoUrl: _currentVideoUrl,
      watermarkText: effectiveWatermark,
      bubbleMessage: widget.bubbleMessage,
      bubbleInterval: widget.bubbleInterval,
      inVideoQuestions: widget.inVideoQuestions,
      onFloatPressed: () {
        VideoOverlayManager().show(
          context,
          videoUrl: _currentVideoUrl,
          videoTitle: widget.videoTitle,
          watermarkText: effectiveWatermark,
          startAt: 0,
          vId: widget.v_id,
          exerciseId: widget.exerciseId,
          courseId: widget.courseId,
          files: widget.files,
          additionalVideos: widget.additionalVideos,
          exerciseArr: widget.exerciseArr,
          bubbleMessage: widget.bubbleMessage,
          bubbleInterval: widget.bubbleInterval,
        );
        Navigator.pop(context);
      },
    );
  }

  void _changeVideo(String newVideoUrl) =>
      setState(() => _currentVideoUrl = newVideoUrl);

  // ── Pop helper: always pass listened state back to parent ──────────────────
  void _navigateBack() {
    Navigator.of(context).pop({
      "listened": _isMarkedAsListened,
      "v_id": widget.v_id,
    });
  }

  @override
  void initState() {
    super.initState();
    isExerciseAnswered = widget.exerciseArr.contains(widget.exerciseId);
    if (isExerciseAnswered) {
      _fetchExerciseScore();
    } else {
      _fetchExerciseInfo();
    }
    VideoOverlayManager().dismiss();
    apiService = ApiService();
    _loadParentNumber();
    _currentVideoUrl = widget.videoUrl;
    isExerciseAnswered = widget.exerciseArr.contains(widget.exerciseId);

    if (_currentVideoUrl.toLowerCase().contains('vimeo')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfDownloaded());
    }
    _loadOfflineVideoFlag();

    // Load persisted listened state on open (local first, then server)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _recordAccess();
      await _loadListenedState(); // ← restores AppLocalizations.of(context)?.watchedBadge ?? "تمت المشاهدة" badge instantly
    });

    // Watch timer — fires every 3 minutes
    _watchTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      // Already marked — no need to keep ticking
      if (_isMarkedAsListened) {
        timer.cancel();
        return;
      }

      setState(() => _watchedChunks += 1);

      // Send time-tracking ping to server
      try {
        await apiService.request(
          "tracktime/add_time/${widget.v_id}",
          {"videoname": "${widget.videoTitle} ${_parentNumber}".trim()},
          "POST",
        );
      } catch (e) {
        debugPrint("❌ Error sending watch time: $e");
      }

      // Check threshold → mark as listened
      if (_watchedChunks >= _kListenThresholdChunks) {
        await _markVideoAsListened();
        timer.cancel(); // stop ticking once marked
      }
    });

    // Bubble notification timer logic
    final String bubbleMsg = (widget.bubbleMessage ?? "").trim();
    final int bubbleIntervalMins = widget.bubbleInterval ?? 0;

    _bubbleInitialTimer?.cancel();
    _bubbleTimer?.cancel();
    _bubbleHideTimer?.cancel();

    if (bubbleMsg.isNotEmpty && bubbleIntervalMins > 0) {
      _currentBubbleMessage = bubbleMsg;

      // Initial trigger after 15 seconds
      _bubbleInitialTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) _triggerBubble();
      });

      _bubbleTimer = Timer.periodic(Duration(minutes: bubbleIntervalMins), (timer) {
        if (mounted) _triggerBubble();
      });
    }

    fetchAllComments();
  }

  Future<void> _recordAccess() async {
    try {
      final response = await apiService.request(
          "tracktime/record_access/${widget.v_id}", {}, "POST");
      if (!mounted) return;
      if (response == null) {
        setState(() => _isOffline = true);
        return;
      }
      // if (response.statusCode == 403) _showAccessBlockedDialog();
    } catch (e) {
      debugPrint("❌ Error recording access: $e");
    }
  }

  // void _showAccessBlockedDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => PopScope(
  //       canPop: false,
  //       onPopInvoked: (didPop) {
  //         if (didPop) return;
  //         Navigator.of(ctx).pop();
  //         Navigator.of(context).pop();
  //       },
  //       child: AlertDialog(
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Text(AppLocalizations.of(context)?.alertTitle ?? "تنبيه ",
  //             textAlign: TextAlign.center,
  //             style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
  //         content: Text(
  //           AppLocalizations.of(context)?.maxViewsReached ?? "لقد وصلت للحد الأقصى من مشاهدات هذا الفيديو. تواصل مع المعلم لزيادة الحد.",
  //           textAlign: TextAlign.center,
  //           style: GoogleFonts.cairo(fontSize: 15, height: 1.5),
  //         ),
  //         actionsAlignment: MainAxisAlignment.center,
  //         actions: [
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: _kBlue,
  //               shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(10)),
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  //             ),
  //             onPressed: () {
  //               Navigator.pop(ctx);
  //               Navigator.pop(context);
  //             },
  //             child: Text(AppLocalizations.of(context)?.returnBtn ?? "العودة",
  //                 style: GoogleFonts.cairo(
  //                     color: Colors.white, fontWeight: FontWeight.bold)),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tabs.isEmpty) {
      final loc = AppLocalizations.of(context)!;
      if (widget.additionalVideos.isNotEmpty) {
        tabs.add(
            _TabItem(label: loc.videos, icon: Icons.video_library_outlined));
      }
      if (widget.exerciseId.isNotEmpty) {
        tabs.add(_TabItem(label: loc.exercises, icon: Icons.bolt_outlined));
      }
      if (widget.files.isNotEmpty) {
        tabs.add(_TabItem(label: loc.files, icon: Icons.folder_open_outlined));
      }
      tabs.add(_TabItem(
          label: loc.comments, icon: Icons.chat_bubble_outline_rounded));
    }
  }

  @override
  void dispose() {
    _watchPageScrollController.dispose();
    _commentController.dispose();
    _watchTimer?.cancel();
    _bubbleInitialTimer?.cancel();
    _bubbleTimer?.cancel();
    _bubbleHideTimer?.cancel();
    _recorder?.closeRecorder();
    _chewieController?.dispose();
    _videoController?.dispose();
    _localServer?.close();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // PopScope intercepts the system back button and passes result to parent
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  _buildVideoWithShell(),
                  Expanded(
                    child: Scrollbar(
                      controller: _watchPageScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _watchPageScrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildLessonHeader(),
                            const SizedBox(height: 16),
                            _buildTabBar(),
                            const SizedBox(height: 16),
                            _buildTabContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Lesson header ──────────────────────────────────────────────────────────
  Widget _buildLessonHeader() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button + title
        Row(
          children: [
            InkWell(
              onTap: _navigateBack,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1D293D) : const Color(0xffF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.getTextColor(isDark),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.videoTitle,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Teacher / grade row
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(PhosphorIconsFill.userSound,
                size: 18, color: AppColors.getTextSecondaryColor(isDark)),
            const SizedBox(width: 4),
            Text(
              (widget.teacherName != null && widget.teacherName!.isNotEmpty)
                  ? widget.teacherName!
                  : AppLocalizations.of(context)?.teacherMohamed ?? "أ. محمد عبد المعبود",
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.getTextSecondaryColor(isDark),
                    shape: BoxShape.rectangle)),
            const SizedBox(width: 8),
            Text(
              (widget.userGroupName != null && widget.userGroupName!.isNotEmpty)
                  ? widget.userGroupName!
                  : AppLocalizations.of(context)?.thirdSecGrade ?? "الصف الثالث الثانوي",
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // XP badge + listen progress row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_enableOfflineVideo && _isVimeo) _buildDownloadWidget(),
            // _buildListenProgressBadge(isDark),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xffFF6900).withOpacity(0.1)
                    : const Color(0XFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark
                        ? const Color(0xffFF6900).withOpacity(0.2)
                        : const Color(0XFFFFEDD4),
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsFill.gift,
                      size: 18, color: Color(0XFFF54900)),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)?.watchForXp ?? "للمشاهده +50 XP",
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0XFFF54900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Listen progress badge ──────────────────────────────────────────────────
  // Widget _buildListenProgressBadge(bool isDark) {
  //   if (_isMarkedAsListened) {
  //     return Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //       decoration: BoxDecoration(
  //         color: _kGreen.withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: _kGreen.withOpacity(0.3)),
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(Icons.check_circle_rounded, size: 14, color: _kGreen),
  //           const SizedBox(width: 4),
  //           Text(
  //             AppLocalizations.of(context)?.watchedBadge ?? "تمت المشاهدة",
  //             style: GoogleFonts.cairo(
  //                 fontSize: 10, fontWeight: FontWeight.w700, color: _kGreen),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   final progress = (_watchedChunks / _kListenThresholdChunks).clamp(0.0, 1.0);
  //   final minutesWatched = _watchedChunks * 3;
  //   final minutesNeeded = _kListenThresholdChunks * 3;

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: isDark ? const Color(0xff1e293b) : const Color(0xffEFF6FF),
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(
  //           color: isDark ? const Color(0xff314158) : const Color(0xffBFDBFE)),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         SizedBox(
  //           width: 60,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(4),
  //                 child: LinearProgressIndicator(
  //                   value: progress,
  //                   minHeight: 5,
  //                   backgroundColor: isDark
  //                       ? const Color(0xff314158)
  //                       : const Color(0xffDBEAFE),
  //                   valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //               Text(
  //                 AppLocalizations.of(context)?.minutesWatchedNeeded(minutesWatched.toString(), minutesNeeded.toString()) ?? "$minutesWatched / $minutesNeeded د",
  //                 style: GoogleFonts.cairo(
  //                     fontSize: 9,
  //                     color: AppColors.getTextSecondaryColor(isDark),
  //                     fontWeight: FontWeight.w600),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 6),
  //         Icon(Icons.visibility_outlined,
  //             size: 13, color: AppColors.getTextSecondaryColor(isDark)),
  //         const SizedBox(width: 3),
  //         Text(
  //           AppLocalizations.of(context)?.watchProgress ?? "تقدم المشاهدة",
  //           style: GoogleFonts.cairo(
  //               fontSize: 10,
  //               fontWeight: FontWeight.w700,
  //               color: AppColors.getTextSecondaryColor(isDark)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDownloadWidget() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    if (_isDownloaded && _chewieController != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.check_circle, color: _kGreen, size: 15),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context)?.savedOfflineBadge ?? "محفوظ بدون إنترنت",
              style: GoogleFonts.cairo(fontSize: 12, color: _kGreen)),
        ],
      );
    }
    if (_isDownloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.sky(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _downloadProgress > 0
                ? AppLocalizations.of(context)?.downloadingPercent((_downloadProgress * 100).toStringAsFixed(0).toString()) ?? "جارٍ التنزيل ${(_downloadProgress * 100).toStringAsFixed(0)}%"
                : AppLocalizations.of(context)?.downloadingDots ?? "جارٍ التنزيل…",
            style:
                GoogleFonts.cairo(fontSize: 12, color: AppColors.sky(isDark)),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _downloadVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sky(isDark).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sky(isDark).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.download,
                size: 16, color: AppColors.sky(isDark)),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)?.downloadOfflineBtn ?? "تنزيل بدون إنترنت",
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sky(isDark))),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final selected = _selectedTabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.sky(isDark)
                    : AppColors.getBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getCardBorderColor(isDark),
                ),
              ),
              child: Text(
                tabs[i].label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF62748E),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab content ────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    final loc = AppLocalizations.of(context)!;
    final currentTab = tabs[_selectedTabIndex].label;
    if (currentTab == loc.exercises) return _buildExerciseTab(loc);
    if (currentTab == loc.files) return _buildFilesTab(loc);
    if (currentTab == loc.comments) return _buildCommentsTab(loc);
    if (currentTab == loc.videos) return _buildVideosTab(loc);
    return const SizedBox();
  }

  // ── Exercise tab ───────────────────────────────────────────────────────────
  Widget _buildExerciseTab(AppLocalizations loc) {
    if (isExerciseAnswered) {
      if (_isLoadingScore) {
        return const Center(child: CircularProgressIndicator());
      }
      return _PassedQuizCard(
        score: _exerciseGrade?.score.round(),
        total: _exerciseGrade?.maxMark.round(),
        onViewMistakes: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultPage(
                examId: widget.exerciseId, title: " ", isExercise: true),
          ),
        ),
        onNextLecture: () => Navigator.pop(context),
      );
    }

    if (_isLoadingExerciseInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    final questions = _exerciseData?["Questions"] as List?;
    final questionCount = questions?.length ?? 2;
    final durationMinutes = _exerciseData?["duration"] ?? 120;
    final passMark = _exerciseData?["passMark"] ?? 50;
    final xpReward = _exerciseData?["xp"] ?? 50;

    return _QuizCard(
      xpReward: xpReward,
      title: _exerciseData?["title"] ?? AppLocalizations.of(context)?.lessonCompletionQuiz ?? "كويز إتمام الدرس",
      subtitle: AppLocalizations.of(context)?.mustPassQuizToUnlock ?? "يلزم اجتياز الكويز لفتح الدرس التالي",
      questionCount: questionCount,
      durationMinutes: durationMinutes,
      passMark: passMark,
      onStart: goToExercise,
    );
  }

  // ── Files tab ──────────────────────────────────────────────────────────────
  Widget _buildFilesTab(AppLocalizations loc) {
    if (widget.files.isEmpty) {
      return _EmptyState(
          icon: Icons.folder_open_outlined, label: loc.noFilesAvailable);
    }
    return Column(
      children: widget.files.map((file) {
        final url = file["fileURL"] ?? "";
        final type = file["type"]?.toString().toLowerCase() ?? "pdf";
        final isHtml = type == "html";
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FileCard(
            icon: isHtml ? Icons.web_outlined : Icons.picture_as_pdf_outlined,
            label: isHtml ? AppLocalizations.of(context)?.htmlPageLabel ?? "صفحة HTML" : loc.pdfFile,
            onTap: () => isHtml ? openHtmlFile(url, "HTML") : openPdfFile(file),
          ),
        );
      }).toList(),
    );
  }

  // ── Comments tab ───────────────────────────────────────────────────────────
  Widget _buildCommentsTab(AppLocalizations loc) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xff1e293b) : const Color(0xffDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isDark ? const Color(0xff314158) : Colors.transparent),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Man%20Student.png",
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.getTextSecondaryColor(isDark),
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: loc.typeQuestionHint,
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.getTextSecondaryColor(isDark),
                      fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: AppColors.getInputBackgroundColor(isDark),
                  contentPadding: const EdgeInsets.all(8),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty) sendTextComment(text);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sky(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        PhosphorIconsFill.paperPlaneTilt,
                        size: 16,
                        color: Colors.white,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppColors.getCardBorderColor(isDark), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppColors.getCardBorderColor(isDark), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppColors.sky(isDark), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._comments.map((c) => _buildCommentBubble(c, loc)),
      ],
    );
  }

  Widget _buildCommentBubble(Map<String, dynamic> c, AppLocalizations loc) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final replyUrl = c["replyUrl"]?.toString() ?? "";
    final isAudio = replyUrl.endsWith(".mp3") ||
        replyUrl.endsWith(".aac") ||
        replyUrl.endsWith(".wav");
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xff1e293b)
                      : const Color(0xffDBEAFE),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark
                          ? const Color(0xff314158)
                          : Colors.transparent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Man%20Student.png",
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getModalSheetColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.getCardBorderColor(isDark)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c["name"] ?? loc.student,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextColor(isDark)),
                      ),
                      const SizedBox(height: 4),
                      Text(c["data"] ?? "",
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xffCAD5E2)
                                  : const Color(0xff45556C))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if ((c["reply"] ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: isAudio
                  ? _AudioReplyBubble(url: replyUrl)
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xff1D293D)
                            : const Color(0xffEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        loc.teacherReply(c["reply"] ?? ""),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                            color: AppColors.sky(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  // ── Additional videos tab ──────────────────────────────────────────────────
  Widget _buildVideosTab(AppLocalizations loc) {
    if (widget.additionalVideos.isEmpty) {
      return _EmptyState(
          icon: Icons.video_library_outlined, label: loc.noAdditionalVideos);
    }
    return Column(
      children: [
        _VideoListCard(
          title: widget.videoTitle,
          subtitle: loc.mainVideo,
          onTap: () => _changeVideo(widget.videoUrl),
        ),
        ...widget.additionalVideos.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          String url = "";
          String title = loc.additionalVideoCount(i + 1);
          if (item is Map) {
            url = item["link"]?.toString() ?? "";
            title = item["name"]?.toString() ?? title;
          } else if (item is String) {
            url = item;
          }
          return _VideoListCard(
            title: title,
            subtitle: "",
            onTap: () => _changeVideo(url),
          );
        }),
      ],
    );
  }
}

// ─── Video shell ──────────────────────────────────────────────────────────────
class _VideoShell extends StatelessWidget {
  final Widget child;
  const _VideoShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(aspectRatio: 16 / 9, child: child),
    );
  }
}

// ─── Quiz card (not answered) ─────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final int xpReward;
  final String title;
  final String subtitle;
  final int questionCount;
  final int durationMinutes;
  final int passMark;
  final VoidCallback onStart;

  const _QuizCard({
    required this.xpReward,
    required this.title,
    required this.subtitle,
    required this.questionCount,
    required this.durationMinutes,
    required this.passMark,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? AppColors.sky(isDark)
                : AppColors.sky(isDark).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.sky(isDark).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.sky(isDark).withOpacity(0.2)),
                    ),
                    child: Icon(PhosphorIconsFill.exam,
                        color: AppColors.sky(isDark), size: 22),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark))),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextSecondaryColor(isDark))),
                    ],
                  )
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xffFF6900).withOpacity(0.1)
                      : const Color(0XFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xffFF6900).withOpacity(0.2)
                          : const Color(0XFFFFEDD4),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsFill.gift,
                        size: 18, color: Color(0xffFF6900)),
                    const SizedBox(width: 4),
                    Text("+XP $xpReward",
                        style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xffFF6900))),
                  ],
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // Container(
          //   decoration: BoxDecoration(
          //       color: AppColors.getBackgroundColor(isDark),
          //       borderRadius: BorderRadius.circular(8),
          //       border:
          //           Border.all(color: AppColors.getCardBorderColor(isDark))),
          //   child: Padding(
          //     padding:
          //         const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       crossAxisAlignment: CrossAxisAlignment.center,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(
          //               PhosphorIconsFill.question,
          //               size: 20,
          //               textDirection: TextDirection.ltr,
          //               color: AppColors.getSecondHintColor(isDark),
          //             ),
          //             const SizedBox(width: 2),
          //             Text(AppLocalizations.of(context)?.questionsCountLabel(questionCount.toString()) ?? "$questionCount اسئلة",
          //                 style: GoogleFonts.cairo(
          //                     fontSize: 10,
          //                     fontWeight: FontWeight.w700,
          //                     color: AppColors.getTextSecondaryColor(isDark))),
          //             const SizedBox(width: 14),
          //             Icon(
          //               PhosphorIconsFill.clock,
          //               size: 20,
          //               textDirection: TextDirection.ltr,
          //               color: AppColors.getSecondHintColor(isDark),
          //             ),
          //             const SizedBox(width: 2),
          //             Text(AppLocalizations.of(context)?.durationMinsLabel(durationMinutes.toString()) ?? "$durationMinutes دقيقة",
          //                 style: GoogleFonts.cairo(
          //                     fontSize: 10,
          //                     fontWeight: FontWeight.w700,
          //                     color: AppColors.getTextSecondaryColor(isDark))),
          //           ],
          //         ),
          //         Text(
          //           AppLocalizations.of(context)?.passMarkPercent(passMark.toString()) ?? "النجاح من $passMark%",
          //           style: GoogleFonts.cairo(
          //               fontSize: 10,
          //               fontWeight: FontWeight.w700,
          //               color: AppColors.sky(isDark)),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onStart,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kBlue, Color(0xFF1E88E5)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _kBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.startExamNowBtn ?? "ابدأ الاختبار الآن",
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz card (passed) ───────────────────────────────────────────────────────
class _PassedQuizCard extends StatelessWidget {
  final int? score; // ✅ now nullable
  final int? total; // ✅ now nullable
  final VoidCallback onViewMistakes;
  final VoidCallback onNextLecture;

  const _PassedQuizCard({
    this.score,
    this.total,
    required this.onViewMistakes,
    required this.onNextLecture,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Color(0XFF004F3B).withOpacity(0.1)
            : Color(0XFFECFDF5).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isDark ? Color(0XFF00BC7D).withOpacity(0.2) : Color(0XFFD0FAE5),
            width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0XFF004F3B).withOpacity(0.1)
                          : Color(0XFFD0FAE5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isDark
                              ? Color(0XFF00BC7D).withOpacity(0.2)
                              : Color(0XFFA4F4CF),
                          width: 1.5),
                    ),
                    child: Icon(PhosphorIconsFill.sealCheck,
                        textDirection: TextDirection.ltr,
                        color: isDark ? Color(0XFF00BC7D) : Color(0XFF009966),
                        size: 24),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          AppLocalizations.of(context)?.lessonCompletionQuiz ??
                              AppLocalizations.of(context)?.lessonCompletionQuiz ?? "كويز إتمام الدرس",
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark))),
                      const SizedBox(height: 4),
                      Text(
                          AppLocalizations.of(context)
                                  ?.nextLectureAvailableNow ??
                              AppLocalizations.of(context)?.nextLectureAvailable ?? "المحاضرة القادمة متاحة الآن",
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.greenStatus(isDark),
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                ],
              ),
              if (score != null && total != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.getInputBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(isDark))),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$score",
                          style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(isDark)),
                        ),
                        TextSpan(
                          text: " / $total",
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextHintColor(isDark)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onViewMistakes,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.getInputBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(isDark)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsFill.eye,
                            size: 20, color: AppColors.getIconColor(isDark)),
                        const SizedBox(width: 8),
                        Text(
                            AppLocalizations.of(context)?.reviewMyMistakes ??
                                AppLocalizations.of(context)?.reviewMyMistakes ?? "مراجعة اخطائي",
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getIconColor(isDark))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onNextLecture,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.greenStatus(isDark),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: _kGreen.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsFill.playCircle,
                            textDirection: TextDirection.ltr,
                            size: 20,
                            color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                            AppLocalizations.of(context)?.nextLecture ??
                                AppLocalizations.of(context)?.nextLectureBtn ?? "المحاضرة التالية",
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── File card ────────────────────────────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FileCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.sky(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.sky(isDark), size: 20),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.getTextColor(isDark))),
            const Spacer(),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.getBackgroundColor(isDark).withOpacity(0.5)),
              child: Icon(
                PhosphorIconsRegular.eye,
                color: AppColors.getIconColor(isDark),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ─── Video list card ──────────────────────────────────────────────────────────
class _VideoListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _VideoListCard(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.getInputBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getCardBorderColor(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.sky(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.play_arrow_rounded,
                  color: AppColors.sky(isDark).withOpacity(0.5), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getTextColor(isDark))),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.getTextColor(isDark))),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_left,
                color: AppColors.getTextColor(isDark), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Audio reply bubble ───────────────────────────────────────────────────────
class _AudioReplyBubble extends StatelessWidget {
  final String url;
  const _AudioReplyBubble({required this.url});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A37F7).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A37F7).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              final player = flutter_sound.FlutterSoundPlayer();
              await player.openPlayer();
              await player.startPlayer(fromURI: url);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration:
                  const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.mic, color: _kBlue, size: 16),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.voiceMessageLabel ?? "رسالة صوتية",
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.sky(isDark).withOpacity(0.5),
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.getBorderColor(isDark)),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 15, color: AppColors.getTextColor(isDark))),
          ],
        ),
      ),
    );
  }
}

// ─── Tab item model ───────────────────────────────────────────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}
