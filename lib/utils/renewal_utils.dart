/// Advances [currentRenewal] forward by [billingCycle] until it is on or
/// after [asOf] (typically "today" at midnight).
///
/// Handles month-end edge cases (e.g. Jan 31 + 1 month = Feb 28/29).
DateTime nextRenewalAfter({
  required DateTime currentRenewal,
  required DateTime asOf,
  required String billingCycle,
}) {
  DateTime next = currentRenewal;
  int safety = 0;

  // Safety cap prevents infinite loops on bad data.
  while (next.isBefore(asOf) && safety < 500) {
    next = _advanceOnce(next, billingCycle);
    safety++;
  }

  return next;
}

DateTime _advanceOnce(DateTime date, String cycle) {
  switch (cycle) {
    case 'Weekly':
      return date.add(const Duration(days: 7));

    case 'Yearly':
      final lastDay = DateTime(date.year + 1, date.month + 1, 0).day;
      return DateTime(
        date.year + 1,
        date.month,
        date.day > lastDay ? lastDay : date.day,
      );

    case 'Monthly':
    default:
      final m = date.month == 12 ? 1 : date.month + 1;
      final y = date.month == 12 ? date.year + 1 : date.year;
      final lastDay = DateTime(y, m + 1, 0).day;
      return DateTime(
        y,
        m,
        date.day > lastDay ? lastDay : date.day,
      );
  }
}