import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/popular_subscription.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../theme/app_theme.dart';
import '../utils/brand_colors.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';
import 'add_subscription_screen.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  final PopularSubscription subscription;
  final List<Subscription> existingSubscriptions;

  const SubscriptionPlanScreen({
    super.key,
    required this.subscription,
    this.existingSubscriptions = const [],
  });

  bool _isOwned(String planName) {
    final s = subscription.name.trim().toLowerCase();
    final p = planName.trim().toLowerCase();
    for (final sub in existingSubscriptions) {
      if (sub.name.trim().toLowerCase() == s &&
          sub.planName.trim().toLowerCase() == p) {
        return true;
      }
    }
    return false;
  }

  int get _availableCount =>
      subscription.plans.where((p) => !_isOwned(p.name)).length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawAccent = BrandColors.of(subscription.name);
    final accent = isDark
        ? Color.lerp(rawAccent, Colors.white, 0.15) ?? rawAccent
        : rawAccent;

    final initial = subscription.name.isEmpty
        ? '?'
        : subscription.name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(subscription.name)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            accent.withOpacity(0.9),
                            accent.withOpacity(0.65),
                          ]
                        : [accent, accent.withOpacity(0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: subscription.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: subscription.logoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Text(
                                initial,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Text(
                                initial,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            )
                          : Text(
                              initial,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subscription.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subscription.category,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'AVAILABLE PLANS',
                style: AppType.microLabel.copyWith(
                  color: colors.textTertiary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose a plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: colors.textPrimary,
                  height: 1,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _availableCount == 0
                    ? 'You already have every plan for this service.'
                    : 'Tap a plan to customize and add it.',
                style: AppType.secondary.copyWith(
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              ...subscription.plans.map((plan) {
                final owned = _isOwned(plan.name);
                return _PlanCard(
                  plan: plan,
                  serviceName: subscription.name,
                  serviceLogoUrl: subscription.logoUrl,
                  category: subscription.category,
                  accent: accent,
                  owned: owned,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String serviceName;
  final String serviceLogoUrl;
  final String category;
  final Color accent;
  final bool owned;

  const _PlanCard({
    required this.plan,
    required this.serviceName,
    required this.serviceLogoUrl,
    required this.category,
    required this.accent,
    required this.owned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveLogo =
        plan.logoUrl.isNotEmpty ? plan.logoUrl : serviceLogoUrl;

    // Owned plan → dim and disable
    if (owned) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Opacity(
            opacity: 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.textTertiary.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'ADDED',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyUtils.format(
                            plan.priceFor(plan.defaultCycle),
                            plan.currency,
                          ),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            height: 1,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ ${plan.defaultCycle.toLowerCase()}',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Already added',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Available plan
    final cycles = plan.availableCycles;
    final monthlyPrice = plan.priceByCycle['Monthly'];
    final hasOnlyYearly = cycles.length == 1 && cycles.first == 'Yearly';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () async {
            final result = await Navigator.push<Subscription>(
              context,
              MaterialPageRoute(
                builder: (_) => AddSubscriptionScreen(
                  initialName: serviceName,
                  initialPlanName: plan.name,
                  initialCurrency: plan.currency,
                  initialCategory: category,
                  initialLogoUrl: effectiveLogo,
                  priceByCycle: plan.priceByCycle,
                ),
              ),
            );
            if (!context.mounted || result == null) return;
            Navigator.pop(context, result);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cycles.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${cycles.length} OPTIONS',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasOnlyYearly
                              ? CurrencyUtils.format(
                                  plan.priceByCycle['Yearly']!,
                                  plan.currency,
                                )
                              : CurrencyUtils.format(
                                  monthlyPrice ?? plan.priceFor(plan.defaultCycle),
                                  plan.currency,
                                ),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            height: 1,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        hasOnlyYearly ? '/ year' : '/ month',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (cycles.length > 1 && monthlyPrice != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Also available: ${cycles.where((c) => c != 'Monthly').map((c) => c).join(', ')}',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.14 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to continue',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
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
    );
  }
}