class SubscriptionPlan {
  final String name;
  final String currency;
  final String logoUrl;

  /// Map of billing cycle → price.
  /// Example: {'Monthly': 169, 'Yearly': 1690}
  final Map<String, double> priceByCycle;

  const SubscriptionPlan({
    required this.name,
    required this.currency,
    required this.priceByCycle,
    this.logoUrl = '',
  });

  /// The cycles this plan supports, in a sensible display order.
  List<String> get availableCycles {
    const order = ['Weekly', 'Monthly', 'Semi-Annual', 'Yearly'];
    return order.where((c) => priceByCycle.containsKey(c)).toList();
  }

  /// Default cycle to preselect when opening the form.
  String get defaultCycle {
    if (priceByCycle.containsKey('Monthly')) return 'Monthly';
    if (priceByCycle.containsKey('Yearly')) return 'Yearly';
    return priceByCycle.keys.first;
  }

  /// Price for the given cycle. Falls back to the default cycle's price.
  double priceFor(String cycle) {
    return priceByCycle[cycle] ??
        priceByCycle[defaultCycle] ??
        0.0;
  }
}