import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OverdueBadge extends StatelessWidget {
  final int daysOverdue;

  const OverdueBadge({super.key, required this.daysOverdue});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final danger = isDark ? AppColors.dangerDark : colors.danger;

    final label = daysOverdue == 0
        ? 'DUE TODAY'
        : daysOverdue == 1
            ? '1D OVERDUE'
            : '${daysOverdue}D OVERDUE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            danger.withOpacity(isDark ? 0.22 : 0.14),
            danger.withOpacity(isDark ? 0.14 : 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: danger.withOpacity(isDark ? 0.4 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 10,
            color: danger,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: danger,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}