import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';


import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../core/network/gold_dio_client.dart';
import '../../../core/network/gold_session.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/screens/expense_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final dio = GoldDioClient.instance.dio;
      final role = GoldSession.instance.userRole?.toLowerCase();
      final userId = GoldSession.instance.userId;

      String url = '/notifications';
      if (role != null && role.contains('admin')) {
        url = '/notifications/admin/$userId';
      }

      final response = await dio.get(url);
      debugPrint('🔔 NOTIFICATIONS API RESPONSE: ${response.data}');
      if (response.data != null && response.data['status'] == 'success') {
        setState(() {
          _notifications = response.data['data'] ?? [];
          _isLoading = false;
        });
        // Automatically mark unread notifications as read
        _markAsRead(_notifications);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS API ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(List<dynamic> notifications) async {
    try {
      final unreadIds = notifications
          .where((n) => n['adminIsRead'] == false || n['isRead'] == false)
          .map((n) => int.tryParse(n['id']?.toString() ?? ''))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (unreadIds.isEmpty) return;

      final role = GoldSession.instance.userRole?.toLowerCase();
      final isAdmin = role != null && role.contains('admin');
      final url = isAdmin ? '/notifications/admin/read' : '/notifications/read';

      final dio = GoldDioClient.instance.dio;
      final response = await dio.put(
        url,
        data: {'notificationIds': unreadIds},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Marked ${unreadIds.length} notifications as read');
      }
    } catch (e) {
      debugPrint('❌ Error marking notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _extractFiles(String val) {
    if (val == 'none' || val.trim().isEmpty || val.trim() == '[]') return [];
    
    String cleaned = val.trim();
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    if (cleaned.isEmpty) return [];
    return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _processFieldChange(List<String> changes, String field, String oldValStr, String newValStr, String currency) {
    final oldVal = oldValStr.isEmpty || oldValStr == 'null' ? 'none' : oldValStr;
    final newVal = newValStr.isEmpty || newValStr == 'null' ? 'none' : newValStr;

    if (field == 'amount') {
      changes.add('Amount changed from $currency$oldVal to $currency$newVal');
    } else if (field == 'description') {
      changes.add("Description changed from '$oldVal' to '$newVal'");
    } else if (field == 'expenseCategoryId') {
      changes.add("Category changed from '$oldVal' to '$newVal'");
    } else if (field == 'branchId') {
      changes.add("Branch changed from '$oldVal' to '$newVal'");
    } else if (field == 'paidBy') {
      changes.add("Paid by changed from '$oldVal' to '$newVal'");
    } else if (field == 'quantity') {
      changes.add("Quantity changed from '$oldVal' to '$newVal'");
    } else if (field == 'service') {
      changes.add("Service changed from '$oldVal' to '$newVal'");
    } else if (field == 'file' || field == 'files') {
      final oldList = _extractFiles(oldVal);
      final newList = _extractFiles(newVal);
      
      final addedCount = newList.where((e) => !oldList.contains(e)).length;
      final removedCount = oldList.where((e) => !newList.contains(e)).length;

      if (addedCount > 0) {
        changes.add('$addedCount receipt image${addedCount > 1 ? 's' : ''} updated');
      }
      if (removedCount > 0) {
        changes.add('$removedCount receipt image${removedCount > 1 ? 's' : ''} removed');
      }
    } else if (field == 'note') {
      if (oldVal == 'none') {
        changes.add("Note added: '$newVal'");
      } else if (newVal == 'none') {
        changes.add("Note removed");
      } else {
        changes.add("Note changed from '$oldVal' to '$newVal'");
      }
    } else if (field == 'amountType') {
      changes.add("Currency changed from '$oldVal' to '$newVal'");
    } else if (field == 'comment') {
      if (oldVal == 'none') {
        changes.add("Comment added: '$newVal'");
      } else if (newVal == 'none') {
        changes.add("Comment removed");
      } else {
        changes.add("Comment changed from '$oldVal' to '$newVal'");
      }
    } else if (field == 'expenseDate') {
      changes.add("Date changed from '$oldVal' to '$newVal'");
    } else {
      changes.add('${field[0].toUpperCase()}${field.substring(1)} changed');
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final expense = notif['expense'] ?? {};
    final description = expense['description'] ?? 'Expenses';
    final branchName = notif['branchName'] ?? 'branch';
    
    // Determine who made the update
    final currentUserId = GoldSession.instance.userId?.toString();
    String prefix = 'You';
    
    final updater = notif['updater'];
    if (updater != null && updater is Map) {
      final updaterIdStr = updater['id']?.toString();
      if (updaterIdStr != null && updaterIdStr != currentUserId && updater['name'] != null) {
        prefix = updater['name'];
      }
    }

    final titleText = '$prefix updated "$description" in "$branchName"';

    List<String> changes = [];
    final currency = expense['currencySymbol'] ?? '₹'; // Fallback currency

    // 1. Handle new format (nested "changes" map)
    if (notif['changes'] != null && notif['changes'] is Map) {
      final changesMap = notif['changes'] as Map;
      changesMap.forEach((key, value) {
        if (value is Map) {
          final oldValStr = value['oldValue']?.toString() ?? '';
          final newValStr = value['newValue']?.toString() ?? '';
          _processFieldChange(changes, key.toString(), oldValStr, newValStr, currency);
        }
      });
    } else {
      // 2. Handle legacy format (top-level updatedField)
      final updatedField = notif['updatedField']?.toString() ?? '';
      if (updatedField.isNotEmpty) {
        final oldValue = notif['oldValue']?.toString() ?? '';
        final newValue = notif['newValue']?.toString() ?? '';
        _processFieldChange(changes, updatedField, oldValue, newValue, currency);
      }
    }

    // Line 3: Date and time
    final createdAtStr = notif['createdAt']?.toString() ?? '';
    String timeStr = '';
    if (createdAtStr.isNotEmpty) {
      try {
        final DateTime dt = DateTime.parse(createdAtStr).toLocal();
        // format: 22 May 2025 at 09:00PM
        timeStr = DateFormat("dd MMM yyyy 'at' hh:mma").format(dt);
      } catch (e) {
        timeStr = createdAtStr;
      }
    }

    final bool isUnread = notif['adminIsRead'] == false || notif['isRead'] == false;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          setState(() {
            notif['adminIsRead'] = true;
            notif['isRead'] = true;
          });
        }
        if (notif['expense'] != null) {
          try {
            final parsedExpense = Expense.fromJson(notif['expense'] as Map<String, dynamic>);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseDetailsScreen(expense: parsedExpense),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing expense for navigation: $e');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon
          SvgPicture.asset(
            'assets/images/ExpenseNotif.svg',
            width: 44,
            height: 44,
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Line 1
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // Line 2
                if (changes.isNotEmpty)
                  ...changes.map((change) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          change,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                const SizedBox(height: 2),
                // Line 3
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF727271),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Filter notifications if search is active
    final query = _searchController.text.toLowerCase();
    final displayedNotifications = query.isEmpty
        ? _notifications
        : _notifications.where((notif) {
            final branchName = (notif['branchName']?.toString() ?? '').toLowerCase();
            final expense = notif['expense'] ?? {};
            final description = (expense['description']?.toString() ?? '').toLowerCase();
            return branchName.contains(query) || description.contains(query);
          }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: const GoldAppBar(
          title: 'Notifications',
          showSearch: false,
          showBackButton: true,
          centerTitle: true,
          showNotification: false,
        ),
        body: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  onChanged: (val) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Content Area ──────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    )
                  : displayedNotifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications found',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayedNotifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(
                                displayedNotifications[index] as Map<String, dynamic>);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
