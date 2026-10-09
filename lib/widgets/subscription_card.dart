import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/brand_colors.dart';
import '../utils/currency_utils.dart';
import '../screens/subscription_details_screen.dart';
import 'overdue_badge.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final String documentId;
  final double convertedPrice;
  final String displayCurrency;
  final VoidCallback onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.documentId,
    required this.convertedPrice,
    required this.displayCurrency,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _billingLabel() {
    switch (subscription.billingCycle) {
      case 'Weekly':
        return 'wk';
      case 'Monthly':
        return 'mo';
      case 'Yearly':
        return 'yr';
      default:
        return subscription.billingCycle.toLowerCase();
    }
  }

  Color _accent() {
    if (subscription.cardColor != null) {
      try {
        final hex = subscription.cardColor!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return BrandColors.of(subscription.name);
      }
    }
    return BrandColors.of(subscription.name);
  }

  Widget _avatar(Color accent, bool isDark) {
    final letter = subscription.name.isEmpty
        ? '?'
        : subscription.name[0].toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23233D) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.2)),
      ),
      alignment: Alignment.center,
      child: subscription.logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: subscription.logoUrl,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                placeholder: (_, __) => Text(
                  letter,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                errorWidget: (_, __, ___) => Text(
                  letter,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            )
          : Text(
              letter,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
    );
  }

  Widget? _statusPill(bool isDark) {
    if (subscription.isActive) return null;

    final isCancelled = subscription.isCancelled;
    final color = isCancelled
        ? (isDark ? AppColors.warningDark : AppColors.warning)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary);
    final label = isCancelled ? 'CANCELLED' : 'ARCHIVED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawAccent = _accent();
    // In dark mode lift the accent a bit so text reads clearly.
    final accent = isDark
        ? Color.lerp(rawAccent, Colors.white, 0.15) ?? rawAccent
        : rawAccent;

    final isInactive = !subscription.isActive;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final renewalMidnight = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );
    final overdueDays = todayMidnight.difference(renewalMidnight).inDays;
    final isOverdue = subscription.isActive && overdueDays > 0;

    final converted = CurrencyUtils.format(convertedPrice, displayCurrency);
    final original = CurrencyUtils.format(
      subscription.price,
      subscription.currency,
    );
    final showOriginal = subscription.currency != displayCurrency;

    final effectiveAccent = isOverdue
        ? (isDark ? AppColors.dangerDark : AppColors.danger)
        : accent;

    // Dark mode uses lower tint opacity; light mode uses the brand tint.
    final tintOpacity = isDark ? 0.14 : 0.08;
    final borderOpacity = isDark ? 0.32 : 0.22;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isInactive ? 0.55 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionDetailsScreen(
                    subscription: subscription,
                    documentId: documentId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: effectiveAccent.withOpacity(tintOpacity),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: effectiveAccent.withOpacity(borderOpacity),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _avatar(effectiveAccent, isDark),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subscription.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: colors.textPrimary,
                                  decoration: isInactive
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: OverdueBadge(
                                  daysOverdue: overdueDays,
                                ),
                              ),
                            ] else if (_statusPill(isDark) != null) ...[
                              const SizedBox(width: 6),
                              _statusPill(isDark)!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subscription.planName.isNotEmpty
                              ? subscription.planName
                              : subscription.category,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 12,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatDate(subscription.renewalDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                subscription.billingCycle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 82,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            converted,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/${_billingLabel()}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showOriginal) ...[
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 82,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              original,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(
                    width: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(
                        Icons.more_vert,
                        color: colors.textTertiary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      onSelected: (v) {
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: isDark
                                    ? AppColors.dangerDark
                                    : AppColors.danger,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.dangerDark
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}