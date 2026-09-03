import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/auth_models.dart';

/// Single source of truth for the logged-in user's session.
///
/// Stores data both in memory (fast) and [SharedPreferences] (persistent).
/// Keys match those used by [GoldDioClient] for the auth token.
///
/// Usage anywhere in the app:
/// ```dart
/// final name  = GoldSession.instance.userName;
/// final email = GoldSession.instance.userEmail;
/// final id    = GoldSession.instance.userId;
/// final token = GoldSession.instance.token;
///
/// // Access control
/// if (GoldSession.instance.canRead('Gold')) { ... }
/// if (GoldSession.instance.canWrite('Gold')) { ... }
/// ```
class GoldSession {
  GoldSession._();
  static final GoldSession instance = GoldSession._();

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kToken               = 'auth_token';
  static const _kUserId              = 'user_id';
  static const _kUserName            = 'user_name';
  static const _kUserEmail           = 'user_email';
  static const _kUserPhone           = 'user_phone';
  static const _kCompanyType         = 'company_type';
  static const _kCompanyName         = 'company_name';
  static const _kUserAccess          = 'user_access'; // JSON-encoded list
  static const _kGlobalAccess        = 'global_access'; // JSON-encoded list
  static const _kPasswordChangedDate = 'password_changed_date';
  static const _kUserRole            = 'user_role';

  // ── In-memory cache ────────────────────────────────────────────────────────
  String? _token;
  int?    _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _companyType;
  String? _companyName;
  String? _passwordChangedDate;
  String? _userRole;
  List<UserAccessEntry> _globalAccess = [];
  List<CompanyAccess> _userAccess = [];

  // ── Getters ────────────────────────────────────────────────────────────────

  String? get token               => _token;
  int?    get userId              => _userId;
  String? get userName            => _userName;
  String? get userEmail           => _userEmail;
  String? get userPhone           => _userPhone;
  String? get companyType         => _companyType;
  String? get companyName         => _companyName;
  String? get passwordChangedDate => _passwordChangedDate;
  String? get userRole            => _userRole;

  /// Full list of module access entries for the logged-in user.
  List<UserAccessEntry> get globalAccess => List.unmodifiable(_globalAccess);
  List<CompanyAccess> get userAccess => List.unmodifiable(_userAccess);

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  bool _isGlobalModule(String module) {
    final lower = module.toLowerCase();
    return lower != 'expenses' && lower != 'users';
  }

  /// Returns true if the user has READ access to [module].
  /// If it is a global module, returns true.
  /// If [branchId] is provided, checks access for that specific branch.
  /// If [branchId] is null, returns true if the user has read access in ANY branch.
  bool canRead(String module, {int? branchId}) {
    // 1. Check globalAccess
    final globalEntry = _globalAccess.where((e) => e.module.toLowerCase() == module.toLowerCase()).firstOrNull;
    if (globalEntry != null && (globalEntry.read || globalEntry.write)) return true;

    if (_isGlobalModule(module)) return true; // Legacy fallback
    
    if (branchId == null) {
      return getAccessibleBranchesForModule(module).isNotEmpty;
    }
    
    final entry = _findEntry(module, branchId);
    return (entry?.read ?? false) || (entry?.write ?? false);
  }

  /// Returns true if the user has WRITE access to [module].
  bool canWrite(String module, {int? branchId}) {
    // 1. Check globalAccess
    final globalEntry = _globalAccess.where((e) => e.module.toLowerCase() == module.toLowerCase()).firstOrNull;
    if (globalEntry != null && globalEntry.write) return true;

    if (_isGlobalModule(module)) return true; // Legacy fallback
    
    if (branchId == null) {
      return _userAccess.any((company) {
        return company.branches.any((branch) {
          final entry = _findEntry(module, branch.branchId);
          return entry?.write ?? false;
        });
      });
    }
    
    final entry = _findEntry(module, branchId);
    return entry?.write ?? false;
  }

  /// Returns a list of branches where the user has read or write access for the given [module].
  List<BranchAccess> getAccessibleBranchesForModule(String module) {
    if (_isGlobalModule(module)) {
      // Return all branches across all companies
      return _userAccess.expand((company) => company.branches).toList();
    }

    return _userAccess.expand((company) => company.branches).where((branch) {
      try {
        final entry = branch.access.firstWhere((e) => e.module.toLowerCase() == module.toLowerCase());
        return entry.read || entry.write;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Returns a list of branch IDs where the user has read access for the given [module].
  /// Returns null if the user is an Admin and should bypass filtering.
  List<int>? getBranchIdsForCharts(String module) {
    if (userRole?.toLowerCase().contains('admin') == true) {
      return null;
    }

    return _userAccess.expand((company) => company.branches).where((branch) {
      try {
        final entry = branch.access.firstWhere((e) => e.module.toLowerCase() == module.toLowerCase());
        return entry.read;
      } catch (_) {
        return false;
      }
    }).map((b) => b.branchId).toList();
  }

  /// Returns a list of branch IDs where the user has read access for the given [module].
  /// Returns null if the user is an Admin and should bypass filtering.
  List<int>? getBranchIdsForReports(String module) {
    if (userRole?.toLowerCase().contains('admin') == true) {
      return null;
    }

    return _userAccess.expand((company) => company.branches).where((branch) {
      try {
        final entry = branch.access.firstWhere((e) => e.module.toLowerCase() == module.toLowerCase());
        return entry.read;
      } catch (_) {
        return false;
      }
    }).map((b) => b.branchId).toList();
  }

  UserAccessEntry? _findEntry(String module, int branchId) {
    try {
      final allBranches = _userAccess.expand((company) => company.branches);
      final branch = allBranches.firstWhere((b) => b.branchId == branchId);
      return branch.access.firstWhere(
        (e) => e.module.toLowerCase() == module.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Save session after login ───────────────────────────────────────────────

  /// Dynamically updates the user's access list and persists it.
  Future<void> updateUserAccess(List<CompanyAccess> newAccess, [List<UserAccessEntry>? globalAccess]) async {
    int? currentTopCompanyId;
    if (_userAccess.isNotEmpty) {
      currentTopCompanyId = _userAccess.first.companyId;
    }

    _userAccess = List.from(newAccess);

    if (currentTopCompanyId != null) {
      final index = _userAccess.indexWhere((c) => c.companyId == currentTopCompanyId);
      if (index > 0) {
        final selected = _userAccess.removeAt(index);
        _userAccess.insert(0, selected);
      }
    }

    final accessJson = jsonEncode(_userAccess.map((e) => e.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserAccess, accessJson);

    if (globalAccess != null) {
      _globalAccess = List.from(globalAccess);
      final globalJson = jsonEncode(_globalAccess.map((e) => e.toJson()).toList());
      await prefs.setString(_kGlobalAccess, globalJson);
    }

    if (kDebugMode) debugPrint('[GoldSession] 🔄 User access updated: ${_userAccess.length} modules');
  }

  /// Manually sets a company as the active top company
  Future<void> setActiveCompany(int companyId) async {
    final index = _userAccess.indexWhere((c) => c.companyId == companyId);
    if (index > 0) {
      final selected = _userAccess.removeAt(index);
      _userAccess.insert(0, selected);
      
      final accessJson = jsonEncode(_userAccess.map((e) => e.toJson()).toList());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserAccess, accessJson);
    }
  }

  /// Call this immediately after a successful login.
  /// Writes all fields to memory and [SharedPreferences].
  Future<void> save({
    required String token,
    required int    userId,
    required String userName,
    required String userEmail,
    String? userPhone,
    String? companyType,
    String? companyName,
    String? passwordChangedDate,
    String? userRole,
    List<UserAccessEntry> globalAccess = const [],
    List<CompanyAccess> userAccess = const [],
  }) async {
    // Memory
    _token               = token;
    _userId              = userId;
    _userName            = userName;
    _userEmail           = userEmail;
    _userPhone           = userPhone;
    _companyType         = companyType;
    _companyName         = companyName;
    _passwordChangedDate = passwordChangedDate;
    _userRole            = userRole;
    _globalAccess        = List.from(globalAccess);
    _userAccess          = List.from(userAccess);

    // Serialise userAccess → JSON string for persistence
    final globalJson = jsonEncode(globalAccess.map((e) => e.toJson()).toList());
    final accessJson = jsonEncode(userAccess.map((e) => e.toJson()).toList());

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,    token);
    await prefs.setInt   (_kUserId,   userId);
    await prefs.setString(_kUserName, userName);
    await prefs.setString(_kUserEmail, userEmail);
    if (userPhone           != null) await prefs.setString(_kUserPhone,           userPhone);
    if (companyType         != null) await prefs.setString(_kCompanyType,         companyType);
    if (companyName         != null) await prefs.setString(_kCompanyName,         companyName);
    if (passwordChangedDate != null) await prefs.setString(_kPasswordChangedDate, passwordChangedDate);
    if (userRole            != null) await prefs.setString(_kUserRole,            userRole);
    await prefs.setString(_kGlobalAccess, globalJson);
    await prefs.setString(_kUserAccess, accessJson);

    if (kDebugMode) {
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════');
      debugPrint('║ 💾 SESSION SAVED');
      debugPrint('║   userId      : $userId');
      debugPrint('║   userName    : $userName');
      debugPrint('║   userEmail   : $userEmail');
      debugPrint('║   userPhone   : $userPhone');
      debugPrint('║   companyType : $companyType');
      debugPrint('║   companyName : $companyName');
      debugPrint('║   userRole    : $userRole');
      debugPrint('║   userAccess : ${_userAccess.length} branches');
      debugPrint('╚══════════════════════════════════════════════════════════');
    }
  }

  // ── Load session on app start ──────────────────────────────────────────────

  /// Called during startup to restore session from [SharedPreferences].
  /// Returns true if a valid token was found.
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token               = prefs.getString(_kToken);
    _userId              = prefs.getInt(_kUserId);
    _userName            = prefs.getString(_kUserName);
    _userEmail           = prefs.getString(_kUserEmail);
    _userPhone           = prefs.getString(_kUserPhone);
    _companyType         = prefs.getString(_kCompanyType);
    _companyName         = prefs.getString(_kCompanyName);
    _passwordChangedDate = prefs.getString(_kPasswordChangedDate);
    _userRole            = prefs.getString(_kUserRole);

    // Restore userAccess from JSON
    final globalJson = prefs.getString(_kGlobalAccess);
    if (globalJson != null && globalJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(globalJson) as List;
        _globalAccess = decoded
            .whereType<Map>()
            .map((e) => UserAccessEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _globalAccess = [];
      }
    }

    final accessJson = prefs.getString(_kUserAccess);
    if (accessJson != null && accessJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(accessJson) as List;
        _userAccess = decoded
            .whereType<Map>()
            .map((e) => CompanyAccess.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _userAccess = [];
      }
    }

    if (kDebugMode && isLoggedIn) {
      debugPrint('[GoldSession] ✅ Session restored → userId: $_userId, name: $_userName, modules: ${_userAccess.length}');
    }
    return isLoggedIn;
  }

  // ── Clear on logout ────────────────────────────────────────────────────────

  /// Wipes memory + SharedPreferences. Call on logout.
  Future<void> clear() async {
    _token               = null;
    _userId              = null;
    _userName            = null;
    _userEmail           = null;
    _userPhone           = null;
    _companyType         = null;
    _companyName         = null;
    _passwordChangedDate = null;
    _userRole            = null;
    _globalAccess        = [];
    _userAccess          = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserPhone);
    await prefs.remove(_kCompanyType);
    await prefs.remove(_kCompanyName);
    await prefs.remove(_kPasswordChangedDate);
    await prefs.remove(_kUserRole);
    await prefs.remove(_kGlobalAccess);
    await prefs.remove(_kUserAccess);

    debugPrint('[GoldSession] 🗑️  Session cleared.');
  }
}
