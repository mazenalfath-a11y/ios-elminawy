import 'package:flutter_version/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/mainscreens/main_screen.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final response =
          await _apiService.request("student/getuser", null, "GET");
      if (response != null && response.statusCode == 200) {
        _pollingTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.sky(isDark)),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)?.registeredSuccessfully ?? "تم التسجيل بنجاح",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.accountUnderReview ?? "حسابك قيد المراجعة حالياً، سيتم تفعيله قريباً بواسطة المعلم.",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.redirectOnActivation ?? "سيتم توجيهك تلقائياً عند التفعيل...",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.getTextSecondaryColor(isDark),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
