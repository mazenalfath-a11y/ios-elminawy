import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class LevelCard extends StatelessWidget {
  final int score;

  const LevelCard({Key? key, required this.score}) : super(key: key);

  Map<String, String> _getLevelInfo(int score, BuildContext context) {
    if (score >= 501) {
      return {
        "image": "assets/images/6Diamond.png",
        "label": AppLocalizations.of(context)!.level6
      };
    } else if (score >= 251) {
      return {
        "image": "assets/images/5Gold.png",
        "label": AppLocalizations.of(context)!.level5
      };
    } else if (score >= 151) {
      return {
        "image": "assets/images/4Platinum.png",
        "label": AppLocalizations.of(context)!.level4
      };
    } else if (score >= 101) {
      return {
        "image": "assets/images/3Bronze.png",
        "label": AppLocalizations.of(context)!.level3
      };
    } else if (score >= 51) {
      return {
        "image": "assets/images/2Iron.png",
        "label": AppLocalizations.of(context)!.level2
      };
    } else {
      return {
        "image": "assets/images/1Wood.png",
        "label": AppLocalizations.of(context)!.level1
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelInfo = _getLevelInfo(score, context);

    return Container(
      width: 160,
      height: 120,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? AppColors.black26
                : AppColors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              levelInfo["image"]!,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              levelInfo["label"]!,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.pointsLabel(score),
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
