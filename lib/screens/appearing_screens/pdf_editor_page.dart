import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_windows/webview_windows.dart' as win_wv;

class PdfEditorPage extends StatefulWidget {
  final String title;
  final String pdfPath;
  final String pdfId;

  const PdfEditorPage({
    super.key,
    required this.title,
    required this.pdfPath,
    required this.pdfId,
  });

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  late final WebViewController _controller;
  final win_wv.WebviewController _winController = win_wv.WebviewController();
  bool _isLoading = true;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      _initWindowsEditor();
    } else {
      _initWebView();
    }
  }

  Future<File?> _getWindowsAssetFile() async {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final possiblePaths = [
        '$exeDir/data/flutter_assets/assets/pdf_editor/index.html',
        '${Directory.current.path}/data/flutter_assets/assets/pdf_editor/index.html',
        '${Directory.current.path}/build/windows/x64/runner/Debug/data/flutter_assets/assets/pdf_editor/index.html',
        '${Directory.current.path}/build/windows/x64/runner/Release/data/flutter_assets/assets/pdf_editor/index.html',
      ];
      for (var path in possiblePaths) {
        final f = File(path);
        if (await f.exists()) return f;
      }
    } catch (e) {
      debugPrint("Error finding Windows asset file: $e");
    }
    return null;
  }

  Future<void> _initWindowsEditor() async {
    try {
      await _winController.initialize();
      await _winController
          .setPopupWindowPolicy(win_wv.WebviewPopupWindowPolicy.deny);
      await _winController.setBackgroundColor(Colors.white);

      final assetFile = await _getWindowsAssetFile();
      if (assetFile != null) {
        final fileUri = Uri.file(assetFile.path).toString();
        await _winController.loadUrl(fileUri);
      } else {
        final html =
            await rootBundle.loadString('assets/pdf_editor/index.html');
        await _winController.loadStringContent(html);
      }

      await Future.delayed(const Duration(milliseconds: 800));
      await _sendPdfToWindowsJs();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error initializing Windows PDF editor: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPdfToWindowsJs() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final identifier = widget.pdfId.isNotEmpty
            ? widget.pdfId
            : (widget.title.isNotEmpty ? widget.title : "document");
        final safeName = "$identifier.pdf".replaceAll("'", "\\'");
        await _winController.executeScript(
            "if (typeof window.loadPDFFromFlutter === 'function') { window.loadPDFFromFlutter('$base64', '$safeName'); }");
      }
    } catch (e) {
      debugPrint("Error sending PDF to Windows JS: $e");
    }
  }

  void _initWebView() {
    if (WebViewPlatform.instance == null) return;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _loadPdfIntoEditor();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Resource Error: ${error.description}');
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _controller.loadFlutterAsset('assets/pdf_editor/index.html');
  }

  Future<void> _loadPdfIntoEditor() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final identifier = widget.pdfId.isNotEmpty
            ? widget.pdfId
            : (widget.title.isNotEmpty ? widget.title : "document");
        final fileName = "$identifier.pdf";
        await Future.delayed(const Duration(milliseconds: 500));
        final safeName = fileName.replaceAll("'", "\\'");
        await _controller.runJavaScript(
            "window.loadPDFFromFlutter('$base64', '$safeName');");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find PDF file')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
    }
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
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 45,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 22),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Listener(
              onPointerPanZoomStart: (event) {
                _lastScale = 1.0;
              },
              onPointerPanZoomUpdate: (event) {
                if (_winController.value.isInitialized) {
                  // Scrolling
                  if (event.panDelta.dx != 0 || event.panDelta.dy != 0) {
                    final dx = -event.panDelta.dx * 1.5;
                    final dy = -event.panDelta.dy * 1.5;
                    _winController.executeScript(
                        "if(document.getElementById('pdfContainer')) document.getElementById('pdfContainer').scrollBy({ left: $dx, top: $dy, behavior: 'instant' });");
                  }
                  
                  // Pinch to Zoom
                  if (event.scale != 1.0) {
                    final scaleDelta = event.scale - _lastScale;
                    if (scaleDelta.abs() > 0.08) { // Threshold for zooming step
                      if (scaleDelta > 0) {
                        _winController.executeScript("var btn = document.getElementById('zoomInBtn'); if(btn) btn.click();");
                      } else {
                        _winController.executeScript("var btn = document.getElementById('zoomOutBtn'); if(btn) btn.click();");
                      }
                      _lastScale = event.scale;
                    }
                  }
                }
              },
              child: win_wv.Webview(_winController),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 45,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 22),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
