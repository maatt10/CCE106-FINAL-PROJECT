import '../models/popular_subscription.dart';
import '../models/subscription_plan.dart';

const List<PopularSubscription> popularSubscriptions = [
  // ==================== NETFLIX ====================
  PopularSubscription(
    name: 'Netflix',
    category: 'Entertainment',
    logoUrl: 'https://www.google.com/s2/favicons?domain=netflix.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Mobile',
        currency: 'PHP',
        priceByCycle: {'Monthly': 169},
      ),
      SubscriptionPlan(
        name: 'Basic',
        currency: 'PHP',
        priceByCycle: {'Monthly': 279},
      ),
      SubscriptionPlan(
        name: 'Standard',
        currency: 'PHP',
        priceByCycle: {'Monthly': 449},
      ),
      SubscriptionPlan(
        name: 'Premium',
        currency: 'PHP',
        priceByCycle: {'Monthly': 619},
      ),
    ],
  ),

  // ==================== SPOTIFY ====================
  PopularSubscription(
    name: 'Spotify',
    category: 'Music',
    logoUrl: 'https://www.google.com/s2/favicons?domain=spotify.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Individual',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 169,
          'Yearly': 1690,
        },
      ),
      SubscriptionPlan(
        name: 'Student',
        currency: 'PHP',
        priceByCycle: {'Monthly': 85},
      ),
      SubscriptionPlan(
        name: 'Duo',
        currency: 'PHP',
        priceByCycle: {'Monthly': 229},
      ),
      SubscriptionPlan(
        name: 'Family',
        currency: 'PHP',
        priceByCycle: {'Monthly': 279},
      ),
    ],
  ),

  // ==================== YOUTUBE PREMIUM ====================
  PopularSubscription(
    name: 'YouTube Premium',
    category: 'Entertainment',
    logoUrl: 'https://www.google.com/s2/favicons?domain=youtube.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Individual',
        currency: 'PHP',
        priceByCycle: {'Monthly': 189},
      ),
      SubscriptionPlan(
        name: 'Student',
        currency: 'PHP',
        priceByCycle: {'Monthly': 115},
      ),
      SubscriptionPlan(
        name: 'Family',
        currency: 'PHP',
        priceByCycle: {'Monthly': 379},
      ),
      SubscriptionPlan(
        name: 'Premium Lite',
        currency: 'PHP',
        priceByCycle: {'Monthly': 109},
      ),
    ],
  ),

  // ==================== DISNEY+ ====================
  PopularSubscription(
    name: 'Disney+',
    category: 'Entertainment',
    logoUrl: 'https://www.google.com/s2/favicons?domain=disneyplus.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Basic',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 289,
          'Yearly': 2290,
        },
      ),
      SubscriptionPlan(
        name: 'Premium',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 599,
          'Yearly': 4600,
        },
      ),
    ],
  ),

  // ==================== APPLE MUSIC ====================
  PopularSubscription(
    name: 'Apple Music',
    category: 'Music',
    logoUrl: 'https://www.google.com/s2/favicons?domain=music.apple.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Individual',
        currency: 'PHP',
        priceByCycle: {'Monthly': 169},
      ),
      SubscriptionPlan(
        name: 'Student',
        currency: 'PHP',
        priceByCycle: {'Monthly': 85},
      ),
      SubscriptionPlan(
        name: 'Family',
        currency: 'PHP',
        priceByCycle: {'Monthly': 279},
      ),
    ],
  ),

  // ==================== CANVA PRO ====================
  PopularSubscription(
    name: 'Canva Pro',
    category: 'Productivity',
    logoUrl: 'https://www.google.com/s2/favicons?domain=canva.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Pro',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 300,
          'Yearly': 2500,
        },
      ),
    ],
  ),

  // ==================== MICROSOFT 365 ====================
  PopularSubscription(
    name: 'Microsoft 365',
    category: 'Productivity',
    logoUrl: 'https://www.google.com/s2/favicons?domain=microsoft.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Personal',
        currency: 'PHP',
        priceByCycle: {'Yearly': 3350},
      ),
      SubscriptionPlan(
        name: 'Family',
        currency: 'PHP',
        priceByCycle: {'Yearly': 4890},
      ),
    ],
  ),

  // ==================== ICLOUD+ ====================
  PopularSubscription(
    name: 'iCloud+',
    category: 'Cloud Storage',
    logoUrl: 'https://www.google.com/s2/favicons?domain=icloud.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: '50GB',
        currency: 'PHP',
        priceByCycle: {'Monthly': 59},
      ),
      SubscriptionPlan(
        name: '200GB',
        currency: 'PHP',
        priceByCycle: {'Monthly': 199},
      ),
      SubscriptionPlan(
        name: '2TB',
        currency: 'PHP',
        priceByCycle: {'Monthly': 699},
      ),
    ],
  ),

  // ==================== GOOGLE ONE ====================
  PopularSubscription(
    name: 'Google One',
    category: 'Cloud Storage',
    logoUrl: 'https://www.google.com/s2/favicons?domain=one.google.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Basic 100GB',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 119,
          'Yearly': 889,
        },
      ),
      SubscriptionPlan(
        name: 'Standard 200GB',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 179,
          'Yearly': 1499,
        },
      ),
      SubscriptionPlan(
        name: 'Premium 2TB',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 599,
          'Yearly': 4799,
        },
      ),
    ],
  ),

  // ==================== CRUNCHYROLL ====================
  PopularSubscription(
    name: 'Crunchyroll',
    category: 'Entertainment',
    logoUrl: 'https://www.google.com/s2/favicons?domain=crunchyroll.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Fan',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 99,
          'Yearly': 699,
        },
      ),
      SubscriptionPlan(
        name: 'Mega Fan',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 119,
          'Yearly': 849,
        },
      ),
    ],
  ),

  // ==================== GRABUNLIMITED ====================
  PopularSubscription(
    name: 'GrabUnlimited',
    category: 'Shopping',
    logoUrl: 'https://www.google.com/s2/favicons?domain=grab.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Standard',
        currency: 'PHP',
        priceByCycle: {
          'Monthly': 88,
          'Semi-Annual': 408, // ₱68/mo equivalent
          'Yearly': 576,      // ₱48/mo equivalent
        },
      ),
    ],
  ),

  // ==================== PC GAME PASS ====================
  PopularSubscription(
    name: 'PC Game Pass',
    category: 'Gaming',
    logoUrl: 'https://www.google.com/s2/favicons?domain=xbox.com&sz=128',
    plans: [
      SubscriptionPlan(
        name: 'Monthly',
        currency: 'PHP',
        priceByCycle: {'Monthly': 225},
      ),
    ],
  ),
];