class CompanyUserData {
  final int? id;
  final String? name;
  final String? email;

  CompanyUserData({
    this.id,
    this.name,
    this.email,
  });

  factory CompanyUserData.fromJson(Map<String, dynamic> json) {
    return CompanyUserData(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? json['_id']?.toString() ?? ''),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (email != null) 'email': email,
  };
}

class Branch {
  final String? id;
  final int? companyId;
  final String name;
  final String sector;
  final String? country;
  final String location;
  final num? radius;
  final num? latitude;
  final num? longitude;

  Branch({
    this.id,
    this.companyId,
    required this.name,
    required this.sector,
    this.country,
    required this.location,
    this.radius,
    this.latitude,
    this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['branchId']?.toString(),
      companyId: json['companyId'] is int ? json['companyId'] : int.tryParse(json['companyId']?.toString() ?? ''),
      name: json['name']?.toString() ?? json['branchName']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      country: json['country']?.toString(),
      location: json['location']?.toString() ?? json['city']?.toString() ?? '',
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
      if (country != null && country!.trim().isNotEmpty) 'country': country,
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
  final CompanyUserData? user;

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
    this.user,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? json['companyId']?.toString() ?? json['_id']?.toString() ?? ''),
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
      user: json['user'] is Map
          ? CompanyUserData.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
    );
  }

  Company copyWith({
    int? id,
    String? companyName,
    String? legalEntityName,
    String? companyType,
    String? sector,
    String? companyEmail,
    String? companyPhone,
    String? city,
    String? country,
    num? radius,
    num? latitude,
    num? longitude,
    String? logo,
    List<Branch>? branches,
    CompanyUserData? user,
  }) {
    return Company(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      companyType: companyType ?? this.companyType,
      sector: sector ?? this.sector,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      city: city ?? this.city,
      country: country ?? this.country,
      radius: radius ?? this.radius,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logo: logo ?? this.logo,
      branches: branches ?? this.branches,
      user: user ?? this.user,
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
      if (user != null) 'user': user!.toJson(),
    };
  }
}
