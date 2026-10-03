import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../utils/currency_utils.dart';
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
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
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

  Future<void> _editSubscription(
    BuildContext context,
  ) async {
    final updatedSubscription =
        await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSubscriptionScreen(
          initialSubscription: subscription,
        ),
      ),
    );

    if (updatedSubscription == null) {
      return;
    }

    try {
      await FirestoreService().updateSubscription(
        documentId,
        updatedSubscription,
      );

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update subscription.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteSubscription(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Subscription?'),
          content: Text(
            'Are you sure you want to delete '
            '${subscription.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirestoreService().deleteSubscription(
        documentId,
      );

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to delete subscription.',
            ),
          ),
        );
      }
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          32,
        ),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              child: Text(
                subscription.name.isEmpty
                    ? '?'
                    : subscription.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              subscription.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              planName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$price /${_billingLabel()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subscription.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(
                                subscription.startDate,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  Row(
                    children: [
                      const Icon(
                        Icons.event_repeat_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Renewal',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(
                                subscription.renewalDate,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () {
              _editSubscription(context);
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Text(
              'Edit Subscription',
            ),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {
              _deleteSubscription(context);
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
            label: const Text(
              'Delete Subscription',
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}