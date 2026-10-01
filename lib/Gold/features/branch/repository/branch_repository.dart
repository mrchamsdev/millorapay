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
        } else if (decodedData is Map) {
          final list = decodedData['data'] ?? decodedData['companies'] ?? decodedData['result'];
          if (list is List) {
            return list.map((e) => Company.fromJson(Map<String, dynamic>.from(e))).toList();
          }
        }
      } catch (e, stack) {
        debugPrint('Error parsing companies: $e\n$stack');
      }
    }
    return [];
  }

  Future<(List<Company>, List<Branch>)?> getCompanyAndBranchList() async {
    final service = GoldGetService(
      GoldApiConstants.companyListAll,
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Company List All GET Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }

        Map<String, dynamic>? dataMap;
        if (decodedData is Map) {
          final rawData = decodedData['data'];
          if (rawData is Map) {
            dataMap = Map<String, dynamic>.from(rawData);
          } else {
            dataMap = Map<String, dynamic>.from(decodedData);
          }
        }

        if (dataMap != null) {
          List<Company> companies = [];
          List<Branch> branches = [];

          final rawCompanies = dataMap['companies'] ?? dataMap['company'];
          if (rawCompanies is List) {
            companies = rawCompanies
                .whereType<Map>()
                .map((e) => Company.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          final rawBranches = dataMap['branches'] ?? dataMap['branch'];
          if (rawBranches is List) {
            branches = rawBranches
                .whereType<Map>()
                .map((e) => Branch.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          return (companies, branches);
        }
      } catch (e, stack) {
        debugPrint('Error parsing company list all: $e\n$stack');
      }
    }
    return null;
  }

  Future<(bool, String?)> createCompany(Map<String, dynamic> payload) async {
    final service = GoldPostAuthService(
      GoldApiConstants.addCompany,
      payload,
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Create Company POST Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      return (true, null);
    } else {
      String? errorMessage;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message']?.toString();
      }
      return (false, errorMessage ?? 'Failed to create company');
    }
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

  Future<(bool, String?, Company?)> updateCompanyWithLogo(
    String id,
    Map<String, dynamic> payload, {
    String? logoPath,
  }) async {
    final service = GoldPutMultipartAuthService(
      url: GoldApiConstants.singleCompany(id),
      fields: payload,
      filePath: logoPath,
      fileFieldName: 'logo',
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Update Company PUT Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      Company? updatedCompany;
      try {
        dynamic decoded = data;
        if (data is String) decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final companyData = decoded['data'] ?? decoded['company'] ?? decoded;
          if (companyData is Map<String, dynamic>) {
            updatedCompany = Company.fromJson(companyData);
          }
        }
      } catch (_) {}
      return (true, null, updatedCompany);
    } else {
      String? errorMessage;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message']?.toString();
      }
      return (false, errorMessage ?? 'Failed to update company', null);
    }
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

  Future<List<String>> getAllSectors() async {
    final service = GoldGetService(
      GoldApiConstants.allSectors,
    );

    final result = await service.data();
    final statusCode = result[0] as int;
    final data = result[1];

    debugPrint('Sectors GET Response ($statusCode): $data');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        dynamic decodedData = data;
        if (data is String) {
          decodedData = jsonDecode(data);
        }

        List rawList = [];
        if (decodedData is List) {
          rawList = decodedData;
        } else if (decodedData is Map) {
          final list = decodedData['data'] ??
              decodedData['sectors'] ??
              decodedData['result'] ??
              decodedData['items'];
          if (list is List) {
            rawList = list;
          }
        }

        final Set<String> sectorSet = {};
        for (final item in rawList) {
          if (item is String && item.trim().isNotEmpty) {
            sectorSet.add(item.trim());
          } else if (item is Map) {
            final name = item['sectorName'] ??
                item['name'] ??
                item['sector'] ??
                item['title'] ??
                item['label'];
            if (name != null && name.toString().trim().isNotEmpty) {
              sectorSet.add(name.toString().trim());
            }
          }
        }
        return sectorSet.toList();
      } catch (e, stack) {
        debugPrint('Error parsing sectors: $e\n$stack');
      }
    }
    return [];
  }
}
