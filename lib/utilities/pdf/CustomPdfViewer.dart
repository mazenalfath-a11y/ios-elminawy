import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_version/utilities/pdf/drawing_overlay.dart';

class CustomPdfViewer extends StatefulWidget {
  final String pdfPath;
  final String pdfId;
  final bool drawingMode;

  const CustomPdfViewer({
    Key? key,
    required this.pdfPath,
    required this.pdfId,
    required this.drawingMode,
  }) : super(key: key);

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = kIsWeb || widget.pdfPath.startsWith('http');
    return Stack(
      children: [
        GestureDetector(
          // Block pinch zoom
          onScaleStart: (_) {}, // prevent propagation
          onScaleUpdate: (_) {}, // prevent scaling
          child: isNetwork
              ? SfPdfViewer.network(
                  widget.pdfPath,
                  key: _viewerKey,
                  controller: _controller,
                  scrollDirection: PdfScrollDirection.horizontal,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  canShowScrollStatus: false,
                  canShowScrollHead: false,
                  enableTextSelection: false,
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                )
              : SfPdfViewer.file(
                  File(widget.pdfPath),
                  key: _viewerKey,
                  controller: _controller,
                  scrollDirection: PdfScrollDirection.horizontal,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  canShowScrollStatus: false,
                  canShowScrollHead: false,
                  enableTextSelection: false,
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),
        ),

        // Drawing overlay for current page only
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.drawingMode,
            child: DrawingOverlay(
              key: ValueKey('${widget.pdfId}_$_currentPage'),
              pdfId: widget.pdfId,
              pageIndex: _currentPage,
              drawingEnabled: widget.drawingMode,
            ),
          ),
        ),
      ],
    );
  }
}
