class Subscription {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final DateTime renewalDate;
  final String category;
  final String? notes;
  final BillingPeriod billingPeriod;
  final SubscriptionStatus status; // New field
  final DateTime createdDate; // New field
  final DateTime? lastRenewDate; // New field for tracking renewals
  final int renewalCount; // New field to track how many times renewed

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.renewalDate,
    required this.category,
    this.notes,
    this.billingPeriod = BillingPeriod.monthly,
    this.status = SubscriptionStatus.active,
    DateTime? createdDate,
    this.lastRenewDate,
    this.renewalCount = 0,
  }) : createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'renewal_date': renewalDate.toIso8601String(),
      'category': category,
      'notes': notes,
      'billing_period': billingPeriod.name,
      'status': status.name,
      'created_date': createdDate.toIso8601String(),
      'last_renew_date': lastRenewDate?.toIso8601String(),
      'renewal_count': renewalCount,
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
      status: SubscriptionStatus.values.firstWhere(
        (status) => status.name == (map['status'] ?? 'active'),
        orElse: () => SubscriptionStatus.active,
      ),
      createdDate: DateTime.parse(map['created_date'] ?? DateTime.now().toIso8601String()),
      lastRenewDate: map['last_renew_date'] != null 
          ? DateTime.parse(map['last_renew_date']) 
          : null,
      renewalCount: map['renewal_count'] ?? 0,
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
  DateTime getNextRenewalDate([DateTime? fromDate]) {
    final baseDate = fromDate ?? renewalDate;
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      case BillingPeriod.quarterly:
        return DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
      case BillingPeriod.sixMonthly:
        return DateTime(baseDate.year, baseDate.month + 6, baseDate.day);
      case BillingPeriod.yearly:
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
    }
  }

  // Smart renewal date suggestion - if overdue, suggest next cycle from today
  DateTime getSmartRenewalDate() {
    final today = DateTime.now();
    final currentRenewal = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    
    if (currentRenewal.isAfter(today) || currentRenewal.isAtSameMomentAs(today)) {
      // Not overdue, suggest next cycle from current renewal date
      return getNextRenewalDate();
    } else {
      // Overdue, suggest next cycle from today
      DateTime nextFromToday = getNextRenewalDate(today);
      
      // If the suggested date is today or in the past, move it forward one more cycle
      while (nextFromToday.isBefore(today) || nextFromToday.isAtSameMomentAs(today)) {
        nextFromToday = getNextRenewalDate(nextFromToday);
      }
      
      return nextFromToday;
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

  // Get status display text with color
  String get statusDisplayText {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  // Check if subscription is overdue
  bool get isOverdue => status == SubscriptionStatus.active && daysUntilRenewal < 0;

  // Get total amount spent on this subscription
  double get totalAmountSpent {
    return amount * (renewalCount + 1); // +1 for initial subscription
  }

  // Get subscription duration in months
  int get subscriptionDurationInMonths {
    final now = DateTime.now();
    final duration = now.difference(createdDate);
    return (duration.inDays / 30).round();
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
    SubscriptionStatus? status,
    DateTime? createdDate,
    DateTime? lastRenewDate,
    int? renewalCount,
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
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      lastRenewDate: lastRenewDate ?? this.lastRenewDate,
      renewalCount: renewalCount ?? this.renewalCount,
    );
  }

  // Create a renewed version of this subscription
  Subscription createRenewed({
    required DateTime newRenewalDate,
    double? newAmount,
    String? newNotes,
  }) {
    return copyWith(
      renewalDate: newRenewalDate,
      amount: newAmount ?? amount,
      notes: newNotes ?? notes,
      lastRenewDate: DateTime.now(),
      renewalCount: renewalCount + 1,
    );
  }

  // Create a cancelled version of this subscription
  Subscription createCancelled({String? cancellationNotes}) {
    return copyWith(
      status: SubscriptionStatus.cancelled,
      notes: cancellationNotes ?? notes,
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

enum SubscriptionStatus {
  active,
  cancelled,
  paused,
  expired;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  bool get isActive => this == SubscriptionStatus.active;
  bool get isCancelled => this == SubscriptionStatus.cancelled;
}