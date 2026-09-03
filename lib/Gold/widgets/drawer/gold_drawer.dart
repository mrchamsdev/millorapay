import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_routes.dart';
import '../../core/network/gold_session.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
class GoldDrawer extends StatelessWidget {
  const GoldDrawer({super.key});

  String _formatPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.isEmpty) return '';
    try {
      final toParse = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
      final phone = PhoneNumber.parse(toParse);
      return '+${phone.countryCode} ${phone.nsn}';
    } catch (e) {
      return rawPhone;
    }
  }

  void _openCompanySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Active Company',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const Divider(height: 1),
              if (GoldSession.instance.userAccess.length <= 1)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No other companies available.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: GoldSession.instance.userAccess.length - 1,
                    itemBuilder: (context, index) {
                      final companyIndex = index + 1;
                      final company = GoldSession.instance.userAccess[companyIndex];
                      return ListTile(
                        leading: SvgPicture.asset('assets/images/Branch2.svg', width: 24, height: 24),
                        title: Text(
                          company.companyName,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        onTap: () {
                          GoldSession.instance.setActiveCompany(company.companyId).then((_) {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.pop(context); // Close drawer
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainNavigation, (route) => false);
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Section
            GestureDetector(
              onTap: () {
                if (GoldSession.instance.userId != null) {
                  Navigator.pop(context); // Close the drawer
                  Navigator.pushNamed(
                    context,
                    AppRoutes.userDetails,
                    arguments: {
                      'id': GoldSession.instance.userId,
                      'userName': GoldSession.instance.userName,
                    },
                  );
                }
              },
              child: Container(
                color: Colors.transparent, // Ensures the entire row is tappable
                padding: const EdgeInsets.only(left: 23, top: 24, bottom: 24, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.modalIconBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (GoldSession.instance.userName?.isNotEmpty == true)
                                  ? GoldSession.instance.userName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF002E6E),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                GoldSession.instance.userName ?? 'User',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPhone(GoldSession.instance.userPhone),
                                style: const TextStyle(
                                  color: Color(0xFF727271),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (GoldSession.instance.userRole?.toLowerCase() == 'super admin')
                                      ? 'Admin'
                                      : (GoldSession.instance.userRole ?? ''),
                                  style: const TextStyle(
                                    color: Color(0xFF002E6E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (GoldSession.instance.userAccess.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.branchDetails,
                            arguments: GoldSession.instance.userAccess.first.companyId.toString(),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.modalIconBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/Branch2.svg',
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              GoldSession.instance.userAccess.first.companyName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (GoldSession.instance.userAccess.length > 1) ...[
                              SizedBox(width: 12),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _openCompanySelector(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                 /* _SectionHeader(title: 'App Settings', hasBackground: true),
                  _DrawerItem(icon: Icons.favorite_border, title: 'Favourites', onTap: () {}),
                  _DrawerItem(icon: Icons.language, title: 'Language', onTap: () {}),
                  _DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () {}),
                  */
                  _SectionHeader(title: 'Security'),
                  _DrawerItem(
                    icon: Icons.face_unlock_outlined,
                    title: 'Face Id',
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      AppRoutes.push(context, AppRoutes.faceId);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      AppRoutes.push(context, AppRoutes.changePassword);
                    },
                  ),
                 
                  
                  if (GoldSession.instance.canRead('Users')) ...[
                    _SectionHeader(title: 'Profile'),
                    _DrawerItem(icon: Icons.person_outline, title: 'User access', onTap: () => Navigator.pushNamed(context, AppRoutes.users)),
                  ],
                  
                  if (GoldSession.instance.userRole?.toLowerCase().contains('admin') == true) ...[
                    _DrawerItem(icon: Icons.category_outlined, title: 'Category', onTap: () => Navigator.pushNamed(context, AppRoutes.categoryManagement)),
                    _DrawerItem(
                      iconWidget: SvgPicture.asset(
                        'assets/images/Branch2.svg', // Replace with your SVG
                        width: 16,
                        height: 16,
                      ),
                      title: 'Company',
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Navigator.pushNamed(context, AppRoutes.branches);
                      },
                    ),
                    _DrawerItem(
                      iconWidget: SvgPicture.asset(
                        'assets/images/Units.svg',
                        width: 16,
                        height: 16,
                      ),
                      title: 'Units',
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Navigator.pushNamed(context, AppRoutes.units);
                      },
                    ),
                    _DrawerItem(
                      iconWidget: SvgPicture.asset(
                        'assets/images/Services.svg',
                        width: 16,
                        height: 16,
                      ),
                      title: 'Services',
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Navigator.pushNamed(context, AppRoutes.services);
                      },
                    ),
                  ],
                  
                  if (GoldSession.instance.canRead('Expenses')) ...[
                    _DrawerItem(
                      iconWidget: SvgPicture.asset(
                        'assets/images/Chart.svg',
                        width: 32,
                        height: 32,
                      ),
                      title: 'Chart',
                      showIconBackground: false,
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Navigator.pushNamed(context, AppRoutes.charts);
                      },
                    ),
                    _DrawerItem(
                      iconWidget: SvgPicture.asset(
                        'assets/images/Report.svg',
                        width: 32,
                        height: 32,
                      ),
                      title: 'Report',
                      showIconBackground: false,
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Navigator.pushNamed(context, AppRoutes.reports);
                      },
                    ),
                  ],
                  
                  if (GoldSession.instance.userAccess.length > 1) ...[
                    _SectionHeader(title: 'Other Companies'),
                    for (int i = 1; i < GoldSession.instance.userAccess.length; i++)
                      _DrawerItem(
                        iconWidget: SvgPicture.asset(
                          'assets/images/Branch2.svg',
                          width: 16,
                          height: 16,
                        ),
                        title: GoldSession.instance.userAccess[i].companyName,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.branchDetails,
                            arguments: GoldSession.instance.userAccess[i].companyId.toString(),
                          );
                        },
                      ),
                  ],
                  
                  _SectionHeader(title: 'More Info & Support'),
                   _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      AppRoutes.push(context, AppRoutes.privacyPolicy);
                    },
                  ),
                  _DrawerItem(icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () {}),
                  _DrawerItem(icon: Icons.help_outline, title: 'Help', onTap: () {}),
                  _DrawerItem(icon: Icons.info_outline, title: 'About', onTap: () {}),
                  //_DrawerItem(icon: Icons.delete_outline, title: 'Trash', onTap: () {}),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Only clear auth session — preserve biometric keys so
                    // the user can log back in with Face ID without re-enabling.
                    await GoldSession.instance.clear();
                    // Explicitly keep 'isFaceEnabled' and 'biometricDeviceId'
                    // in FlutterSecureStorage (they are not stored in GoldSession).
                    if (context.mounted) {
                      AppRoutes.pushAndClearStack(context, AppRoutes.welcome);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool hasBackground;

  const _SectionHeader({required this.title, this.hasBackground = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: hasBackground ? const Color(0xFFEEEEEE) : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final VoidCallback onTap;
  final bool showIconBackground;

  const _DrawerItem({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.onTap,
    this.showIconBackground = true,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: showIconBackground
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.modalIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: iconWidget ?? Icon(icon!, color: AppColors.primaryBlue, size: 16),
                  ),
                )
              : SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: iconWidget ?? Icon(icon!, color: AppColors.primaryBlue, size: 16),
                  ),
                ),
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          minLeadingWidth: 0,
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 0, endIndent: 0),
      ],
    );
  }
}
