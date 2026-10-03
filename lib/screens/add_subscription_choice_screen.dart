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
                const Text(
                  'How would you like to add it?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose from popular services or enter your own subscription.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                _ChoiceCard(
                  title: 'Popular Subscriptions',
                  subtitle: 'Pick a service and choose from existing plans.',
                  icon: Icons.auto_awesome_rounded,
                  gradient: AppColors.heroGradient,
                  onTap: () async {
                    final result = await Navigator.push<Subscription>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PopularSubscriptionsScreen(),
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
    return Material(
      color: Colors.white.withOpacity(0.82),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}