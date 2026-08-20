import 'dart:io';

import 'package:bank_scan/Gold/widgets/gold_app_bar.dart';
import 'package:bank_scan/Gold/widgets/gold_dialogs.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../branch/models/branch_model.dart';
import '../../branch/repository/branch_repository.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repository/category_repository.dart';
import '../../units/models/unit_model.dart';
import '../../services/models/service_model.dart';
import '../../users/models/user_model.dart';
import '../../users/repository/user_repository.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../notifications/providers/notification_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ─── State ───────────────────────────────────────────────────────────────
  final ExpenseRepository _repository = ExpenseRepository();
  final BranchRepository _branchRepository = BranchRepository();
  final UserRepository _userRepository = UserRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ImagePicker _picker = ImagePicker();

  Branch? _selectedBranch;
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;

  User? _selectedPaidByUser;
  List<User> _users = [];
  bool _isLoadingUsers = false;

  ExpenseCategory? _selectedCategory;
  String _selectedCurrency = 'INR';
  DateTime _selectedDate = DateTime.now();
  final List<String> _imagePaths = [];
  List<String> _currentImageUrls = [];
  bool _isLoading = false;

  List<String> _units = [];
  String _selectedUnit = '';

  ServiceModel? _selectedService;
  List<ServiceModel> _services = [];

  Future<void> _fetchCategoryDetails(ExpenseCategory category) async {
    List<Unit>? unitsList = category.units;
    List<ServiceModel>? servicesList = category.services;

    if (((unitsList == null || unitsList.isEmpty) || (servicesList == null || servicesList.isEmpty)) && category.id != null) {
      try {
        final fullCat = await _categoryRepository.getCategoryById(category.id!);
        if (fullCat != null) {
          unitsList = fullCat.units ?? unitsList;
          servicesList = fullCat.services ?? servicesList;
          _selectedCategory = fullCat;
        }
      } catch (_) {}
    }

    final catUnits = unitsList?.map((u) => u.name).where((n) => n.isNotEmpty).toList() ?? [];
    final catServices = servicesList ?? [];

    if (mounted) {
      setState(() {
        _units = catUnits;
        if (catUnits.isNotEmpty) {
          if (!_units.contains(_selectedUnit)) {
            _selectedUnit = catUnits.first;
          }
        } else {
          _selectedUnit = '';
        }

        _services = catServices;
        if (_selectedService != null && !catServices.any((s) => s.name == _selectedService?.name)) {
          _selectedService = null;
          _serviceController.clear();
        }
      });
    }
  }

  // ─── Controllers ─────────────────────────────────────────────────────────
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '',
  );
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final DateMaskController _dateController = DateMaskController();

  bool get _isEditMode => widget.expense != null;

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDateForMask(_selectedDate);
    _fetchBranches();
    _fetchUsers();
    if (_isEditMode) {
      _populateEditFields(widget.expense!);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final list = await _userRepository.getAllUsers();
      if (mounted) {
        setState(() {
          _users = list;
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  /// Opens the Paid by selection bottom sheet listing users with name and role.
  Future<void> _openPaidByPicker() async {
    if (_selectedBranch == null) {
      GoldDialogs.showSnackBar(
        context,
        'Please select a branch first',
        isError: true,
      );
      return;
    }

    if (_users.isEmpty && !_isLoadingUsers) {
      await _fetchUsers();
    }

    if (!mounted) return;

    final filteredUsers = _users.where((u) => u.branchId?.toString() == _selectedBranch!.id).toList();

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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Select Paid By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_isLoadingUsers)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    )
                  else if (filteredUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No users found for this branch',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final u = filteredUsers[index];
                          final isSelected = _selectedPaidByUser?.id == u.id || _paidByController.text == u.name;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              u.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: (u.role != null && u.role!.isNotEmpty)
                                ? Text(
                                    u.role!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedPaidByUser = u;
                                _paidByController.text = u.name;
                              });
                              Navigator.pop(context);
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
  void _openUnitPicker() {
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Select Unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _units.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Center(
                            child: Text(
                              'No units are present for this category.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF727271),
                              ),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _units.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                            itemBuilder: (context, index) {
                              final u = _units[index];
                              final isSelected = _selectedUnit == u;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                title: Text(
                                  u,
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
                                  setState(() {
                                    _selectedUnit = u;
                                  });
                                  Navigator.pop(context);
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

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final list = await _branchRepository.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = list;
          _isLoadingBranches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  /// Opens the branch selection bottom sheet listing branches with name and location.
  Future<void> _openBranchPicker() async {
    if (_branches.isEmpty && !_isLoadingBranches) {
      await _fetchBranches();
    }

    if (!mounted) return;

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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Select Branch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_isLoadingBranches)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    )
                  else if (_branches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No branches found',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _branches.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final b = _branches[index];
                          final isSelected = _selectedBranch?.id == b.id || _branchController.text == b.name;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              b.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: b.location.isNotEmpty
                                ? Text(
                                    b.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedBranch = b;
                                _branchController.text = b.name;
                                _selectedPaidByUser = null;
                                _paidByController.clear();
                              });
                              Navigator.pop(context);
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

  @override
  void dispose() {
    _branchController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _paidByController.dispose();
    _quantityController.dispose();
    _serviceController.dispose();
    _commentController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _populateEditFields(Expense exp) {
    _amountController.text = exp.amount.toStringAsFixed(2);
    _commentController.text = exp.comment ?? '';
    _noteController.text = exp.note ?? '';
    _selectedCurrency = exp.amountType;
    _selectedCategory = exp.expenseCategory;
    _categoryController.text = exp.description.isNotEmpty ? exp.description : (exp.expenseCategory?.name ?? '');
    _currentImageUrls = List.from(exp.files ?? (exp.file != null ? [exp.file!] : []));
    try {
      _selectedDate = DateTime.parse(exp.expenseDate);
      _dateController.text = _formatDateForMask(_selectedDate);
    } catch (_) {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForMask(_selectedDate);
    }

    // Pre-fill Branch
    if (exp.branch != null) {
      _selectedBranch = exp.branch;
      _branchController.text = exp.branch!.name;
    }

    // Pre-fill Paid By
    if (exp.paidByUser != null) {
      _selectedPaidByUser = User(
        id: exp.paidByUser!.id,
        name: exp.paidByUser!.name ?? '',
        email: exp.paidByUser!.email,
        phoneNumber: exp.paidByUser!.phoneNumber,
      );
      _paidByController.text = exp.paidByUser!.name ?? '';
    }

    // Pre-fill Quantity
    if (exp.quantities != null && exp.quantities!.isNotEmpty) {
      final qStr = exp.quantities!.first;
      final parts = qStr.split(' ');
      if (parts.length > 1) {
        _quantityController.text = parts[0];
        final unitPart = parts.sublist(1).join(' ');
        _selectedUnit = unitPart;
      } else {
        _quantityController.text = qStr;
      }
    }

    // Pre-fill Service
    if (exp.service != null && exp.service!.isNotEmpty) {
      _serviceController.text = exp.service!;
      _selectedService = ServiceModel(name: exp.service!);
    }

    if (_selectedCategory != null) {
      _fetchCategoryDetails(_selectedCategory!);
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Opens the category picker and updates selected category on return.
  Future<void> _openCategoryPicker() async {
    final result = await Navigator.pushNamed(context, AppRoutes.categoryPicker);
    if (result != null && result is ExpenseCategory) {
      setState(() {
        _selectedCategory = result;
        _quantityController.clear();
      });
      await _fetchCategoryDetails(result);
    }
  }

  /// Opens the service picker bottom sheet listing services for the category.
  void _openServicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              _services.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Center(
                        child: Text(
                          'No services are present for this category.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF727271),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _services.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final svc = _services[index];
                          final isSelected = _selectedService != null && _selectedService!.name == svc.name;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              svc.name,
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
                              setState(() {
                                _selectedService = svc;
                                _serviceController.text = svc.name;
                              });
                              Navigator.pop(context);
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

  /// Opens the currency picker and updates selected currency on return.
  Future<void> _openCurrencyPicker() async {
    final result = await Navigator.pushNamed(context, AppRoutes.currencyPicker);
    if (result != null && result is Currency) {
      setState(() => _selectedCurrency = result.code);
    }
  }

  /// Opens a date picker dialog.
  Future<void> _openDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: AppColors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDateForMask(picked);
      });
    }
  }

  /// Opens the image picker bottom sheet.
  Future<void> _openImagePicker() async {
    final totalImages = _currentImageUrls.length + _imagePaths.length;
    if (totalImages >= 5) {
      GoldDialogs.showSnackBar(
        context,
        'Maximum limit of 5 images reached',
        isError: true,
      );
      return;
    }
    try {
      final XFile? image = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Photo Gallery'),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1280,
                    maxHeight: 1280,
                  );
                  if (context.mounted) AppRoutes.pop(context, img);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Camera'),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1280,
                    maxHeight: 1280,
                  );
                  if (context.mounted) AppRoutes.pop(context, img);
                },
              ),
            ],
          ),
        ),
      );
      if (image != null) {
        setState(() {
          final totalImages = _currentImageUrls.length + _imagePaths.length;
          if (totalImages < 5) {
            _imagePaths.add(image.path);
          }
        });
      }
    } catch (_) {
      GoldDialogs.showSnackBar(context, 'Failed to pick image', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }



  /// Validates and submits the expense form.
  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) {
      GoldDialogs.showSnackBar(
        context,
        'Please select a category',
        isError: true,
      );
      return;
    }

    final amountText = _amountController.text.trim();
    final digitCount = amountText.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > 15) {
      GoldDialogs.showSnackBar(
        context,
        'Amount cannot exceed 15 digits',
        isError: true,
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0.0) {
      GoldDialogs.showSnackBar(
        context,
        'Please enter a valid amount greater than 0',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime? parsedDate;
      try {
        final val = _dateController.text;
        if (val.length == 10 && !val.contains('d') && !val.contains('m') && !val.contains('y')) {
          final parts = val.split('/');
          if (parts.length == 3) {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            parsedDate = DateTime(y, m, d);
          }
        }
      } catch (_) {}
      
      final dateToUse = parsedDate ?? _selectedDate;
      final dateStr =
          '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.day.toString().padLeft(2, '0')}';

      Expense? savedExpense;

      // description = whatever the user typed in the category text field (falls back to category name if empty)
      final description = _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : (_selectedCategory?.name ?? '');

      if (_isEditMode) {
        savedExpense = await _repository.updateExpense(
          widget.expense!.id!,
          expenseCategoryId: _selectedCategory!.id!,
          companyId: widget.expense!.companyId,
          expenseDate: dateStr,
          amount: amount,
          amountType: _selectedCurrency,
          description: description,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          paidBy: _selectedPaidByUser?.id,
          branchId: _selectedBranch != null ? int.tryParse(_selectedBranch!.id ?? '') : null,
          quantity: _quantityController.text.trim().isEmpty
              ? null
              : '${_quantityController.text.trim()} $_selectedUnit',
          service: _selectedService?.name,
          file: _imagePaths.isNotEmpty
              ? (widget.expense?.files ?? (_currentImageUrls.isNotEmpty ? _currentImageUrls : null))
              : (_currentImageUrls.isNotEmpty ? _currentImageUrls : null),
        );
      } else {
        savedExpense = await _repository.createExpense(
          expenseCategoryId: _selectedCategory!.id!,
          companyId: 1,
          expenseDate: dateStr,
          amount: amount,
          amountType: _selectedCurrency,
          description: description,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          paidBy: _selectedPaidByUser?.id,
          branchId: _selectedBranch != null ? int.tryParse(_selectedBranch!.id ?? '') : null,
          quantity: _quantityController.text.trim().isEmpty
              ? null
              : '${_quantityController.text.trim()} $_selectedUnit',
          service: _selectedService?.name,
        );
      }

      if (savedExpense != null) {
        if (_imagePaths.isNotEmpty) {
          await _repository.uploadExpenseFiles(
            savedExpense.id!,
            _imagePaths,
          );
        }
        
        // Refresh notification count only when an expense is edited successfully
        if (_isEditMode) {
          NotificationProvider.fetchUnreadCount();
        }

        if (mounted) {
          GoldDialogs.showSnackBar(
            context,
            _isEditMode
                ? 'Expense updated successfully!'
                : 'Expense created successfully!',
          );
          AppRoutes.pop(context, true);
        }
      } else {
        if (mounted) {
          GoldDialogs.showSnackBar(
            context,
            _isEditMode
                ? 'Failed to update expense.'
                : 'Failed to create expense.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GoldDialogs.showSnackBar(
          context,
          _isEditMode ? 'Failed to update expense' : 'Failed to create expense',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _formatDateForMask(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getFormattedDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _getCurrencySymbol(String code) {
    if (code == 'Rupees' || code == 'INR') return '₹';
    final currency = CurrencyService().findByCode(code);
    return currency?.symbol ?? code;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.white,
        appBar: GoldAppBar(
          showSearch: false,
          title: _isEditMode ? 'Edit Expense' : 'Add Expense',
          showBackButton: true,
          centerTitle: true,
          showNotification: false,
          actions: [
            if (!_isLoading)
              IconButton(
                onPressed: _handleSubmit,
                icon: const Icon(
                  Icons.check,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ── 1. Enter Branch Row (Top) ──────────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/Branch1.svg', // Replace with your Branch SVG asset path
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.domain_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                showBorder: true,
                onIconTap: _openBranchPicker,
                child: GestureDetector(
                  onTap: _openBranchPicker,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _branchController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Select Branch',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB0B1B4),
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
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Category Row ──────────────────────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/Category1.svg', // Replace with your Category SVG
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.category_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                showBorder: true,
                onIconTap: _openCategoryPicker,
                child: TextField(
                  controller: _categoryController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () {
                    if (_selectedCategory == null) {
                      _openCategoryPicker();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Select Category',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0B1B4),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    suffixIcon: _selectedCategory != null
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryBlue,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. Amount Row ────────────────────────────────────────
              _FormRow(
                iconWidget: Text(
                  _getCurrencySymbol(_selectedCurrency),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                showBorder: true,
                onIconTap: _openCurrencyPicker,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    DigitLimitFormatter(15),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration('0.00'),
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Date Row ──────────────────────────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/Date.svg', // Replace with your Date SVG
                  width: 20,
                  height: 20,
                ),
                showBorder: true,
                onIconTap: _openDatePicker,
                child: TextField(
                  controller: _dateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    DateMaskFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration('dd/mm/yyyy'),
                  onChanged: (val) {
                    if (val.length == 10 && !val.contains('d') && !val.contains('m') && !val.contains('y')) {
                      try {
                        final parts = val.split('/');
                        if (parts.length == 3) {
                          final d = int.parse(parts[0]);
                          final m = int.parse(parts[1]);
                          final y = int.parse(parts[2]);
                          _selectedDate = DateTime(y, m, d);
                        }
                      } catch (_) {}
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── 5. Paid by Row (After Date) ──────────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/PaidBy1.svg', // Replace with your Paid by SVG asset path
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                showBorder: true,
                onIconTap: _openPaidByPicker,
                child: GestureDetector(
                  onTap: _openPaidByPicker,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _paidByController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paid by',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB0B1B4),
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
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedCategory?.quantity == true) ...[
                // ── 6. Quantity Row (After Paid by) ──────────────────────
                _FormRow(
                  iconWidget: SvgPicture.asset(
                    'assets/images/Quantity1.svg', // Replace with your Quantity SVG asset path
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.grid_view_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  showBorder: true,
                  onIconTap: () {},
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Quantity',
                      hintStyle: const TextStyle(
                        color: Color(0xFFB0B1B4),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: GestureDetector(
                        onTap: _openUnitPicker,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_selectedUnit.isNotEmpty)
                              Text(
                                _selectedUnit,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_selectedCategory?.service == true) ...[
                // ── Service Row ──────────────────────────────────────────
                _FormRow(
                  iconWidget: SvgPicture.asset(
                    'assets/images/Services2.svg',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.design_services_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  showBorder: true,
                  onIconTap: _openServicePicker,
                  child: GestureDetector(
                    onTap: _openServicePicker,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _serviceController,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Select Service',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB0B1B4),
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
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── 7. Note Section ──────────────────────────────────────
              const Text(
                'Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 75,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: null,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 8. Images Section (Max Limit 5) ──────────────────────
              const Text(
                'Images',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Add Image Picker Tile (Shown if less than 5 images)
                    if (_imagePaths.length < 5)
                      GestureDetector(
                        onTap: _openImagePicker,
                        child: Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/add_image.svg', // Replace with your image icon SVG
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Network Images (if editing existing expense)
                    ..._currentImageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              height: 64,
                              width: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentImageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Selected Local Image Thumbnails (Max 5)
                    ..._imagePaths.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0B1B4), fontSize: 14),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    filled: false,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
  );
}

// ─── _FormRow ─────────────────────────────────────────────────────────────────
/// A reusable row with a tappable icon on the left and a child widget on the right.
class _FormRow extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onIconTap;
  final Widget child;
  final bool showBorder;

  const _FormRow({
    this.icon,
    this.iconWidget,
    required this.onIconTap,
    required this.child,
    this.showBorder = false,
  }) : assert(
         icon != null || iconWidget != null,
         'Provide either icon or iconWidget',
       );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left icon — tapping it opens the corresponding picker
        GestureDetector(
          onTap: onIconTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: showBorder ? Border.all(color: const Color(0xFFE2E8F0)) : null,
              borderRadius: showBorder ? BorderRadius.circular(8) : null,
            ),
            child: Center(
              child:
                  iconWidget ??
                  Icon(icon!, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}
// ─── DigitLimitFormatter ──────────────────────────────────────────────────────
/// A custom formatter that restricts input to a specified number of digits.
class DigitLimitFormatter extends TextInputFormatter {
  final int maxDigits;
  DigitLimitFormatter(this.maxDigits);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitCount = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > maxDigits) {
      return oldValue;
    }
    return newValue;
  }
}

class DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    
    if (digits.length > 8) digits = digits.substring(0, 8);
    
    String formatted = 'dd/mm/yyyy';
    for (int i = 0; i < digits.length; i++) {
      if (i < 2) formatted = formatted.replaceFirst('d', digits[i]);
      else if (i < 4) formatted = formatted.replaceFirst('m', digits[i]);
      else formatted = formatted.replaceFirst('y', digits[i]);
    }
    
    bool isDeleting = oldValue.text.length > newValue.text.length;
    int cursor;
    if (digits.length == 0) cursor = 0;
    else if (digits.length == 1) cursor = 1;
    else if (digits.length == 2) cursor = isDeleting ? 2 : 3;
    else if (digits.length == 3) cursor = 4;
    else if (digits.length == 4) cursor = isDeleting ? 5 : 6;
    else cursor = digits.length + 2;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class DateMaskController extends TextEditingController {
  DateMaskController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<TextSpan> children = [];
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (char == 'd' || char == 'm' || char == 'y') {
        children.add(TextSpan(
          text: char,
          style: style?.copyWith(color: const Color(0xFFB0B1B4)),
        ));
      } else {
        children.add(TextSpan(
          text: char,
          style: style,
        ));
      }
    }
    return TextSpan(style: style, children: children);
  }
}

