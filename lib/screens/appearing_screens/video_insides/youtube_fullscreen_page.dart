import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
// import 'package:flutter_version/widgets/watch_time_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'dart:developer'; // 👈 ده عشان log()
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 ده عشان launchUrl()
import 'package:webview_windows/webview_windows.dart' as win_wv;

import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_version/widgets/watch_time_helper.dart';
import 'youtube_video_player.dart';

class YoutubeFullscreenPage extends StatefulWidget {
  final String videoUrl;
  final String watermarkText;
  final String? bubbleMessage;
  final int? bubbleInterval;
  final List<dynamic>? inVideoQuestions;
  final double startAt;

  const YoutubeFullscreenPage({
    super.key,
    required this.videoUrl,
    this.watermarkText = "",
    this.bubbleMessage,
    this.bubbleInterval,
    this.inVideoQuestions,
    this.startAt = 0.0,
  });

  @override
  State<YoutubeFullscreenPage> createState() => _YoutubeFullscreenPageState();
}

class _YoutubeFullscreenPageState extends State<YoutubeFullscreenPage> {
  late final WebViewController _controller;

  double _selectedAspectRatio = 16 / 9;
  double currentTime = 0;

  // Bubble Notification Overlay for Fullscreen
  Timer? _bubbleInitialTimer;
  Timer? _bubbleTimer;
  Timer? _bubbleHideTimer;
  bool _showBubble = false;
  String _currentBubbleMessage = "";
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
      log('Error initializing Windows webview in fullscreen: $e');
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

    final videoId = _extractVideoId(widget.videoUrl);
    final isVimeo = widget.videoUrl.toLowerCase().contains('vimeo');

    // Add WebKit configuration for iOS inline playback
    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true, // ← This enables inline playback
        mediaTypesRequiringUserAction:
            const <PlaybackMediaTypes>{}, // ← This allows autoplay
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

        // ✅ Allow your site, YouTube hosts, and Vimeo hosts
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
            !(uri.host.contains('youtube') ||
                uri.host.contains('github.io') ||
                uri.host.contains('vimeo'))) {
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
      if (${widget.startAt.toInt()} > 0) {
        player.setCurrentTime(${widget.startAt.toInt()});
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
          'https://coursesapp.github.io/youtube_embedded_video/?video=$videoId&watermark=${Uri.encodeComponent(widget.watermarkText)}&start=${widget.startAt.toInt()}',
        ),
      );
    }

    // Add iOS-specific configuration
    final webViewPlatform = _controller.platform;
    if (webViewPlatform is AndroidWebViewController) {
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
      // iOS inline playback is enabled by the creation params above
    }

    _setupBubbleNotification();
  }

  void _setupBubbleNotification() {
    _bubbleInitialTimer?.cancel();
    _bubbleTimer?.cancel();
    _bubbleHideTimer?.cancel();

    final String bubbleMsg = (widget.bubbleMessage ?? "").trim();
    final int bubbleIntervalMins = widget.bubbleInterval ?? 0;

    if (bubbleMsg.isNotEmpty && bubbleIntervalMins > 0) {
      _currentBubbleMessage = bubbleMsg;

      _bubbleInitialTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) _triggerBubble();
      });

      _bubbleTimer = Timer.periodic(Duration(minutes: bubbleIntervalMins), (
        timer,
      ) {
        if (mounted) _triggerBubble();
      });
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

  String _extractVideoId(String url) {
    final regex = RegExp(r"(?:v=|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})");
    final match = regex.firstMatch(url);
    return match?.group(1) ?? "";
  }

  @override
  void dispose() {
    _winTimer?.cancel();
    _bubbleInitialTimer?.cancel();
    _bubbleTimer?.cancel();
    _bubbleHideTimer?.cancel();
    if (!kIsWeb && Platform.isWindows) {
      _winController.dispose();
    }
    super.dispose();
  }

  String formatRatio(double ratio) {
    if (ratio == 16 / 9) return "16:9";
    if (ratio == 4 / 3) return "4:3";
    if (ratio == 1.0) return "1:1";
    if (ratio == 21 / 9) return "21:9";
    if (ratio == 9 / 16) return "9:16";
    return ratio.toStringAsFixed(2);
  }

  Widget _buildBubbleNotificationOverlay(bool isDark) {
    if (!_showBubble || _currentBubbleMessage.isEmpty)
      return const SizedBox.shrink();

    final skyColor = AppColors.sky(isDark);

    return Positioned(
      top: 14,
      left: 60,
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
              maxWidth: MediaQuery.of(context).size.width * 0.8,
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
              border: Border.all(color: skyColor.withOpacity(0.4), width: 1.5),
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

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, currentTime),
          ),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: _selectedAspectRatio,
            child: _isWinInitialized
                ? win_wv.Webview(_winController)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),
      );
    }
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        Navigator.pop(context, currentTime);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _selectedAspectRatio,
                    child: _hasError
                        ? Container(
                            color: Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'تعذّر تشغيل الفيديو',
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : WebViewWidget(controller: _controller),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context, currentTime);
                    },
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: PopupMenuButton<double>(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.aspect_ratio, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            formatRatio(_selectedAspectRatio),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    color: const Color(0xFF1E293B),
                    onSelected: (double ratio) {
                      setState(() {
                        _selectedAspectRatio = ratio;
                      });
                    },
                    itemBuilder: (ctx) {
                      final mediaQuery = MediaQuery.of(ctx);
                      final screenRatio = mediaQuery.size.width / mediaQuery.size.height;
                      return [
                        const PopupMenuItem(
                          value: 16 / 9,
                          child: Text('📺 16:9 (عريض قياسي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: 9 / 16,
                          child: Text('📱 9:16 (طولي / عمودي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: 4 / 3,
                          child: Text('🖥️ 4:3 (تابلت / ايباد)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: 1.0,
                          child: Text('🔲 1:1 (مربع)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        PopupMenuItem(
                          value: screenRatio,
                          child: const Text('↔️ ملء الشاشة بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
