import 'package:flutter/material.dart';
import 'package:flutter_version/screens/appearing_screens/video_insides/real_player.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:provider/provider.dart';

class ReelsPlayerPage extends StatefulWidget {
  final List<String> reels;
  final int initialIndex;

  const ReelsPlayerPage({
    Key? key,
    required this.reels,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ReelsPlayerPage> createState() => _ReelsPlayerPageState();
}

class _ReelsPlayerPageState extends State<ReelsPlayerPage> {
  late PageController _pageController;
  late int initialPage;
  static const int _fakeItemCount = 1000000000;

  @override
  void initState() {
    super.initState();
    initialPage = _fakeItemCount ~/ 2 -
        ((_fakeItemCount ~/ 2) % widget.reels.length) +
        widget.initialIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          final videoUrl = widget.reels[index % widget.reels.length];
          return YoutubeFullscreenPage(
            videoUrl: videoUrl,
            watermarkText: '',
          );
        },
      ),
    );
  }
}
