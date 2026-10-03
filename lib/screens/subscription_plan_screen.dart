import 'package:flutter/material.dart';

import '../models/popular_subscription.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../utils/currency_utils.dart';
import 'add_subscription_screen.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  final PopularSubscription subscription;

  const SubscriptionPlanScreen({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subscription.name)),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Select the plan that matches your subscription.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          const SizedBox(height: 24),

          ...subscription.plans.map((plan) {
            return _PlanCard(
              plan: plan,
              onTap: () async {
                final result = await Navigator.push<Subscription>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSubscriptionScreen(
                      initialName: subscription.name,
                      initialPlanName: plan.name,
                      initialPrice: plan.price,
                      initialCurrency: plan.currency,
                      initialBillingCycle: plan.billingCycle,
                      initialCategory: subscription.category,
                      initialLogoUrl: subscription.logoUrl,
                    ),
                  ),
                );

                if (!context.mounted || result == null) {
                  return;
                }

                Navigator.pop(context, result);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  String _billingLabel() {
    switch (plan.billingCycle) {
      case 'Weekly':
        return 'week';

      case 'Monthly':
        return 'month';

      case 'Yearly':
        return 'year';

      default:
        return plan.billingCycle.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceText = CurrencyUtils.format(plan.price, plan.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${plan.billingCycle} • ${plan.currency}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '/${_billingLabel()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
