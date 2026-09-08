class Branch {
  final String? id;
  final int? companyId;
  final String name;
  final String sector;
  final String location;
  final num? radius;
  final num? latitude;
  final num? longitude;

  Branch({
    this.id,
    this.companyId,
    required this.name,
    required this.sector,
    required this.location,
    this.radius,
    this.latitude,
    this.longitude,
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
          : num.tryParse(json['radius']?.toString() ?? ''),
      latitude: json['latitude'] is num
          ? json['latitude']
          : num.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? json['longitude']
          : num.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (companyId != null) 'companyId': companyId,
      'name': name,
      'sector': sector,
      'location': location,
      if (radius != null) 'radius': radius,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class Company {
  final int? id;
  final String? companyName;
  final String? legalEntityName;
  final String? companyType;
  final String? sector;
  final String? companyEmail;
  final String? companyPhone;
  final String? city;
  final String? country;
  final num? radius;
  final num? latitude;
  final num? longitude;
  final String? logo;
  final List<Branch> branches;

  Company({
    this.id,
    this.companyName,
    this.legalEntityName,
    this.companyType,
    this.sector,
    this.companyEmail,
    this.companyPhone,
    this.city,
    this.country,
    this.radius,
    this.latitude,
    this.longitude,
    this.logo,
    this.branches = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      companyName: json['companyName']?.toString(),
      legalEntityName: json['legalEntityName']?.toString(),
      companyType: json['companyType']?.toString(),
      sector: json['sector']?.toString(),
      companyEmail: json['companyEmail']?.toString(),
      companyPhone: json['companyPhone']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      radius: json['radius'] is num ? json['radius'] : num.tryParse(json['radius']?.toString() ?? ''),
      latitude: json['latitude'] is num ? json['latitude'] : num.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num ? json['longitude'] : num.tryParse(json['longitude']?.toString() ?? ''),
      logo: json['logo']?.toString(),
      branches: (json['branches'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Branch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'companyName': companyName,
      'legalEntityName': legalEntityName,
      'companyType': companyType,
      'sector': sector,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'city': city,
      'country': country,
      if (radius != null) 'radius': radius,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (logo != null) 'logo': logo,
      'branches': branches.map((e) => e.toJson()).toList(),
    };
  }
}
