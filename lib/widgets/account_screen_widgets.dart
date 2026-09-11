import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// ✅ كارت الرتبة والنقاط
Widget buildRankCard(
    {required String rank, int score = 0, required BuildContext context}) {
  final theme = Theme.of(context);

  return Container(
    width: 160,
    height: 120,
    decoration: BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 5),
              Text(
                rank,
                style: GoogleFonts.tajawal(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pointsTitle(score),
            style: GoogleFonts.tajawal(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

/// ✅ كارت المجموعة
Widget buildGroupCard(
    {required String group, String time = "", required BuildContext context}) {
  return Container(
    width: 160,
    height: 120,
    decoration: BoxDecoration(
      color: AppColors.primaryBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "assets/images/group_-removebg-preview 1.png",
          width: 36,
          height: 36,
        ),
        const SizedBox(height: 8),
        Text(
          group.isNotEmpty ? group : AppLocalizations.of(context)!.undefined,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.tajawal(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]
      ],
    ),
  );
}

/// ✅ زر التواصل مع تأثير Blur
Widget buildContactButton({
  required BuildContext context,
  required String bgImage,
  required String title,
  required Widget icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      height: 60,
      child: Stack(
        children: [
          // ✅ الخلفية
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              bgImage,
              width: double.infinity,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          // ✅ تأثير البلور
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // ✅ النص والأيقونة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                icon,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// ✅ بيانات المستخدم
Widget buildProfileCard({
  required String name,
  required String username,
  required String phoneNumber,
  required BuildContext context,
}) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.dark
              ? Colors.black26
              : Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.accountInfo,
          style: GoogleFonts.tajawal(
            color: theme.colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildInfoRow(AppLocalizations.of(context)!.nameLabel, name, theme),
        _buildInfoRow(
            AppLocalizations.of(context)!.usernameLabel, username, theme),
        _buildInfoRow(
            AppLocalizations.of(context)!.phoneLabel, phoneNumber, theme),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.tajawal(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.tajawal(
              color: theme.textTheme.titleMedium?.color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}
