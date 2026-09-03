import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/gold_api_constants.dart';
import '../../../core/network/gold_network_service.dart';
import '../models/branch_model.dart';

class BranchRepository {
  Future<List<Company>> getAllCompanies() async {
    final service = GoldGetService(
      GoldApiConstants.allCompanies,
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Companies GET Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }

        if (decodedData is List) {
          return decodedData.map((e) => Company.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (decodedData is Map && decodedData['data'] is List) {
          return (decodedData['data'] as List).map((e) => Company.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } catch (e, stack) {
        debugPrint('Error parsing companies: $e\n$stack');
      }
    }
    return [];
  }

  Future<bool> updateCompany(String id, Map<String, dynamic> payload) async {
    final service = GoldPutAuthService(
      GoldApiConstants.singleCompany(id),
      payload,
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    
    return statusCode >= 200 && statusCode < 300;
  }

  Future<bool> deleteCompany(String id) async {
    final service = GoldDeleteService(
      GoldApiConstants.deleteCompany(id),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    
    return statusCode >= 200 && statusCode < 300;
  }

  Future<Company?> getCompanyById(String id) async {
    final service = GoldGetService(
      GoldApiConstants.singleCompany(id),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }
        
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            return Company.fromJson(Map<String, dynamic>.from(decodedData['data']));
          }
          return Company.fromJson(decodedData);
        }
      } catch (e, stack) {
        debugPrint('Error parsing single company: $e\n$stack');
      }
    }
    return null;
  }

  Future<List<Branch>> getAllBranches({int? companyId}) async {
    final endpoint = companyId != null 
        ? '${GoldApiConstants.allBranches}?companyId=$companyId'
        : GoldApiConstants.allBranches;

    final service = GoldGetService(endpoint);

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Branches GET Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }

        if (decodedData is List) {
          return decodedData.map((e) => Branch.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (decodedData is Map && decodedData['data'] is List) {
          return (decodedData['data'] as List).map((e) => Branch.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } catch (e, stack) {
        debugPrint('Error parsing branches: $e\\n$stack');
      }
    }
    return [];
  }

  Future<bool> addBranch(Branch branch) async {
    final service = GoldPostAuthService(
      GoldApiConstants.branch,
      branch.toJson(),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    
    return statusCode >= 200 && statusCode < 300;
  }

  Future<bool> updateBranch(String id, Branch branch) async {
    final service = GoldPutAuthService( 
      GoldApiConstants.updateBranch(id),
      branch.toJson(),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    
    return statusCode >= 200 && statusCode < 300;
  }

  Future<bool> deleteBranch(String id) async {
    final service = GoldDeleteService(
      GoldApiConstants.deleteBranch(id),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    
    return statusCode >= 200 && statusCode < 300;
  }

  Future<Branch?> getBranchById(String id) async {
    final service = GoldGetService(
      GoldApiConstants.singleBranch(id),
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }
        
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            return Branch.fromJson(Map<String, dynamic>.from(decodedData['data']));
          }
          return Branch.fromJson(decodedData);
        }
      } catch (e, stack) {
        debugPrint('Error parsing single branch: $e\\n$stack');
      }
    }
    return null;
  }
}
