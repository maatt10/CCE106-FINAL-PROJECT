import 'package:flutter/material.dart';

import '../models/subscription.dart';
import 'popular_subscriptions_screen.dart';
import 'add_subscription_screen.dart';

class AddSubscriptionChoiceScreen extends StatelessWidget {
  const AddSubscriptionChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How would you like to add it?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose from popular services or enter your own subscription.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),

              leading: const CircleAvatar(
                child: Icon(Icons.auto_awesome),
              ),

              title: const Text(
                'Popular Subscriptions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Choose a service and select an existing plan.',
                ),
              ),

              trailing: const Icon(
                Icons.chevron_right,
              ),

              onTap: () async {
                final result =
                    await Navigator.push<Subscription>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PopularSubscriptionsScreen(),
                  ),
                );

                if (!context.mounted || result == null) {
                  return;
                }

                Navigator.pop(context, result);
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),

              leading: const CircleAvatar(
                child: Icon(Icons.edit_outlined),
              ),

              title: const Text(
                'Custom Subscription',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Enter the subscription details yourself.',
                ),
              ),

              trailing: const Icon(
                Icons.chevron_right,
              ),

              onTap: () async {
                final result =
                    await Navigator.push<Subscription>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddSubscriptionScreen(),
                  ),
                );

                if (!context.mounted || result == null) {
                  return;
                }

                Navigator.pop(context, result);
              },
            ),
          ),
        ],
      ),
    );
  }
}