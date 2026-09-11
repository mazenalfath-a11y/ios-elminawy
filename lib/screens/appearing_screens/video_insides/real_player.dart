import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;

class YoutubeFullscreenPage extends StatefulWidget {
  final String videoUrl;
  final String watermarkText;

  const YoutubeFullscreenPage({
    super.key,
    required this.videoUrl,
    this.watermarkText = "",
  });

  @override
  State<YoutubeFullscreenPage> createState() => _YoutubeFullscreenPageState();
}

class _YoutubeFullscreenPageState extends State<YoutubeFullscreenPage> {
  late final WebViewController _controller;

  final win_wv.WebviewController _winController = win_wv.WebviewController();
  bool _isWinInitialized = false;

  Future<void> _initWindowsPlayer() async {
    try {
      await _winController.initialize();
      await _winController.setPopupWindowPolicy(win_wv.WebviewPopupWindowPolicy.deny);
      await _winController.setBackgroundColor(Colors.black);

      final videoId = _extractVideoId(widget.videoUrl);
      final targetUrl =
          'https://coursesapp.github.io/youtube_embedded_video/?video=$videoId&watermark=${Uri.encodeComponent(widget.watermarkText)}';
      await _winController.loadUrl(targetUrl);

      if (mounted) {
        setState(() => _isWinInitialized = true);
      }
    } catch (e) {
      log('Error initializing Windows webview in reels real_player: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && Platform.isWindows) {
      _initWindowsPlayer();
      return;
    }

    if (WebViewPlatform.instance == null) return;

    final videoId = _extractVideoId(widget.videoUrl);

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
        log('[WEBVIEW ERROR] ${error.description}', name: 'WebViewError');
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);

        if (uri == null) {
          return NavigationDecision.prevent;
        }

        if (uri.host.contains('coursesapp.github.io') ||
            uri.host.contains('youtube.com') ||
            uri.host.contains('youtube-nocookie.com')) {
          return NavigationDecision.navigate;
        }

        if (uri.path == '/watch' && uri.queryParameters.containsKey('v')) {
          return NavigationDecision.navigate;
        }

        return NavigationDecision.prevent;
      },
    );

    _controller = WebViewController.fromPlatformCreationParams(webViewParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(navigationDelegate)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
      )
      ..enableZoom(false)
      ..loadRequest(
        Uri.parse(
          'https://coursesapp.github.io/youtube_embedded_video/?video=$videoId&watermark=${widget.watermarkText}',
        ),
      );

    final webViewPlatform = _controller.platform;
    if (webViewPlatform is AndroidWebViewController) {
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isWindows) {
      _winController.dispose();
    }
    super.dispose();
  }

  String _extractVideoId(String url) {
    final regex = RegExp(r"(?:v=|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})");
    final match = regex.firstMatch(url);
    return match?.group(1) ?? "";
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isWindows) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: _isWinInitialized
                      ? win_wv.Webview(_winController)
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: WebViewWidget(controller: _controller),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
