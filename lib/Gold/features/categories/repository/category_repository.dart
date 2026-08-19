import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/gold_api_constants.dart';
import '../../../core/network/gold_dio_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final Dio _dio = GoldDioClient.instance.dio;

  /// Fetch all expense categories
  /// GET /api/expenseCategory
  Future<List<ExpenseCategory>> getCategories() async {
    try {
      final url = GoldApiConstants.expenseCategory;
      if (kDebugMode) debugPrint('🌐 GET CATEGORIES: $url');
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ExpenseCategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET CATEGORIES ERROR: $e');
      rethrow;
    }
  }

  /// Fetch a single category by ID
  /// GET /api/expenseCategory/:id
  Future<ExpenseCategory?> getCategoryById(int id) async {
    try {
      final url = GoldApiConstants.expenseCategoryById(id.toString());
      if (kDebugMode) debugPrint('🌐 GET CATEGORY BY ID: $url');
      
      final response = await _dio.get(url);
      
      if (kDebugMode) debugPrint('📦 GET CATEGORY BY ID RESPONSE: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return ExpenseCategory.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET CATEGORY BY ID ERROR: $e');
      rethrow;
    }
  }

  /// Create a new category (2-step flow)
  /// Step 1: POST text data as application/json
  /// Step 2: PUT icon file as multipart/form-data if filePath is provided
  Future<bool> createCategory(ExpenseCategory category, {String? filePath}) async {
    try {
      final url = GoldApiConstants.expenseCategory;
      // Step 1: Send text data as standard JSON
      final payload = category.toJson();

      if (kDebugMode) {
        debugPrint('🌐 CREATE CATEGORY (Step 1 - JSON POST): $url');
        debugPrint('📦 PAYLOAD: $payload');
      }

      final response = await _dio.post(url, data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Step 2: If file is selected, trigger PUT call with FormData
        if (filePath != null && filePath.isNotEmpty && response.data != null) {
          final data = response.data['data'];
          final id = data != null ? (data['id'] ?? data['_id']) : null;
          if (id != null) {
            final categoryId = int.tryParse(id.toString());
            if (categoryId != null) {
              await uploadCategoryIcon(categoryId, filePath);
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE CATEGORY ERROR: $e');
      return false;
    }
  }

  /// Upload category icon via PUT (multipart/form-data)
  Future<bool> uploadCategoryIcon(int id, String filePath) async {
    try {
      final url = GoldApiConstants.expenseCategoryById(id.toString());
      final formData = FormData.fromMap({
        'icon': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      if (kDebugMode) {
        debugPrint('🌐 UPLOAD CATEGORY ICON (Step 2 - PUT FormData): $url');
        debugPrint('📁 FILE PATH: $filePath');
      }

      final response = await _dio.put(url, data: formData);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPLOAD CATEGORY ICON ERROR: $e');
      return false;
    }
  }

  /// Update an existing category
  /// PUT /api/expenseCategory/:id
  Future<bool> updateCategory(int id, ExpenseCategory category, {String? filePath}) async {
    try {
      final url = GoldApiConstants.expenseCategoryById(id.toString());
      
      // Step 1: Send text data as standard JSON
      final payload = category.toJson();

      if (kDebugMode) {
        debugPrint('🌐 UPDATE CATEGORY (JSON): $url');
        debugPrint('📦 PUT PAYLOAD: $payload');
      }

      final response = await _dio.put(url, data: payload);
      
      if (kDebugMode) {
        debugPrint('📦 UPDATE CATEGORY RESPONSE: ${response.data}');
      }
      
      if (response.statusCode == 200) {
        // Step 2: If a new file is selected, trigger uploadCategoryIcon
        if (filePath != null && filePath.isNotEmpty) {
          final iconSuccess = await uploadCategoryIcon(id, filePath);
          return iconSuccess;
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE CATEGORY ERROR: $e');
      return false;
    }
  }

  /// Soft delete a category
  /// DELETE /api/expenseCategory/:id
  Future<bool> deleteCategory(int id) async {
    try {
      final url = GoldApiConstants.expenseCategoryById(id.toString());
      if (kDebugMode) debugPrint('🌐 DELETE CATEGORY: $url');

      final response = await _dio.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE CATEGORY ERROR: $e');
      return false;
    }
  }
}
