import '../../units/models/unit_model.dart';
import '../../services/models/service_model.dart';

class ExpenseCategory {
  final int? id;
  final String name;
  final String? type;
  final String? icon;
  final dynamic quantity;
  final List<Unit>? units;
  final bool? service;
  final List<ServiceModel>? services;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  ExpenseCategory({
    this.id,
    required this.name,
    this.type,
    this.icon,
    this.quantity,
    this.units,
    this.service,
    this.services,
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
      quantity: json['quantity'],
      units: json['units'] != null ? (json['units'] as List).map((u) => Unit.fromJson(u)).toList() : null,
      service: json['service'],
      services: json['services'] != null ? (json['services'] as List).map((s) => ServiceModel.fromJson(s)).toList() : null,
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
      'quantity': quantity ?? false,
      if (units != null) 'units': units!.map((u) => {'id': u.id, 'name': u.name}).toList(),
      'service': service ?? false,
      if (services != null) 'services': services!.map((s) => {'id': s.id, 'name': s.name}).toList(),
    };
  }
}
