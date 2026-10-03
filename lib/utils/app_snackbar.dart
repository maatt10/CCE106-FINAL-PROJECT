import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SnackKind { success, error, info, warning }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackKind kind = SnackKind.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final (Color color, IconData icon) = switch (kind) {
    SnackKind.success => (AppColors.success, Icons.check_circle_rounded),
    SnackKind.error => (AppColors.danger, Icons.error_rounded),
    SnackKind.warning => (AppColors.warning, Icons.warning_rounded),
    SnackKind.info => (AppColors.primary, Icons.info_rounded),
  };

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}