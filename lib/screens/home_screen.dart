import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../services/currency_service.dart';
import '../services/user_settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/currency_utils.dart';

import 'renewal_calendar_screen.dart';
import 'settings_screen.dart';
import 'add_subscription_choice_screen.dart';
import 'analytics_screen.dart';

import '../widgets/app_background.dart';
import '../widgets/skeleton.dart';
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
  String _selectedStatus = 'Active & Cancelled';
  String _selectedBillingCycle = 'All';
  String _sortOption = 'Renewal Date';

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastDocs;

  static const List<String> _statusOptions = [
    'Active & Cancelled',
    'Active Only',
    'Cancelled Only',
    'Archived Only',
    'All Subscriptions',
  ];

  static const List<String> _billingOptions = [
    'All',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  static const List<String> _sortOptions = [
    'Renewal Date',
    'Name A-Z',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_selectedStatus != 'Active & Cancelled') count++;
    if (_selectedBillingCycle != 'All') count++;
    if (_sortOption != 'Renewal Date') count++;
    return count;
  }

  bool get _hasFilters => _searchQuery.isNotEmpty || _activeFilterCount > 0;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedStatus = 'Active & Cancelled';
      _selectedBillingCycle = 'All';
      _sortOption = 'Renewal Date';
    });
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
          showAppSnackBar(
            context,
            'Subscription added successfully',
            kind: SnackKind.success,
          );
        }
      } catch (e) {
        debugPrint('FIRESTORE ERROR: $e');
        if (mounted) {
          showAppSnackBar(
            context,
            'Failed to save subscription',
            kind: SnackKind.error,
          );
        }
      }
    }
  }

  Future<void> _deleteSubscription(String documentId) async {
    try {
      await _firestoreService.deleteSubscription(documentId);
      if (mounted) {
        showAppSnackBar(
          context,
          'Subscription deleted',
          kind: SnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Failed to delete subscription',
          kind: SnackKind.error,
        );
      }
    }
  }

  Future<Map<String, double>> _getExchangeRates(
    List<Subscription> subscriptions,
    String preferredCurrency,
  ) async {
    final currencies = subscriptions.map((s) => s.currency).toSet();
    final rates = <String, double>{};

    for (final currency in currencies) {
      try {
        rates[currency] = await _currencyService.getRate(
          currency,
          preferredCurrency,
        );
      } catch (e) {
        debugPrint('RATE ERROR for $currency: $e');
        rates[currency] = 1.0;
      }
    }
    return rates;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ===== Filter sheet =====
  Future<void> _openFilterSheet(List<String> categories) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void update(VoidCallback fn) {
              setState(fn);
              setSheetState(() {});
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter Subscriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                          setSheetState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _sheetDropdown(
                    label: 'Status',
                    icon: Icons.toggle_on_outlined,
                    value: _selectedStatus,
                    items: _statusOptions,
                    onChanged: (v) => update(() => _selectedStatus = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    label: 'Category',
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    items: ['All', ...categories],
                    displayFor: (v) => v == 'All' ? 'All Categories' : v,
                    onChanged: (v) => update(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    label: 'Billing Cycle',
                    icon: Icons.repeat_outlined,
                    value: _selectedBillingCycle,
                    items: _billingOptions,
                    displayFor: (v) => v == 'All' ? 'All Cycles' : v,
                    onChanged: (v) => update(() => _selectedBillingCycle = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    label: 'Sort By',
                    icon: Icons.sort,
                    value: _sortOption,
                    items: _sortOptions,
                    onChanged: (v) => update(() => _sortOption = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String)? displayFor,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more, color: AppColors.textTertiary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            displayFor != null ? displayFor(item) : item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  // ===== Dashboard widgets =====
  Widget _buildDashboardHeader(BuildContext context, int subscriptionCount) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting 👋',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your subscription overview',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subscriptionCount == 0
              ? 'Start tracking your recurring expenses.'
              : 'Keep your recurring expenses organized.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.insights_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Insight',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add a subscription to start seeing your spending overview.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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

    for (final s in subscriptions.skip(1)) {
      final converted = s.monthlyCost * (rates[s.currency] ?? 1.0);
      if (converted > highestMonthlyCost) {
        mostExpensive = s;
        highestMonthlyCost = converted;
      }
    }

    final formatted = CurrencyUtils.format(
      highestMonthlyCost,
      preferredCurrency,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Monthly Cost',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mostExpensive.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$formatted per month',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated: uses the same SubscriptionCard widget as My Subscriptions.
  // Shows active subs whose renewal is overdue OR within the next 7 days.
  Widget _buildUpcomingRenewals(
    List<MapEntry<String, Subscription>> activeEntries,
    String preferredCurrency,
    Map<String, double> rates,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter: overdue OR within 7 days from today.
    final dueSoon = activeEntries.where((e) {
      final r = e.value.renewalDate;
      final renewalDay = DateTime(r.year, r.month, r.day);
      final diff = renewalDay.difference(today).inDays;
      return diff <= 7; // negative = overdue, 0 = today, 1..7 = this week
    }).toList();

    // Sort ascending: overdue first, then earliest upcoming.
    dueSoon.sort((a, b) => a.value.renewalDate.compareTo(b.value.renewalDate));

    final overdueCount = dueSoon
        .where((e) => e.value.renewalDate.isBefore(today))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Upcoming Renewals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            if (overdueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$overdueCount overdue',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Renewing in the next 7 days',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (dueSoon.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nothing due this week',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You\'re all caught up.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          )
        else
          ...dueSoon.map((entry) {
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_card_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No subscriptions yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your recurring expenses by adding\nyour first subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _EmptyFeature(
                icon: Icons.notifications_outlined,
                label: 'Reminders',
              ),
              SizedBox(width: 20),
              _EmptyFeature(icon: Icons.analytics_outlined, label: 'Analytics'),
              SizedBox(width: 20),
              _EmptyFeature(
                icon: Icons.currency_exchange,
                label: 'Multi-currency',
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _addSubscription,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Add Your First Subscription',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
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
      final s = entry.value;
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.planName.toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' || s.category == _selectedCategory;

      final matchesBilling =
          _selectedBillingCycle == 'All' ||
          s.billingCycle == _selectedBillingCycle;

      final matchesStatus = switch (_selectedStatus) {
        'Active Only' => s.isActive,
        'Cancelled Only' => s.isCancelled,
        'Archived Only' => s.isArchived,
        'All Subscriptions' => true,
        'Active & Cancelled' || _ => s.isActive || s.isCancelled,
      };

      return matchesSearch &&
          matchesCategory &&
          matchesBilling &&
          matchesStatus;
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
    }

    return filtered;
  }

  Widget _filterButton() {
    final isActive = _activeFilterCount > 0;

    return Material(
      color: isActive ? AppColors.primary : Colors.white.withOpacity(0.82),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          final docs = _lastDocs ?? [];
          final categories =
              docs
                  .map((doc) => Subscription.fromMap(doc.data()).category)
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          _openFilterSheet(categories);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.12),
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.tune_rounded,
                color: isActive ? Colors.white : AppColors.primary,
                size: 22,
              ),
              if (isActive)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, double> rates,
    String preferredCurrency,
  ) {
    _lastDocs = docs;

    final filteredEntries = _buildFilteredSubscriptions(docs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Subscriptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${filteredEntries.length}'
              '${_hasFilters ? ' of ' : ' total'}'
              '${_hasFilters ? docs.length : ''}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search subscriptions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _filterButton(),
          ],
        ),
        if (_hasFilters && _activeFilterCount > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedStatus != 'Active & Cancelled')
                _activeFilterChip(
                  label: _selectedStatus,
                  onRemove: () =>
                      setState(() => _selectedStatus = 'Active & Cancelled'),
                ),
              if (_selectedCategory != 'All')
                _activeFilterChip(
                  label: _selectedCategory,
                  onRemove: () => setState(() => _selectedCategory = 'All'),
                ),
              if (_selectedBillingCycle != 'All')
                _activeFilterChip(
                  label: _selectedBillingCycle,
                  onRemove: () => setState(() => _selectedBillingCycle = 'All'),
                ),
              if (_sortOption != 'Renewal Date')
                _activeFilterChip(
                  label: 'Sort: $_sortOption',
                  onRemove: () => setState(() => _sortOption = 'Renewal Date'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (docs.isEmpty)
          _buildEmptyState()
        else if (filteredEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 42, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No matching subscriptions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try changing your search or filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
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
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: AppBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getSubscriptions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const DashboardSkeleton();
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load subscriptions.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final subscriptions = docs
                .map((doc) => Subscription.fromMap(doc.data()))
                .toList();
            final activeSubscriptions = subscriptions
                .where((s) => s.isActive)
                .toList();

            // Build MapEntry list of only active subs (with doc IDs)
            // so we can reuse SubscriptionCard in both sections.
            final activeEntries = docs
                .map(
                  (doc) => MapEntry(doc.id, Subscription.fromMap(doc.data())),
                )
                .where((e) => e.value.isActive)
                .toList();

            return FutureBuilder<String>(
              future: _settingsService.getPreferredCurrency(),
              builder: (context, currencySnapshot) {
                if (currencySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const DashboardSkeleton();
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
                    if (rateSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const DashboardSkeleton();
                    }

                    if (rateSnapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load exchange rates.'),
                      );
                    }

                    final rates = rateSnapshot.data ?? {};

                    double getRate(Subscription s) => rates[s.currency] ?? 1.0;

                    final monthlyTotal = activeSubscriptions.fold<double>(
                      0,
                      (sum, s) => sum + (s.monthlyCost * getRate(s)),
                    );

                    final yearlyTotal = activeSubscriptions.fold<double>(
                      0,
                      (sum, s) => sum + (s.yearlyCost * getRate(s)),
                    );

                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDashboardHeader(
                              context,
                              activeSubscriptions.length,
                            ),
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
                                    icon: Icons.calendar_month_rounded,
                                    variant: SummaryCardVariant.gradient,
                                    gradientColors: AppColors.heroGradient,
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
                                    icon: Icons.payments_rounded,
                                    variant: SummaryCardVariant.gradient,
                                    gradientColors: AppColors.infoGradient,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SummaryCard(
                              title: 'Active Subscriptions',
                              value: '${activeSubscriptions.length}',
                              subtitle: activeSubscriptions.isEmpty
                                  ? 'Add your first one to begin'
                                  : 'You\'re tracking ${activeSubscriptions.length} services',
                              icon: Icons.subscriptions_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildSpendingInsight(
                              activeSubscriptions,
                              preferredCurrency,
                              rates,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: activeSubscriptions.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RenewalCalendarScreen(
                                                  subscriptions:
                                                      activeSubscriptions,
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
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: activeSubscriptions.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AnalyticsScreen(
                                              subscriptions:
                                                  activeSubscriptions,
                                              preferredCurrency:
                                                  preferredCurrency,
                                              rates: rates,
                                            ),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text('View Spending Analytics'),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildSubscriptionManagement(
                              docs,
                              rates,
                              preferredCurrency,
                            ),
                            const SizedBox(height: 32),
                            _buildUpcomingRenewals(
                              activeEntries,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubscription,
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
    );
  }
}

class _EmptyFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
