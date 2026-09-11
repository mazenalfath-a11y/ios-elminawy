import 'package:flutter_version/l10n/app_localizations.dart';
// // lib/screens/local_video_player_screen.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class LocalVideoPlayerScreen extends StatefulWidget {
//   final String filePath;

//   const LocalVideoPlayerScreen({Key? key, required this.filePath})
//       : super(key: key);

//   @override
//   State<LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
// }

// class _LocalVideoPlayerScreenState extends State<LocalVideoPlayerScreen> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.filePath))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text(AppLocalizations.of(context)?.videoPlayerTitle ?? "مشغل الفيديو")),
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }
