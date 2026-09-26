import '../../auth/models/auth_models.dart';

class User {
  final int? id;
  final String name;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? branch;
  final int? branchId;
  final List<String> branches;
  final List<int> branchIds;
  final String? gender;
  final String? accountStatus;
  final String? createdDate;
  final String? updatedDate;
  final int? createdBy;
  final List<String> modules;
  final List<UserAccessEntry> globalAccess;
  final List<CompanyAccess> userAccess;

  User({
    this.id,
    required this.name,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.role,
    this.branch,
    this.branchId,
    this.branches = const [],
    this.branchIds = const [],
    this.gender,
    this.accountStatus,
    this.createdDate,
    this.updatedDate,
    this.createdBy,
    this.modules = const [],
    this.globalAccess = const [],
    this.userAccess = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parsedBranches = [];
    List<int> parsedBranchIds = [];
    
    // Parse branch names
    if (json['multipleBranches'] is List) {
       for (var b in json['multipleBranches']) {
        if (b is Map) {
          if (b['name'] != null) parsedBranches.add(b['name'].toString());
          if (b['id'] != null) {
            parsedBranchIds.add(b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0);
          }
        } else {
          parsedBranches.add(b.toString());
        }
      }
    } else if (json['branches'] is List) {
       for (var b in json['branches']) {
        if (b is Map) {
          if (b['name'] != null) parsedBranches.add(b['name'].toString());
          if (b['id'] != null) {
            parsedBranchIds.add(b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0);
          }
        } else {
          parsedBranches.add(b.toString());
        }
      }
    } else if (json['branch'] is List) {
      for (var b in json['branch']) {
        if (b is Map) {
          if (b['name'] != null) parsedBranches.add(b['name'].toString());
          if (b['id'] != null) {
            parsedBranchIds.add(b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0);
          }
        } else {
          parsedBranches.add(b.toString());
        }
      }
    }

    // Parse branchIds from branchId or branchIds key
    if (json['branchId'] is List) {
      parsedBranchIds = (json['branchId'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    } else if (json['branchIds'] is List) {
      parsedBranchIds = (json['branchIds'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    }

    return User(
      id: json['id'],
      name: json['name'] ?? '',
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      branch: json['branch'] is Map ? json['branch']['name'] : (json['branch'] is List ? (parsedBranches.isNotEmpty ? parsedBranches.first : null) : json['branch']),
      branchId: json['branch'] is Map
          ? (json['branch']['id'] is int ? json['branch']['id'] : int.tryParse(json['branch']['id']?.toString() ?? ''))
          : (json['branchId'] is int ? json['branchId'] : int.tryParse(json['branchId']?.toString() ?? '')),
      branches: parsedBranches,
      branchIds: parsedBranchIds,
      gender: json['gender'],
      accountStatus: json['accountStatus'],
      createdDate: json['createdDate'] ?? json['createdAt'],
      updatedDate: json['updatedDate'] ?? json['updatedAt'],
      createdBy: json['createdBy'],
      modules: (json['modules'] as List?)?.map((e) => e.toString()).toList() ?? [],
      globalAccess: json['userAccess'] != null && json['userAccess'] is Map
          ? (json['userAccess']['globalAccess'] as List? ?? [])
              .map((e) => UserAccessEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      userAccess: (json['userAccess'] != null && json['userAccess'] is Map && json['userAccess']['companies'] is List)
          ? (json['userAccess']['companies'] as List)
              .map((e) => CompanyAccess.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : (json['companies'] is List
              ? (json['companies'] as List)
                  .map((e) => CompanyAccess.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : []),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (role != null) 'role': role,
        if (branchIds.isNotEmpty) 'branchId': branchIds else if (branchId != null) 'branchId': branchId,
        if (userAccess.isNotEmpty) 'companyId': userAccess.map((e) => e.companyId).toList(),
        if (gender != null) 'gender': gender,
        if (createdBy != null) 'createdBy': createdBy,
        'modules': modules,
        'userAccess': {
          'globalAccess': globalAccess.map((e) => e.toJson()).toList(),
          'companies': userAccess.map((e) => e.toJson()).toList(),
        },
      };
}
