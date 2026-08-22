import 'dart:async';
import 'package:bank_scan/Gold/features/loans/screens/loans_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../dashboard/dashboard_screen.dart';
import '../expenses/screens/expenses_screen.dart';
import '../expenses/screens/add_expense_screen.dart';
import '../notifications/screens/notifications_screen.dart';
import '../notifications/providers/notification_provider.dart';
import '../gold/screens/gold_screen.dart';
import '../../widgets/drawer/gold_drawer.dart';
import '../../widgets/modals/quick_actions_modal.dart';
import '../../widgets/gold_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/network/gold_session.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ExpensesScreenState> _expensesKey = GlobalKey<ExpensesScreenState>();
  final GlobalKey<GoldScreenState> _goldKey = GlobalKey<GoldScreenState>();
  final GlobalKey<LoansScreenState> _loansKey = GlobalKey<LoansScreenState>();
  late final List<Widget> _screens;
  final List<bool> _visited = [true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onTabSelected: _onItemTapped,
        onSessionRefreshed: () {
          if (mounted) setState(() {});
        },
      ),
      ExpensesScreen(key: _expensesKey),
      const SizedBox.shrink(), // Placeholder for FAB
      const Scaffold(body: Center(child: Text("Notifications Screen"))), // Notifications placeholder
      // GoldScreen(key: _goldKey),
      // LoansScreen(key: _loansKey),
    ];
    
    // Initial fetch of unread count
    NotificationProvider.fetchUnreadCount();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      QuickActionsModal.show(context);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    
    // Check for new notifications when switching tabs
    NotificationProvider.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final canReadExpenses = GoldSession.instance.canRead('Expenses');
    final canWriteExpenses = GoldSession.instance.canWrite('Expenses');

    return Scaffold(
      drawer: const GoldDrawer(),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(5, (index) {
          if (!_visited[index] && index != _selectedIndex) {
            return const SizedBox.shrink();
          }
          _visited[index] = true;
          return _screens[index];
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: BottomAppBar(
          color: AppColors.appBarBackground,
          elevation: 0,
          padding: EdgeInsets.zero,
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSvgNavItem(0, 'assets/images/Home1.svg', 'assets/images/Home1.svg', 'Home'),
              if (canReadExpenses && canWriteExpenses) _buildFab(),
              if (canReadExpenses) _buildNavItem(1, 'assets/gold/expenses.png', 'assets/gold/active-expenses.png', 'Expenses'),
              // _buildFab(),
              // _buildNavItem(3, 'assets/gold/gold.png', 'assets/gold/avtive-gold.png', 'Gold'),
              // _buildNavItem(4, 'assets/gold/loans.png', 'assets/gold/active-loans.png', 'Loans'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () {
        // QuickActionsModal.show(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF003366), // Specific dark blue from image
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: AppColors.white, size: 25),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String? title;
    bool showSearch = true;
    bool showMenuButton = true;
    bool showNotification = false;
    List<Widget>? actions;

    switch (_selectedIndex) {
      case 0:
        title = 'Home';
        showSearch = false;
        showNotification = true;
        break;
      case 1:
        title = 'Expenses';
        showSearch = true;
        showMenuButton = false;
        showNotification = true;
        break;
      case 3:
        title = 'Notifications';
        showSearch = false;
        break;
    }

    return GoldAppBar(
      title: title,
      showSearch: showSearch,
      showMenuButton: showMenuButton,
      showNotification: showNotification,
      onNotificationPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        // Refresh count upon returning to clear badge
        NotificationProvider.fetchUnreadCount();
      },
      actions: actions,
      onSearchChanged: (query) {
        if (_selectedIndex == 1) {
          _expensesKey.currentState?.filterExpenses(query);
        }
        // else if (_selectedIndex == 3) {
        //   _goldKey.currentState?.filterPurchases(query);
        // } else if (_selectedIndex == 4) {
        //   _loansKey.currentState?.filterLoans(query);
        // }
      },
    );
  }

  Widget _buildNavItem(int index, String assetPath, String activeAssetPath, String label) {
    final isSelected = _selectedIndex == index;
    final textColor = isSelected ? AppColors.primaryBlue : const Color(0xFF121212);
    final iconColor = isSelected ? AppColors.primaryBlue : null;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Transform.translate(
                  offset: index == 1 ? const Offset(0, 0.7) : Offset.zero,
                  child: Image.asset(
                    isSelected ? activeAssetPath : assetPath,
                    width: index == 0
                        ? 20
                        : index == 3
                            ? 26
                            : 24,
                    height: index == 0
                        ? 20
                        : index == 3
                            ? 28
                            : 24,
                    // Tint the icon only when active
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 0),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                label,
                style: AppTextStyles.navLabel.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSvgNavItem(int index, String assetPath, String activeAssetPath, String label) {
    final isSelected = _selectedIndex == index;
    final textColor = isSelected ? AppColors.primaryBlue : const Color(0xFF121212);
    final iconColor = isSelected ? AppColors.primaryBlue : null;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Transform.translate(
                  offset: index == 0 ? const Offset(0, 1) : Offset.zero,
                  child: SvgPicture.asset(
                    isSelected ? activeAssetPath : assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: iconColor != null ? ColorFilter.mode(iconColor, BlendMode.srcIn) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 0),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                label,
                style: AppTextStyles.navLabel.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
