import '../models/popular_subscription.dart';
import '../models/subscription_plan.dart';

const List<PopularSubscription> popularSubscriptions = [
  PopularSubscription(
    name: 'Netflix',
    category: 'Entertainment',
    logoUrl: 'https://www.google.com/s2/favicons?domain=netflix.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Mobile',
        price: 169,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Basic',
        price: 279,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Standard',
        price: 449,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Premium',
        price: 619,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
    ],
  ),

  PopularSubscription(
    name: 'Spotify',
    category: 'Music',
    logoUrl: 'https://cdn.simpleicons.org/spotify/1DB954',
    plans: [
      SubscriptionPlan(
        name: 'Individual',
        price: 169,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Student',
        price: 85,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Duo',
        price: 229,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
      SubscriptionPlan(
        name: 'Family',
        price: 279,
        currency: 'PHP',
        billingCycle: 'Monthly',
      ),
    ],
  ),
];
