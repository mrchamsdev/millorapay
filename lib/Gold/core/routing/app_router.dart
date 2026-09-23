import 'package:flutter/material.dart';

import '../constants/app_routes.dart';
import '../network/gold_session.dart';
import '../../features/auth/gold_welcome_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_code_screen.dart';
import '../../features/auth/screens/set_password_screen.dart';
import '../../features/auth/screens/password_success_screen.dart';
import '../../features/main/main_navigation_screen.dart';
import '../../features/expenses/screens/add_expense_screen.dart';
import '../../features/expenses/screens/expense_details_screen.dart';
import '../../features/expenses/screens/category_picker_screen.dart';
import '../../features/expenses/screens/add_note_screen.dart';
import '../../features/expenses/screens/currency_picker_screen.dart';
import '../../features/expenses/screens/reports_screen.dart';
import '../../features/expenses/screens/charts_screen.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/gold/screens/gold_details_screen.dart';
import '../../features/gold/screens/add_gold_purchase_screen.dart';
import '../../features/gold/screens/add_gold_item_screen.dart';
import '../../features/gold/models/gold_purchase_model.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/users/screens/user_details_screen.dart';
import '../../features/users/models/user_model.dart';
import '../../features/settings/screens/face_id_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/terms_conditions_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/customer/screens/customers_screen.dart';
import '../../features/customer/screens/customer_details_screen.dart';
import '../../features/customer/models/customer_model.dart';
import '../../features/branch/screens/branches_screen.dart';
import '../../features/branch/screens/companies_screen.dart';
import '../../features/branch/screens/add_company_screen.dart';
import '../../features/branch/screens/add_branch_screen.dart';
import '../../features/branch/screens/branch_details_screen.dart';
import '../../features/branch/screens/company_details_screen.dart';
import '../../features/branch/models/branch_model.dart';
import '../../features/units/screens/units_screen.dart';
import '../../features/services/screens/services_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth routes ───────────────────────────────────────────────────────
      case AppRoutes.welcome:
        if (GoldSession.instance.isLoggedIn) {
          return _fade(const MainNavigationScreen());
        }
        return _fade(const GoldWelcomeScreen());

      case AppRoutes.signIn:
        if (GoldSession.instance.isLoggedIn) {
          return _fade(const MainNavigationScreen());
        }
        return _slide(const GoldSignInScreen());

      case AppRoutes.signUp:
        if (GoldSession.instance.isLoggedIn) {
          return _fade(const MainNavigationScreen());
        }
        return _slide(const GoldSignUpScreen());

      case AppRoutes.forgotPassword:
        return _slide(const GoldForgotPasswordScreen());

      case AppRoutes.verifyCode:
        final email = settings.arguments as String? ?? '';
        return _slide(GoldVerifyCodeScreen(email: email));

      case AppRoutes.setPassword:
        final email = settings.arguments as String? ?? '';
        return _slide(GoldSetPasswordScreen(email: email));

      case AppRoutes.passwordSuccess:
        return _slide(const GoldPasswordSuccessScreen());

      case AppRoutes.users:
        return _slide(const UsersScreen());

      case AppRoutes.userDetails:
        int userId;
        String? userName;

        if (settings.arguments is User) {
          final user = settings.arguments as User;
          userId = user.id!;
          userName = user.name;
        } else if (settings.arguments is Map) {
          final args = settings.arguments as Map;
          userId = args['id'] as int;
          userName = args['userName'] as String?;
        } else {
          throw ArgumentError('Invalid arguments for userDetails route');
        }

        return _slide(UserDetailsScreen(
          userId: userId, 
          userName: userName,
        ));

      // ── Main Tabs (not pushed directly usually) ───────────────────────────────────────────────────
      case AppRoutes.mainNavigation:
        return _fade(const MainNavigationScreen());

      case AppRoutes.expenseDetails:
        final expense = settings.arguments as Expense;
        return _slide(ExpenseDetailsScreen(expense: expense));

      case AppRoutes.addExpense:
        final expense = settings.arguments as Expense?;
        return _slide(AddExpenseScreen(expense: expense));

      case AppRoutes.categoryPicker:
        return _slide(const CategoryPickerScreen());

      case AppRoutes.currencyPicker:
        return _slide(const CurrencyPickerScreen());

      case AppRoutes.categoryManagement:
        return _slide(const CategoryScreen());

      case AppRoutes.reports:
        return _slide(const ReportsScreen());

      case AppRoutes.charts:
        return _slide(const ChartsScreen());

      case AppRoutes.addNote:
        final initialData = settings.arguments as Map<String, String>?;
        return _slide(AddNoteScreen(initialData: initialData));

      case AppRoutes.goldDetails:
        final purchase = settings.arguments as GoldPurchase?;
        return _slide(GoldDetailsScreen(purchase: purchase));

      case AppRoutes.addGold:
        final purchase = settings.arguments as GoldPurchase?;
        return _slide(AddGoldPurchaseScreen(purchase: purchase));

      case AppRoutes.addGoldItem:
        final initialItems = settings.arguments as List<GoldBilledItem>?;
        return _slide(AddGoldItemScreen(initialItems: initialItems));

      case AppRoutes.faceId:
        return _slide(const FaceIdScreen());

      case AppRoutes.changePassword:
        return _slide(const ChangePasswordScreen());

      case AppRoutes.privacyPolicy:
        return _slide(const PrivacyPolicyScreen());

      case AppRoutes.termsConditions:
        return _slide(const TermsConditionsScreen());

      case AppRoutes.help:
        return _slide(const HelpScreen());

      case AppRoutes.about:
        return _slide(const AboutScreen());

      case AppRoutes.customers:
        return _slide(const CustomersScreen());

      case AppRoutes.customerDetails:
        final customer = settings.arguments as Customer;
        return _slide(CustomerDetailsScreen(customer: customer));

      case AppRoutes.companies:
        return _slide(const CompaniesScreen());

      case AppRoutes.addCompany:
        final company = settings.arguments as Company?;
        return _slide(AddCompanyScreen(companyToEdit: company));

      case AppRoutes.branches:
        return _slide(const BranchesScreen());
        
      case AppRoutes.units:
        return _slide(const UnitsScreen());
        
      case AppRoutes.services:
        return _slide(const ServicesScreen());
        
      case AppRoutes.addBranch:
        if (settings.arguments is Branch) {
          return _slide(AddBranchScreen(branchToEdit: settings.arguments as Branch));
        }
        final company = settings.arguments as Company?;
        return _slide(AddBranchScreen(companyToEdit: company));

      case AppRoutes.branchDetails:
        final branchId = settings.arguments as String;
        return _slide(BranchDetailsScreen(branchId: branchId));

      case AppRoutes.companyDetails:
        if (settings.arguments is Company) {
          final c = settings.arguments as Company;
          return _slide(CompanyDetailsScreen(companyId: c.id?.toString() ?? '', initialCompany: c));
        }
        final companyId = settings.arguments as String;
        return _slide(CompanyDetailsScreen(companyId: companyId));

      // ── Unknown route ─────────────────────────────────────────────────────
      default:
        return _slide(
          Scaffold(
            body: Center(
              child: Text('No route defined for "${settings.name}"'),
            ),
          ),
        );
    }
  }

  // ── Transition helpers ────────────────────────────────────────────────────

  /// Standard right-to-left slide (most screens).
  static PageRoute<T> _slide<T>(Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page);
  }

  /// Fade transition (used for top-level auth/main switches).
  static PageRoute<T> _fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, _, __) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
