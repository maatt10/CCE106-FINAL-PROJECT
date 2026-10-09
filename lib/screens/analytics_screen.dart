import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Subscription> subscriptions;
  final String preferredCurrency;
  final Map<String, double> rates;

  const AnalyticsScreen({
    super.key,
    required this.subscriptions,
    required this.preferredCurrency,
    required this.rates,
  });

  double _monthlyCost(Subscription s) {
    final rate = rates[s.currency] ?? 1.0;
    return s.monthlyCost * rate;
  }

  Color _categoryColor(String category) {
    const palette = {
      'Entertainment': Color(0xFF8B5CF6),
      'Music': Color(0xFFEC4899),
      'Gaming': Color(0xFF6366F1),
      'Productivity': Color(0xFF0EA5E9),
      'Education': Color(0xFF14B8A6),
      'Cloud Storage': Color(0xFF06B6D4),
      'Shopping': Color(0xFFF59E0B),
      'Other': Color(0xFF64748B),
    };
    return palette[category] ?? const Color(0xFF64748B);
  }

  Widget _buildHeroCard(
    BuildContext context,
    double monthly,
    double yearly,
    List<MapEntry<String, double>> categories,
    double total,
  ) {
    final colors = context.colors;
    final hasData = categories.isNotEmpty && total > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MONTHLY SPEND',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyUtils.format(monthly, preferredCurrency),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${CurrencyUtils.format(yearly, preferredCurrency)} / yr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          if (hasData)
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 30,
                      startDegreeOffset: -90,
                      sections: categories.map((entry) {
                        return PieChartSectionData(
                          color: _categoryColor(entry.key),
                          value: entry.value,
                          showTitle: false,
                          radius: 18,
                        );
                      }).toList(),
                    ),
                    swapAnimationDuration:
                        const Duration(milliseconds: 350),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${categories.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categories.length == 1 ? 'category' : 'categories',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                color: Colors.white54,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, int activeCount, double avg) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _statCell(
                context,
                label: 'Active Subs',
                value: '$activeCount',
                accent: isDark ? AppColors.infoDark : AppColors.info,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 14),
              color: colors.border,
            ),
            Expanded(
              child: _statCell(
                context,
                label: 'Avg / Month',
                value: CurrencyUtils.format(avg, preferredCurrency),
                accent: isDark ? AppColors.successDark : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(
    BuildContext context, {
    required String label,
    required String value,
    required Color accent,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String category,
    double amount,
    double total,
  ) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total == 0 ? 0.0 : (amount / total) * 100;
    final color = _categoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconForCategory(category),
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.2,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pct.toStringAsFixed(1)}% of total',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyUtils.format(amount, preferredCurrency),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withOpacity(isDark ? 0.15 : 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    const icons = {
      'Entertainment': Icons.movie_outlined,
      'Music': Icons.music_note_outlined,
      'Gaming': Icons.sports_esports_outlined,
      'Productivity': Icons.work_outline_rounded,
      'Education': Icons.school_outlined,
      'Cloud Storage': Icons.cloud_outlined,
      'Shopping': Icons.shopping_bag_outlined,
      'Other': Icons.category_outlined,
    };
    return icons[category] ?? Icons.category_outlined;
  }

  Widget _buildHighestCard(
    BuildContext context,
    Subscription highest,
    double highestCost,
    double monthlyTotal,
  ) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = monthlyTotal == 0 ? 0.0 : (highestCost / monthlyTotal) * 100;
    final accent = _categoryColor(highest.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              highest.name.isEmpty ? '?' : highest.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  highest.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${CurrencyUtils.format(highestCost, preferredCurrency)} / month',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor:
                              accent.withOpacity(isDark ? 0.18 : 0.12),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some active subscriptions to see your spending analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = subscriptions.where((s) => s.isActive).toList();

    if (active.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spending Analytics')),
        body: AppBackground(child: _buildEmptyState(context)),
      );
    }

    final monthlyTotal =
        active.fold<double>(0, (sum, s) => sum + _monthlyCost(s));
    final yearlyTotal = monthlyTotal * 12;
    final averageMonthly = monthlyTotal / active.length;

    Subscription highest = active.first;
    double highestCost = _monthlyCost(highest);
    for (final s in active.skip(1)) {
      final c = _monthlyCost(s);
      if (c > highestCost) {
        highest = s;
        highestCost = c;
      }
    }

    final categoryTotals = <String, double>{};
    for (final s in active) {
      categoryTotals[s.category] =
          (categoryTotals[s.category] ?? 0) + _monthlyCost(s);
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Analytics')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(
                  context,
                  monthlyTotal,
                  yearlyTotal,
                  sortedCategories,
                  monthlyTotal,
                ),

                const SizedBox(height: 14),

                _buildStatsBar(context, active.length, averageMonthly),

                const SizedBox(height: 28),

                Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Where your money goes each month.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),

                const SizedBox(height: 14),

                ...sortedCategories.map(
                  (e) => _buildCategoryRow(
                    context,
                    e.key,
                    e.value,
                    monthlyTotal,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Highest Cost',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                _buildHighestCard(
                  context,
                  highest,
                  highestCost,
                  monthlyTotal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}