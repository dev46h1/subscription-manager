class Subscription {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final DateTime renewalDate;
  final String category;
  final String? notes;

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.renewalDate,
    required this.category,
    this.notes,
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

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    DateTime? renewalDate,
    String? category,
    String? notes,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      renewalDate: renewalDate ?? this.renewalDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}