import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense_model.dart';
import '../../../core/network/gold_dio_client.dart';

class ExpenseRepository {
  final Dio _dio = GoldDioClient.instance.dio;

  /// Fetch all expenses grouped by month
  /// GET /api/expense/all
  Future<List<ExpenseMonthGroup>> getAllExpenses() async {
    try {
      const url = '/expense/all';
      if (kDebugMode) debugPrint('🌐 GET ALL EXPENSES: $url');
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((json) => ExpenseMonthGroup.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET ALL EXPENSES ERROR: $e');
      rethrow;
    }
  }

  /// Fetch a single expense by ID
  /// GET /api/expense/:id
  Future<Expense?> getExpenseById(int id) async {
    try {
      final url = '/expense/$id';
      if (kDebugMode) debugPrint('🌐 GET EXPENSE BY ID: $url');
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final expense = Expense.fromJson(response.data['data']);
        _cleanHistory(expense);
        return expense;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET EXPENSE BY ID ERROR: $e');
      rethrow;
    }
  }

  /// Create a new expense record
  /// POST /api/expense
  Future<Expense?> createExpense({
    required int expenseCategoryId,
    required int companyId,
    required String expenseDate,
    required double amount,
    required String amountType,
    required String description,
    String? comment,
    String? note,
    int? paidBy,
    int? branchId,
    String? quantity,
    String? service,
  }) async {
    try {
      const url = '/expense';
      final payload = {
        'expenseCategoryId': expenseCategoryId,
        'companyId': companyId,
        'expenseDate': expenseDate,
        'amount': amount,
        'amountType': amountType,
        'description': description,
        if (comment != null) 'comment': comment,
        if (note != null) 'note': note,
        if (paidBy != null) 'paidBy': paidBy,
        if (branchId != null) 'branchId': branchId,
        if (quantity != null) 'quantity': quantity,
        if (service != null) 'service': service,
      };
      
      if (kDebugMode) {
        debugPrint('🌐 CREATE EXPENSE: $url');
        debugPrint('📦 PAYLOAD: $payload');
      }

      final response = await _dio.post(url, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data['status'] == 'success' && response.data['data'] != null) {
          return Expense.fromJson(response.data['data']);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CREATE EXPENSE ERROR: $e');
      rethrow;
    }
  }

  /// Update an existing expense record (Multipart)
  /// PUT /api/expense/update/:id
  Future<Expense?> updateExpense(
    int id, {
    required int expenseCategoryId,
    required int companyId,
    required String expenseDate,
    required double amount,
    required String amountType,
    required String description,
    String? comment,
    String? note,
    List<String>? existingFiles,
    List<String>? newFilePaths,
    int? paidBy,
    int? branchId,
    String? quantity,
    String? service,
  }) async {
    try {
      final url = '/expense/update/$id';
      
      final Map<String, dynamic> dataMap = {
        'expenseCategoryId': expenseCategoryId,
        'companyId': companyId,
        'expenseDate': expenseDate,
        'amount': amount == amount.toInt() ? '${amount.toInt()}.00' : amount,
        'amountType': amountType,
        'description': description,
      };
      
      if (comment != null) dataMap['comment'] = comment;
      if (note != null) dataMap['note'] = note;
      if (paidBy != null) dataMap['paidBy'] = paidBy;
      if (branchId != null) dataMap['branchId'] = branchId;
      if (quantity != null) dataMap['quantity'] = quantity;
      if (service != null) dataMap['service'] = service;



      // Combine existing URLs and new MultipartFiles into the same 'file' field array
      final List<dynamic> allFiles = [];
      if (existingFiles != null && existingFiles.isNotEmpty) {
        allFiles.addAll(existingFiles);
      }
      
      if (newFilePaths != null && newFilePaths.isNotEmpty) {
        for (final filePath in newFilePaths) {
          final fileName = filePath.split('/').last;
          allFiles.add(await MultipartFile.fromFile(filePath, filename: fileName));
        }
      }
      
      if (allFiles.isNotEmpty) {
        dataMap['file'] = allFiles;
      } else {
        dataMap['file'] = '';
      }

      final formData = FormData.fromMap(dataMap);

      if (kDebugMode) {
        debugPrint('🌐 UPDATE EXPENSE (MULTIPART): $url');
        debugPrint('📦 DATA FIELDS: $dataMap');
      }

      final response = await _dio.put(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (response.data['status'] == 'success' && response.data['data'] != null) {
          return Expense.fromJson(response.data['data']);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPDATE EXPENSE MULTIPART ERROR: $e');
      rethrow;
    }
  }

  /// Upload receipt file for an expense (form data)
  /// PUT /api/expense/update/:id
  Future<bool> uploadExpenseFiles(int id, List<String> filePaths, {bool isCreation = false}) async {
    try {
      final url = isCreation ? '/expense/update/$id?image=history' : '/expense/update/$id';
      
      final List<MultipartFile> multipartFiles = [];
      for (final filePath in filePaths) {
        final fileName = filePath.split('/').last;
        multipartFiles.add(await MultipartFile.fromFile(filePath, filename: fileName));
      }
      
      final formData = FormData.fromMap({
        'file': multipartFiles,
      });

      if (kDebugMode) {
        debugPrint('🌐 UPLOAD EXPENSE FILES: $url');
        debugPrint('📁 FILE PATHS: $filePaths');
      }

      final response = await _dio.put(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ UPLOAD EXPENSE FILE ERROR: $e');
      return false;
    }
  }

  /// Fetch all soft-deleted/trash expenses
  /// GET /api/expense/deleted/all
  Future<List<ExpenseMonthGroup>> getTrashExpenses() async {
    try {
      const url = '/expense/deleted/all';
      if (kDebugMode) debugPrint('🌐 GET TRASH EXPENSES: $url');
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((json) => ExpenseMonthGroup.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GET TRASH EXPENSES ERROR: $e');
      rethrow;
    }
  }

  /// Remove/delete an expense record permanently or soft delete
  /// DELETE /api/expense/delete/:id
  Future<bool> deleteExpense(int id) async {
    try {
      final url = '/expense/delete/$id';
      if (kDebugMode) debugPrint('🌐 DELETE EXPENSE: $url');
      final response = await _dio.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DELETE EXPENSE ERROR: $e');
      return false;
    }
  }

  /// Restore a deleted expense record
  /// PUT /api/expense/restore/:id
  Future<bool> restoreExpense(int id) async {
    try {
      final url = '/expense/restore/$id';
      if (kDebugMode) debugPrint('🌐 RESTORE EXPENSE: $url');
      final response = await _dio.put(url);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RESTORE EXPENSE ERROR: $e');
      return false;
    }
  }
  // Clean history data anomalies, especially for amount field
  void _cleanHistory(Expense expense) {
    if (expense.history == null) return;
    for (var item in expense.history!) {
      final changes = item.changes;
      if (changes == null) continue;
      changes.forEach((field, detail) {
        if (field == 'amount') {
          // Ensure old and new values are formatted as numbers with two decimals
          String? format(String? val) {
            if (val == null) return null;
            final numVal = double.tryParse(val.replaceAll(',', ''));
            if (numVal != null) {
              return numVal.toStringAsFixed(2);
            }
            return val;
          }

          final formattedOld = format(detail.oldValue);
          final formattedNew = format(detail.newValue);
          // Update the map entry with formatted values
          changes[field] = ExpenseHistoryChangeDetail(
            newValue: formattedNew,
            oldValue: formattedOld,
          );
        }
      });
    }
  }

  /// Download Report (PDF or Excel)
  /// GET /api/expense/report/download
  Future<String?> downloadReport({
    required String branchId,
    required String fileType,
    required String reportType,
    required String currency,
    String? startDate,
    String? endDate,
    String? userId,
    String? categoryId,
  }) async {
    try {
      const url = '/expense/report/download';
      final queryParams = {
        'branchId': branchId,
        'fileType': fileType,
        'reportType': reportType,
        'amountType': currency,
      };
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      if (kDebugMode) {
        debugPrint('🌐 DOWNLOAD REPORT: $url');
        debugPrint('📦 PARAMS: $queryParams');
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes, // Important for downloading files
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = fileType.toLowerCase() == 'excel' ? 'xlsx' : 'pdf';
        final fileName = 'Expense_Report_${reportType}_$timestamp.$extension';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);
        
        if (kDebugMode) debugPrint('✅ REPORT DOWNLOADED TO: $filePath');
        return filePath;
      } else {
        if (kDebugMode) debugPrint('❌ DOWNLOAD REPORT FAILED: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DOWNLOAD REPORT ERROR: $e');
      rethrow;
    }
  }
}

