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

  List<Subscription> _currentSubscriptions = [];

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runRenewalMaintenance();
    });
  }

  Future<void> _runRenewalMaintenance() async {
    try {
      final count = await _firestoreService.advanceOverdueRenewals();
      if (count > 0) {
        debugPrint('MAINTENANCE: advanced $count overdue renewals');
      }
    } catch (e) {
      debugPrint('MAINTENANCE ERROR: $e');
    }
  }

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

  bool _isDuplicate(Subscription candidate) {
    final name = candidate.name.trim().toLowerCase();
    final plan = candidate.planName.trim().toLowerCase();

    for (final existing in _currentSubscriptions) {
      final existingName = existing.name.trim().toLowerCase();
      final existingPlan = existing.planName.trim().toLowerCase();

      if (existingName != name) continue;

      if (plan.isNotEmpty && existingPlan.isNotEmpty) {
        if (existingPlan == plan) return true;
      } else {
        return true;
      }
    }
    return false;
  }

  Future<void> _addSubscription() async {
    final result = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(builder: (_) => const AddSubscriptionChoiceScreen()),
    );

    if (result == null) return;

    if (_isDuplicate(result)) {
      if (!mounted) return;
      final planLabel = result.planName.isNotEmpty
          ? ' (${result.planName})'
          : '';
      showAppSnackBar(
        context,
        '${result.name}$planLabel is already in your subscriptions.',
        kind: SnackKind.warning,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      await _firestoreService.addSubscription(result);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Subscription added successfully',
        kind: SnackKind.success,
      );
    } catch (e) {
      debugPrint('FIRESTORE ERROR: $e');
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Failed to save subscription',
        kind: SnackKind.error,
      );
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

  Future<void> _openFilterSheet(List<String> categories) async {
    final colors = context.colors;

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
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
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
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter Subscriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
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
                    context,
                    label: 'Status',
                    icon: Icons.toggle_on_outlined,
                    value: _selectedStatus,
                    items: _statusOptions,
                    onChanged: (v) => update(() => _selectedStatus = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    context,
                    label: 'Category',
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    items: ['All', ...categories],
                    displayFor: (v) => v == 'All' ? 'All Categories' : v,
                    onChanged: (v) => update(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    context,
                    label: 'Billing Cycle',
                    icon: Icons.repeat_outlined,
                    value: _selectedBillingCycle,
                    items: _billingOptions,
                    displayFor: (v) => v == 'All' ? 'All Cycles' : v,
                    onChanged: (v) => update(() => _selectedBillingCycle = v),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown(
                    context,
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

  Widget _sheetDropdown(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String)? displayFor,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.expand_more, color: colors.textTertiary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        filled: true,
        fillColor: isDark ? colors.surfaceElevated : colors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
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

  Widget _buildDashboardHeader(BuildContext context, int subscriptionCount) {
    final colors = context.colors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'GOOD MORNING'
        : hour < 18
            ? 'GOOD AFTERNOON'
            : 'GOOD EVENING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppType.microLabel.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: 6),
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: colors.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subscriptionCount == 0
              ? 'Track your recurring expenses.'
              : 'You\'re tracking $subscriptionCount active '
                  '${subscriptionCount == 1 ? "subscription" : "subscriptions"}.',
          style: AppType.secondary.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSpendingInsight(
    BuildContext context,
    List<Subscription> subscriptions,
    String preferredCurrency,
    Map<String, double> rates,
  ) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subscriptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.insights_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENDING INSIGHT',
                    style: AppType.microLabel.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Add a subscription to see your top cost.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? AppColors.heroGradientDark
              : AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                'TOP MONTHLY COST',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mostExpensive.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mostExpensive.planName.isNotEmpty ? mostExpensive.planName : mostExpensive.category} '
                      '• ${mostExpensive.billingCycle}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatted,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRenewals(
    BuildContext context,
    List<MapEntry<String, Subscription>> activeEntries,
    String preferredCurrency,
    Map<String, double> rates,
  ) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueSoon = activeEntries.where((e) {
      final r = e.value.renewalDate;
      final renewalDay = DateTime(r.year, r.month, r.day);
      final diff = renewalDay.difference(today).inDays;
      return diff <= 7;
    }).toList();

    dueSoon.sort(
      (a, b) => a.value.renewalDate.compareTo(b.value.renewalDate),
    );

    final overdueCount = dueSoon
        .where((e) => e.value.renewalDate.isBefore(today))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Due Soon',
              style: AppType.section.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(width: 8),
            if (overdueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.dangerDark : AppColors.danger)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$overdueCount OVERDUE',
                  style: TextStyle(
                    color: isDark ? AppColors.dangerDark : AppColors.danger,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Renewing within the next 7 days.',
          style: AppType.secondary.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (dueSoon.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
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
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 36,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Nothing due this week',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You\'re all caught up.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
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

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_card_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No subscriptions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your recurring expenses by adding\nyour first subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
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

      final matchesSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.planName.toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' || s.category == _selectedCategory;

      final matchesBilling = _selectedBillingCycle == 'All' ||
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
        filtered.sort((a, b) =>
            a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()));
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) => a.value.price.compareTo(b.value.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.value.price.compareTo(a.value.price));
        break;
      case 'Renewal Date':
      default:
        filtered
            .sort((a, b) => a.value.renewalDate.compareTo(b.value.renewalDate));
    }

    return filtered;
  }

  Widget _filterButton(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _activeFilterCount > 0;

    return Material(
      color: isActive
          ? Theme.of(context).colorScheme.primary
          : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          final docs = _lastDocs ?? [];
          final categories = docs
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
                  ? Theme.of(context).colorScheme.primary
                  : colors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.tune_rounded,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
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
                    decoration: BoxDecoration(
                      color: isDark ? colors.surfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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

  Widget _activeFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, double> rates,
    String preferredCurrency,
  ) {
    _lastDocs = docs;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredEntries = _buildFilteredSubscriptions(docs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Subscriptions',
              style: AppType.section.copyWith(color: colors.textPrimary),
            ),
            Text(
              '${filteredEntries.length}'
              '${_hasFilters ? ' of ' : ' total'}'
              '${_hasFilters ? docs.length : ''}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
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
            _filterButton(context),
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
                  context,
                  label: _selectedStatus,
                  onRemove: () => setState(
                    () => _selectedStatus = 'Active & Cancelled',
                  ),
                ),
              if (_selectedCategory != 'All')
                _activeFilterChip(
                  context,
                  label: _selectedCategory,
                  onRemove: () => setState(() => _selectedCategory = 'All'),
                ),
              if (_selectedBillingCycle != 'All')
                _activeFilterChip(
                  context,
                  label: _selectedBillingCycle,
                  onRemove: () =>
                      setState(() => _selectedBillingCycle = 'All'),
                ),
              if (_sortOption != 'Renewal Date')
                _activeFilterChip(
                  context,
                  label: 'Sort: $_sortOption',
                  onRemove: () =>
                      setState(() => _sortOption = 'Renewal Date'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (docs.isEmpty)
          _buildEmptyState(context)
        else if (filteredEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
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
              children: [
                Icon(
                  Icons.search_off,
                  size: 42,
                  color: colors.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No matching subscriptions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try changing your search or filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
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
        titleSpacing: 16,
        title: Row(
          children: [
            // Small logo — purple tile
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SubTrack'),
          ],
        ),
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
            final subscriptions =
                docs.map((doc) => Subscription.fromMap(doc.data())).toList();

            _currentSubscriptions = subscriptions;

            final activeSubscriptions =
                subscriptions.where((s) => s.isActive).toList();

            final activeEntries = docs
                .map((doc) =>
                    MapEntry(doc.id, Subscription.fromMap(doc.data())))
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
                  future:
                      _getExchangeRates(subscriptions, preferredCurrency),
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

                    double getRate(Subscription s) =>
                        rates[s.currency] ?? 1.0;

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
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                              title: 'Active',
                              value: '${activeSubscriptions.length}',
                              subtitle: activeSubscriptions.isEmpty
                                  ? 'Add your first one to begin'
                                  : '${activeSubscriptions.length == 1 ? "subscription" : "subscriptions"} tracked',
                              icon: Icons.subscriptions_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildSpendingInsight(
                              context,
                              activeSubscriptions,
                              preferredCurrency,
                              rates,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
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
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Calendar'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: activeSubscriptions.isEmpty
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AnalyticsScreen(
                                                  subscriptions:
                                                      activeSubscriptions,
                                                  preferredCurrency:
                                                      preferredCurrency,
                                                  rates: rates,
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.analytics_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Analytics'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildSubscriptionManagement(
                              context,
                              docs,
                              rates,
                              preferredCurrency,
                            ),
                            const SizedBox(height: 32),
                            _buildUpcomingRenewals(
                              context,
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