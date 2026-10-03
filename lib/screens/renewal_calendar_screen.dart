import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
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

  // ===== Calendar =====
  Widget _buildCalendar() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = first.weekday;
    final cells = ((startWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navBtn(Icons.chevron_left, () => _changeMonth(-1)),
              Column(
                children: [
                  Text(
                    _monthName(_displayedMonth.month),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${_displayedMonth.year}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _navBtn(Icons.chevron_right, () => _changeMonth(1)),
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
                        ? const LinearGradient(
                            colors: AppColors.heroGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: today && !selected
                        ? Border.all(
                            color: AppColors.primary,
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
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : today
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
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
                                : AppColors.primary,
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

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  // ===== Selected date detail =====
  Widget _buildSelectedDate() {
    final subs = _subsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Renewals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        if (subs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No renewals on this date',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick another day to see its renewals.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
            child: Column(
              children: [
                ...subs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final rate = widget.rates[s.currency] ?? 1.0;
                  final converted = s.price * rate;
                  final amount = CurrencyUtils.format(
                    converted,
                    widget.preferredCurrency,
                  );
                  final planText = s.planName.isNotEmpty
                      ? s.planName
                      : s.category;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.heroGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.name.isEmpty
                                ? '?'
                                : s.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '$planText • ${s.billingCycle}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _renewalLabel(s.renewalDate),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < subs.length - 1)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renewal Calendar')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendar(),
                const SizedBox(height: 24),
                _buildSelectedDate(),
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
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}