class FoodItem {
  final String id;
  final String name;
  final String quantity;
  final DateTime expiryDate;
  final DateTime createdAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    required this.createdAt,
  });

  // Create a food item from JSON
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      expiryDate: DateTime.parse(json['expiryDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert food item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
