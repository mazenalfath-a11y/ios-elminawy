import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Stroke {
  final List<Offset?> points;
  final Color color;
  final bool isEraser;
  Stroke(this.points, this.color, {this.isEraser = false});
}

class DrawingOverlay extends StatefulWidget {
  final String pdfId;
  final int pageIndex;
  final bool drawingEnabled;

  const DrawingOverlay({
    Key? key,
    required this.pdfId,
    required this.pageIndex,
    required this.drawingEnabled,
  }) : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  List<Stroke> strokes = [];
  List<Offset?> currentPoints = [];
  List<Stroke> undoneStrokes = [];
  Color selectedColor = Colors.red;
  bool isEraser = false;
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

    if (_backgroundImage != null) {
      canvas.drawImage(_backgroundImage!, Offset.zero, Paint());
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.transparent : stroke.color
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver
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

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoneStrokes.add(strokes.removeLast());
      });
      _saveDrawing();
    }
  }

  void _redo() {
    if (undoneStrokes.isNotEmpty) {
      setState(() {
        strokes.add(undoneStrokes.removeLast());
      });
      _saveDrawing();
    }
  }

  void _clearCanvas() async {
    setState(() {
      strokes.clear();
      _backgroundImage = null;
    });
    if (kIsWeb) return;
    final file = File(await _drawingPath);
    if (await file.exists()) await file.delete();
  }

  void _toggleEraser() {
    setState(() => isEraser = !isEraser);
  }

  void _pickColor(Color color) {
    setState(() {
      selectedColor = color;
      isEraser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onPanUpdate: widget.drawingEnabled
              ? (details) {
                  setState(() {
                    currentPoints.add(details.localPosition);
                  });
                }
              : null,
          onPanEnd: widget.drawingEnabled
              ? (_) {
                  setState(() {
                    currentPoints.add(null);
                    strokes.add(
                      Stroke(
                        List.from(currentPoints),
                        selectedColor,
                        isEraser: isEraser,
                      ),
                    );
                    currentPoints.clear();
                    undoneStrokes.clear(); // clear redo stack
                  });
                  _saveDrawing();
                }
              : null,
          child: CustomPaint(
            painter: _DrawingPainter(
              strokes: strokes,
              currentPoints: currentPoints,
              backgroundImage: _backgroundImage,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        if (widget.drawingEnabled)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.undo, color: Colors.white),
                  onPressed: _undo,
                ),
                IconButton(
                  icon: Icon(Icons.redo, color: Colors.white),
                  onPressed: _redo,
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: _clearCanvas,
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isEraser ? Colors.grey : Colors.white,
                  ),
                  onPressed: _toggleEraser,
                ),
                ...[
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.black,
                ].map(
                  (c) => GestureDetector(
                    onTap: () => _pickColor(c),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color:
                              selectedColor == c ? Colors.white : Colors.grey,
                          width: 2,
                        ),
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
        ..color = stroke.isEraser ? Colors.transparent : stroke.color
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    final paint = Paint()
      ..color = currentPoints.isNotEmpty && strokes.isNotEmpty
          ? strokes.last.color
          : Colors.red
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < currentPoints.length - 1; i++) {
      if (currentPoints[i] != null && currentPoints[i + 1] != null) {
        canvas.drawLine(currentPoints[i]!, currentPoints[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
