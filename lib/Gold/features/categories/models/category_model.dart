class ExpenseCategory {
  final int? id;
  final String name;
  final String? type;
  final String? icon;
  final List<dynamic>? quantity;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  ExpenseCategory({
    this.id,
    required this.name,
    this.type,
    this.icon,
    this.quantity,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'],
      icon: json['icon'],
      quantity: json['quantity'] is List ? List<dynamic>.from(json['quantity']) : null,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type ?? 'Personal',
      if (icon != null) 'icon': icon,
      'quantity': quantity ?? [],
    };
  }
}
