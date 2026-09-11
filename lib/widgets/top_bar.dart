import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildTopBar({
  required String title,
  required BuildContext context,
  VoidCallback? onBack,
}) {
  final theme = Theme.of(context);

  return Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    color: theme.appBarTheme.backgroundColor,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: GoogleFonts.cairo(
                color: theme.appBarTheme.foregroundColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.foregroundColor,
            ),
          ),
      ],
    ),
  );
}
