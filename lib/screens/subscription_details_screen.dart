import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';
import 'add_subscription_screen.dart';
import '../widgets/confirm_dialog.dart';

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

  Color _statusColor() {
    switch (subscription.status) {
      case 'cancelled':
        return AppColors.warning;
      case 'archived':
        return AppColors.textTertiary;
      default:
        return AppColors.success;
    }
  }

  String _statusLabel() {
    switch (subscription.status) {
      case 'cancelled':
        return 'Cancelled';
      case 'archived':
        return 'Archived';
      default:
        return 'Active';
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
    ];
    int hash = 0;
    for (final c in subscription.name.codeUnits) {
      hash = c + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Color _accent() {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription updated')));
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
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete Subscription?',
      message:
          'Are you sure you want to delete ${subscription.name}? '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;

    try {
      await FirestoreService().deleteSubscription(documentId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription deleted')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete subscription.')),
        );
      }
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: emphasized ? 18 : 14,
                    fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: emphasized ? -0.4 : 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill() {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context) {
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
              icon: const Icon(Icons.pause_circle_outline, size: 20),
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
              icon: const Icon(Icons.archive_outlined, size: 20),
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
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
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
              icon: const Icon(Icons.archive_outlined, size: 20),
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
        icon: const Icon(Icons.unarchive_outlined, size: 20),
        label: const Text('Restore Subscription'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = CurrencyUtils.format(
      subscription.price,
      subscription.currency,
    );
    final planName = subscription.planName.isNotEmpty
        ? subscription.planName
        : 'Custom subscription';
    final accent = _accent();

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Details')),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Hero gradient header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      alignment: Alignment.center,
                      child: subscription.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Image.network(
                                subscription.logoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  subscription.name.isEmpty
                                      ? '?'
                                      : subscription.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              subscription.name.isEmpty
                                  ? '?'
                                  : subscription.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      subscription.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _statusPill(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _infoTile(
                      icon: Icons.payments_rounded,
                      label: 'Price',
                      value: '$price / ${_billingLabel()}',
                      emphasized: true,
                    ),
                    const Divider(height: 1, indent: 60),
                    _infoTile(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: subscription.category,
                    ),
                    const Divider(height: 1, indent: 60),
                    _infoTile(
                      icon: Icons.event_rounded,
                      label: 'Start Date',
                      value: _formatDate(subscription.startDate),
                    ),
                    const Divider(height: 1, indent: 60),
                    _infoTile(
                      icon: Icons.event_repeat_rounded,
                      label: 'Next Renewal',
                      value: _formatDate(subscription.renewalDate),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildStatusActions(context),

              const SizedBox(height: 10),

              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit Subscription'),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
