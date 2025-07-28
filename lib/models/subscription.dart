class Subscription {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final DateTime renewalDate;
  final String category;
  final String? notes;
  final BillingPeriod billingPeriod; // New field

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.renewalDate,
    required this.category,
    this.notes,
    this.billingPeriod = BillingPeriod.monthly, // Default to monthly
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'renewal_date': renewalDate.toIso8601String(),
      'category': category,
      'notes': notes,
      'billing_period': billingPeriod.name, // Store as string
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      currency: map['currency'],
      renewalDate: DateTime.parse(map['renewal_date']),
      category: map['category'],
      notes: map['notes'],
      billingPeriod: BillingPeriod.values.firstWhere(
        (period) => period.name == (map['billing_period'] ?? 'monthly'),
        orElse: () => BillingPeriod.monthly,
      ),
    );
  }

  int get daysUntilRenewal {
    // Get today's date at midnight (start of day)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get renewal date at midnight (start of day)
    final renewal = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    
    // Calculate difference in days
    return renewal.difference(today).inDays;
  }

  // Convert subscription amount to monthly equivalent for calculations
  double get monthlyEquivalent {
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        return amount;
      case BillingPeriod.quarterly:
        return amount / 3;
      case BillingPeriod.sixMonthly:
        return amount / 6;
      case BillingPeriod.yearly:
        return amount / 12;
    }
  }

  // Get the next renewal date based on billing period
  DateTime getNextRenewalDate() {
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        return DateTime(renewalDate.year, renewalDate.month + 1, renewalDate.day);
      case BillingPeriod.quarterly:
        return DateTime(renewalDate.year, renewalDate.month + 3, renewalDate.day);
      case BillingPeriod.sixMonthly:
        return DateTime(renewalDate.year, renewalDate.month + 6, renewalDate.day);
      case BillingPeriod.yearly:
        return DateTime(renewalDate.year + 1, renewalDate.month, renewalDate.day);
    }
  }

  // Get display text for billing period
  String get billingPeriodDisplayText {
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        return '/month';
      case BillingPeriod.quarterly:
        return '/3 months';
      case BillingPeriod.sixMonthly:
        return '/6 months';
      case BillingPeriod.yearly:
        return '/year';
    }
  }

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    DateTime? renewalDate,
    String? category,
    String? notes,
    BillingPeriod? billingPeriod,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      renewalDate: renewalDate ?? this.renewalDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      billingPeriod: billingPeriod ?? this.billingPeriod,
    );
  }
}

enum BillingPeriod {
  monthly,
  quarterly,
  sixMonthly,
  yearly;

  String get displayName {
    switch (this) {
      case BillingPeriod.monthly:
        return 'Monthly';
      case BillingPeriod.quarterly:
        return 'Quarterly (3 months)';
      case BillingPeriod.sixMonthly:
        return 'Half Yearly (6 months)';
      case BillingPeriod.yearly:
        return 'Yearly';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case BillingPeriod.monthly:
        return 'Monthly';
      case BillingPeriod.quarterly:
        return 'Quarterly';
      case BillingPeriod.sixMonthly:
        return 'Half Yearly';
      case BillingPeriod.yearly:
        return 'Yearly';
    }
  }

  int get monthsCount {
    switch (this) {
      case BillingPeriod.monthly:
        return 1;
      case BillingPeriod.quarterly:
        return 3;
      case BillingPeriod.sixMonthly:
        return 6;
      case BillingPeriod.yearly:
        return 12;
    }
  }
}