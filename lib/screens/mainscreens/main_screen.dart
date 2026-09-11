import 'package:flutter/material.dart';
import 'package:flutter_version/screens/mainscreens/home_screen.dart';
import 'package:flutter_version/screens/mainscreens/messages_page.dart';
import 'package:flutter_version/screens/mainscreens/exams_page.dart';
import 'package:flutter_version/screens/mainscreens/courses_page.dart';
import 'package:flutter_version/screens/mainscreens/videos_page.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

const _kBarHeight = 85.0;
const _kHumpHeight = 45.0;
const _kHumpWidth = 90.0;
const _kButtonSize = 60.0;
const _kCornerRadius = 20.0;

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 4}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  late final List<Widget> _pages = [
    const VideosPage(),
    const ExamsPage(),
    MessagesPage(
      onBackToHome: () => setState(() => _selectedIndex = 4),
    ),
    const CoursesPage(),
    const HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          if (_selectedIndex != 2)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final rightItems = [
      _NavItem(icon: PhosphorIconsFill.exam, label: loc.exams, index: 1),
      _NavItem(
          icon: PhosphorIconsFill.videoCamera, label: loc.videos, index: 0),
    ];
    final leftItems = [
      _NavItem(icon: PhosphorIconsFill.houseSimple, label: loc.home, index: 4),
      _NavItem(icon: PhosphorIconsFill.bookOpen, label: loc.courses, index: 3),
    ];
    const centerIndex = 2;

    return SizedBox(
      height: _kBarHeight + _kHumpHeight + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _HumpBarPainter(isDark: isDark),
              child: SizedBox(
                height: _kBarHeight + _kHumpHeight,
                child: Column(
                  children: [
                    SizedBox(height: _kHumpHeight),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: leftItems
                                  .map((item) => _buildItem(item, context))
                                  .toList(),
                            ),
                          ),
                          SizedBox(width: _kHumpWidth),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: rightItems
                                  .map((item) => _buildItem(item, context))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: _kBarHeight - (_kButtonSize / 2) + 3,
            child: GestureDetector(
              onTap: () => onTap(centerIndex),
              child: Container(
                width: _kButtonSize,
                height: _kButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sky(isDark),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sky(isDark).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsFill.chatsCircle,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_NavItem item, BuildContext context) {
    final isSelected = selectedIndex == item.index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final color =
        isSelected ? AppColors.sky(isDark) : AppColors.getIconColor(isDark);

    return GestureDetector(
      onTap: () => onTap(item.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon,
                size: 30, color: color, textDirection: TextDirection.ltr),
            const SizedBox(height: 5),
            Text(
              item.label,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.sky(isDark)
                      : AppColors.getIconColor(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HumpBarPainter extends CustomPainter {
  final bool isDark;
  _HumpBarPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.getBackgroundColor(isDark)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = _buildPath(size);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  Path _buildPath(Size size) {
    final cx = size.width / 2;
    const r = _kCornerRadius;
    const hw = _kHumpWidth / 2;
    const hh = _kHumpHeight;
    const barTop = hh;

    final path = Path();

    path.moveTo(r, size.height);
    path.lineTo(size.width - r, size.height);

    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - r);

    path.lineTo(size.width, barTop + r);
    path.quadraticBezierTo(size.width, barTop, size.width - r, barTop);

    path.lineTo(cx + hw + 5, barTop);

    path.cubicTo(
      cx + hw,
      barTop,
      cx + hw * 0.9,
      0,
      cx,
      0,
    );

    path.cubicTo(
      cx - hw * 0.9,
      0,
      cx - hw,
      barTop,
      cx - hw - 5,
      barTop,
    );

    path.lineTo(r, barTop);
    path.quadraticBezierTo(0, barTop, 0, barTop + r);

    path.lineTo(0, size.height - r);
    path.quadraticBezierTo(0, size.height, r, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem(
      {required this.icon, required this.label, required this.index});
}
