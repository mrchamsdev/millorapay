import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/gold_dio_client.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final Dio _dio = GoldDioClient.instance.dio;

  Future<List<ServiceModel>> getAllServices({String? search}) async {
    try {
      final query = search != null && search.isNotEmpty ? {'search': search} : null;
      if (kDebugMode) debugPrint('🌐 GET ALL SERVICES: /service ${query ?? ''}');

      final response = await _dio.get('/service', queryParameters: query);
      if (response.statusCode == 200 && response.data != null) {
        dynamic responseData = response.data['data'] ?? response.data;
        if (responseData is List) {
          return responseData.map((json) => ServiceModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET ALL SERVICES ERROR: $e');
      return [];
    }
  }

  Future<String?> createService(ServiceModel service) async {
    try {
      final payload = service.toJson();
      if (kDebugMode) debugPrint('🌐 CREATE SERVICE: /service $payload');

      final response = await _dio.post('/service', data: payload);
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to create service.';
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE SERVICE ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE SERVICE ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> updateService(int id, ServiceModel service) async {
    try {
      final payload = service.toJson();
      if (kDebugMode) debugPrint('🌐 UPDATE SERVICE: /service/$id $payload');

      final response = await _dio.put('/service/$id', data: payload);
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to update service.';
        }
      }

      if (response.statusCode == 200) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE SERVICE ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE SERVICE ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> deleteService(int id) async {
    try {
      if (kDebugMode) debugPrint('🌐 DELETE SERVICE: /service/$id');

      final response = await _dio.delete('/service/$id');
      
      if (response.data != null && response.data is Map) {
        final resData = response.data;
        if (resData['status'] == 'error') {
           return resData['message']?.toString() ?? 'Failed to delete service.';
        }
      }

      if (response.statusCode == 200) return null;
      return 'Unknown error occurred';
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE SERVICE ERROR: ${e.response?.data}');
      return e.response?.data?['message'] ?? e.message ?? 'Network error occurred.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE SERVICE ERROR: $e');
      return e.toString();
    }
  }
}
