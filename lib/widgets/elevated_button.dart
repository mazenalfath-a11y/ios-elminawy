import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ElevatedButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final double height;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final Widget? icon;

  const ElevatedButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.height = 44,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.buttonGradient,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.sky(isDark).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.cairo(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      width: 4.5,
                    ),
                    if (icon != null) ...[icon!],
                  ],
                ),
        ),
      ),
    );
  }
}
