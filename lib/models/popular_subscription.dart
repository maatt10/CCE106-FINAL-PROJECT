import 'subscription_plan.dart';

class PopularSubscription {
  final String name;
  final String category;
  final String logoUrl;
  final List<SubscriptionPlan> plans;

  const PopularSubscription({
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.plans,
  });
}