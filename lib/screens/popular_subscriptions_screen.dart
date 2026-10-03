import 'package:flutter/material.dart';

import '../data/popular_subscriptions.dart';
import '../models/popular_subscription.dart';
import '../models/subscription.dart';
import 'subscription_plan_screen.dart';

class PopularSubscriptionsScreen extends StatelessWidget {
  const PopularSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Subscriptions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Select a subscription to view its available plans.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          const SizedBox(height: 24),

          ...popularSubscriptions.map((subscription) {
            return _PopularSubscriptionCard(
              subscription: subscription,
              onSelected: (result) {
                Navigator.pop(context, result);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _PopularSubscriptionCard extends StatelessWidget {
  final PopularSubscription subscription;
  final ValueChanged<Subscription> onSelected;

  const _PopularSubscriptionCard({
    required this.subscription,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 25,
          child: subscription.logoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    subscription.logoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Text(
                        subscription.name.isEmpty
                            ? '?'
                            : subscription.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  subscription.name.isEmpty
                      ? '?'
                      : subscription.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),

        title: Text(
          subscription.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${subscription.category} • '
            '${subscription.plans.length} plans',
          ),
        ),

        trailing: const Icon(Icons.chevron_right),

        onTap: () async {
          final result = await Navigator.push<Subscription>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SubscriptionPlanScreen(subscription: subscription),
            ),
          );

          if (!context.mounted || result == null) {
            return;
          }

          onSelected(result);
        },
      ),
    );
  }
}
