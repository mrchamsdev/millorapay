// ── Auth Request Models ───────────────────────────────────────────────────────

/// POST http://localhost:7000/api/users
/// Payload: { email, name, phoneNumber, companyType, companyName }
class RegisterRequest {
  final String email;
  final String name;
  final String phoneNumber;
  final String companyType; // "Individual" | "Company"
  final String companyName;

  const RegisterRequest({
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.companyType,
    required this.companyName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'companyType': companyType,
        'companyName': companyName,
      };
}

class LoginRequest {
  final String email;
  final String passWord; // field name matches API: passWord

  const LoginRequest({required this.email, required this.passWord});

  /// Maps to the exact payload the API expects → POST users/login
  Map<String, dynamic> toJson() => {
        'email': email,
        'passWord': passWord,
      };
}

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyOtpRequest {
  final String email;
  final String confirmationCode;

  const VerifyOtpRequest({required this.email, required this.confirmationCode});

  Map<String, dynamic> toJson() => {
        'email': email,
        'confirmationCode': confirmationCode,
      };
}

class ResetPasswordRequest {
  final String email;
  final String newPassword;
  final String confirmNewPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      };
}

class SetPasswordRequest {
  final String email;
  final String temporaryPassword;
  final String newPassword;

  const SetPasswordRequest({
    required this.email,
    required this.temporaryPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'temporaryPassword': temporaryPassword,
        'newPassword': newPassword,
      };
}

/// Typed response for POST /users/login
///
/// Real API response shape:
/// ```json
/// {
///   "status": "success",
///   "token": "<jwt>",
///   "user": {
///     "id": 12, "name": "Naveen",
///     "userAccess": [{"read": true, "write": false, "module": "Gold"}, ...]
///   }
/// }
/// ```
class UserAccessEntry {
  final String module;
  final bool read;
  final bool write;

  const UserAccessEntry({required this.module, required this.read, required this.write});

  factory UserAccessEntry.fromJson(Map<String, dynamic> json) => UserAccessEntry(
        module: json['module']?.toString() ?? '',
        read:   json['read'] == true,
        write:  json['write'] == true,
      );

  Map<String, dynamic> toJson() => {'module': module, 'read': read, 'write': write};
}

class BranchAccess {
  final int branchId;
  final String branchName;
  final List<UserAccessEntry> access;

  const BranchAccess({
    required this.branchId,
    required this.branchName,
    required this.access,
  });

  factory BranchAccess.fromJson(Map<String, dynamic> json) {
    return BranchAccess(
      branchId: json['branchId'] is int
          ? json['branchId'] as int
          : int.tryParse(json['branchId']?.toString() ?? '') ?? 0,
      branchName: json['branchName']?.toString() ?? '',
      access: (json['access'] as List? ?? [])
          .whereType<Map>()
          .map((e) => UserAccessEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'branchId': branchId,
        'branchName': branchName,
        'access': access.map((e) => e.toJson()).toList(),
      };
}

class CompanyAccess {
  final int companyId;
  final String companyName;
  final String? sector;
  final List<BranchAccess> branches;

  const CompanyAccess({
    required this.companyId,
    required this.companyName,
    this.sector,
    required this.branches,
  });

  factory CompanyAccess.fromJson(Map<String, dynamic> json) {
    return CompanyAccess(
      companyId: json['companyId'] is int
          ? json['companyId'] as int
          : (int.tryParse(json['companyId']?.toString() ?? json['id']?.toString() ?? '') ?? 0),
      companyName: json['companyName']?.toString() ?? json['name']?.toString() ?? '',
      sector: json['sector']?.toString(),
      branches: (json['branches'] as List? ?? [])
          .whereType<Map>()
          .map((e) => BranchAccess.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'companyName': companyName,
        if (sector != null) 'sector': sector,
        'branches': branches.map((e) => e.toJson()).toList(),
      };
}

class LoginResponse {
  final String? token;        // root-level JWT — used for Bearer auth
  final int?    userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? companyType;
  final String? companyName;
  final String? accountStatus;
  final String? passwordChangedDate; // ISO-8601 from API
  final String? role;
  final List<UserAccessEntry> globalAccess;
  final List<CompanyAccess> userAccess;

  const LoginResponse({
    this.token,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.companyType,
    this.companyName,
    this.accountStatus,
    this.passwordChangedDate,
    this.role,
    this.globalAccess = const [],
    this.userAccess = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Token lives at the root level
    final token = json['token']?.toString();

    // User object
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};

    final userId = userMap['id'] is int
        ? userMap['id'] as int
        : int.tryParse(userMap['id']?.toString() ?? '');

    // Parse userAccess object (globalAccess and branches)
    List<UserAccessEntry> globalList = [];
    List<CompanyAccess> accessList = [];
    
    if (userMap['userAccess'] is Map) {
      final accessMap = userMap['userAccess'] as Map;
      globalList = (accessMap['globalAccess'] as List? ?? [])
          .whereType<Map>()
          .map((e) => UserAccessEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      accessList = (accessMap['companies'] as List? ?? [])
          .whereType<Map>()
          .map((e) => CompanyAccess.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (userMap['userAccess'] is List) {
      // Fallback for old format
      accessList = [];
    }

    return LoginResponse(
      token:               token,
      userId:              userId,
      userName:            userMap['name']?.toString(),
      userEmail:           userMap['email']?.toString(),
      userPhone:           userMap['phoneNumber']?.toString(),
      companyType:         userMap['companyType']?.toString(),
      companyName:         userMap['companyName']?.toString(),
      accountStatus:       userMap['accountStatus']?.toString(),
      passwordChangedDate: userMap['passwordChangedDate']?.toString(),
      role:                userMap['role']?.toString(),
      globalAccess:        globalList,
      userAccess:          accessList,
    );
  }

  bool get hasToken => token != null && token!.isNotEmpty;
}

/// Generic API response wrapper with error extraction helper.
class ApiResponse {
  final int statusCode;
  final dynamic body;

  const ApiResponse({required this.statusCode, required this.body});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Extracts a human-readable message from the API response body.
  String extractMessage(String fallback) {
    if (body is Map) {
      final map = body as Map;
      return (map['message'] ?? map['error'] ?? _firstError(map) ?? fallback)
          .toString();
    }
    return fallback;
  }

  String? _firstError(Map map) {
    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) {
      return errors.values.first.toString();
    }
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    return null;
  }
}
