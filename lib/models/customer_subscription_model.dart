class CustomerSubscriptionModel {
  final String id;
  final String name;
  final String phone;
  final String carModel;
  final String carPlate;
  final String currentPlan;
  final DateTime? subscriptionEndDate;
  final DateTime? lastSubscriptionDate;
  final bool isSubscriptionActive;

  CustomerSubscriptionModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.carModel,
    required this.carPlate,
    required this.currentPlan,
    this.subscriptionEndDate,
    this.lastSubscriptionDate,
    required this.isSubscriptionActive,
  });

  factory CustomerSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return CustomerSubscriptionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      carModel: json['car_model'] ?? '',
      carPlate: json['car_plate'] ?? '',
      currentPlan: json['current_plan'] ?? '',
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'])
          : null,
      lastSubscriptionDate: json['last_subscription_date'] != null
          ? DateTime.parse(json['last_subscription_date'])
          : null,
      isSubscriptionActive: json['is_subscription_active'] ?? false,
    );
  }
}
