import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/popular_subscriptions.dart';
import '../models/popular_subscription.dart';
import '../models/subscription.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/brand_colors.dart';
import '../widgets/app_background.dart';
import 'subscription_plan_screen.dart';

class PopularSubscriptionsScreen extends StatefulWidget {
  const PopularSubscriptionsScreen({super.key});

  @override
  State<PopularSubscriptionsScreen> createState() =>
      _PopularSubscriptionsScreenState();
}

class _PopularSubscriptionsScreenState
    extends State<PopularSubscriptionsScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();

  String _query = '';
  String _selectedCategory = 'All';

  List<Subscription> _existingSubs = [];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final snapshot = await _firestoreService.getSubscriptions().first;
      final subs = snapshot.docs
          .map((doc) => Subscription.fromMap(doc.data()))
          .toList();
      if (!mounted) return;
      setState(() => _existingSubs = subs);
    } catch (_) {
      // Silent — badges just won't render.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True if the user already owns (service, plan).
  bool _isPlanOwned(String serviceName, String planName) {
    final s = serviceName.trim().toLowerCase();
    final p = planName.trim().toLowerCase();
    for (final sub in _existingSubs) {
      if (sub.name.trim().toLowerCase() == s &&
          sub.planName.trim().toLowerCase() == p) {
        return true;
      }
    }
    return false;
  }

  int _ownedCount(PopularSubscription ps) {
    return ps.plans
        .where((p) => _isPlanOwned(ps.name, p.name))
        .length;
  }

  List<String> get _categories {
    final set = popularSubscriptions
        .map((s) => s.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...set];
  }

  List<PopularSubscription> get _filtered {
    final q = _query.trim().toLowerCase();
    return popularSubscriptions.where((s) {
      final matchesSearch = q.isEmpty || s.name.toLowerCase().contains(q);
      final matchesCat =
          _selectedCategory == 'All' || s.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POPULAR SERVICES',
                      style: AppType.microLabel.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick a service',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: colors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a plan to prefill the details.',
                      style: AppType.secondary
                          .copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final selected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : colors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: list.isEmpty
                    ? _emptyState(context)
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final ps = list[i];
                          final owned = _ownedCount(ps);
                          final total = ps.plans.length;
                          final allOwned = owned == total && total > 0;

                          return _PopularCard(
                            subscription: ps,
                            ownedCount: owned,
                            totalPlans: total,
                            allOwned: allOwned,
                            existingSubscriptions: _existingSubs,
                            onSelected: (result) =>
                                Navigator.pop(context, result),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final PopularSubscription subscription;
  final int ownedCount;
  final int totalPlans;
  final bool allOwned;
  final List<Subscription> existingSubscriptions;
  final ValueChanged<Subscription> onSelected;

  const _PopularCard({
    required this.subscription,
    required this.ownedCount,
    required this.totalPlans,
    required this.allOwned,
    required this.existingSubscriptions,
    required this.onSelected,
  });

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

    final tintOpacity = isDark ? 0.14 : 0.06;
    final borderOpacity = isDark ? 0.32 : 0.22;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: accent.withOpacity(tintOpacity),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () async {
            final result = await Navigator.push<Subscription>(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionPlanScreen(
                  subscription: subscription,
                  existingSubscriptions: existingSubscriptions,
                ),
              ),
            );
            if (!context.mounted || result == null) return;
            onSelected(result);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: accent.withOpacity(borderOpacity),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF23233D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: accent.withOpacity(isDark ? 0.35 : 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: subscription.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: subscription.logoUrl,
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Text(
                            initial,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Text(
                            initial,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        )
                      : Text(
                          initial,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subscription.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ownedCount > 0) ...[
                            const SizedBox(width: 8),
                            _OwnedBadge(
                              ownedCount: ownedCount,
                              totalPlans: totalPlans,
                              allOwned: allOwned,
                              accent: accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${subscription.category}  •  '
                        '$totalPlans ${totalPlans == 1 ? "plan" : "plans"}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: accent.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  final int ownedCount;
  final int totalPlans;
  final bool allOwned;
  final Color accent;

  const _OwnedBadge({
    required this.ownedCount,
    required this.totalPlans,
    required this.allOwned,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = allOwned
        ? 'ALL ADDED'
        : '$ownedCount/$totalPlans ADDED';

    final bg = allOwned
        ? colors.textTertiary.withOpacity(0.15)
        : accent.withOpacity(0.15);
    final fg = allOwned ? colors.textSecondary : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}