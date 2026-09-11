import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

class OutlineTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final BuildContext context;
  final bool isNumber;
  final bool isPassword;

  const OutlineTextField({
    required this.hint,
    required this.controller,
    required this.icon,
    required this.context,
    this.isNumber = false,
    this.isPassword = false,
  });

  @override
  State<OutlineTextField> createState() => _OutlineTextFieldState();
}

class _OutlineTextFieldState extends State<OutlineTextField> {
  late bool _obscurePassword;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(widget.context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscurePassword,
        keyboardType:
            widget.isNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: widget.isNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ]
            : null,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          color: AppColors.getInputTextColor(isDark),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.cairo(
              color: AppColors.getIconColor(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w700),
          prefixIcon: Icon(widget.icon,
              textDirection: TextDirection.ltr,
              color: AppColors.getIconColor(isDark),
              size: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? PhosphorIconsFill.eyeSlash
                        : PhosphorIconsFill.eye,
                    color: AppColors.getIconColor(isDark),
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.getInputBackgroundColor(isDark),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.getInputBorderColor(isDark),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.sky(isDark),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy function wrapper for backward compatibility
Widget outlineTextField({
  required String hint,
  required TextEditingController controller,
  required IconData icon,
  required BuildContext context,
  bool obscure = false,
  bool isNumber = false,
  bool isPassword = false,
  VoidCallback? onTogglePassword,
}) {
  return OutlineTextField(
    hint: hint,
    controller: controller,
    icon: icon,
    context: context,
    isNumber: isNumber,
    isPassword: isPassword,
  );
}
