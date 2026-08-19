class Unit {
  final int? id;
  final String name;

  Unit({this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
        name: json['name'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
      };
}
