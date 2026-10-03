import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../utils/currency_utils.dart';

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

class _RenewalCalendarScreenState
    extends State<RenewalCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _displayedMonth = DateTime(
      now.year,
      now.month,
    );
  }

  List<Subscription> _subscriptionsForDate(
    DateTime date,
  ) {
    return widget.subscriptions.where((subscription) {
      final renewal = subscription.renewalDate;

      return renewal.year == date.year &&
          renewal.month == date.month &&
          renewal.day == date.day;
    }).toList();
  }

  bool _hasRenewal(DateTime date) {
    return _subscriptionsForDate(date).isNotEmpty;
  }

  void _changeMonth(int amount) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + amount,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();

    setState(() {
      _selectedDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      _displayedMonth = DateTime(
        now.year,
        now.month,
      );
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} '
        '${date.day}, ${date.year}';
  }

  String _renewalLabel(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final renewalDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        renewalDay.difference(today).inDays;

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

    return _formatDate(date);
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    // Monday = 1 ... Sunday = 7
    final startingWeekday =
        firstDayOfMonth.weekday;

    final totalCells =
        ((startingWeekday - 1 + daysInMonth) / 7)
            .ceil() *
        7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(
                  Icons.chevron_left,
                ),
              ),
              Column(
                children: [
                  Text(
                    _monthName(
                      _displayedMonth.month,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_displayedMonth.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: const [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),

          const SizedBox(height: 6),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final dayNumber =
                  index - (startingWeekday - 1) + 1;

              if (dayNumber < 1 ||
                  dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                dayNumber,
              );

              final isSelected =
                  date.year == _selectedDate.year &&
                      date.month ==
                          _selectedDate.month &&
                      date.day == _selectedDate.day;

              final isToday = _isToday(date);
              final hasRenewal = _hasRenewal(date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : null,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: isToday ||
                                  isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasRenewal)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .primary,
                          ),
                        )
                      else
                        const SizedBox(
                          height: 6,
                        ),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildSelectedDate() {
    final renewals =
        _subscriptionsForDate(_selectedDate);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selected Date',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _goToToday,
              child: const Text('Today'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          _formatDate(_selectedDate),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 12),

        if (renewals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
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
                  'No renewals on this date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: renewals.map((subscription) {
                final rate =
                    widget.rates[
                            subscription.currency] ??
                        1.0;

                final convertedPrice =
                    subscription.price * rate;

                final amount =
                    CurrencyUtils.format(
                  convertedPrice,
                  widget.preferredCurrency,
                );

                final planText =
                    subscription.planName.isNotEmpty
                        ? subscription.planName
                        : subscription.category;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    child: Text(
                      subscription.name.isEmpty
                          ? '?'
                          : subscription.name[0]
                              .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    subscription.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$planText • ${subscription.billingCycle}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _renewalLabel(
                          subscription.renewalDate,
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewal Calendar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildCalendar(),

              const SizedBox(height: 28),

              _buildSelectedDate(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}