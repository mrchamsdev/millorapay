import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/gold_dio_client.dart';
import '../models/unit_model.dart';

class UnitRepository {
  final Dio _dio = GoldDioClient.instance.dio;

  Future<List<Unit>> getAllUnits({String? search}) async {
    try {
      final query = search != null && search.isNotEmpty ? {'search': search} : null;
      if (kDebugMode) debugPrint('🌐 GET ALL UNITS: /unit ${query ?? ''}');

      final response = await _dio.get('/unit', queryParameters: query);
      if (response.statusCode == 200 && response.data != null) {
        dynamic responseData = response.data['data'] ?? response.data;
        if (responseData is List) {
          return responseData.map((json) => Unit.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET ALL UNITS ERROR: $e');
      return [];
    }
  }

  Future<String?> createUnit(Unit unit) async {
    try {
      final payload = unit.toJson();
      if (kDebugMode) debugPrint('🌐 CREATE UNIT: /unit $payload');

      final response = await _dio.post('/unit', data: payload);
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to create unit.';
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE UNIT ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE UNIT ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> updateUnit(int id, Unit unit) async {
    try {
      final payload = unit.toJson();
      if (kDebugMode) debugPrint('🌐 UPDATE UNIT: /unit/$id $payload');

      final response = await _dio.put('/unit/$id', data: payload);
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to update unit.';
        }
      }

      if (response.statusCode == 200) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE UNIT ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE UNIT ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> deleteUnit(int id) async {
    try {
      if (kDebugMode) debugPrint('🌐 DELETE UNIT: /unit/$id');

      final response = await _dio.delete('/unit/$id');
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to delete unit.';
        }
      }

      if (response.statusCode == 200) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE UNIT ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE UNIT ERROR: $e');
      return e.toString();
    }
  }
}
