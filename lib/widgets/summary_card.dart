import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SummaryCardVariant { plain, gradient }

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final SummaryCardVariant variant;
  final List<Color>? gradientColors;
  final String? subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.variant = SummaryCardVariant.plain,
    this.gradientColors,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGradient = variant == SummaryCardVariant.gradient;

    // Swap to dark gradients when in dark mode.
    final resolvedGradient = isGradient
        ? (gradientColors == AppColors.heroGradient
            ? (isDark ? AppColors.heroGradientDark : AppColors.heroGradient)
            : gradientColors == AppColors.infoGradient
                ? (isDark
                    ? AppColors.infoGradientDark
                    : AppColors.infoGradient)
                : (gradientColors ?? AppColors.heroGradient))
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isGradient ? null : colors.surface,
        gradient: isGradient
            ? LinearGradient(
                colors: resolvedGradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: resolvedGradient!.first.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: isGradient
                    ? Colors.white.withOpacity(0.85)
                    : colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: isGradient
                        ? Colors.white.withOpacity(0.85)
                        : colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
                height: 1.05,
                color: isGradient ? Colors.white : colors.textPrimary,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isGradient
                    ? Colors.white.withOpacity(0.8)
                    : colors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}