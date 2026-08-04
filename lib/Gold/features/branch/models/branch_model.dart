class Branch {
  final String? id;
  final int? companyId;
  final String name;
  final String sector;
  final String location;
  final num radius;
  final num latitude;
  final num longitude;

  Branch({
    this.id,
    this.companyId,
    required this.name,
    required this.sector,
    required this.location,
    required this.radius,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      companyId: json['companyId'] is int ? json['companyId'] : int.tryParse(json['companyId']?.toString() ?? ''),
      name: json['name'] ?? '',
      sector: json['sector'] ?? '',
      location: json['location'] ?? '',
      radius: json['radius'] is num
          ? json['radius']
          : (num.tryParse(json['radius']?.toString() ?? '0') ?? 0),
      latitude: json['latitude'] is num
          ? json['latitude']
          : (num.tryParse(json['latitude']?.toString() ?? '0') ?? 0),
      longitude: json['longitude'] is num
          ? json['longitude']
          : (num.tryParse(json['longitude']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (companyId != null) 'companyId': companyId,
      'name': name,
      'sector': sector,
      'location': location,
      'radius': radius,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
