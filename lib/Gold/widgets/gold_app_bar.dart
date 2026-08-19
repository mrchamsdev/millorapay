import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/network/gold_dio_client.dart';
import '../core/network/gold_session.dart';
import '../features/notifications/providers/notification_provider.dart';
class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showSearch;
  final bool showNotification;
  final bool showBackButton;
  final bool showMenuButton;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final Function(String)? onSearchChanged;
  final VoidCallback? onBackPressed;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final Color? backgroundColor;

  const GoldAppBar({
    super.key,
    this.title,
    this.showSearch = true,
    this.showNotification = false,
    this.showBackButton = false,
    this.showMenuButton = true,
    this.centerTitle = false,
    this.actions,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.onSearchChanged,
    this.onBackPressed,
    this.titleFontSize,
    this.titleFontWeight,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.appBarBackground,
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            _buildCircularButton(
              icon: showBackButton ? Icons.arrow_back_ios_new : Icons.menu,
              size: showBackButton ? 16 : 20,
              onPressed: showBackButton 
                ? (onBackPressed ?? () => AppRoutes.pop(context))
                : (onMenuPressed ?? () => Scaffold.of(context).openDrawer()),
            ),
            const SizedBox(width: 12),
          ],
          // Search Bar or Title
          Expanded(
            child: showSearch 
              ? Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF727271), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: onSearchChanged,
                          autofocus: false,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    title ?? '', 
                    style: TextStyle(
                      fontSize: titleFontSize ?? 16, 
                      fontWeight: titleFontWeight ?? FontWeight.w500, 
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 12),
            Row(children: actions!),
          ] else if (showNotification) ...[
            const SizedBox(width: 12),
            _NotificationBadgeButton(onPressed: onNotificationPressed),
          ] else if (centerTitle && showMenuButton) ...[
            const SizedBox(width: 35),
          ],
        ],
      ),
    );
  }

  /*Widget _buildCircularButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFF1F2F5)),
       
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
*/
Widget _buildCircularButton({
  required IconData icon,
  VoidCallback? onPressed,
  double size = 20,
}) {
  return Container(
    width: 35,
    height: 35,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white,
      border: Border.all(color: const Color(0xFFF1F2F5)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Icon(icon, color: AppColors.textPrimary, size: size),
      ),
    ),
  );
}

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _NotificationBadgeButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _NotificationBadgeButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationProvider.unreadCountNotifier,
      builder: (context, unreadCount, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(color: const Color(0xFFF1F2F5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Instantly hide the red badge locally
                    NotificationProvider.markAllReadLocally();
                    
                    // Trigger navigation
                    if (onPressed != null) {
                      onPressed!();
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: const Icon(Icons.notifications_none_outlined, color: AppColors.textPrimary, size: 20),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
