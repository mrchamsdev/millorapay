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
import '../../users/models/user_model.dart';
import '../../users/repository/user_repository.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // ─── Controllers ─────────────────────────────────────────────────────────
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '',
  );
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool get _isEditMode => widget.expense != null;

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
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
    if (_users.isEmpty && !_isLoadingUsers) {
      await _fetchUsers();
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
                  else if (_users.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (context, index) {
                          final u = _users[index];
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

  void _openQuantityPicker() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first', style: TextStyle(color: Colors.white))),
      );
      return;
    }

    final quantities = _selectedCategory!.quantity;
    if (quantities == null || quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quantities available for this category', style: TextStyle(color: Colors.white))),
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
                      'Select Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: quantities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final q = quantities[index].toString();
                        final isSelected = _quantityController.text == q;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          title: Text(
                            q,
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
                              _quantityController.text = q;
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
    _commentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _populateEditFields(Expense exp) {
    _amountController.text = exp.amount.toStringAsFixed(2);
    _commentController.text = exp.comment ?? '';
    _noteController.text = exp.note ?? '';
    _selectedCurrency = exp.amountType;
    _selectedCategory = exp.expenseCategory;
    _categoryController.text = exp.description.isNotEmpty ? exp.description : (exp.expenseCategory?.name ?? '');
    _currentImageUrls = exp.files ?? (exp.file != null ? [exp.file!] : []);
    try {
      _selectedDate = DateTime.parse(exp.expenseDate);
    } catch (_) {
      _selectedDate = DateTime.now();
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
      _quantityController.text = exp.quantities!.first;
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
    }
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
      setState(() => _selectedDate = picked);
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
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

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
              : _quantityController.text.trim(),
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
              : _quantityController.text.trim(),
        );
      }

      if (savedExpense != null) {
        if (_imagePaths.isNotEmpty) {
          for (final imgPath in _imagePaths) {
            await _repository.uploadExpenseFile(
              savedExpense.id!,
              imgPath,
            );
          }
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
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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
                  'assets/images/Branches.svg', // Replace with your Branch SVG asset path
                  width: 44,
                  height: 44,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.domain_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
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
                        hintText: 'Enter Branch',
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
                iconWidget: _selectedCategory?.icon != null && _selectedCategory!.icon!.isNotEmpty
                    ? _selectedCategory!.icon!.toLowerCase().endsWith('.svg')
                        ? SvgPicture.network(
                            _selectedCategory!.icon!.replaceAll(' ', '%20'),
                            width: 20,
                            height: 20,
                            placeholderBuilder: (context) => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Image.network(
                            _selectedCategory!.icon!.replaceAll(' ', '%20'),
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
                              'assets/imagess/Category.svg', // Replace with your Category SVG
                              width: 44,
                              height: 44,
                            ),
                          )
                    : SvgPicture.asset(
                        'assets/images/Category.svg', // Replace with your Category SVG
                        width: 44,
                        height: 44,
                      ),
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
                    hintText: 'Enter a Category',
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
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
                iconWidget: SvgPicture.asset(
                  'assets/images/Rupee.svg', // Replace with your Amount SVG
                  width: 44,
                  height: 44,
                ),
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
                child: GestureDetector(
                  onTap: _openDatePicker,
                  child: AbsorbPointer(
                    child: TextFormField(
                      key: ValueKey(_selectedDate),
                      readOnly: true,
                      initialValue: _getFormattedDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration('Select Date'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 5. Paid by Row (After Date) ──────────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/Paidby.svg', // Replace with your Paid by SVG asset path
                  width: 44,
                  height: 44,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

              // ── 6. Quantity Row (After Paid by) ──────────────────────
              _FormRow(
                iconWidget: SvgPicture.asset(
                  'assets/images/Quantity.svg', // Replace with your Quantity SVG asset path
                  width: 44,
                  height: 44,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.grid_view_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                onIconTap: _openQuantityPicker,
                child: GestureDetector(
                  onTap: _openQuantityPicker,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _quantityController,
                      readOnly: true,
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
