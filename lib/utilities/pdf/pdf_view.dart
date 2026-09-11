import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/pdf/CustomPdfViewer.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewPage extends StatefulWidget {
  final String title;
  final String pdfPath;
  final String pdfId;

  const PdfViewPage({
    super.key,
    required this.title,
    required this.pdfPath,
    required this.pdfId,
  });

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  bool drawingMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(drawingMode ? Icons.edit_off : Icons.edit),
            onPressed: () {
              setState(() {
                drawingMode = !drawingMode;
              });
            },
          ),
        ],
      ),
      body: CustomPdfViewer(
        pdfPath: widget.pdfPath,
        pdfId: widget.pdfId,
        drawingMode: drawingMode,
      ),
    );
  }
}
