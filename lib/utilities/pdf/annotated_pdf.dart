import 'package:flutter_version/l10n/app_localizations.dart';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_version/utilities/pdf/canva_draw.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class AnnotatedPdfViewer extends StatefulWidget {
//   final String pdfPath;
//   final String pdfId;
//   final bool drawingEnabled;

//   const AnnotatedPdfViewer({
//     Key? key,
//     required this.pdfPath,
//     required this.pdfId,
//     this.drawingEnabled = true,
//   }) : super(key: key);

//   @override
//   State<AnnotatedPdfViewer> createState() => _AnnotatedPdfViewerState();
// }

// class _AnnotatedPdfViewerState extends State<AnnotatedPdfViewer> {
//   int _currentPage = 1;
//   final PdfViewerController _pdfController = PdfViewerController();
//   // Key to access DrawingCanvas state
//   final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           SfPdfViewer.file(
//             File(widget.pdfPath),
//             controller: _pdfController,
//             onPageChanged: (details) {
//               setState(() {
//                 _currentPage = details.newPageNumber;
//               });
//             },
//           ),
//           if (widget.drawingEnabled) ...[
//             Positioned.fill(
//               child: IgnorePointer(
//                 ignoring: false, // allow touch input
//                 child: DrawingCanvas(
//                   key: _canvasKey,
//                   pageIndex: _currentPage,
//                   pdfId: widget.pdfId,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 32,
//               right: 24,
//               child: FloatingActionButton(
//                 heroTag: 'clearCanvasBtn',
//                 mini: true,
//                 backgroundColor: Colors.white.withOpacity(0.85),
//                 child: Icon(Icons.clear, color: Colors.red),
//                 tooltip: AppLocalizations.of(context)?.clearDrawingForPage ?? "مسح الرسم لهذه الصفحة",
//                 onPressed: () {
//                   _canvasKey.currentState?.clearCanvasForPage(_currentPage);
//                 },
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
