import 'package:flutter/material.dart';

/// All named routes for the Gold app.
class AppRoutes {
  AppRoutes._(); // prevent instantiation

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String welcome        = '/';
  static const String signIn         = '/sign-in';
  static const String signUp         = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode     = '/verify-code';
  static const String setPassword    = '/set-password';
  static const String passwordSuccess = '/password-success';

  // ── Main App ──────────────────────────────────────────────────────────────
  static const String mainNavigation = '/main';
  static const String dashboard      = '/dashboard';

  // ── Expenses ──────────────────────────────────────────────────────────────
  static const String expenses       = '/expenses';
  static const String expenseDetails = '/expense-details';
  static const String addExpense     = '/add-expense';
  static const String categoryManagement = '/category-management';
  static const String categoryPicker = '/category-picker';
  static const String currencyPicker = '/currency-picker';
  static const String addNote        = '/add-note';
  static const String reports        = '/reports';
  static const String charts         = '/charts';

  // ── Gold ──────────────────────────────────────────────────────────────────
  static const String gold           = '/gold';
  static const String goldDetails    = '/gold-details';
  static const String addGold        = '/add-gold';
  static const String addGoldItem    = '/add-gold-item';

  // ── Loans ─────────────────────────────────────────────────────────────────
  static const String loans          = '/loans';

  // ── Users ─────────────────────────────────────────────────────────────────
  static const String users          = '/users';
  static const String userDetails    = '/user-details';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String faceId         = '/face-id';
  static const String changePassword = '/change-password';
  static const String privacyPolicy  = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String help           = '/help';
  static const String about          = '/about';

  // ── Customers ─────────────────────────────────────────────────────────────
  static const String customers       = '/customers';
  static const String customerDetails = '/customer-details';

  // ── Branches & Companies ──────────────────────────────────────────────────
  static const String companies       = '/companies';
  static const String branches        = '/branches';
  static const String addBranch       = '/add-branch';
  static const String branchDetails   = '/branch-details';
  static const String companyDetails  = '/company-details';

  // ── Units ─────────────────────────────────────────────────────────────────
  static const String units           = '/units';

  // ── Services ──────────────────────────────────────────────────────────────
  static const String services        = '/services';

  // ── Navigation helpers ────────────────────────────────────────────────────

  static void push(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void replace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushAndClearStack(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (_) => false,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) => Navigator.pop<T>(context, result);

  static void popToRoot(BuildContext context) =>
      Navigator.popUntil(context, (route) => route.isFirst);
}
