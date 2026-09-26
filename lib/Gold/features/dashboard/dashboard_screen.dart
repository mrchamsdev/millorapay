/*import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/screen_utility.dart';
import '../loans/repository/loan_repository.dart';
import '../gold/repository/gold_repository.dart';
import '../expenses/repository/expense_repository.dart';
import 'repository/dashboard_repository.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;

  const DashboardScreen({super.key, this.onTabSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Settings & Toggles
  bool _showBalances = true;
  bool _autoUpdate = true;
  String _selectedPeriod = 'Today';
  String _selectedCurrency = 'USD';
  String _selectedUnit = 'Ounce';
  int _selectedMultiplier = 1;
  bool _isExpandedMetals = false;

  // Clock
  String _currentTimeString = '';
  Timer? _clockTimer;

  // Real-time market timer
  Timer? _fluctuationTimer;

  // Data State
  double _totalInvestment = 45682.50;
  double _totalPL = 1250.30;
  double _totalPLPercent = 2.80;
  double _todaysPL = 456.80;
  double _todaysPLPercent = 1.05;
  double _loansOutstanding = 45682.50;
  //double _recentTransactionsAmount = 45682.50;
  int _recentTransactionsCount = 0;

  // Precious Metals Rates State
  final List<Map<String, dynamic>> _baseMetals = [
    {
      'name': 'Gold',
      'baseBid': 4290.00,
      'baseAsk': 4292.00,
      'change': -38.40,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver', // Alternate silver row as shown in image
      'baseBid': 66.75,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.76,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.75,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.76,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Palladium',
      'baseBid': 1752.00,
      'baseAsk': 1762.00,
      'change': 0.00,
    },
    {
      'name': 'Platinum',
      'baseBid': 1045.00,
      'baseAsk': 1048.50,
      'change': -12.30,
    },
  ];

  late List<Map<String, dynamic>> _liveMetals;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _liveMetals = List.from(_baseMetals.map((m) => {
      'name': m['name'],
      'bid': m['baseBid'],
      'ask': m['baseAsk'],
      'change': m['change'],
      'time': DateFormat('HH:mm').format(DateTime.now()),
    }));

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateClock();
    });

    _loadSettings().then((_) {
      _loadTelemetryData();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fluctuationTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTimeString = DateFormat('EEE, MMM d, yyyy, h:mm a').format(DateTime.now());
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showBalances = prefs.getBool('dashboard_show_balances') ?? true;
        _autoUpdate = prefs.getBool('dashboard_auto_update') ?? true;
        _selectedPeriod = prefs.getString('dashboard_period') ?? 'Today';
        _selectedCurrency = prefs.getString('dashboard_currency') ?? 'USD';
        _selectedUnit = prefs.getString('dashboard_unit') ?? 'Ounce';
        _selectedMultiplier = prefs.getInt('dashboard_multiplier') ?? 1;
      });
      _setupFluctuationTimer();
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  void _setupFluctuationTimer() {
    _fluctuationTimer?.cancel();
    if (_autoUpdate) {
      _fluctuationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && _autoUpdate) {
          setState(() {
            for (var metal in _liveMetals) {
              // 0.05% fluctuation
              final changePercent = (_random.nextDouble() * 0.1 - 0.05) / 100;
              final double oldBid = metal['bid'];
              final double newBid = oldBid * (1 + changePercent);
              final double spread = metal['ask'] - oldBid;
              
              metal['bid'] = newBid;
              metal['ask'] = newBid + spread;
              metal['change'] = metal['change'] + (newBid - oldBid);
              metal['time'] = DateFormat('HH:mm').format(DateTime.now());
            }
          });
        }
      });
    }
  }

  /*Future<void> _loadTelemetryData() async {
    try {
      final DashboardData? data = await DashboardRepository().getAdminDashboard();
      if (data != null && mounted) { */
    Future<void> _loadTelemetryData() async {
    try {
      final DashboardData? data = await DashboardRepository().getAdminDashboard(period: _selectedPeriod);
      if (data != null && mounted) {
        setState(() {
          _totalInvestment = data.totalInvestment;
          _totalPL = data.totalProfitLoss;
          _todaysPL = data.todayProfitLoss;
          /*_loansOutstanding = data.loansOutstanding;
          _recentTransactionsAmount = data.totalExpenses;*/
          _loansOutstanding = data.loansOutstanding;
          _recentTransactionsCount = data.recentTransactionsCount;

          _totalPLPercent = _totalInvestment > 0 
              ? (_totalPL / _totalInvestment) * 100 
              : 0.0;
          _todaysPLPercent = _totalInvestment > 0 
              ? (_todaysPL / _totalInvestment) * 100 
              : 0.0;
          
        });
      } else {
        await _loadTelemetryDataLocal();
      }
    } catch (e) {
      debugPrint('[Dashboard] Telemetry remote load error: $e. Falling back to local aggregation.');
      await _loadTelemetryDataLocal();
    }
  }

  Future<void> _loadTelemetryDataLocal() async {
    try {
      // 1. Fetch outstanding loans
      final loanRecords = await LoanRepository().getRecords();
      double loansSum = 0;
      double principalSum = 0;
      for (var record in loanRecords) {
        for (var person in record.persons) {
          loansSum += person.totalPending;
          principalSum += person.totalPrincipal;
        }
      }

      // 2. Fetch gold purchases
      final goldGroups = await GoldRepository().getAllGoldPurchases();
      double goldSum = 0;
      for (var group in goldGroups) {
        for (var rec in group.records) {
          goldSum += rec.grandTotal ?? 0;
        }
      }

      // 3. Fetch expenses
      /*final expenseGroups = await ExpenseRepository().getAllExpenses();
      double expensesSum = 0;
      for (var group in expenseGroups) {
        for (var rec in group.records) {
          expensesSum += rec.amount;
        }
      }

      if (mounted) {
        setState(() {
          _loansOutstanding = loansSum > 0 ? loansSum : 45682.50;
          _totalInvestment = (principalSum + goldSum) > 0 ? (principalSum + goldSum) : 45682.50;
          _recentTransactionsAmount = expensesSum > 0 ? expensesSum : 45682.50;

          // P&L ratios fallback
          _totalPL = _totalInvestment * 0.028;
          _totalPLPercent = 2.80;
          _todaysPL = _totalInvestment * 0.028;
          _todaysPLPercent = 2.80;

        });
      }*/
      // 3. Fetch expenses
      final expenseGroups = await ExpenseRepository().getAllExpenses();
      int expensesCount = 0;
      for (var group in expenseGroups) {
        expensesCount += group.records.length;
      }

      if (mounted) {
        setState(() {
          _loansOutstanding = loansSum > 0 ? loansSum : 45682.50;
          _totalInvestment = (principalSum + goldSum) > 0 ? (principalSum + goldSum) : 45682.50;
          _recentTransactionsCount = expensesCount;

          // P&L ratios fallback
          _totalPL = _totalInvestment * 0.028;
          _totalPLPercent = 2.80;
          _todaysPL = _totalInvestment * 0.028;
          _todaysPLPercent = 2.80;

        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Local Telemetry fallback error: $e');
    }
  }

  // Currency formatting helper
  /*String _formatCurrency(double amount) {
    if (!_showBalances) return '••••••';
    
    // Choose currency symbol
    String symbol = '\$';
    double convertedAmount = amount.abs();
    
    if (_selectedCurrency == 'INR') {
      symbol = '₹';
      convertedAmount = amount.abs() * 83.5;
    } else if (_selectedCurrency == 'EUR') {
      symbol = '€';
      convertedAmount = amount.abs() * 0.92;
    } else if (_selectedCurrency == 'GBP') {
      symbol = '£';
      convertedAmount = amount.abs() * 0.79;
    }

    final format = NumberFormat.currency(locale: 'en_US', symbol: '$symbol ', decimalDigits: 2);
    return format.format(convertedAmount);
  }
  */
  String _formatCurrency(double amount) {
    if (!_showBalances) return '••••••';
    
    // Underlying portfolio amounts are already in INR (native currency).
    // Convert OUT of INR for other display currencies instead of into it.
    String symbol = '₹';
    double convertedAmount = amount.abs();
    
    if (_selectedCurrency == 'USD') {
      symbol = '\$';
      convertedAmount = amount.abs() / 83.5;
    } else if (_selectedCurrency == 'EUR') {
      symbol = '€';
      convertedAmount = (amount.abs() / 83.5) * 0.92;
    } else if (_selectedCurrency == 'GBP') {
      symbol = '£';
      convertedAmount = (amount.abs() / 83.5) * 0.79;
    }
    // INR needs no conversion — it's already native.

    final format = NumberFormat.currency(locale: 'en_US', symbol: '$symbol ', decimalDigits: 2);
    return format.format(convertedAmount);
  }

  // Precious metals values conversion based on unit, currency & weight multiplier
  Map<String, String> _convertMetalValues(double bid, double ask, double change) {
    double conversionFactor = 1.0;

    // Base quotes are per Ounce in USD.
    // 1 Ounce = 28.3495 Grams
    // 1 Tola = 11.6638 Grams = 0.4114 Ounces
    if (_selectedUnit == 'Gram') {
      conversionFactor /= 28.3495;
    } else if (_selectedUnit == 'Tola') {
      conversionFactor *= (11.6638 / 28.3495);
    }

    // Currency conversions
    if (_selectedCurrency == 'INR') {
      conversionFactor *= 83.5;
    } else if (_selectedCurrency == 'EUR') {
      conversionFactor *= 0.92;
    } else if (_selectedCurrency == 'GBP') {
      conversionFactor *= 0.79;
    }

    // Multiplier
    conversionFactor *= _selectedMultiplier;

    final double displayBid = bid * conversionFactor;
    final double displayAsk = ask * conversionFactor;
    final double displayChange = change * conversionFactor;

    final format = NumberFormat('#,##0.00', 'en_US');
    final changeFormat = NumberFormat('+#,##0.00;-#,##0.00', 'en_US');

    return {
      'bid': format.format(displayBid),
      'ask': format.format(displayAsk),
      'change': displayChange == 0.0 ? '0.00' : changeFormat.format(displayChange),
      'isPositive': displayChange >= 0 ? 'true' : 'false',
    };
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtility().init(context);

    final totalPLColor = _totalPL >= 0 ? AppColors.success : AppColors.error;
    final todaysPLColor = _todaysPL >= 0 ? AppColors.success : AppColors.error;

    final totalPLSign = _totalPL >= 0 ? '+' : '-';
    final todaysPLSign = _todaysPL >= 0 ? '+' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTelemetryData();
        },
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section ──────────────────────────────────────────────────
              /*Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentTimeString,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF727271),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Auto-Update',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _autoUpdate,
                          activeThumbColor: AppColors.primaryBlue,
                          activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                          onChanged: (val) {
                            setState(() {
                              _autoUpdate = val;
                              _saveSetting('dashboard_auto_update', val);
                              _setupFluctuationTimer();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              
              const SizedBox(height: 4),
              */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'The Spot Market is Open',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF727271),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Closes in 13hrs, 40mins',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Portfolio Summary Card ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F2F5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Portfolio Summary',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showBalances = !_showBalances;
                                  _saveSetting('dashboard_show_balances', _showBalances);
                                });
                              },
                              child: Icon(
                                _showBalances ? Icons.visibility : Icons.visibility_off,
                                size: 18,
                                color: const Color(0xFF727271),
                              ),
                            ),
                          ],
                        ),
                        // Dropdown for period
                        GestureDetector(
                          onTap: () => _showPeriodSelector(context),
                          child: Row(
                            children: [
                              Text(
                                _selectedPeriod,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Total Investment
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Investment',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatCurrency(_totalInvestment),
                                  
                                  style: AppTextStyles.amount.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFF1F2F5),
                        ),
                        const SizedBox(width: 12),
                        // Total P&L
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total P&L',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _showBalances
                                      ? '$totalPLSign${_formatCurrency(_totalPL)} (${_totalPLPercent.abs().toStringAsFixed(2)}%)'
                                      : '••••••',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: totalPLColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFF1F2F5),
                        ),
                        const SizedBox(width: 12),
                        // Todays P&L
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todays P&L',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _showBalances
                                      ? '$todaysPLSign${_formatCurrency(_todaysPL)} (${_todaysPLPercent.abs().toStringAsFixed(2)}%)'
                                      : '••••••',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: todaysPLColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick Access Row (Loans & Recent Transactions) ────────────────
              Row(
                children: [
                  // Loans Outstanding Card
                  /*Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.onTabSelected?.call(4); // Switches to Loans
                      },
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F2F5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF003366),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.monetization_on_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Loans Outstanding',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF727271),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatCurrency(_loansOutstanding),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  */
                  Expanded(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F2F5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.monetization_on_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Loans Outstanding',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFF727271),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatCurrency(_loansOutstanding),
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Recent Transactions Card
                  /*Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.onTabSelected?.call(1); // Switches to Expenses
                      },
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F2F5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF003366),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Recent Transactions',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF727271),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatCurrency(_recentTransactionsAmount),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                */
                if (GoldSession.instance.canRead('Expenses'))
                  Expanded(
                      child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F2F5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Recent Transactions',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFF727271),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatCurrency(_recentTransactionsAmount),
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Precious Metals Header & Selectors ──────────────────────────────
              /*Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Precious Metals -',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                    */
                    Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Precious Metals -',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      // Currency Selector dropdown
                      // Currency Selector dropdown
                      GestureDetector(
                        onTap: () => _showCurrencySelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedCurrency == 'USD'
                                    ? '🇺🇸 USD'
                                    : _selectedCurrency == 'INR'
                                        ? '🇮🇳 INR'
                                        : _selectedCurrency == 'EUR'
                                            ? '🇪🇺 EUR'
                                            : '🇬🇧 GBP',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit Selector dropdown
                      GestureDetector(
                        onTap: () => _showUnitSelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedUnit,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Multiplier Toggle button (1 vs 10)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMultiplier = _selectedMultiplier == 1 ? 10 : 1;
                            _saveSetting('dashboard_multiplier', _selectedMultiplier);
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF003366),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_selectedMultiplier',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Precious Metals Table ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F2F5)),
                ),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Color(0xFFF1F2F5), width: 1),
                    verticalInside: BorderSide(color: Color(0xFFF1F2F5), width: 1),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(1.0),
                  },
                  children: [
                    // Table Header
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      children: [
                        _buildTableHeaderCell('Updated at', Alignment.centerLeft),
                        _buildTableHeaderCell('Bid', Alignment.centerRight),
                        _buildTableHeaderCell('Ask', Alignment.centerRight),
                        _buildTableHeaderCell('Change', Alignment.centerRight),
                      ],
                    ),
                    // Table Rows
                    ...List.generate(
                      _isExpandedMetals ? _liveMetals.length : 3, // Show Gold, Silver, Silver (first 3)
                      (index) {
                        final metal = _liveMetals[index];
                        final converted = _convertMetalValues(
                          metal['bid'],
                          metal['ask'],
                          metal['change'],
                        );
                        final isPositive = converted['isPositive'] == 'true';
                        
                        return TableRow(
                          children: [
                            // Updated At & Metal Name
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  '${metal['time']} ${metal['name']}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Bid
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['bid']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Ask
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['ask']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Change
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['change']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? AppColors.success : AppColors.error,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── View All Metals Button ──────────────────────────────────────────
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isExpandedMetals = !_isExpandedMetals;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpandedMetals ? 'Collapse Metals' : 'View All Metals',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpandedMetals ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Footnote/Disclaimer Card ────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF2).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  '*Precious and Base Metals Quotes are live. Indices and Oil quotes are delayed by at least 30 minutes. Mining stock quotes are delayed by at least 20 minutes. TSX quotes are provided by Ticker technologies. Tap here to view disclaimer.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF003366),
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, Alignment alignment) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: alignment,
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF727271),
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // Bottom sheets selectors
  void _showPeriodSelector(BuildContext context) {
    final periods = ['Today', 'Yesterday', 'This Week', 'This Month', 'All Time'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((p) {
              return ListTile(
                title: Text(p, style: AppTextStyles.bodyMedium),
                trailing: _selectedPeriod == p ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedPeriod = p;
                    _saveSetting('dashboard_period', p);
                  });
                  Navigator.pop(context);
                  _loadTelemetryData();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCurrencySelector(BuildContext context) {
    final currencies = [
      {'code': 'USD', 'label': '🇺🇸 USD'},
      {'code': 'INR', 'label': '🇮🇳 INR'},
      {'code': 'EUR', 'label': '🇪🇺 EUR'},
      {'code': 'GBP', 'label': '🇬🇧 GBP'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              return ListTile(
                title: Text(c['label']!, style: AppTextStyles.bodyMedium),
                trailing: _selectedCurrency == c['code'] ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = c['code']!;
                    _saveSetting('dashboard_currency', c['code']!);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showUnitSelector(BuildContext context) {
    final units = ['Ounce', 'Gram', 'Tola'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: units.map((u) {
              return ListTile(
                title: Text(u, style: AppTextStyles.bodyMedium),
                trailing: _selectedUnit == u ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedUnit = u;
                    _saveSetting('dashboard_unit', u);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
*/

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/screen_utility.dart';
import '../../core/network/gold_session.dart';
import '../../core/constants/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/models/auth_models.dart';
import '../branch/repository/branch_repository.dart';
import '../branch/models/branch_model.dart';
import '../users/models/user_model.dart';
import '../loans/repository/loan_repository.dart';
import '../gold/repository/gold_repository.dart';
import '../gold/screens/gold_screen.dart';
import '../expenses/repository/expense_repository.dart';
import '../users/repository/user_repository.dart';
import 'repository/dashboard_repository.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;
  final VoidCallback? onSessionRefreshed;

  const DashboardScreen({super.key, this.onTabSelected, this.onSessionRefreshed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  // Super Admin / Zero Companies State
  User? _currentUser;
  int _companiesCount = 0;
  bool _isLoadingUserData = true;

  bool get _isSuperAdmin {
    final role = (_currentUser?.role ?? GoldSession.instance.userRole ?? '').toLowerCase().trim();
    return role.contains('super admin') || role == 'super admin';
  }

  bool get _hasZeroCompanies => _companiesCount == 0 && GoldSession.instance.userAccess.isEmpty;

  // Active Company & Sector State
  String? _activeCompanySector;
  String? _activeCompanyName;

  bool get _isMiningSector {
    final sector = (_activeCompanySector ?? GoldSession.instance.activeCompanySector ?? '').toLowerCase().trim();
    if (sector.contains('it') || sector.contains('information technology') || sector.contains('technology') || sector.contains('software')) {
      return false;
    }
    if (sector.contains('mining') || sector.contains('gold') || sector.contains('metal')) {
      return true;
    }
    if (sector.isNotEmpty) {
      return false;
    }
    return true;
  }

  // Settings & Toggles
  bool _showBalances = true;
  bool _autoUpdate = true;
  String _selectedPeriod = 'Today';
  String _selectedCurrency = 'USD';
  String _selectedUnit = 'Ounce';
  int _selectedMultiplier = 1;
  bool _isExpandedMetals = false;

  // Clock
  String _currentTimeString = '';
  Timer? _clockTimer;

  // Real-time market timer
  Timer? _fluctuationTimer;

  // Data State
  double _totalInvestment = 45682.50;
  double _totalPL = 1250.30;
  double _totalPLPercent = 2.80;
  double _todaysPL = 456.80;
  double _todaysPLPercent = 1.05;
  double _loansOutstanding = 45682.50;
  int _recentTransactionsCount = 0;

  // Precious Metals Rates State
  final List<Map<String, dynamic>> _baseMetals = [
    {
      'name': 'Gold',
      'baseBid': 4290.00,
      'baseAsk': 4292.00,
      'change': -38.40,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver', // Alternate silver row as shown in image
      'baseBid': 66.75,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.76,
      'baseAsk': 67.01,
      'change': -0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.75,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.76,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Silver',
      'baseBid': 66.78,
      'baseAsk': 67.01,
      'change': 0.95,
    },
    {
      'name': 'Palladium',
      'baseBid': 1752.00,
      'baseAsk': 1762.00,
      'change': 0.00,
    },
    {
      'name': 'Platinum',
      'baseBid': 1045.00,
      'baseAsk': 1048.50,
      'change': -12.30,
    },
  ];

  late List<Map<String, dynamic>> _liveMetals;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _companiesCount = GoldSession.instance.userAccess.length;
    _liveMetals = List.from(_baseMetals.map((m) => {
      'name': m['name'],
      'bid': m['baseBid'],
      'ask': m['baseAsk'],
      'change': m['change'],
      'time': DateFormat('HH:mm').format(DateTime.now()),
    }));

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateClock();
    });

    _loadSettings().then((_) {
      _loadTelemetryData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      goldRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Automatically re-check when returning to Home screen
    _loadTelemetryData();
  }

  @override
  void dispose() {
    goldRouteObserver.unsubscribe(this);
    _clockTimer?.cancel();
    _fluctuationTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTimeString = DateFormat('EEE, MMM d, yyyy, h:mm a').format(DateTime.now());
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showBalances = prefs.getBool('dashboard_show_balances') ?? true;
        _autoUpdate = prefs.getBool('dashboard_auto_update') ?? true;
        _selectedPeriod = prefs.getString('dashboard_period') ?? 'Today';
        _selectedCurrency = prefs.getString('dashboard_currency') ?? 'USD';
        _selectedUnit = prefs.getString('dashboard_unit') ?? 'Ounce';
        _selectedMultiplier = prefs.getInt('dashboard_multiplier') ?? 1;
      });
      _setupFluctuationTimer();
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  void _setupFluctuationTimer() {
    _fluctuationTimer?.cancel();
    if (_autoUpdate) {
      _fluctuationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && _autoUpdate) {
          setState(() {
            for (var metal in _liveMetals) {
              // 0.05% fluctuation
              final changePercent = (_random.nextDouble() * 0.1 - 0.05) / 100;
              final double oldBid = metal['bid'];
              final double newBid = oldBid * (1 + changePercent);
              final double spread = metal['ask'] - oldBid;

              metal['bid'] = newBid;
              metal['ask'] = newBid + spread;
              metal['change'] = metal['change'] + (newBid - oldBid);
              metal['time'] = DateFormat('HH:mm').format(DateTime.now());
            }
          });
        }
      });
    }
  }

  /*Future<void> _loadTelemetryData() async {
    try {
      final DashboardData? data = await DashboardRepository().getAdminDashboard(period: _selectedPeriod);
      if (data != null && mounted) {
        setState(() {
          _totalInvestment = data.totalInvestment;
          _totalPL = data.totalProfitLoss;
          _todaysPL = data.todayProfitLoss;
          _loansOutstanding = data.loansOutstanding;
          _recentTransactionsCount = data.recentTransactionsCount;

          _totalPLPercent = _totalInvestment > 0
              ? (_totalPL / _totalInvestment) * 100
              : 0.0;
          _todaysPLPercent = _totalInvestment > 0
              ? (_todaysPL / _totalInvestment) * 100
              : 0.0;
        });
      } else {
        await _loadTelemetryDataLocal();
      }
    } catch (e) {
      debugPrint('[Dashboard] Telemetry remote load error: $e. Falling back to local aggregation.');
      await _loadTelemetryDataLocal();
    }
  }
*/
  Future<void> _loadTelemetryData() async {
    try {
      int count = GoldSession.instance.userAccess.length;

      // 1. Silently update user access permissions in the background
      if (GoldSession.instance.userId != null) {
        try {
          final user = await UserRepository().getUser(GoldSession.instance.userId!);
          if (user != null) {
            _currentUser = user;
            if (user.role != null && user.role!.isNotEmpty) {
              await GoldSession.instance.updateUserRole(user.role!);
            }
            await GoldSession.instance.updateUserAccess(user.userAccess, user.globalAccess);
            count = user.userAccess.length;
            if (mounted) {
              widget.onSessionRefreshed?.call();
            }
          }
        } catch (e) {
          debugPrint('[Dashboard] Failed to refresh user profile: $e');
        }
      }

      // If count is 0 and role is super admin, check BranchRepository().getAllCompanies()
      if (count == 0 && _isSuperAdmin) {
        try {
          final comps = await BranchRepository().getAllCompanies();
          count = comps.length;
          if (comps.isNotEmpty) {
            final access = comps.map((c) => CompanyAccess(
              companyId: c.id ?? 0,
              companyName: c.companyName ?? '',
              sector: c.sector,
              branches: c.branches.map((b) => BranchAccess(
                branchId: int.tryParse(b.id ?? '') ?? 0,
                branchName: b.name,
                access: [],
              )).toList(),
            )).toList();
            await GoldSession.instance.updateUserAccess(access);
            if (mounted) {
              widget.onSessionRefreshed?.call();
            }
          }
        } catch (_) {}
      }

      // Always ensure active company sector is loaded
      try {
        final comps = await BranchRepository().getAllCompanies();
        if (comps.isNotEmpty) {
          final activeId = GoldSession.instance.userAccess.isNotEmpty
              ? GoldSession.instance.userAccess.first.companyId
              : null;
          final currentComp = activeId != null
              ? comps.firstWhere((c) => c.id == activeId, orElse: () => comps.first)
              : comps.first;
          _activeCompanySector = currentComp.sector;
          _activeCompanyName = currentComp.companyName;

          // Sync sector into GoldSession userAccess if missing
          final currentSessionAccess = GoldSession.instance.userAccess;
          if (currentSessionAccess.isNotEmpty) {
            final updatedAccess = currentSessionAccess.map((ca) {
              final match = comps.where((c) => c.id == ca.companyId).firstOrNull;
              if (match != null && match.sector != null && match.sector!.isNotEmpty && ca.sector != match.sector) {
                return CompanyAccess(
                  companyId: ca.companyId,
                  companyName: ca.companyName,
                  sector: match.sector,
                  branches: ca.branches,
                );
              }
              return ca;
            }).toList();
            await GoldSession.instance.updateUserAccess(updatedAccess);
          }
        }
      } catch (e) {
        debugPrint('[Dashboard] Error fetching active company sector: $e');
      }

      if (mounted) {
        setState(() {
          _companiesCount = count;
          _isLoadingUserData = false;
        });
      }

      // If Super Admin with 0 companies, skip dashboard telemetry calculations
      if (_isSuperAdmin && count == 0) {
        return;
      }

      // 2. Fetch period-scoped portfolio summary AND un-scoped totals
      // (loans/transactions) in parallel.
      final results = await Future.wait([
        DashboardRepository().getAdminDashboard(period: _selectedPeriod),
        DashboardRepository().getAdminDashboardTotals(),
      ]);

      final DashboardData? periodData = results[0];
      final DashboardData? totalsData = results[1];

      if (mounted && (periodData != null || totalsData != null)) {
        setState(() {
          if (periodData != null) {
            _totalInvestment = periodData.totalInvestment;
            _totalPL = periodData.totalProfitLoss;
            _todaysPL = periodData.todayProfitLoss;

            _totalPLPercent = _totalInvestment > 0
                ? (_totalPL / _totalInvestment) * 100
                : 0.0;
            _todaysPLPercent = _totalInvestment > 0
                ? (_todaysPL / _totalInvestment) * 100
                : 0.0;
          }

          if (totalsData != null) {
            _loansOutstanding = totalsData.loansOutstanding;
            _recentTransactionsCount = totalsData.recentTransactionsCount;
          }
        });
      }

      if (periodData == null && totalsData == null) {
        await _loadTelemetryDataLocal();
      }
    } catch (e) {
      debugPrint('[Dashboard] Telemetry remote load error: $e. Falling back to local aggregation.');
      await _loadTelemetryDataLocal();
    }
  }
  /// Refreshes ONLY the portfolio summary (Total Investment, Total P&L,
  /// Today's P&L) when the period dropdown changes.
  /// Does NOT touch Loans Outstanding or Recent Transactions — those stay
  /// fixed from the initial dashboard load / pull-to-refresh only.
  Future<void> _loadPortfolioSummaryForPeriod() async {
    try {
      final DashboardData? data =
          await DashboardRepository().getAdminDashboard(period: _selectedPeriod);
      if (data != null && mounted) {
        setState(() {
          _totalInvestment = data.totalInvestment;
          _totalPL = data.totalProfitLoss;
          _todaysPL = data.todayProfitLoss;

          _totalPLPercent = _totalInvestment > 0
              ? (_totalPL / _totalInvestment) * 100
              : 0.0;
          _todaysPLPercent = _totalInvestment > 0
              ? (_todaysPL / _totalInvestment) * 100
              : 0.0;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Portfolio summary period load error: $e');
    }
  }
  

  Future<void> _loadTelemetryDataLocal() async {
    try {
      // 1. Fetch outstanding loans
      final loanRecords = await LoanRepository().getRecords();
      double loansSum = 0;
      double principalSum = 0;
      for (var record in loanRecords) {
        for (var person in record.persons) {
          loansSum += person.totalPending;
          principalSum += person.totalPrincipal;
        }
      }

      // 2. Fetch gold purchases
      final goldGroups = await GoldRepository().getAllGoldPurchases();
      double goldSum = 0;
      for (var group in goldGroups) {
        for (var rec in group.records) {
          goldSum += rec.grandTotal ?? 0;
        }
      }

      // 3. Fetch expenses (count only, since Recent Transactions now shows a count)
      final expenseGroups = await ExpenseRepository().getAllExpenses();
      int expensesCount = 0;
      for (var group in expenseGroups) {
        expensesCount += group.records.length;
      }

      if (mounted) {
        setState(() {
          _loansOutstanding = loansSum > 0 ? loansSum : 45682.50;
          _totalInvestment = (principalSum + goldSum) > 0 ? (principalSum + goldSum) : 45682.50;
          _recentTransactionsCount = expensesCount;

          // P&L ratios fallback
          _totalPL = _totalInvestment * 0.028;
          _totalPLPercent = 2.80;
          _todaysPL = _totalInvestment * 0.028;
          _todaysPLPercent = 2.80;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Local Telemetry fallback error: $e');
    }
  }

  // Currency formatting helper
  String _formatCurrency(double amount) {
    if (!_showBalances) return '••••••';

    // Underlying portfolio amounts are already in INR (native currency).
    // Convert OUT of INR for other display currencies instead of into it.
    String symbol = '₹';
    double convertedAmount = amount.abs();

    if (_selectedCurrency == 'USD') {
      symbol = '\$';
      convertedAmount = amount.abs() / 83.5;
    } else if (_selectedCurrency == 'EUR') {
      symbol = '€';
      convertedAmount = (amount.abs() / 83.5) * 0.92;
    } else if (_selectedCurrency == 'GBP') {
      symbol = '£';
      convertedAmount = (amount.abs() / 83.5) * 0.79;
    }
    // INR needs no conversion — it's already native.

    final format = NumberFormat.currency(locale: 'en_US', symbol: '$symbol ', decimalDigits: 2);
    return format.format(convertedAmount);
  }

  // Precious metals values conversion based on unit, currency & weight multiplier
  Map<String, String> _convertMetalValues(double bid, double ask, double change) {
    double conversionFactor = 1.0;

    // Base quotes are per Ounce in USD.
    // 1 Ounce = 28.3495 Grams
    // 1 Tola = 11.6638 Grams = 0.4114 Ounces
    if (_selectedUnit == 'Gram') {
      conversionFactor /= 28.3495;
    } else if (_selectedUnit == 'Tola') {
      conversionFactor *= (11.6638 / 28.3495);
    }

    // Currency conversions
    if (_selectedCurrency == 'INR') {
      conversionFactor *= 83.5;
    } else if (_selectedCurrency == 'EUR') {
      conversionFactor *= 0.92;
    } else if (_selectedCurrency == 'GBP') {
      conversionFactor *= 0.79;
    }

    // Multiplier
    conversionFactor *= _selectedMultiplier;

    final double displayBid = bid * conversionFactor;
    final double displayAsk = ask * conversionFactor;
    final double displayChange = change * conversionFactor;

    final format = NumberFormat('#,##0.00', 'en_US');
    final changeFormat = NumberFormat('+#,##0.00;-#,##0.00', 'en_US');

    return {
      'bid': format.format(displayBid),
      'ask': format.format(displayAsk),
      'change': displayChange == 0.0 ? '0.00' : changeFormat.format(displayChange),
      'isPositive': displayChange >= 0 ? 'true' : 'false',
    };
  }

  Widget _buildNoCompanyState() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadTelemetryData();
      },
      color: AppColors.primaryBlue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/Company.svg',
                            width: 44,
                            height: 44,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_outlined,
                              size: 44,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create company first',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please create your company first to start managing branches, expenses, and portfolio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, AppRoutes.addCompany);
                            if (result == true) {
                              await _loadTelemetryData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '+ Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtility().init(context);

    if (_isSuperAdmin && _hasZeroCompanies) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: _buildNoCompanyState(),
      );
    }

    final totalPLColor = _totalPL >= 0 ? AppColors.success : AppColors.error;
    final todaysPLColor = _todaysPL >= 0 ? AppColors.success : AppColors.error;

    final totalPLSign = _totalPL >= 0 ? '+' : '-';
    final todaysPLSign = _todaysPL >= 0 ? '+' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTelemetryData();
        },
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section (Market Status) ─────────────────────────────────
              if (_isMiningSector) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'The Spot Market is Open',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF727271),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Closes in 13hrs, 40mins',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Portfolio Summary Card ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F2F5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Portfolio Summary',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showBalances = !_showBalances;
                                  _saveSetting('dashboard_show_balances', _showBalances);
                                });
                              },
                              child: Icon(
                                _showBalances ? Icons.visibility : Icons.visibility_off,
                                size: 18,
                                color: const Color(0xFF727271),
                              ),
                            ),
                          ],
                        ),
                        // Dropdown for period
                        GestureDetector(
                          onTap: () => _showPeriodSelector(context),
                          child: Row(
                            children: [
                              Text(
                                _selectedPeriod,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Total Investment
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Investment',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatCurrency(_totalInvestment),
                                  style: AppTextStyles.amount.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFF1F2F5),
                        ),
                        const SizedBox(width: 12),
                        // Total P&L
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total P&L',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _showBalances
                                      ? '$totalPLSign${_formatCurrency(_totalPL)} (${_totalPLPercent.abs().toStringAsFixed(2)}%)'
                                      : '••••••',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: totalPLColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFF1F2F5),
                        ),
                        const SizedBox(width: 12),
                        // Todays P&L
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todays P&L',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF727271),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _showBalances
                                      ? '$todaysPLSign${_formatCurrency(_todaysPL)} (${_todaysPLPercent.abs().toStringAsFixed(2)}%)'
                                      : '••••••',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: todaysPLColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isMiningSector) ...[
                const SizedBox(height: 16),

                // ── Quick Access Row (Loans & Recent Transactions) ────────────────
                Row(
                  children: [
                    // Loans Outstanding Card
                    Expanded(
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F2F5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF003366),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.monetization_on_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Loans Outstanding',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF727271),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatCurrency(_loansOutstanding),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Recent Transactions Card
                    Expanded(
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F2F5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF003366),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Recent Transactions',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: const Color(0xFF727271),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$_recentTransactionsCount',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Precious Metals Header & Selectors ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Precious Metals -',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      // Currency Selector dropdown
                      GestureDetector(
                        onTap: () => _showCurrencySelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedCurrency == 'USD'
                                    ? '🇺🇸 USD'
                                    : _selectedCurrency == 'INR'
                                        ? '🇮🇳 INR'
                                        : _selectedCurrency == 'EUR'
                                            ? '🇪🇺 EUR'
                                            : '🇬🇧 GBP',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit Selector dropdown
                      GestureDetector(
                        onTap: () => _showUnitSelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedUnit,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Multiplier Toggle button (1 vs 10)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMultiplier = _selectedMultiplier == 1 ? 10 : 1;
                            _saveSetting('dashboard_multiplier', _selectedMultiplier);
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF003366),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_selectedMultiplier',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Precious Metals Table ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F2F5)),
                ),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Color(0xFFF1F2F5), width: 1),
                    verticalInside: BorderSide(color: Color(0xFFF1F2F5), width: 1),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(1.0),
                  },
                  children: [
                    // Table Header
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      children: [
                        _buildTableHeaderCell('Updated at', Alignment.centerLeft),
                        _buildTableHeaderCell('Bid', Alignment.centerRight),
                        _buildTableHeaderCell('Ask', Alignment.centerRight),
                        _buildTableHeaderCell('Change', Alignment.centerRight),
                      ],
                    ),
                    // Table Rows
                    ...List.generate(
                      _isExpandedMetals ? _liveMetals.length : 3, // Show Gold, Silver, Silver (first 3)
                      (index) {
                        final metal = _liveMetals[index];
                        final converted = _convertMetalValues(
                          metal['bid'],
                          metal['ask'],
                          metal['change'],
                        );
                        final isPositive = converted['isPositive'] == 'true';

                        return TableRow(
                          children: [
                            // Updated At & Metal Name
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  '${metal['time']} ${metal['name']}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Bid
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['bid']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Ask
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['ask']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Change
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  converted['change']!,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? AppColors.success : AppColors.error,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── View All Metals Button ──────────────────────────────────────────
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isExpandedMetals = !_isExpandedMetals;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpandedMetals ? 'Collapse Metals' : 'View All Metals',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpandedMetals ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Footnote/Disclaimer Card ────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF2).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  '*Precious and Base Metals Quotes are live. Indices and Oil quotes are delayed by at least 30 minutes. Mining stock quotes are delayed by at least 20 minutes. TSX quotes are provided by Ticker technologies. Tap here to view disclaimer.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF003366),
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTableHeaderCell(String text, Alignment alignment) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: alignment,
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF727271),
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // Bottom sheets selectors
  void _showPeriodSelector(BuildContext context) {
    final periods = ['Today', 'Yesterday', 'This Week', 'This Month', 'All Time'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((p) {
              return ListTile(
                title: Text(p, style: AppTextStyles.bodyMedium),
                trailing: _selectedPeriod == p ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedPeriod = p;
                    _saveSetting('dashboard_period', p);
                  });
                  Navigator.pop(context);
                  _loadPortfolioSummaryForPeriod();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCurrencySelector(BuildContext context) {
    final currencies = [
      {'code': 'USD', 'label': '🇺🇸 USD'},
      {'code': 'INR', 'label': '🇮🇳 INR'},
      {'code': 'EUR', 'label': '🇪🇺 EUR'},
      {'code': 'GBP', 'label': '🇬🇧 GBP'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              return ListTile(
                title: Text(c['label']!, style: AppTextStyles.bodyMedium),
                trailing: _selectedCurrency == c['code'] ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = c['code']!;
                    _saveSetting('dashboard_currency', c['code']!);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showUnitSelector(BuildContext context) {
    final units = ['Ounce', 'Gram', 'Tola'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: units.map((u) {
              return ListTile(
                title: Text(u, style: AppTextStyles.bodyMedium),
                trailing: _selectedUnit == u ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() {
                    _selectedUnit = u;
                    _saveSetting('dashboard_unit', u);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}