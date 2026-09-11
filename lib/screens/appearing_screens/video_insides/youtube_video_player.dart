import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/youtube_fullscreen_page.dart';
import 'package:flutter_version/widgets/watch_time_helper.dart';
import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:flutter_version/widgets/video_overlay_manager.dart';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'dart:developer'; // 👈 ده عشان log()
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 ده عشان launchUrl()
import 'package:webview_windows/webview_windows.dart' as win_wv;

typedef YoutubeWebResourceError = WebResourceError;

class YoutubeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String watermarkText;
  final String? bubbleMessage;
  final int? bubbleInterval;
  final List<dynamic>? inVideoQuestions;

  const YoutubeVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.watermarkText,
    this.startAt = 0.0,
    this.isMini = false,
    this.onFloatPressed,
    this.bubbleMessage,
    this.bubbleInterval,
    this.inVideoQuestions,
  });

  final double startAt;
  final bool isMini;
  final VoidCallback? onFloatPressed;

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer> {
  final List<double> speedOptions = [0.25, 0.5, 1.0, 1.5, 2.0];
  double selectedSpeed = 1.0;

  late final WebViewController _controller;

  double currentTime = 0;
  double duration = 1;
  double position = 0;

  bool isPlaying = false;
  bool isMuted = false;

  bool showOverlay = false;
  bool _hasError = false;

  final win_wv.WebviewController _winController = win_wv.WebviewController();
  bool _isWinInitialized = false;
  Timer? _winTimer;

  Future<void> _initWindowsPlayer() async {
    try {
      await _winController.initialize();
      await _winController.setPopupWindowPolicy(win_wv.WebviewPopupWindowPolicy.deny);
      await _winController.setBackgroundColor(Colors.black);

      double initialStart = widget.startAt;
      if (initialStart == 0.0) {
        initialStart = await WatchTimeHelper.loadWatchTime(widget.videoUrl);
        currentTime = initialStart;
      }

      final isVimeo = widget.videoUrl.toLowerCase().contains('vimeo');
      final videoId = isVimeo ? '' : _extractVideoId(widget.videoUrl);

      if (isVimeo) {
        final sep = widget.videoUrl.contains('?') ? '&' : '?';
        final formattedVimeoUrl = '${widget.videoUrl}${sep}playsinline=1&dnt=1&transparent=0&autopause=0&quality=auto';
        final vimeoHtml = '''<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>* { margin: 0; padding: 0; } body, html { width: 100%; height: 100%; background: #000; overflow: hidden; } iframe { width: 100%; height: 100%; border: none; }</style><script src="https://player.vimeo.com/api/player.js"></script></head><body><iframe src="$formattedVimeoUrl" allow="autoplay; fullscreen" allowfullscreen></iframe></body></html>''';
        await _winController.loadStringContent(vimeoHtml);
      } else {
        final targetUrl = 'https://coursesapp.github.io/youtube_embedded_video/?video=$videoId&watermark=${Uri.encodeComponent(widget.watermarkText)}&start=${initialStart.toInt()}';
        await _winController.loadUrl(targetUrl);
      }

      _winTimer?.cancel();
      _winTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted) return;
        try {
          final res = await _winController.executeScript("""
            (function() {
              if (typeof player !== 'undefined' && typeof player.getCurrentTime === 'function') {
                return player.getCurrentTime();
              }
              return 0;
            })()
          """);
          if (res != null) {
            final double currentSecs = double.tryParse(res.toString()) ?? 0.0;
            if (currentSecs > 0) {
              currentTime = currentSecs;
              WatchTimeHelper.saveWatchTime(widget.videoUrl, currentSecs);
              _checkInVideoQuestions(currentSecs);
            }
          }
        } catch (_) {}
      });

      if (mounted) {
        setState(() => _isWinInitialized = true);
      }
    } catch (e) {
      log('Error initializing Windows webview: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    currentTime = widget.startAt;

    if (!kIsWeb && Platform.isWindows) {
      _initWindowsPlayer();
      return;
    }

    if (WebViewPlatform.instance == null) return;

    // Check if it's a Vimeo URL
    final isVimeo = widget.videoUrl.toLowerCase().contains('vimeo');
    final videoId = isVimeo ? '' : _extractVideoId(widget.videoUrl);

    // Add WebKit configuration for iOS inline playback
    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true, // ← This enables inline playback
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}, // ← This allows autoplay
      );
    } else {
      webViewParams = const PlatformWebViewControllerCreationParams();
    }

    // ✅ IMPROVED NavigationDelegate
    final navigationDelegate = NavigationDelegate(
      onWebResourceError: (error) {
        log('[WEBVIEW ERROR] ${error.description}', name: 'WebViewError');
        if (isVimeo && error.isForMainFrame == true && mounted) {
          setState(() => _hasError = true);
        }
      },
      onHttpError: (HttpResponseError error) {
        log('[HTTP ERROR] ${error.response?.statusCode}', name: 'WebViewError');
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);

        if (uri == null) {
          log('[BLOCKED] Invalid URL');
          return NavigationDecision.prevent;
        }

        if (request.url.startsWith('data:') || request.url.startsWith('about:blank')) {
          return NavigationDecision.navigate;
        }

        // ✅ Allow your site, YouTube, and Vimeo hosts
        if (uri.host.contains('coursesapp.github.io') ||
            uri.host.contains('youtube.com') ||
            uri.host.contains('youtube-nocookie.com') ||
            uri.host.contains('vimeo.com') ||
            uri.host.contains('player.vimeo.com')) {
          log('[ALLOWED] ${uri.host}${uri.path}');
          return NavigationDecision.navigate;
        }

        // ✅ Allow YouTube video URLs like /watch?v=...
        if (uri.path == '/watch' && uri.queryParameters.containsKey('v')) {
          log('[YOUTUBE VIDEO ALLOWED] ${uri.queryParameters['v']}');
          return NavigationDecision.navigate;
        }

        // 🌐 Open external links in browser
        if (uri.scheme.startsWith('http') &&
            !(uri.host.contains('youtube') || uri.host.contains('github.io'))) {
          log('[EXTERNAL LINK OPENED] ${uri.toString()}');
          return NavigationDecision.prevent;
        }

        // 🚫 Block everything else
        log('[BLOCKED] ${uri.toString()}');
        return NavigationDecision.prevent;
      },
    );

    // Add JavaScript Channel for In-Video Questions
    _controller = WebViewController.fromPlatformCreationParams(webViewParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(navigationDelegate)
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'InVideoQuestionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['event'] == 'timeupdate') {
              final double currentSecs = (data['seconds'] as num).toDouble();
              currentTime = currentSecs;
              WatchTimeHelper.saveWatchTime(widget.videoUrl, currentSecs);
              _checkInVideoQuestions(currentSecs);
            }
          } catch (e) {
            log('Error in InVideoQuestionChannel: $e');
          }
        },
      );

    if (Platform.isIOS) {
      _controller.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
      );
    }

    _initPlayerPosition(isVimeo, videoId);
  }

  Future<void> _initPlayerPosition(bool isVimeo, String videoId) async {
    double initialStart = widget.startAt;
    if (initialStart == 0.0) {
      initialStart = await WatchTimeHelper.loadWatchTime(widget.videoUrl);
      currentTime = initialStart;
    }

    if (isVimeo) {
      final sep = widget.videoUrl.contains('?') ? '&' : '?';
      final formattedVimeoUrl = '${widget.videoUrl}${sep}playsinline=1&dnt=1&transparent=0&autopause=0&quality=auto';
      final vimeoHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body, html { width: 100%; height: 100%; background-color: #000; overflow: hidden; position: relative; }
    iframe { width: 100%; height: 100%; border: none; }
    .watermark {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: rgba(255, 255, 255, 0.15);
      font-family: system-ui, -apple-system, sans-serif;
      font-size: 32px;
      font-weight: 800;
      letter-spacing: 1px;
      pointer-events: none;
      z-index: 9999;
      text-align: center;
      white-space: nowrap;
      user-select: none;
    }
  </style>
  <script src="https://player.vimeo.com/api/player.js"></script>
</head>
<body>
  <iframe id="vimeo-player" src="$formattedVimeoUrl" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>
  ${widget.watermarkText.isNotEmpty ? '<div class="watermark">${widget.watermarkText}</div>' : ''}
  <script>
    var iframe = document.getElementById('vimeo-player');
    var player = new Vimeo.Player(iframe);

    player.ready().then(function() {
      if (${initialStart.toInt()} > 0) {
        player.setCurrentTime(${initialStart.toInt()});
      }
    });

    var lastSentTime = 0;
    player.on('timeupdate', function(data) {
      var now = Date.now();
      if (now - lastSentTime >= 1000) {
        lastSentTime = now;
        if (window.InVideoQuestionChannel) {
          window.InVideoQuestionChannel.postMessage(JSON.stringify({
            event: 'timeupdate',
            seconds: data.seconds
          }));
        }
      }
    });

    function pauseVideo() {
      if (player && typeof player.pause === 'function') player.pause();
    }

    function playVideo() {
      if (player && typeof player.play === 'function') player.play();
    }
  </script>
</body>
</html>
''';
      _controller.loadHtmlString(vimeoHtml, baseUrl: 'https://coursesapp.github.io');
    } else {
      _controller.loadRequest(
        Uri.parse(
          'https://coursesapp.github.io/youtube_embedded_video/?video=$videoId&watermark=${Uri.encodeComponent(widget.watermarkText)}&start=${initialStart.toInt()}',
        ),
      );
    }

    // Add iOS-specific configuration
    final webViewPlatform = _controller.platform;
    if (webViewPlatform is AndroidWebViewController) {
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
    }
  }

  String _extractVideoId(String url) {
    final regex = RegExp(r"(?:v=|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})");
    final match = regex.firstMatch(url);
    return match?.group(1) ?? "";
  }

  void _seekTo(double seconds) {
    if (!kIsWeb && Platform.isWindows) {
      _winController.executeScript("""
        if (typeof player !== 'undefined') {
          if (typeof player.setCurrentTime === 'function') player.setCurrentTime($seconds);
          if (typeof player.seekTo === 'function') player.seekTo($seconds);
        }
      """);
      return;
    }
    _controller.runJavaScript("""
      if (typeof player !== 'undefined') {
        if (typeof player.setCurrentTime === 'function') player.setCurrentTime($seconds);
        if (typeof player.seekTo === 'function') player.seekTo($seconds);
      }
    """);
  }

  // === Idea 3: Fullscreen open and return to same position ===
  Future<void> _openFullScreen() async {
    if (!kIsWeb && Platform.isWindows) {
      _winController.executeScript("""
        if (typeof pauseVideo === 'function') pauseVideo();
        if (typeof player !== 'undefined' && typeof player.pauseVideo === 'function') player.pauseVideo();
      """);

      final returnedTime = await Navigator.of(context).push<double>(
        MaterialPageRoute(
          builder: (_) => YoutubeFullscreenPage(
            videoUrl: widget.videoUrl,
            watermarkText: widget.watermarkText,
            bubbleMessage: widget.bubbleMessage,
            bubbleInterval: widget.bubbleInterval,
            inVideoQuestions: widget.inVideoQuestions,
            startAt: currentTime,
          ),
        ),
      );
      if (returnedTime != null && mounted) {
        setState(() {
          currentTime = returnedTime;
          position = returnedTime;
        });
        _seekTo(returnedTime);
      }
      return;
    }
    _controller.runJavaScript("if (typeof pauseVideo === 'function') pauseVideo();");

    final returnedTime = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => YoutubeFullscreenPage(
          videoUrl: widget.videoUrl,
          watermarkText: widget.watermarkText,
          bubbleMessage: widget.bubbleMessage,
          bubbleInterval: widget.bubbleInterval,
          inVideoQuestions: widget.inVideoQuestions,
          startAt: currentTime,
        ),
      ),
    );

    if (returnedTime != null && mounted) {
      setState(() {
        currentTime = returnedTime;
        position = returnedTime;
      });
      _seekTo(returnedTime);
    }
  }

  // === Idea 2: Save watch time when disposed ===
  @override
  void dispose() {
    _winTimer?.cancel();
    if (!kIsWeb && Platform.isWindows) {
      _winController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows) {
      return Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                _isWinInitialized
                    ? win_wv.Webview(_winController)
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                if (!widget.isMini && widget.onFloatPressed != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: widget.onFloatPressed,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_in_picture_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                if (!widget.isMini)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: InkWell(
                      onTap: _openFullScreen,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_hasError)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.white54, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'تعذّر تشغيل الفيديو',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!widget.isMini && widget.onFloatPressed != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: widget.onFloatPressed,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.picture_in_picture_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (!widget.isMini)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: InkWell(
                        onTap: _openFullScreen,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  final Set<String> _triggeredQuestions = {};
  bool _isShowingQuestionDialog = false;

  void _checkInVideoQuestions(double currentSeconds) {
    if (_isShowingQuestionDialog) return;
    final questions = widget.inVideoQuestions;
    if (questions == null || questions.isEmpty) return;

    for (var rawQ in questions) {
      if (rawQ == null) continue;
      final qMap = Map<String, dynamic>.from(rawQ as Map);
      final String qId = qMap['_id']?.toString() ?? qMap['question']?.toString() ?? '';
      final double qTime = (qMap['timestamp'] as num?)?.toDouble() ?? 0.0;

      if (!_triggeredQuestions.contains(qId) && currentSeconds >= qTime && (currentSeconds - qTime) < 5.0) {
        _triggeredQuestions.add(qId);
        _triggerInVideoQuestion(qMap);
        break;
      }
    }
  }

  void _triggerInVideoQuestion(Map<String, dynamic> qData) async {
    setState(() => _isShowingQuestionDialog = true);
    _controller.runJavaScript("if (typeof pauseVideo === 'function') pauseVideo();");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InVideoQuestionDialog(qData: qData),
    );

    if (mounted) {
      setState(() => _isShowingQuestionDialog = false);
      _controller.runJavaScript("if (typeof playVideo === 'function') playVideo();");
    }
  }
}

class InVideoQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> qData;
  const InVideoQuestionDialog({super.key, required this.qData});

  @override
  State<InVideoQuestionDialog> createState() => _InVideoQuestionDialogState();
}

class _InVideoQuestionDialogState extends State<InVideoQuestionDialog> {
  String? _selectedOption;
  bool _hasAnswered = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.qData;
    final String questionText = q['question'] ?? 'سؤال';
    final String img = q['img'] ?? '';
    final String role = q['role'] ?? 'choice';
    final String explanation = q['explanation'] ?? '';

    List<String> options = [];
    if (role == 'boolean') {
      options = ['صح', 'خطأ'];
    } else {
      if ((q['answer_1'] ?? '').toString().isNotEmpty) options.add(q['answer_1'].toString());
      if ((q['answer_2'] ?? '').toString().isNotEmpty) options.add(q['answer_2'].toString());
      if ((q['answer_3'] ?? '').toString().isNotEmpty) options.add(q['answer_3'].toString());
      if ((q['answer_4'] ?? '').toString().isNotEmpty) options.add(q['answer_4'].toString());
    }

    String _getCorrectText() {
      if (role == 'boolean') {
        final cb = (q['correctBoolean'] ?? q['correctChoice'] ?? '').toString().trim();
        if (cb == 'True' || cb == 'true' || cb == 'answer_1' || cb == '1') return 'صح';
        return 'خطأ';
      }
      final rawKey = (q['correctChoice'] ?? '').toString().trim();
      if (rawKey.isEmpty) return '';
      if (rawKey == 'answer_1' || rawKey == '1' || rawKey.toLowerCase() == 'a') return (q['answer_1'] ?? '').toString().trim();
      if (rawKey == 'answer_2' || rawKey == '2' || rawKey.toLowerCase() == 'b') return (q['answer_2'] ?? '').toString().trim();
      if (rawKey == 'answer_3' || rawKey == '3' || rawKey.toLowerCase() == 'c') return (q['answer_3'] ?? '').toString().trim();
      if (rawKey == 'answer_4' || rawKey == '4' || rawKey.toLowerCase() == 'd') return (q['answer_4'] ?? '').toString().trim();
      return rawKey;
    }

    void _submitAnswer(String opt) {
      if (_hasAnswered) return;
      final expectedText = _getCorrectText().trim();
      final bool correct = opt.trim() == expectedText;

      setState(() {
        _selectedOption = opt;
        _hasAnswered = true;
        _isCorrect = correct;
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '❓ سؤال تفاعلي',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (_hasAnswered)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'متابعة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                questionText,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (img.isNotEmpty && img != 'empty') ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(img, height: 140, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isThisSel = _selectedOption == opt;
                Color btnBg = Colors.grey.shade100;
                Color textColor = Colors.black87;
                BorderSide borderSide = BorderSide(color: Colors.grey.shade300);

                if (_hasAnswered) {
                  final expectedText = _getCorrectText().trim();
                  final isOptCorrect = opt.trim() == expectedText;

                  if (isOptCorrect) {
                    btnBg = Colors.green.shade50;
                    textColor = Colors.green.shade800;
                    borderSide = const BorderSide(color: Colors.green, width: 2);
                  } else if (isThisSel) {
                    btnBg = Colors.red.shade50;
                    textColor = Colors.red.shade800;
                    borderSide = const BorderSide(color: Colors.red, width: 2);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: btnBg,
                      side: borderSide,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _submitAnswer(opt),
                    child: Text(
                      opt,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                );
              }),
              if (_hasAnswered) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isCorrect ? '🎉 إجابة صحيحة!' : '❌ إجابة خاطئة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'الشرح: $explanation',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
