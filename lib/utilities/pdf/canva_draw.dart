import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Stroke {
  final List<Offset?> points;
  final Color color;
  Stroke(this.points, this.color);
}

class DrawingCanvas extends StatefulWidget {
  final String pdfId;
  final int pageIndex;

  const DrawingCanvas({
    super.key,
    required this.pdfId,
    required this.pageIndex,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> strokes = [];
  List<Offset?> currentPoints = [];
  Color selectedColor = Colors.red;
  ui.Image? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadDrawing();
  }

  Future<String> get _drawingPath async {
    if (kIsWeb) return '';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${widget.pdfId}_page${widget.pageIndex}.png';
  }

  Future<void> _loadDrawing() async {
    if (kIsWeb) return;
    final path = await _drawingPath;
    if (await File(path).exists()) {
      final bytes = await File(path).readAsBytes();
      final image = await decodeImageFromList(bytes);
      setState(() {
        _backgroundImage = image;
      });
    }
  }

  Future<void> _saveDrawing() async {
    if (kIsWeb) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = context.size ?? const Size(400, 600);

    // Draw previous background
    if (_backgroundImage != null) {
      canvas.drawImage(_backgroundImage!, Offset.zero, Paint());
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final path = await _drawingPath;
    await File(path).writeAsBytes(bytes);
  }

  void clearCanvas() async {
    setState(() {
      strokes.clear();
      _backgroundImage = null;
    });
    if (kIsWeb) return;
    final file = File(await _drawingPath);
    if (await file.exists()) await file.delete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          currentPoints.add(details.localPosition);
        });
      },
      onPanEnd: (_) {
        setState(() {
          currentPoints.add(null);
          strokes.add(Stroke(List.from(currentPoints), selectedColor));
          currentPoints.clear();
        });
        _saveDrawing();
      },
      child: CustomPaint(
        painter: _DrawingPainter(
          strokes: strokes,
          currentPoints: currentPoints,
          backgroundImage: _backgroundImage,
        ),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentPoints;
  final ui.Image? backgroundImage;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = strokes.isNotEmpty ? strokes.last.color : Colors.red
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < currentPoints.length - 1; i++) {
        if (currentPoints[i] != null && currentPoints[i + 1] != null) {
          canvas.drawLine(currentPoints[i]!, currentPoints[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
