import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../branch/repository/branch_repository.dart';
import '../../branch/models/branch_model.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repository/category_repository.dart';
import '../../users/models/user_model.dart';
import '../../users/repository/user_repository.dart';
import '../../../widgets/gold_app_bar.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';
import 'charts_screen.dart'; // For DateFilterPickerBottomSheet
import '../../../core/network/gold_session.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedDocumentType = 'Excel';

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<Expense> _allExpenses = [];
  List<String> _availableCurrencies = [];
  String? _selectedCurrency;
  bool _isLoadingExpenses = false;
  bool _isDownloading = false;

  // --- Logic from ChartsScreen ---
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

    final topCompany = GoldSession.instance.userAccess.isNotEmpty ? GoldSession.instance.userAccess.first : null;
    final topCompanyId = topCompany?.companyId;

    try {
      final topCompanyBranchIds = topCompany?.branches.map((b) => b.branchId).toSet() ?? {};
      final allBranches = await _branchRepository.getAllBranches(companyId: topCompanyId);
      final allowedBranchIds = GoldSession.instance.getBranchIdsForReports('Expenses');
      final filteredBranches = allowedBranchIds == null
          ? allBranches.where((b) => topCompanyBranchIds.contains(int.tryParse(b.id ?? ''))).toList()
          : allBranches.where((b) {
              final bId = int.tryParse(b.id ?? '');
              return topCompanyBranchIds.contains(bId) && allowedBranchIds.contains(bId);
            }).toList();
      if (mounted) setState(() => _branches = filteredBranches);
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
      final expenseGroups = await _expenseRepository.getAllExpenses(companyId: topCompanyId);
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
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.expenseCategoryId == _selectedCategory!.id);
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
                                _selectedUser = null;
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
          selectedCategory: _selectedCategory,
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
  // --- End Logic from ChartsScreen ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const GoldAppBar(
        title: 'Reports',
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
            
            // Conditional Fields exactly like ChartsScreen
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
            const SizedBox(height: 20),

            // Document Type Selection
            const Text(
              'Choose Document Type',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDocumentTypeButton('Excel', Icons.download_rounded),
                const SizedBox(width: 12),
                _buildDocumentTypeButton('PDF Document', Icons.download_rounded),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          width: double.infinity,
          height: 60,
          margin: const EdgeInsets.all(0),
          child: ElevatedButton(
            onPressed: _isDownloading ? null : _handleDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002E6E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isDownloading
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Download',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.download_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
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

  Widget _buildDocumentTypeButton(String title, IconData icon) {
    bool isSelected = selectedDocumentType == title;
    
    final Color selectedBorderColor = const Color(0xFF002E6E);
    final Color selectedTextColor = const Color(0xFF002E6E);
    final Color selectedBgColor = const Color(0xFF727271).withOpacity(0.1);
    
    final Color unselectedColor = const Color(0xFF727271);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDocumentType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedBorderColor : unselectedColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? selectedTextColor : unselectedColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? selectedTextColor : unselectedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownload() async {
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

    setState(() => _isDownloading = true);

    try {
      final fileType = selectedDocumentType == 'Excel' ? 'excel' : 'pdf';
      final reportType = _selectedChartType == 'Spending By Category' ? 'category-wise' : 'time-wise';
      
      String? parsedStartDate;
      String? parsedEndDate;

      if (_selectedChartType == 'Spending By Category' && _selectedDateLabel != 'All Time') {
        if (_selectedDateLabel.contains(' - ')) {
          final parts = _selectedDateLabel.split(' - ');
          if (parts.length == 2) {
            try {
              final start = DateFormat('dd/MM/yyyy').parse(parts[0]);
              final end = DateFormat('dd/MM/yyyy').parse(parts[1]);
              parsedStartDate = DateFormat('yyyy-MM-dd').format(start);
              parsedEndDate = DateFormat('yyyy-MM-dd').format(end);
            } catch (_) {}
          }
        } else {
          try {
            final monthDate = DateFormat('MMM yyyy').parse(_selectedDateLabel);
            final startDate = DateTime(monthDate.year, monthDate.month, 1);
            final endDate = DateTime(monthDate.year, monthDate.month + 1, 0);
            parsedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
            parsedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
          } catch (_) {}
        }
      }

      final topCompanyId = GoldSession.instance.userAccess.isNotEmpty 
          ? GoldSession.instance.userAccess.first.companyId 
          : 1;

      final filePath = await _expenseRepository.downloadReport(
        companyId: topCompanyId!,
        branchId: _selectedBranch!.id!,
        fileType: fileType,
        reportType: reportType,
        currency: _selectedCurrency!,
        startDate: parsedStartDate,
        endDate: parsedEndDate,
        userId: _selectedUser?.id?.toString(),
        categoryId: _selectedCategory?.id?.toString(),
      );

      if (filePath != null) {
        final result = await OpenFilex.open(filePath);
        
        // If the device doesn't have an app to open the file (like no Excel app),
        // fallback to opening the native Share Sheet so they can save/send it.
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No app found to open this file. Opening share menu...'))
          );
          await Share.shareXFiles([XFile(filePath)], text: 'Expense Report');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Downloaded! Opening...'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download report', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download report', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}

