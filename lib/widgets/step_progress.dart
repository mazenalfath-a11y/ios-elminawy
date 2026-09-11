import 'package:flutter/material.dart';
import 'package:flutter_version/main.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

Widget buildStepProgress({bool isSecondStep = false}) {
  final context = navigatorKey.currentContext!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isSecondStep ? AppColors.greenSuccess : AppColors.sky(isDark),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSecondStep
                    ? null
                    : Border.all(color: AppColors.white, width: 1),
              ),
              child: const Center(
                child: Text("1",
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Container(
            width: 230,
            height: 6,
            decoration: BoxDecoration(
              color: isSecondStep
                  ? AppColors.sky(isDark)
                  : AppColors.getInputBorderColor(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: isSecondStep
                ? AppColors.sky(isDark)
                : AppColors.getBackgroundColor(isDark),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1),
              ),
              child: Center(
                child: Text("2",
                    style: TextStyle(
                        color: isSecondStep ? AppColors.white : AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(AppLocalizations.of(context)!.loginData,
              style: GoogleFonts.cairo(
                  color: !isSecondStep
                      ? AppColors.sky(isDark)
                      : AppColors.greenSuccess,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 220),
          Text(AppLocalizations.of(context)!.studentData,
              style: GoogleFonts.cairo(
                  color: isSecondStep ? AppColors.sky(isDark) : AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ],
  );
}
