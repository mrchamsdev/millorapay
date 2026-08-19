import 'package:flutter/material.dart';
import '../../../../Gold/core/network/gold_dio_client.dart';
import '../../../../Gold/core/network/gold_session.dart';

class NotificationProvider {
  // Global state for unread notifications count
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  // Instantly mark all as read locally
  static void markAllReadLocally() {
    unreadCountNotifier.value = 0;
  }

  // Fetch the actual unread count from the server
  static Future<void> fetchUnreadCount() async {
    try {
      final dio = GoldDioClient.instance.dio;
      final role = GoldSession.instance.userRole?.toLowerCase();
      final userId = GoldSession.instance.userId;

      String url = '/notifications';
      if (role != null && role.contains('admin')) {
        url = '/notifications/admin/$userId';
      }

      final response = await dio.get(url);
      if (response.data != null && response.data['status'] == 'success') {
        unreadCountNotifier.value = response.data['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }
}
