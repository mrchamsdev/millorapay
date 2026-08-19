class ServiceModel {
  final int? id;
  final String name;

  ServiceModel({this.id, required this.name});

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
        name: json['name'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
      };
}
