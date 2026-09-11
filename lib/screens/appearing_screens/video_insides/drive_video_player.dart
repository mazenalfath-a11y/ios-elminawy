import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;

class DriveVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String watermarkText;
  final bool isMini;
  final VoidCallback? onFloatPressed;
  final String? bubbleMessage;
  final int? bubbleInterval;

  const DriveVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.watermarkText,
    this.isMini = false,
    this.onFloatPressed,
    this.bubbleMessage,
    this.bubbleInterval,
  });

  @override
  State<DriveVideoPlayer> createState() => _DriveVideoPlayerState();
}

class _DriveVideoPlayerState extends State<DriveVideoPlayer> {
  late final WebViewController _controller;

  static String _extractDriveId(String rawUrl) {
    final match = RegExp(
            r'(?:drive\.google\.com\/(?:file\/d\/|open\?id=|uc\?id=))([a-zA-Z0-9_-]+)')
        .firstMatch(rawUrl);
    if (match != null) return match.group(1)!;
    return '';
  }

  static String _getPreviewUrl(String rawUrl) {
    if (rawUrl.contains('/preview')) return rawUrl;
    final id = _extractDriveId(rawUrl);
    if (id.isNotEmpty) {
      return 'https://drive.google.com/file/d/$id/preview';
    }
    return rawUrl;
  }

  static String _buildIframeHtml(String previewUrl) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background-color: #000; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
  <script>
    try {
      Object.defineProperty(navigator, 'platform', { get: function() { return 'Win32'; } });
      Object.defineProperty(navigator, 'maxTouchPoints', { get: function() { return 0; } });
    } catch(e) {}

    function fixIframe() {
      try {
        var frame = document.getElementById('driveFrame');
        if (!frame || !frame.contentDocument) return;
        var doc = frame.contentDocument;
        var win = frame.contentWindow;

        try {
          Object.defineProperty(win.navigator, 'platform', { get: function() { return 'Win32'; } });
          Object.defineProperty(win.navigator, 'maxTouchPoints', { get: function() { return 0; } });
        } catch(e) {}

        if (!doc.getElementById('customHideControls')) {
          var style = doc.createElement('style');
          style.id = 'customHideControls';
          style.textContent = 'video::-webkit-media-controls, video::-webkit-media-controls-panel, video::-webkit-media-controls-play-button, video::-webkit-media-controls-start-playback-button { display: none !important; -webkit-appearance: none !important; }';
          if (doc.head) doc.head.appendChild(style);
        }

        var videos = doc.querySelectorAll('video');
        videos.forEach(function(v) {
          if (v.hasAttribute('controls')) {
            v.removeAttribute('controls');
          }
        });
      } catch(e) {}
    }

    setInterval(fixIframe, 300);
  </script>
</head>
<body>
  <iframe id="driveFrame" src="$previewUrl" allow="autoplay; fullscreen" allowfullscreen></iframe>
</body>
</html>''';
  }

  final win_wv.WebviewController _winController = win_wv.WebviewController();
  bool _isWinInitialized = false;

  Future<void> _initWindowsPlayer() async {
    try {
      await _winController.initialize();
      await _winController.setPopupWindowPolicy(win_wv.WebviewPopupWindowPolicy.deny);
      await _winController.setBackgroundColor(Colors.black);

      final previewUrl = _getPreviewUrl(widget.videoUrl);
      final html = _buildIframeHtml(previewUrl);
      await _winController.loadStringContent(html);

      if (mounted) {
        setState(() => _isWinInitialized = true);
      }
    } catch (e) {
      log('Error initializing Drive Windows webview: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      _initWindowsPlayer();
      return;
    }
    if (WebViewPlatform.instance != null) {
      _initWebViewController();
    }
  }

  void _initWebViewController() {
    if (WebViewPlatform.instance == null) return;
    final previewUrl = _getPreviewUrl(widget.videoUrl);

    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      webViewParams = const PlatformWebViewControllerCreationParams();
    }

    final navigationDelegate = NavigationDelegate(
      onWebResourceError: (error) {
        log('[DRIVE WEBVIEW ERROR] ${error.description}',
            name: 'DriveWebViewError');
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) return NavigationDecision.prevent;

        if (uri.host.contains('drive.google.com') ||
            uri.host.contains('docs.google.com') ||
            uri.host.contains('googleusercontent.com') ||
            uri.host.contains('accounts.google.com') ||
            uri.host.contains('video.google.com') ||
            uri.scheme == 'about' ||
            uri.scheme == 'data') {
          return NavigationDecision.navigate;
        }

        return NavigationDecision.prevent;
      },
    );

    _controller = WebViewController.fromPlatformCreationParams(webViewParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(navigationDelegate)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      )
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(
        _buildIframeHtml(previewUrl),
        baseUrl: 'https://drive.google.com',
      );

    final webViewPlatform = _controller.platform;
    if (webViewPlatform is AndroidWebViewController) {
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
    }
  }

  Future<void> _openFullScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DriveFullscreenPage(
          videoUrl: widget.videoUrl,
          watermarkText: widget.watermarkText,
          bubbleMessage: widget.bubbleMessage,
          bubbleInterval: widget.bubbleInterval,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isWindows) {
      _winController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: _isWinInitialized
                    ? win_wv.Webview(_winController)
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
              if (!widget.isMini && widget.onFloatPressed != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: widget.onFloatPressed,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(7),
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
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    onTap: _openFullScreen,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            if (widget.watermarkText.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.watermarkText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.isMini && widget.onFloatPressed != null)
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: widget.onFloatPressed,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(7),
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
                bottom: 6,
                right: 6,
                child: InkWell(
                  onTap: _openFullScreen,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DriveFullscreenPage — Fullscreen Drive player
// ─────────────────────────────────────────────────────────────────────────────
class DriveFullscreenPage extends StatefulWidget {
  final String videoUrl;
  final String watermarkText;
  final String? bubbleMessage;
  final int? bubbleInterval;

  const DriveFullscreenPage({
    super.key,
    required this.videoUrl,
    this.watermarkText = '',
    this.bubbleMessage,
    this.bubbleInterval,
  });

  @override
  State<DriveFullscreenPage> createState() => _DriveFullscreenPageState();
}

class _DriveFullscreenPageState extends State<DriveFullscreenPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final previewUrl = _DriveVideoPlayerState._getPreviewUrl(widget.videoUrl);

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (e) =>
            log('[DRIVE FS ERROR] ${e.description}', name: 'DriveFullscreen'),
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.host.contains('drive.google.com') ||
              uri.host.contains('docs.google.com') ||
              uri.host.contains('googleusercontent.com') ||
              uri.host.contains('accounts.google.com') ||
              uri.host.contains('video.google.com') ||
              uri.scheme == 'about' ||
              uri.scheme == 'data') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(
        _DriveVideoPlayerState._buildIframeHtml(previewUrl),
        baseUrl: 'https://drive.google.com',
      );

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    } else if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(false);
    }

    _setupBubbleNotification();
  }

  // Bubble Notification Overlay for Drive Fullscreen
  Timer? _bubbleInitialTimer;
  Timer? _bubbleTimer;
  Timer? _bubbleHideTimer;
  bool _showBubble = false;
  String _currentBubbleMessage = "";

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

      _bubbleTimer = Timer.periodic(Duration(minutes: bubbleIntervalMins), (timer) {
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

  @override
  void dispose() {
    _bubbleInitialTimer?.cancel();
    _bubbleTimer?.cancel();
    _bubbleHideTimer?.cancel();
    super.dispose();
  }

  Widget _buildBubbleNotificationOverlay() {
    if (!_showBubble || _currentBubbleMessage.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      left: 60,
      right: 16,
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF38BDF8).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF38BDF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentBubbleMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (mounted) setState(() => _showBubble = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if (_showBubble) _buildBubbleNotificationOverlay(),
          ],
        ),
      ),
    );
  }
}
