import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/gold_dio_client.dart';
import '../../branch/repository/branch_repository.dart';
import '../../branch/models/branch_model.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repository/category_repository.dart';
import '../../users/models/user_model.dart';
import '../../users/repository/user_repository.dart';
import '../../../widgets/gold_app_bar.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';

class CategoryWiseExpense {
  final String categoryName;
  final double totalAmount;

  CategoryWiseExpense({required this.categoryName, required this.totalAmount});
}

class TimeWiseExpense {
  final String period;
  final double totalAmount;

  TimeWiseExpense({required this.period, required this.totalAmount});
}

Color _pieColor(int index) {
  final hue = (index * 137.508 + 200) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
}

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<Expense> _allExpenses = [];
  List<String> _availableCurrencies = [];
  String? _selectedCurrency;
  bool _isLoadingExpenses = false;

  final BranchRepository _branchRepository = BranchRepository();
  Branch? _selectedBranch;
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;

  final UserRepository _userRepository = UserRepository();
  List<User> _allUsers = [];
  bool _isLoadingUsers = false;
  User? _selectedUser;

  final CategoryRepository _categoryRepository = CategoryRepository();
  List<ExpenseCategory> _categories = [];
  bool _isLoadingCategories = false;
  ExpenseCategory? _selectedCategory;

  String? _selectedChartType;
  final List<String> _chartTypes = ['Spending By Category', 'Spending Over Time'];

  String _selectedDateLabel = 'All Time';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingBranches = true;
      _isLoadingUsers = true;
      _isLoadingExpenses = true;
    });

    try {
      final branches = await _branchRepository.getAllBranches();
      if (mounted) setState(() => _branches = branches);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }

    try {
      final users = await _userRepository.getAllUsers();
      if (mounted) setState(() => _allUsers = users);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }

    try {
      final expenseGroups = await _expenseRepository.getAllExpenses();
      final allExp = expenseGroups.expand((g) => g.records).toList();
      if (mounted) {
        setState(() {
          _allExpenses = allExp;
        });
        _updateCurrencies();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingExpenses = false);
    }
  }

  void _updateCurrencies() {
    if (_selectedBranch == null) {
      _availableCurrencies = [];
      _selectedCurrency = null;
      return;
    }
    
    var filtered = _allExpenses.where((e) => e.branch?.id == _selectedBranch!.id);
    if (_selectedUser != null) {
      filtered = filtered.where((e) => e.paidByUser?.id == _selectedUser!.id);
    }
    
    final currencies = filtered.map((e) => e.amountType).toSet().toList();
    if (currencies.isNotEmpty) {
      currencies.sort();
    }
    
    setState(() {
      _availableCurrencies = currencies;
      if (_selectedCurrency != null && !currencies.contains(_selectedCurrency)) {
        _selectedCurrency = null;
      }
    });
  }

  void _openBranchPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Select Branch',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  const Divider(height: 1),
                  if (_isLoadingBranches)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))
                  else if (_branches.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No branches found', style: TextStyle(color: Colors.grey))))
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _branches.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final b = _branches[index];
                          final isSelected = _selectedBranch?.id == b.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(b.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20) : null,
                            onTap: () {
                              setState(() {
                                _selectedBranch = b;
                                _selectedCategory = null;
                                _categories = [];
                              });
                              Navigator.pop(context);
                              _fetchCategories();
                              _updateCurrencies();
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
      },
    );
  }

  void _openChartTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Select Category or Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                itemCount: _chartTypes.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final t = _chartTypes[index];
                  final isSelected = _selectedChartType == t;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(t,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20) : null,
                    onTap: () {
                      setState(() {
                        _selectedChartType = t;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchCategories() async {
    if (_selectedBranch == null) return;
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await _categoryRepository.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _openCategoryPicker() {
    List<ExpenseCategory> activeCategories = _categories;
    if (_selectedBranch != null) {
      final usedCategoryIds = _allExpenses
          .where((e) => e.branch?.id == _selectedBranch!.id)
          .map((e) => e.expenseCategoryId.toString())
          .toSet();

      activeCategories = _categories.where((c) {
        return usedCategoryIds.contains(c.id.toString());
      }).toList();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Select Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  const Divider(height: 1),
                  if (_isLoadingCategories)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))
                  else
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text('All Categories',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCategory == null ? AppColors.primaryBlue : AppColors.textPrimary)),
                            trailing: _selectedCategory == null
                                ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                                : null,
                            onTap: () {
                              setState(() => _selectedCategory = null);
                              Navigator.pop(context);
                            },
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          ...activeCategories.map((cat) {
                            final isSelected = _selectedCategory?.id == cat.id;
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  title: Text(cat.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary)),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    Navigator.pop(context);
                                  },
                                ),
                                const Divider(height: 1, indent: 20, endIndent: 20),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openUserPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return MemberPickerBottomSheet(
          allUsers: _allUsers,
          allExpenses: _allExpenses,
          selectedBranch: _selectedBranch,
          selectedUser: _selectedUser,
          isLoading: _isLoadingUsers,
          onSelected: (user) {
            setState(() {
              _selectedUser = user;
            });
            _updateCurrencies();
          },
        );
      },
    );
  }

  void _openCurrencyPicker() {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch first', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Select Currency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const Divider(height: 1),
              if (_isLoadingExpenses)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))
              else if (_availableCurrencies.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No currencies found', style: TextStyle(color: Colors.grey))))
              else
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [

                      ..._availableCurrencies.map((c) {
                        final isSelected = _selectedCurrency == c;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              title: Text(c,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary)),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20) : null,
                              onTap: () {
                                setState(() {
                                  _selectedCurrency = c;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openDatePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DateFilterPickerBottomSheet(initialLabel: _selectedDateLabel);
      },
    ).then((value) {
      if (value != null && value is String) {
        setState(() {
          _selectedDateLabel = value;
        });
      }
    });
  }

  bool _isFetchingChartData = false;
  List<CategoryWiseExpense> _chartData = [];
  List<TimeWiseExpense> _timeChartData = [];
  String _groupingType = '';
  bool _hasChartData = false;

  Future<void> _fetchChartData() async {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch first', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedChartType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category or time first', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a currency first', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isFetchingChartData = true;
    });

    try {
      final queryParams = <String, dynamic>{
        'branchId': _selectedBranch!.id,
      };

      if (_selectedUser != null) {
        queryParams['userId'] = _selectedUser!.id;
      }
      
      if (_selectedCurrency != null) {
        queryParams['amountType'] = _selectedCurrency;
      }

      if (_selectedChartType == 'Spending By Category' && _selectedDateLabel != 'All Time') {
        if (_selectedDateLabel.contains(' - ')) {
          final parts = _selectedDateLabel.split(' - ');
          if (parts.length == 2) {
            try {
              final start = DateFormat('dd/MM/yyyy').parse(parts[0]);
              final end = DateFormat('dd/MM/yyyy').parse(parts[1]);
              queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(start);
              queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(end);
            } catch (_) {}
          }
        } else {
          try {
            final monthDate = DateFormat('MMM yyyy').parse(_selectedDateLabel);
            final startDate = DateTime(monthDate.year, monthDate.month, 1);
            final endDate = DateTime(monthDate.year, monthDate.month + 1, 0);
            queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
            queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
          } catch (_) {}
        }
      }

      if (kDebugMode) {
        debugPrint('🌐 FETCHING CHART DATA: /expense/report/category-wise');
        debugPrint('📦 QUERY PARAMS: $queryParams');
      }

      if (_selectedChartType == 'Spending By Category') {
        final response = await GoldDioClient.instance.dio.get(
          '/expense/report/category-wise',
          queryParameters: queryParams,
        );
        if (kDebugMode) debugPrint('✅ CATEGORY-WISE RESPONSE: ${response.data}');

        List<dynamic> rawData = [];
        final dynamic dataPayload = response.data['data'];

        if (dataPayload is Map) {
          if (_selectedCurrency != null && dataPayload[_selectedCurrency] is Map) {
            final currencyMap = dataPayload[_selectedCurrency] as Map<String, dynamic>;
            if (currencyMap['reports'] is List) {
              rawData = currencyMap['reports'] as List<dynamic>;
            }
          } else if (dataPayload.values.isNotEmpty) {
            final firstEntry = dataPayload.values.first;
            if (firstEntry is Map && firstEntry['reports'] is List) {
              rawData = firstEntry['reports'] as List<dynamic>;
            }
          }
        } else if (dataPayload is List) {
          rawData = dataPayload;
        }

        final parsed = rawData.map((item) {
          final categoryName = (item['category']?['name'] as String?) ?? 'Unknown';
          final totalAmount = (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
          return CategoryWiseExpense(categoryName: categoryName, totalAmount: totalAmount);
        }).toList();

        if (mounted) {
          setState(() {
            _chartData = parsed;
            _hasChartData = true;
          });
        }
      } else {
        // Spending Over Time
        if (_selectedCategory != null) {
          queryParams['categoryId'] = _selectedCategory!.id;
        }
        if (kDebugMode) {
          debugPrint('🌐 FETCHING CHART DATA: /expense/report/time-wise');
          debugPrint('📦 QUERY PARAMS: $queryParams');
        }
        final response = await GoldDioClient.instance.dio.get(
          '/expense/report/time-wise',
          queryParameters: queryParams,
        );
        if (kDebugMode) debugPrint('✅ TIME-WISE RESPONSE: ${response.data}');

        final gType = response.data['groupingType'] as String? ?? '';
        List<dynamic> rawData = [];
        final dynamic timeDataPayload = response.data['data'];

        if (timeDataPayload is Map) {
          if (_selectedCurrency != null && timeDataPayload[_selectedCurrency] is Map) {
            final currencyMap = timeDataPayload[_selectedCurrency] as Map<String, dynamic>;
            if (currencyMap['reports'] is List) {
              rawData = currencyMap['reports'] as List<dynamic>;
            }
          } else if (timeDataPayload.values.isNotEmpty) {
            final firstEntry = timeDataPayload.values.first;
            if (firstEntry is Map && firstEntry['reports'] is List) {
              rawData = firstEntry['reports'] as List<dynamic>;
            }
          }
        } else if (timeDataPayload is List) {
          rawData = timeDataPayload;
        }

        final parsed = rawData.map((item) {
          final period = (item['period'] as String?) ?? 'Unknown';
          final totalAmount = (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
          return TimeWiseExpense(period: period, totalAmount: totalAmount);
        }).toList();

        if (mounted) {
          setState(() {
            _groupingType = gType;
            _timeChartData = parsed;
            _hasChartData = true;
          });
        }
      }

    } catch (e) {
      if (kDebugMode) debugPrint('❌ CHART API ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to show chart data', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingChartData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const GoldAppBar(
        title: 'Charts',
        titleFontSize: 18,
        showSearch: false,
        showBackButton: true,
        centerTitle: true,
        showNotification: false,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              hint: 'Select Branch',
              value: _selectedBranch?.name,
              onTap: _openBranchPicker,
            ),
            const SizedBox(height: 20),
            _buildField(
              hint: 'Select Category or Time',
              value: _selectedChartType,
              onTap: _openChartTypePicker,
            ),
            const SizedBox(height: 24),
            
            if (_selectedChartType == 'Spending By Category') ...[
              const Text(
                'Showing Expenses for',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildField(
                hint: 'All Time',
                value: _selectedDateLabel,
                onTap: _openDatePickerBottomSheet,
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedChartType == 'Spending Over Time') ...[
              const Text(
                'Showing Expenses for',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildField(
                hint: 'All Categories',
                value: _selectedCategory != null ? _selectedCategory!.name : 'All Categories',
                onTap: _openCategoryPicker,
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedChartType != null) ...[
              _buildField(
                hint: 'All Members',
                value: _selectedUser != null ? _selectedUser!.name : 'All Members',
                onTap: _openUserPicker,
              ),
              const SizedBox(height: 20),
            ],

            _buildField(
              hint: 'Select Currency',
              value: _selectedCurrency,
              onTap: _openCurrencyPicker,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton('Reset', isGo: false),
                _buildActionButton('GO', isGo: true),
              ],
            ),

            if (_hasChartData) ...[
              const SizedBox(height: 32),
              if (_selectedChartType == 'Spending By Category' ? _chartData.isEmpty : _timeChartData.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No expenses found\nfor selected filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF727271)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_selectedChartType == 'Spending By Category') ...[
                _buildPieChart(),
                const SizedBox(height: 32),
                _buildLegend(),
              ] else ...[
                _buildBarChart(),
                const SizedBox(height: 32),
                _buildTimeWiseLegend(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String hint, required String? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF727271),
              fontSize: 14,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    // Sort descending by totalAmount
    final sorted = [..._chartData]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final sections = sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = _pieColor(index);
      return PieChartSectionData(
        value: item.totalAmount,
        color: color,
        radius: 130,
        title: '',
        showTitle: false,
      );
    }).toList();

    return SizedBox(
      height: 320,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 1,
          centerSpaceRadius: 0,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final amountFmt = NumberFormat('#,##0.00', 'en_IN');
    // Sort descending by totalAmount
    final sorted = [..._chartData]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    const double amountColWidth = 140.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: const [
            Expanded(
              child: Text(
                'Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(
              width: amountColWidth,
              child: Text(
                'Total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final color = _pieColor(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.categoryName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: amountColWidth,
                  child: Text(
                    '${_selectedCurrency != null ? '$_selectedCurrency ' : ''}${amountFmt.format(item.totalAmount)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBarChart() {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final chartAreaWidth = screenWidth - 60.0;
    final minChartWidth = _timeChartData.length * 60.0;
    final chartWidth = minChartWidth > chartAreaWidth ? minChartWidth : chartAreaWidth;

    double maxDataValue = 0;
    for (var item in _timeChartData) {
      if (item.totalAmount > maxDataValue) {
        maxDataValue = item.totalAmount;
      }
    }
    // Add 20% padding at the top
    final calculatedMaxY = maxDataValue > 0 ? maxDataValue * 1.2 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCurrency != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              '(${_selectedCurrency!})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF727271),
              ),
            ),
          ),
        SizedBox(
          height: 320,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Pinned Y-Axis
          SizedBox(
            width: 60,
            child: BarChart(
              BarChartData(
                maxY: calculatedMaxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value == meta.max) return const SizedBox.shrink();
                        // Semicompact formatting
                        String formatted;
                        if (value >= 1000000) {
                          formatted = '${(value / 1000000).toStringAsFixed(1)}M';
                        } else if (value >= 1000) {
                          formatted = '${(value / 1000).toStringAsFixed(1)}K';
                        } else {
                          formatted = value.toStringAsFixed(0);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            formatted,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                    left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                barGroups: <BarChartGroupData>[],
              ),
            ),
          ),
          // Scrollable Chart
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: calculatedMaxY,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _timeChartData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _timeChartData[index].period,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                        left: BorderSide.none,
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                    barGroups: _timeChartData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.totalAmount,
                            color: const Color(0xFF64B5F6),
                            width: 16,
                            borderRadius: BorderRadius.zero,
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeWiseLegend() {
    final amountFmt = NumberFormat('#,##0.00', 'en_IN');
    const double amountColWidth = 140.0;

    String heading = 'Period';
    if (_groupingType.toLowerCase() == 'quarterly') {
      heading = 'Quarter';
    } else if (_groupingType.toLowerCase() == 'monthly') {
      heading = 'Month';
    } else if (_groupingType.toLowerCase() == 'weekly') {
      heading = 'Week';
    } else if (_groupingType.toLowerCase() == 'daily') {
      heading = 'Day';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(
              width: amountColWidth,
              child: const Text(
                'Total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Data rows
        ..._timeChartData.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.period,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: amountColWidth,
                  child: Text(
                    '${_selectedCurrency != null ? '$_selectedCurrency ' : ''}${amountFmt.format(item.totalAmount)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(String text, {required bool isGo}) {
    return GestureDetector(
      onTap: () {
        if (isGo && !_isFetchingChartData) {
          _fetchChartData();
        } else if (!isGo) {
          setState(() {
            _chartData = [];
            _timeChartData = [];
            _groupingType = '';
            _hasChartData = false;
            _selectedBranch = null;
            _availableCurrencies = [];
            _selectedCurrency = null;
            _selectedChartType = null;
            _selectedCategory = null;
            _categories = [];
            _selectedUser = null;
            _selectedDateLabel = 'All Time';
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isGo ? 32 : 24, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF002E6E),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: _isFetchingChartData && isGo
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF002E6E)))
            : Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF002E6E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class DateFilterPickerBottomSheet extends StatefulWidget {
  final String? initialLabel;

  const DateFilterPickerBottomSheet({Key? key, this.initialLabel}) : super(key: key);

  @override
  State<DateFilterPickerBottomSheet> createState() => _DateFilterPickerBottomSheetState();
}

class _DateFilterPickerBottomSheetState extends State<DateFilterPickerBottomSheet> {
  String? _selectedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialLabel != null && widget.initialLabel != 'All Time') {
      if (widget.initialLabel!.contains(' - ')) {
        final parts = widget.initialLabel!.split(' - ');
        if (parts.length == 2) {
          try {
            _startDate = DateFormat('dd/MM/yyyy').parse(parts[0]);
            _endDate = DateFormat('dd/MM/yyyy').parse(parts[1]);
          } catch (_) {}
        }
      } else {
        _selectedMonth = widget.initialLabel;
      }
    }
  }

  List<String> _generateMonths() {
    final months = <String>[];
    DateTime current = DateTime.now();
    for (int i = 0; i < 12; i++) {
      months.add(DateFormat('MMM yyyy').format(current));
      current = DateTime(current.year, current.month - 1, 1);
    }
    return months;
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          _selectedMonth = null; 
        } else {
          _endDate = date;
          _selectedMonth = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _generateMonths();
    final double itemWidth = (MediaQuery.of(context).size.width - 40 - 24) / 3;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMonth = null;
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'ALL TIME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: (_selectedMonth == null && _startDate == null && _endDate == null)
                        ? AppColors.primaryBlue
                        : const Color(0xFF727271),
                  ),
                ),
              ),
            ),
            const Text(
              'BY MONTH',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF727271),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: months.map((m) {
                final isSelected = _selectedMonth == m;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = m;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : const Color(0xFFE8E8E8),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 24),
            const Text(
              'CUSTOM RANGE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF727271),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Start Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _startDate != null ? AppColors.textPrimary : const Color(0xFFB0B1B4),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF727271)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF727271)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'End Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _endDate != null ? AppColors.textPrimary : const Color(0xFFB0B1B4),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF727271)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = null;
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedMonth != null) {
                        Navigator.pop(context, _selectedMonth);
                      } else if (_startDate != null && _endDate != null) {
                        Navigator.pop(context, '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}');
                      } else {
                        Navigator.pop(context, 'All Time');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MemberPickerBottomSheet extends StatelessWidget {
  final List<User> allUsers;
  final List<Expense> allExpenses;
  final Branch? selectedBranch;
  final User? selectedUser;
  final bool isLoading;
  final ValueChanged<User?> onSelected;

  const MemberPickerBottomSheet({
    Key? key,
    required this.allUsers,
    required this.allExpenses,
    this.selectedBranch,
    this.selectedUser,
    this.isLoading = false,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<User> branchUsers = allUsers;
    if (selectedBranch != null) {
      final branchIdStr = selectedBranch!.id?.toString();
      final paidByUserIds = allExpenses
          .where((e) => e.branch?.id == selectedBranch!.id && e.paidByUser != null)
          .map((e) => e.paidByUser!.id.toString())
          .toSet();

      final branchIdInt = int.tryParse(branchIdStr ?? '') ?? 0;
      branchUsers = allUsers.where((u) {
        final isBranchMember = u.branchIds.contains(branchIdInt) || u.branchId == branchIdInt;
        final isPaidByUser = paidByUserIds.contains(u.id.toString());
        return isBranchMember && isPaidByUser;
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select Member',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
            )
          else
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(
                      'All Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selectedUser == null ? AppColors.primaryBlue : AppColors.textPrimary,
                      ),
                    ),
                    trailing: selectedUser == null
                        ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                        : null,
                    onTap: () {
                      onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  ...branchUsers.map((u) {
                    final isSelected = selectedUser?.id == u.id;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          title: Text(
                            u.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                              : null,
                          onTap: () {
                            onSelected(u);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
