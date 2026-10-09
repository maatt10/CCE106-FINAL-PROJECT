import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/brand_colors.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';

class RenewalCalendarScreen extends StatefulWidget {
  final List<Subscription> subscriptions;
  final String preferredCurrency;
  final Map<String, double> rates;

  const RenewalCalendarScreen({
    super.key,
    required this.subscriptions,
    required this.preferredCurrency,
    required this.rates,
  });

  @override
  State<RenewalCalendarScreen> createState() =>
      _RenewalCalendarScreenState();
}

class _RenewalCalendarScreenState extends State<RenewalCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month);
  }

  List<Subscription> _subsForDate(DateTime d) => widget.subscriptions
      .where((s) =>
          s.renewalDate.year == d.year &&
          s.renewalDate.month == d.month &&
          s.renewalDate.day == d.day)
      .toList();

  bool _hasRenewal(DateTime d) => _subsForDate(d).isNotEmpty;

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _displayedMonth = DateTime(now.year, now.month);
    });
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m - 1];

  String _formatDate(DateTime d) =>
      '${_monthName(d.month)} ${d.day}, ${d.year}';

  String _renewalLabel(DateTime d) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final r = DateTime(d.year, d.month, d.day);
    final diff = r.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Renews today';
    if (diff == 1) return 'Renews tomorrow';
    if (diff <= 7) return 'In $diff days';
    return _formatDate(d);
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final colors = context.colors;
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = first.weekday;
    final cells = ((startWeekday - 1 + daysInMonth) / 7).ceil() * 7;

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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navBtn(context, Icons.chevron_left, () => _changeMonth(-1)),
              Column(
                children: [
                  Text(
                    _monthName(_displayedMonth.month),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_displayedMonth.year}',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              _navBtn(context, Icons.chevron_right, () => _changeMonth(1)),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: const [
              _Weekday('M'), _Weekday('T'), _Weekday('W'),
              _Weekday('T'), _Weekday('F'), _Weekday('S'), _Weekday('S'),
            ],
          ),

          const SizedBox(height: 6),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - (startWeekday - 1) + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                dayNum,
              );
              final selected = _isSameDay(date, _selectedDate);
              final today = _isToday(date);
              final hasRenewal = _hasRenewal(date);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: isDark
                                ? AppColors.heroGradientDark
                                : AppColors.heroGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: today && !selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: today || selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : today
                                  ? Theme.of(context).colorScheme.primary
                                  : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (hasRenewal)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDate(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subs = _subsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Renewals',
                style: AppType.section.copyWith(color: colors.textPrimary),
              ),
            ),
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text('Today'),
            ),
          ],
        ),

        const SizedBox(height: 2),

        Text(
          _formatDate(_selectedDate),
          style: AppType.secondary.copyWith(color: colors.textSecondary),
        ),

        const SizedBox(height: 12),

        if (subs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 26,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No renewals on this date',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick another day to see its renewals.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...subs.map((s) {
            final rawAccent = BrandColors.of(s.name);
            final accent = isDark
                ? Color.lerp(rawAccent, Colors.white, 0.15) ?? rawAccent
                : rawAccent;

            final rate = widget.rates[s.currency] ?? 1.0;
            final converted = s.price * rate;
            final amount = CurrencyUtils.format(
              converted,
              widget.preferredCurrency,
            );
            final planText =
                s.planName.isNotEmpty ? s.planName : s.category;
            final initial =
                s.name.isEmpty ? '?' : s.name[0].toUpperCase();

            final tintOpacity = isDark ? 0.14 : 0.06;
            final borderOpacity = isDark ? 0.32 : 0.22;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(tintOpacity),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: accent.withOpacity(borderOpacity),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF23233D)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: accent.withOpacity(isDark ? 0.35 : 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$planText • ${s.billingCycle}',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          amount,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _renewalLabel(s.renewalDate),
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendar(context),
                const SizedBox(height: 24),
                _buildSelectedDate(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String text;
  const _Weekday(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: context.colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}