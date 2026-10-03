import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../services/currency_service.dart';
import '../services/user_settings_service.dart';
import '../utils/currency_utils.dart';

import 'renewal_calendar_screen.dart';
import 'settings_screen.dart';
import 'add_subscription_choice_screen.dart';

import '../widgets/subscription_card.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CurrencyService _currencyService = CurrencyService();
  final UserSettingsService _settingsService = UserSettingsService();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortOption = 'Renewal Date';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSubscription() async {
    final result = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(builder: (_) => const AddSubscriptionChoiceScreen()),
    );

    if (result != null) {
      try {
        await _firestoreService.addSubscription(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription added successfully!')),
          );
        }
      } catch (e) {
        debugPrint('FIRESTORE ERROR: $e');

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        }
      }
    }
  }

  Future<void> _deleteSubscription(String documentId) async {
    try {
      await _firestoreService.deleteSubscription(documentId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete subscription.')),
        );
      }
    }
  }

  Future<Map<String, double>> _getExchangeRates(
    List<Subscription> subscriptions,
    String preferredCurrency,
  ) async {
    final currencies = subscriptions
        .map((subscription) => subscription.currency)
        .toSet();

    final rates = <String, double>{};

    for (final currency in currencies) {
      rates[currency] = await _currencyService.getRate(
        currency,
        preferredCurrency,
      );
    }

    return rates;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _renewalLabel(DateTime renewalDate) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final renewalDay = DateTime(
      renewalDate.year,
      renewalDate.month,
      renewalDate.day,
    );

    final difference = renewalDay.difference(today).inDays;

    if (difference < 0) {
      return 'Overdue';
    }

    if (difference == 0) {
      return 'Renews today';
    }

    if (difference == 1) {
      return 'Renews tomorrow';
    }

    if (difference <= 7) {
      return 'In $difference days';
    }

    return _formatDate(renewalDate);
  }

  Widget _buildDashboardHeader(BuildContext context, int subscriptionCount) {
    final hour = DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting 👋',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your subscription overview',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subscriptionCount == 0
              ? 'Start tracking your recurring expenses.'
              : 'Keep your recurring expenses organized.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSpendingInsight(
    List<Subscription> subscriptions,
    String preferredCurrency,
    Map<String, double> rates,
  ) {
    if (subscriptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(Icons.insights_outlined, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Insight',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add a subscription to start seeing '
                    'your spending overview.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Subscription mostExpensive = subscriptions.first;

    double highestMonthlyCost =
        mostExpensive.monthlyCost * (rates[mostExpensive.currency] ?? 1.0);

    for (final subscription in subscriptions.skip(1)) {
      final convertedMonthly =
          subscription.monthlyCost * (rates[subscription.currency] ?? 1.0);

      if (convertedMonthly > highestMonthlyCost) {
        mostExpensive = subscription;
        highestMonthlyCost = convertedMonthly;
      }
    }

    final formattedAmount = CurrencyUtils.format(
      highestMonthlyCost,
      preferredCurrency,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            child: Icon(Icons.insights_outlined, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Monthly Cost',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  mostExpensive.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$formattedAmount per month',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRenewals(
    List<Subscription> subscriptions,
    String preferredCurrency,
    Map<String, double> rates,
  ) {
    final sortedSubscriptions = [...subscriptions]
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));

    final upcomingSubscriptions = sortedSubscriptions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Renewals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (subscriptions.length > 5)
              Text(
                'Next 5',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingSubscriptions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No upcoming renewals.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ...upcomingSubscriptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subscription = entry.value;

                  final rate = rates[subscription.currency] ?? 1.0;

                  final convertedPrice = subscription.price * rate;

                  final amount = CurrencyUtils.format(
                    convertedPrice,
                    preferredCurrency,
                  );

                  final planText = subscription.planName.isNotEmpty
                      ? subscription.planName
                      : subscription.category;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            subscription.name.isEmpty
                                ? '?'
                                : subscription.name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          subscription.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$planText • '
                          '${_renewalLabel(subscription.renewalDate)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amount,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatDate(subscription.renewalDate),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < upcomingSubscriptions.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.grey.shade200,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            child: Icon(
              Icons.add_card_outlined,
              size: 32,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No subscriptions yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first subscription to start '
            'tracking your recurring expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _addSubscription,
            icon: const Icon(Icons.add),
            label: const Text('Add Subscription'),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, Subscription>> _buildFilteredSubscriptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final entries = docs.map((doc) {
      return MapEntry(doc.id, Subscription.fromMap(doc.data()));
    }).toList();

    final filtered = entries.where((entry) {
      final subscription = entry.value;

      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          subscription.name.toLowerCase().contains(query) ||
          subscription.planName.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          subscription.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case 'Name A-Z':
        filtered.sort(
          (a, b) =>
              a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()),
        );
        break;

      case 'Price: Low to High':
        filtered.sort((a, b) => a.value.price.compareTo(b.value.price));
        break;

      case 'Price: High to Low':
        filtered.sort((a, b) => b.value.price.compareTo(a.value.price));
        break;

      case 'Renewal Date':
      default:
        filtered.sort(
          (a, b) => a.value.renewalDate.compareTo(b.value.renewalDate),
        );
        break;
    }

    return filtered;
  }

  Widget _buildSubscriptionManagement(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, double> rates,
    String preferredCurrency,
  ) {
    final categories =
        docs
            .map((doc) => Subscription.fromMap(doc.data()).category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final filteredEntries = _buildFilteredSubscriptions(docs);

    final hasFilters = _searchQuery.isNotEmpty || _selectedCategory != 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Subscriptions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: Text(
                '${filteredEntries.length}'
                '${hasFilters ? ' of ' : ' total'}'
                '${hasFilters ? docs.length : ''}',
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search subscriptions...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Responsive filters.
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;

            final categoryDropdown = DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: 'All',
                  child: Text(
                    'All Categories',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCategory = value;
                });
              },
            );

            final sortDropdown = DropdownButtonFormField<String>(
              value: _sortOption,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Sort',
                prefixIcon: const Icon(Icons.sort),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'Renewal Date',
                  child: Text('Renewal Date', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<String>(
                  value: 'Name A-Z',
                  child: Text('Name A-Z', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<String>(
                  value: 'Price: Low to High',
                  child: Text(
                    'Price: Low → High',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Price: High to Low',
                  child: Text(
                    'Price: High → Low',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _sortOption = value;
                });
              },
            );

            if (isNarrow) {
              return Column(
                children: [
                  categoryDropdown,
                  const SizedBox(height: 10),
                  sortDropdown,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 10),
                Expanded(child: sortDropdown),
              ],
            );
          },
        ),

        if (hasFilters) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear filters'),
            ),
          ),
        ],

        const SizedBox(height: 8),

        if (filteredEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 42, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                const Text(
                  'No matching subscriptions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try changing your search or filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...filteredEntries.map((entry) {
            final documentId = entry.key;
            final subscription = entry.value;

            final rate = rates[subscription.currency] ?? 1.0;

            final convertedPrice = subscription.price * rate;

            return SubscriptionCard(
              subscription: subscription,
              documentId: documentId,
              convertedPrice: convertedPrice,
              displayCurrency: preferredCurrency,
              onDelete: () => _deleteSubscription(documentId),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SubTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );

              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load subscriptions.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final subscriptions = docs.map((doc) {
            return Subscription.fromMap(doc.data());
          }).toList();

          return FutureBuilder<String>(
            future: _settingsService.getPreferredCurrency(),
            builder: (context, currencySnapshot) {
              if (currencySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (currencySnapshot.hasError) {
                return const Center(
                  child: Text('Failed to load currency settings.'),
                );
              }

              final preferredCurrency = currencySnapshot.data ?? 'PHP';

              return FutureBuilder<Map<String, double>>(
                future: _getExchangeRates(subscriptions, preferredCurrency),
                builder: (context, rateSnapshot) {
                  if (rateSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (rateSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.currency_exchange, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Unable to load exchange rates.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your internet '
                              'connection and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final rates = rateSnapshot.data ?? {};

                  double getRate(Subscription subscription) {
                    return rates[subscription.currency] ?? 1.0;
                  }

                  final monthlyTotal = subscriptions.fold<double>(0, (
                    sum,
                    subscription,
                  ) {
                    final rate = getRate(subscription);

                    return sum + (subscription.monthlyCost * rate);
                  });

                  final yearlyTotal = subscriptions.fold<double>(0, (
                    sum,
                    subscription,
                  ) {
                    final rate = getRate(subscription);

                    return sum + (subscription.yearlyCost * rate);
                  });

                  return SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDashboardHeader(context, subscriptions.length),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Monthly',
                                  value: CurrencyUtils.format(
                                    monthlyTotal,
                                    preferredCurrency,
                                  ),
                                  icon: Icons.calendar_month,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Yearly',
                                  value: CurrencyUtils.format(
                                    yearlyTotal,
                                    preferredCurrency,
                                  ),
                                  icon: Icons.payments_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          SummaryCard(
                            title: 'Active Subscriptions',
                            value: '${subscriptions.length}',
                            icon: Icons.subscriptions_outlined,
                          ),

                          const SizedBox(height: 20),

                          _buildSpendingInsight(
                            subscriptions,
                            preferredCurrency,
                            rates,
                          ),

                          const SizedBox(height: 28),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: subscriptions.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RenewalCalendarScreen(
                                            subscriptions: subscriptions,
                                            preferredCurrency:
                                                preferredCurrency,
                                            rates: rates,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: const Text('View Renewal Calendar'),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // My Subscriptions comes
                          // before Upcoming Renewals
                          _buildSubscriptionManagement(
                            docs,
                            rates,
                            preferredCurrency,
                          ),

                          const SizedBox(height: 32),

                          _buildUpcomingRenewals(
                            subscriptions,
                            preferredCurrency,
                            rates,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubscription,
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
    );
  }
}
