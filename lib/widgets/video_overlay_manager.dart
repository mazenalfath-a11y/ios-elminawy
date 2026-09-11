import 'package:flutter/material.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/youtube_video_player.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/drive_video_player.dart';
import 'package:flutter_version/screens/appearing_screens/video_watch_page.dart';

class VideoOverlayManager {
  static final VideoOverlayManager _instance = VideoOverlayManager._internal();
  factory VideoOverlayManager() => _instance;
  VideoOverlayManager._internal();

  OverlayEntry? _overlayEntry;
  Offset _position = const Offset(20, 100);

  void show(BuildContext context, {
    required String videoUrl,
    required String videoTitle,
    required String watermarkText,
    required double startAt,
    required String vId,
    required String exerciseId,
    required String courseId,
    required List<dynamic> files,
    required List<dynamic> additionalVideos,
    required List<String> exerciseArr,
    String? bubbleMessage,
    int? bubbleInterval,
  }) {
    if (_overlayEntry != null) return; // Already showing

    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: _position.dx,
        top: _position.dy,
        child: Draggable(
          feedback: Container(), // No visual feedback while dragging using this widget directly
          onDragEnd: (details) {
            _position = details.offset;
            _overlayEntry?.markNeedsBuild();
          },
          childWhenDragging: Container(), // Hide original while dragging? No, we update position manually
          // Using a Listener or GestureDetector for custom drag logic might be smoother for Overlay
          // But let's stick to a simple GestureDetector updating the OverlayEntry
          child: Material(
            elevation: 8,
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onPanUpdate: (details) {
                _position += details.delta;
                _overlayEntry?.markNeedsBuild();
              },
              onTap: () {
                // Return to full screen
                dismiss();
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => VideoWatchPage(
                      videoTitle: videoTitle,
                      videoUrl: videoUrl,
                      v_id: vId,
                      watermarkText: watermarkText,
                      exerciseId: exerciseId,
                      courseId: courseId,
                      files: files,
                      additionalVideos: additionalVideos,
                      exerciseArr: exerciseArr,
                      bubbleMessage: bubbleMessage,
                      bubbleInterval: bubbleInterval,
                    ),
                  ),
                );
              },
              child: Container(
                width: 250,
                height: 145, // 16:9 + border margin
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Video Player
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: videoUrl.toLowerCase().contains('drive.google.com') ||
                              videoUrl.toLowerCase().contains('docs.google.com')
                          ? DriveVideoPlayer(
                              videoUrl: videoUrl,
                              watermarkText: watermarkText,
                              isMini: true,
                            )
                          : YoutubeVideoPlayer(
                              videoUrl: videoUrl,
                              watermarkText: watermarkText,
                              startAt: startAt,
                              isMini: true, // New flag to hide controls/simplify UI
                            ),
                    ),
                    // Close Button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          dismiss();
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => VideoWatchPage(
                                videoTitle: videoTitle,
                                videoUrl: videoUrl,
                                v_id: vId,
                                watermarkText: watermarkText,
                                exerciseId: exerciseId,
                                courseId: courseId,
                                files: files,
                                additionalVideos: additionalVideos,
                                exerciseArr: exerciseArr,
                                bubbleMessage: bubbleMessage,
                                bubbleInterval: bubbleInterval,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
