import 'package:flutter/material.dart';

import '../models/subscription.dart';
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
        return 'week';
      case 'Monthly':
        return 'month';
      case 'Yearly':
        return 'year';
      default:
        return subscription.billingCycle.toLowerCase();
    }
  }

  Color _autoColor() {
    const colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
    ];

    int hash = 0;

    for (final character in subscription.name.codeUnits) {
      hash = character + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  Color _cardColor() {
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

  Widget _buildAvatar(Color accentColor) {
    if (subscription.logoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: accentColor.withOpacity(0.12),
        child: ClipOval(
          child: Image.network(
            subscription.logoUrl,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) {
              debugPrint('LOGO FAILED: ${subscription.name}');
              debugPrint('URL: ${subscription.logoUrl}');
              debugPrint('ERROR: $error');

              return Text(
                subscription.name.isEmpty
                    ? '?'
                    : subscription.name[0].toUpperCase(),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            },
          ),
        ),
      );
    }

    debugPrint('NO LOGO URL: ${subscription.name}');

    return CircleAvatar(
      radius: 25,
      backgroundColor: accentColor.withOpacity(0.15),
      child: Text(
        subscription.name.isEmpty ? '?' : subscription.name[0].toUpperCase(),
        style: TextStyle(
          color: accentColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _cardColor();

    final convertedAmount = CurrencyUtils.format(
      convertedPrice,
      displayCurrency,
    );

    final originalAmount = CurrencyUtils.format(
      subscription.price,
      subscription.currency,
    );

    final subtitle = subscription.planName.isNotEmpty
        ? '${subscription.planName} • '
              '${subscription.billingCycle}'
        : '${subscription.category} • '
              '${subscription.billingCycle}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: accentColor.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildAvatar(accentColor),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Renews '
                      '${_formatDate(subscription.renewalDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    convertedAmount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    '/${_billingLabel()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),

                  if (subscription.currency != displayCurrency)
                    Text(
                      originalAmount,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
