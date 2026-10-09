import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'popular_subscriptions_screen.dart';
import 'add_subscription_screen.dart';

class AddSubscriptionChoiceScreen extends StatelessWidget {
  const AddSubscriptionChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'ADD A SUBSCRIPTION',
                  style: AppType.microLabel.copyWith(
                    color: colors.textTertiary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'How would you\nlike to add it?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.1,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Browse a catalog of popular services or enter the details yourself.',
                  style: AppType.secondary.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 28),

                _ChoiceCard(
                  title: 'Popular Subscriptions',
                  subtitle: 'Pick a service and choose from its plans.',
                  icon: Icons.auto_awesome_rounded,
                  gradient: AppColors.heroGradient,
                  onTap: () async {
                    final result = await Navigator.push<Subscription>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PopularSubscriptionsScreen(),
                      ),
                    );
                    if (!context.mounted || result == null) return;
                    Navigator.pop(context, result);
                  },
                ),

                const SizedBox(height: 14),

                _ChoiceCard(
                  title: 'Custom Subscription',
                  subtitle: 'Enter the subscription details yourself.',
                  icon: Icons.edit_rounded,
                  gradient: AppColors.infoGradient,
                  onTap: () async {
                    final result = await Navigator.push<Subscription>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSubscriptionScreen(),
                      ),
                    );
                    if (!context.mounted || result == null) return;
                    Navigator.pop(context, result);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode fade the gradient slightly so it doesn't glow too hard.
    final effectiveGradient = isDark
        ? gradient
            .map((c) => Color.lerp(c, Colors.black, 0.15) ?? c)
            .toList()
        : gradient;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: effectiveGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveGradient.first.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}