import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../screens/subscription_details_screen.dart';

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

  Color _autoColor() {
    const colors = [
      Color(0xFF6C4CE0),
      Color(0xFFEC4899),
      Color(0xFF0EA5E9),
      Color(0xFF16A34A),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];

    int hash = 0;
    for (final c in subscription.name.codeUnits) {
      hash = c + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Color _accentColor() {
    if (subscription.cardColor != null) {
      try {
        final hex = subscription.cardColor!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return _autoColor();
      }
    }
    return _autoColor();
  }

  Widget _avatar(Color accent) {
    final letter = subscription.name.isEmpty
        ? '?'
        : subscription.name[0].toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: subscription.logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(
                subscription.logoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            )
          : Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
    );
  }

  Widget? _statusPill() {
    if (subscription.isActive) return null;

    final isCancelled = subscription.isCancelled;
    final color = isCancelled ? AppColors.warning : AppColors.textTertiary;
    final label = isCancelled ? 'Cancelled' : 'Archived';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final isInactive = !subscription.isActive;

    final converted = CurrencyUtils.format(convertedPrice, displayCurrency);
    final original = CurrencyUtils.format(
      subscription.price,
      subscription.currency,
    );
    final showOriginal = subscription.currency != displayCurrency;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isInactive ? 0.55 : 1.0,
        child: Material(
          color: AppColors.surface,
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
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _avatar(accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subscription.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                  decoration: isInactive
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_statusPill() != null) ...[
                              const SizedBox(width: 6),
                              _statusPill()!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subscription.planName.isNotEmpty
                              ? subscription.planName
                              : subscription.category,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(subscription.renewalDate),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              subscription.billingCycle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          converted,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/${_billingLabel()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showOriginal) ...[
                        const SizedBox(height: 2),
                        Text(
                          original,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textTertiary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
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