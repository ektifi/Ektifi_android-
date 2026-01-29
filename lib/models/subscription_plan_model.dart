class SubscriptionPlan {
  final int id;
  final String planType;
  final double price;
  final String validationMonth;
  final int noOfApplicationsAllowed;
  final String chatSystemAllowed;
  final String status;
  final int graceDays;
  final String createdAt;
  final String updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.planType,
    required this.price,
    required this.validationMonth,
    required this.noOfApplicationsAllowed,
    required this.chatSystemAllowed,
    required this.status,
    required this.graceDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int? ?? 0,
      planType: json['plan_type'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      validationMonth: json['validation_month'] as String? ?? '0',
      noOfApplicationsAllowed: json['no_of_applications_allowed'] as int? ?? 0,
      chatSystemAllowed: json['chat_system_allowed'] as String? ?? 'no',
      status: json['status'] as String? ?? 'inactive',
      graceDays: json['grace_days'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_type': planType,
      'price': price,
      'validation_month': validationMonth,
      'no_of_applications_allowed': noOfApplicationsAllowed,
      'chat_system_allowed': chatSystemAllowed,
      'status': status,
      'grace_days': graceDays,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isActive => status == 'active';
  bool get hasChatSystem => chatSystemAllowed.toLowerCase() == 'yes';
  
  String get formattedPrice {
    if (price == 0) {
      return 'Free';
    }
    return '₹${price.toStringAsFixed(0)}';
  }
  
  String get pricePerMonth {
    if (price == 0) {
      return 'Free';
    }
    var months = int.tryParse(validationMonth) ?? 1;
    if (months == 0) months = 1;
    final monthlyPrice = price / months;
    return '₹${monthlyPrice.toStringAsFixed(0)} / month';
  }
}

