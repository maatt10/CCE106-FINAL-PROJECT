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
    final isGradient = variant == SummaryCardVariant.gradient;
    final colors = gradientColors ?? AppColors.heroGradient;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isGradient ? null : AppColors.surface,
        gradient: isGradient
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isGradient ? null : Border.all(color: AppColors.border),
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGradient
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isGradient ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isGradient
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isGradient ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isGradient
                    ? Colors.white.withOpacity(0.85)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}