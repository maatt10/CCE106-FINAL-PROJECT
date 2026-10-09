class Subscription {
  String name;
  String planName;
  double price;
  String currency;
  String billingCycle;
  DateTime startDate;
  DateTime renewalDate;
  String category;

  String logoUrl;
  String? cardColor;
  String status; // 'active' | 'cancelled' | 'archived'

  Subscription({
    required this.name,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.startDate,
    required this.renewalDate,
    required this.category,
    this.planName = '',
    this.logoUrl = '',
    this.cardColor,
    this.status = 'active',
  });

  // ===== Status helpers =====
  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isArchived => status == 'archived';

  double get monthlyCost {
    switch (billingCycle) {
      case 'Weekly':
        return price * 52 / 12;
      case 'Monthly':
        return price;
      case 'Semi-Annual':
        return price / 6;
      case 'Yearly':
        return price / 12;
      default:
        return 0;
    }
  }

  double get yearlyCost {
    switch (billingCycle) {
      case 'Weekly':
        return price * 52;
      case 'Monthly':
        return price * 12;
      case 'Semi-Annual':
        return price * 2;
      case 'Yearly':
        return price;
      default:
        return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'planName': planName,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle,
      'startDate': startDate.toIso8601String(),
      'renewalDate': renewalDate.toIso8601String(),
      'category': category,
      'logoUrl': logoUrl,
      'cardColor': cardColor,
      'status': status,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      name: map['name'] ?? '',
      planName: map['planName'] ?? '',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      currency: map['currency'] ?? 'PHP',
      billingCycle: map['billingCycle'] ?? 'Monthly',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.parse(map['renewalDate']),
      renewalDate: DateTime.parse(map['renewalDate']),
      category: map['category'] ?? 'Other',
      logoUrl: map['logoUrl'] ?? '',
      cardColor: map['cardColor'],
      status: map['status'] ?? 'active',
    );
  }

  Subscription copyWithStatus(String newStatus) {
    return Subscription(
      name: name,
      planName: planName,
      price: price,
      currency: currency,
      billingCycle: billingCycle,
      startDate: startDate,
      renewalDate: renewalDate,
      category: category,
      logoUrl: logoUrl,
      cardColor: cardColor,
      status: newStatus,
    );
  }
}