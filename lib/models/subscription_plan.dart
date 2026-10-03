class SubscriptionPlan {
  final String name;
  final double price;
  final String currency;
  final String billingCycle;
  final String logoUrl;

  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.currency,
    required this.billingCycle,
    this.logoUrl = '',
  });
}