import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/gold_session.dart';
import '../../../core/utils/responsive_extensions.dart';
import '../../../core/utils/screen_utility.dart';
import '../../../widgets/gold_dialogs.dart';
import '../../../widgets/gold_shimmer.dart';
import '../../../widgets/no_access_widget.dart';
import '../../gold/screens/gold_screen.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';
import '../widgets/expense_card.dart';
import '../widgets/section_header.dart';
import '../../branch/repository/branch_repository.dart';
import '../../branch/models/branch_model.dart';
import '../../users/repository/user_repository.dart';
import 'charts_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => ExpensesScreenState();
}

class ExpensesScreenState extends State<ExpensesScreen> with RouteAware {
  final ExpenseRepository _repository = ExpenseRepository();
  final BranchRepository _branchRepository = BranchRepository();
  List<ExpenseMonthGroup> _monthGroups = [];
  List<ExpenseMonthGroup> _filteredMonthGroups = [];
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
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
  void dispose() {
    goldRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Automatically refresh when a screen above is dismissed
    _fetchExpenses(showLoader: false);
  }

  Future<void> _fetchExpenses({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }
    try {
      if (GoldSession.instance.userId != null) {
        try {
          final user = await UserRepository().getUser(GoldSession.instance.userId!);
          if (user != null) {
            await GoldSession.instance.updateUserAccess(user.userAccess, user.globalAccess);
          }
        } catch (_) {}
      }

      final results = await Future.wait([
        _repository.getAllExpenses(),
        _branchRepository.getAllBranches(),
      ]);
      setState(() {
        _monthGroups = results[0] as List<ExpenseMonthGroup>;
        final loadedBranches = results[1] as List<Branch>;
        
        if (GoldSession.instance.userRole?.toLowerCase().contains('admin') == true) {
          _branches = loadedBranches;
        } else {
          _branches = loadedBranches.where((b) {
            final bId = int.tryParse(b.id ?? '') ?? 0;
            return GoldSession.instance.canRead('Expenses', branchId: bId);
          }).toList();
        }
        _isLoading = false;
      });
      filterExpenses(_searchController.text);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        GoldDialogs.showSnackBar(context, 'Failed to load expenses', isError: true);
      }
    }
  }

  void filterExpenses(String query) {
    final lowerQuery = query.toLowerCase();
    final List<ExpenseMonthGroup> newGroups = [];

    for (var group in _monthGroups) {
      final matchingRecords = group.records.where((rec) {
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final catName = rec.expenseCategory?.name.toLowerCase() ?? '';
          final desc = rec.description.toLowerCase();
          final comment = rec.comment?.toLowerCase() ?? '';
          matchesQuery = catName.contains(lowerQuery) ||
              desc.contains(lowerQuery) ||
              comment.contains(lowerQuery);
        }

        final matchesBranch = _selectedBranch == null || rec.branch?.id == _selectedBranch!.id;
        
        return matchesQuery && matchesBranch;
      }).toList();

      if (matchingRecords.isNotEmpty) {
        newGroups.add(ExpenseMonthGroup(
          month: group.month,
          records: matchingRecords,
        ));
      }
    }

    setState(() {
      _filteredMonthGroups = newGroups;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtility().init(context);

    if (!GoldSession.instance.canRead('Expenses')) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: NoAccessWidget(moduleName: 'Expenses'),
      );
    }

    // Generate a flattened list representing sections and records
    final List<dynamic> flatList = [];
    for (var group in _filteredMonthGroups) {
      final double totalSum =
          group.records.fold(0.0, (sum, rec) => sum + rec.amount);
      flatList.add({'month': group.month, 'sum': totalSum});
      flatList.addAll(group.records);
    }

    // Check if user is an admin
    final role = GoldSession.instance.userRole?.toLowerCase();
    final isAdmin = role != null && role.contains('admin');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            if (!_isLoading)
              Row(
                children: [
                    Expanded(
                      child: Container(
                        height: 5.h,
                        margin: EdgeInsets.only(top: 1.h, bottom: 0),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _branches.length + 1,
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final branch = isAll ? null : _branches[index - 1];
                            final isSelected = _selectedBranch?.id == branch?.id;
                            final title = isAll ? 'All' : (branch?.name ?? '');

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBranch = branch;
                                });
                                filterExpenses(_searchController.text);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: IntrinsicWidth(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? const Color(0xFF003366) : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          margin: EdgeInsets.only(top: 0.5.h),
                                          height: 2,
                                          color: const Color(0xFF003366),
                                        ),
                                      if (!isSelected)
                                        Container(
                                          margin: EdgeInsets.only(top: 0.5.h),
                                          height: 2,
                                          color: Colors.transparent,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.reports);
                            },
                            child: SvgPicture.asset(
                              'assets/images/Excel.svg',
                              width: 8.w,
                              height: 8.w,
                            ),
                          ),
                          SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChartsScreen()),
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/images/Pie.svg',
                            width: 8.w,
                            height: 8.w,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                    ),
            ],
          ),
          Expanded(
            child: _isLoading
                  ? ListView.builder(
                      padding: EdgeInsets.only(
                        left: 4.w,
                        right: 4.w,
                        bottom: 1.5.h,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GoldShimmer(
                                  width: 12.w,
                                  height: 6.h,
                                  borderRadius: 6.r),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GoldShimmer(
                                        width: 35.w,
                                        height: 2.h,
                                        borderRadius: 1.r),
                                    SizedBox(height: 1.h),
                                    GoldShimmer(
                                        width: 22.w,
                                        height: 1.5.h,
                                        borderRadius: 1.r),
                                  ],
                                ),
                              ),
                              SizedBox(width: 4.w),
                              GoldShimmer(
                                  width: 18.w,
                                  height: 2.5.h,
                                  borderRadius: 1.r),
                            ],
                          ),
                        );
                      },
                    )
                  : flatList.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchExpenses,
                          color: AppColors.primaryBlue,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 5.h,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(5.w),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_outlined,
                                            size: 11.w,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          _searchController.text.isEmpty
                                              ? 'No expenses recorded'
                                              : 'No matching results',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.sp,
                                          ),
                                        ),
                                        SizedBox(height: 1.5.h),
                                        Text(
                                          _searchController.text.isEmpty
                                              ? 'Start tracking your spending by adding a new expense record using the + button.'
                                              : 'We couldn\'t find any expenses matching "${_searchController.text}".',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14.sp,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchExpenses,
                          color: AppColors.primaryBlue,
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              left: 4.w,
                              right: 4.w,
                              bottom: 1.5.h,
                            ),
                            itemCount: flatList.length,
                            itemBuilder: (context, index) {
                              final item = flatList[index];

                              if (item is Map<String, dynamic>) {
                                return SectionHeader(
                                  title: item['month'] as String,
                                );
                              }

                              if (item is Expense) {
                                return ExpenseCard(
                                  expense: item,
                                  onReturnFromDetails: () =>
                                      _fetchExpenses(showLoader: false),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
