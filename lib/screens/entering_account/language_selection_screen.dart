import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/data/app_config.dart';
import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:flutter_version/screens/entering_account/login_screen.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/locale_provider.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/widgets/elevated_button.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.06),
                end: Offset.zero,
              ).animate(curvedAnim),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnim),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final currentLang = localeProvider.locale?.languageCode ??
        AppConfig.defaultLanguage;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HERO HEADER ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    isDark
                        ? AppColors.primaryColor.withValues(alpha: 0.15)
                        : AppColors.lightGrad,
                    isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Top Row: Dark mode toggle & Sparkle icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.getCardBackgroundColor(isDark),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.getBorderColor(isDark),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isDark
                                    ? PhosphorIconsFill.sun
                                    : PhosphorIconsFill.moon,
                                color: isDark
                                    ? Colors.amber
                                    : AppColors.primaryColor,
                                size: 20,
                              ),
                              onPressed: () => themeProvider.toggleTheme(),
                            ),
                          ),
                          Image.asset(
                            "assets/images/sparkles.png",
                            height: 36,
                            width: 36,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Animated Hero Character Gifs / Emojis
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                right: 60,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Transform.scale(
                                    scale: 0.85,
                                    child: Image.asset(
                                      'assets/images/emojis/Star.gif',
                                      height: 110,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 60,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Transform.scale(
                                    scale: 0.85,
                                    child: Image.asset(
                                      'assets/images/emojis/Astronaut.gif',
                                      height: 110,
                                    ),
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/emojis/Student.gif',
                                height: 160,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── CONTENT BODY ───────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      // Welcome Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sky(isDark).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.sky(isDark).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          AppConfig.teacherName,
                          style: GoogleFonts.cairo(
                            color: AppColors.sky(isDark),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        AppLocalizations.of(context)?.chooseAppLanguage ??
                            "اختر لغة التطبيق",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: AppColors.getTextColor(isDark),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          AppLocalizations.of(context)?.selectLanguageSubtitle ??
                              "اختر اللغة التي تفضل استخدامها لتصفح الكورسات والمحتوى",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: AppColors.getTextSecondaryColor(isDark),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── LANGUAGE CARDS ─────────────────────────────────────
                      _buildLanguageCard(
                        context: context,
                        isDark: isDark,
                        langCode: 'ar',
                        title: AppLocalizations.of(context)?.arabicLanguage ??
                            "العربية",
                        subtitle:
                            AppLocalizations.of(context)?.arabicSubtitle ??
                                "أهلاً بك! تصفح التطبيق كاملاً باللغة العربية",
                        flagEmoji: "🇪🇬",
                        isSelected: currentLang == 'ar',
                        onTap: () {
                          localeProvider.setLocale(const Locale('ar'));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageCard(
                        context: context,
                        isDark: isDark,
                        langCode: 'en',
                        title: AppLocalizations.of(context)?.englishLanguage ??
                            "English",
                        subtitle:
                            AppLocalizations.of(context)?.englishSubtitle ??
                                "Welcome! Browse the full app in English",
                        flagEmoji: "🇬🇧",
                        isSelected: currentLang == 'en',
                        onTap: () {
                          localeProvider.setLocale(const Locale('en'));
                        },
                      ),

                      const SizedBox(height: 36),

                      // ─── CONTINUE BUTTON ────────────────────────────────────
                      ElevatedButtonWidget(
                        onPressed: _navigateToLogin,
                        text: AppLocalizations.of(context)?.continueToApp ??
                            "المتابعة",
                        height: 56,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required bool isDark,
    required String langCode,
    required String title,
    required String subtitle,
    required String flagEmoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.sky(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08)
                  : AppColors.getCardBackgroundColor(isDark),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : AppColors.getBorderColor(isDark),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : AppColors.getShadowColor(isDark),
                  blurRadius: isSelected ? 20 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Flag / Badge Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      flagEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: AppColors.getTextColor(isDark),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          color: AppColors.getTextSecondaryColor(isDark),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Selection Radio / Checkmark Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? activeColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : AppColors.getBorderColor(isDark),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          PhosphorIconsBold.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
