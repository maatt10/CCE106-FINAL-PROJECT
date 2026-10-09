import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/brand_colors.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';
import 'add_subscription_screen.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  final Subscription subscription;
  final String documentId;

  const SubscriptionDetailsScreen({
    super.key,
    required this.subscription,
    required this.documentId,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _billingLabel() {
    switch (subscription.billingCycle) {
      case 'Weekly':
        return 'week';
      case 'Monthly':
        return 'month';
      case 'Yearly':
        return 'year';
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

  Color _statusColor(bool isDark) {
    switch (subscription.status) {
      case 'cancelled':
        return isDark ? AppColors.warningDark : AppColors.warning;
      case 'archived':
        return isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
      default:
        return isDark ? AppColors.successDark : AppColors.success;
    }
  }

  String _statusLabel() {
    switch (subscription.status) {
      case 'cancelled':
        return 'CANCELLED';
      case 'archived':
        return 'ARCHIVED';
      default:
        return 'ACTIVE';
    }
  }

  int _overdueDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewal = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );
    return today.difference(renewal).inDays;
  }

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddSubscriptionScreen(initialSubscription: subscription),
      ),
    );

    if (updated == null) return;

    try {
      await FirestoreService().updateSubscription(documentId, updated);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update subscription.')),
        );
      }
    }
  }

  Future<void> _changeStatus(
    BuildContext context, {
    required String newStatus,
    required String title,
    required String message,
    required String success,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirestoreService().updateStatus(documentId, newStatus);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subscription?'),
        content: Text(
          'Are you sure you want to delete ${subscription.name}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirestoreService().deleteSubscription(documentId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription deleted')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete subscription.')),
        );
      }
    }
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool emphasized = false,
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppType.microLabel.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: emphasized ? 18 : 14,
                    fontWeight:
                        emphasized ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: emphasized ? -0.4 : -0.1,
                    color: valueColor ?? colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBanner(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _overdueDays();
    if (days <= 0 || !subscription.isActive) return const SizedBox.shrink();

    final danger = isDark ? AppColors.dangerDark : AppColors.danger;
    final label = days == 1
        ? 'Renewed 1 day ago'
        : 'Renewed $days days ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: danger.withOpacity(isDark ? 0.35 : 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: danger.withOpacity(isDark ? 0.22 : 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: danger,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Update the renewal date if this was already paid.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;

    if (subscription.isActive) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _changeStatus(
                context,
                newStatus: 'cancelled',
                title: 'Cancel Subscription?',
                message:
                    'Mark ${subscription.name} as cancelled? You can restore it later.',
                success: 'Subscription cancelled.',
              ),
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _changeStatus(
                context,
                newStatus: 'archived',
                title: 'Archive Subscription?',
                message: 'Hide ${subscription.name} from your main list?',
                success: 'Subscription archived.',
              ),
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archive'),
            ),
          ),
        ],
      );
    }

    if (subscription.isCancelled) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _changeStatus(
                context,
                newStatus: 'active',
                title: 'Reactivate Subscription?',
                message: 'Restore ${subscription.name} as active?',
                success: 'Subscription reactivated.',
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Reactivate'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _changeStatus(
                context,
                newStatus: 'archived',
                title: 'Archive Subscription?',
                message: 'Hide ${subscription.name} from your main list?',
                success: 'Subscription archived.',
              ),
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archive'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _changeStatus(
          context,
          newStatus: 'active',
          title: 'Restore Subscription?',
          message: 'Restore ${subscription.name} as an active subscription?',
          success: 'Subscription restored.',
        ),
        icon: const Icon(Icons.unarchive_outlined, size: 18),
        label: const Text('Restore Subscription'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final price = CurrencyUtils.format(
      subscription.price,
      subscription.currency,
    );
    final planName = subscription.planName.isNotEmpty
        ? subscription.planName
        : 'Custom subscription';

    final rawAccent = _accent();
    final accent = isDark
        ? Color.lerp(rawAccent, Colors.white, 0.15) ?? rawAccent
        : rawAccent;

    final isInactive = !subscription.isActive;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: subscription.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: subscription.logoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Text(
                                subscription.name.isEmpty
                                    ? '?'
                                    : subscription.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Text(
                                subscription.name.isEmpty
                                    ? '?'
                                    : subscription.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            )
                          : Text(
                              subscription.name.isEmpty
                                  ? '?'
                                  : subscription.name[0].toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subscription.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    _statusPill(context),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildOverdueBanner(context),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: colors.border),
                  boxShadow: isDark
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
                  children: [
                    _infoTile(
                      context,
                      icon: Icons.payments_rounded,
                      label: 'Price',
                      value: '$price / ${_billingLabel()}',
                      emphasized: true,
                      valueColor: accent,
                    ),
                    Divider(height: 1, color: colors.border),
                    _infoTile(
                      context,
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: subscription.category,
                    ),
                    Divider(height: 1, color: colors.border),
                    _infoTile(
                      context,
                      icon: Icons.event_rounded,
                      label: 'Start Date',
                      value: _formatDate(subscription.startDate),
                    ),
                    Divider(height: 1, color: colors.border),
                    _infoTile(
                      context,
                      icon: Icons.event_repeat_rounded,
                      label: 'Next Renewal',
                      value: _formatDate(subscription.renewalDate),
                      valueColor: _overdueDays() > 0 && subscription.isActive
                          ? danger
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildStatusActions(context),

              const SizedBox(height: 10),

              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Subscription'),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: danger,
                  side: BorderSide(color: danger.withOpacity(0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}