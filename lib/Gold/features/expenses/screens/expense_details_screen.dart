import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/gold_session.dart';
import '../../../core/utils/responsive_extensions.dart';
import '../../../core/utils/screen_utility.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/expense_model.dart';
import '../repository/expense_repository.dart';
import '../widgets/detail_header.dart';
import '../widgets/detail_note.dart';
import '../widgets/history_item.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final ExpenseRepository _repository = ExpenseRepository();

  late Expense _expense;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_expense.id == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = await _repository.getExpenseById(_expense.id!);
      if (updated != null) setState(() => _expense = updated);
    } catch (_) {
      // Keep using current state as fallback
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_expense.id == null) return;

    final confirm = await GoldDialogs.showPermissionDialog(
      context: context,
      title: 'Delete Expense?',
      message: 'Are you sure you want to delete this expense record?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final success = await _repository.deleteExpense(_expense.id!);
      if (success) {
        if (mounted) {
          GoldDialogs.showSnackBar(context, 'Expense deleted successfully');
          AppRoutes.pop(context, true);
        }
      } else {
        if (mounted) {
          GoldDialogs.showSnackBar(context, 'Failed to delete expense',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        GoldDialogs.showSnackBar(context, 'Failed to delete expense',
            isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addExpense,
      arguments: _expense,
    );
    if (result == true) {
      _hasChanges = true;
      _fetchDetails();
    }
  }

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<String> _extractFiles(String val) {
    if (val == 'none' || val.trim().isEmpty || val.trim() == '[]') return [];
    
    String cleaned = val.trim();
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    if (cleaned.isEmpty) return [];
    return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String _formatChangeHistory(ExpenseHistoryItem historyItem) {
    if (historyItem.changes == null || historyItem.changes!.isEmpty) {
      return 'Modified record details';
    }

    final List<String> changeTexts = [];
    historyItem.changes!.forEach((field, detail) {
      final oldVal = detail.oldValue ?? 'none';
      final newVal = detail.newValue ?? 'none';
      if (field == 'amount') {
        changeTexts.add('Amount changed from ${_expense.currencySymbol}$oldVal to ${_expense.currencySymbol}$newVal');
      } else if (field == 'description') {
        changeTexts.add("Description changed from '$oldVal' to '$newVal'");
      } else if (field == 'expenseCategoryId') {
        changeTexts.add("Category changed from '$oldVal' to '$newVal'");
      } else if (field == 'branchId') {
        changeTexts.add("Branch changed from '$oldVal' to '$newVal'");
      } else if (field == 'paidBy') {
        changeTexts.add("Paid by changed from '$oldVal' to '$newVal'");
      } else if (field == 'quantity') {
        changeTexts.add("Quantity changed from '$oldVal' to '$newVal'");
      } else if (field == 'service') {
        changeTexts.add("Service changed from '$oldVal' to '$newVal'");
      } else if (field == 'file') {
        final oldList = _extractFiles(oldVal);
        final newList = _extractFiles(newVal);
        
        final addedCount = newList.where((e) => !oldList.contains(e)).length;
        final removedCount = oldList.where((e) => !newList.contains(e)).length;

        if (addedCount > 0) {
          changeTexts.add('$addedCount receipt image${addedCount > 1 ? 's' : ''} updated');
        }
        if (removedCount > 0) {
          changeTexts.add('$removedCount receipt image${removedCount > 1 ? 's' : ''} removed');
        }
      } else if (field == 'note') {
        if (oldVal == 'none' || oldVal.isEmpty) {
          changeTexts.add("Note added: '$newVal'");
        } else if (newVal == 'none' || newVal.isEmpty) {
          changeTexts.add("Note removed");
        } else {
          changeTexts.add("Note changed from '$oldVal' to '$newVal'");
        }
      } else if (field == 'amountType') {
        changeTexts.add("Currency changed from '$oldVal' to '$newVal'");
      } else if (field == 'comment') {
        if (oldVal == 'none' || oldVal.isEmpty) {
          changeTexts.add("Comment added: '$newVal'");
        } else if (newVal == 'none' || newVal.isEmpty) {
          changeTexts.add("Comment removed");
        } else {
          changeTexts.add("Comment changed from '$oldVal' to '$newVal'");
        }
      } else if (field == 'expenseDate') {
        changeTexts.add("Date changed from '$oldVal' to '$newVal'");
      } else {
        changeTexts
            .add('${field[0].toUpperCase()}${field.substring(1)} changed');
      }
    });

    return '- ' + changeTexts.join('\n- ');
  }

  List<ExpenseHistoryItem> get _filteredHistory {
    if (_expense.history == null || _expense.history!.isEmpty) return [];
    
    DateTime? expenseCreated;
    if (_expense.createdAt != null) {
      expenseCreated = DateTime.tryParse(_expense.createdAt!);
    }

    return _expense.history!.where((item) {
      if (item.updatedAt == null || expenseCreated == null) return true;
      
      final itemUpdated = DateTime.tryParse(item.updatedAt!);
      if (itemUpdated == null) return true;

      final diff = itemUpdated.difference(expenseCreated).inSeconds.abs();
      if (diff <= 45) {
        final changes = item.changes?.keys.toList() ?? [];
        if (changes.length == 1 && (changes.contains('file') || changes.contains('files'))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtility().init(context);

    final displayNote =
        (_expense.note != null && _expense.note!.isNotEmpty)
            ? _expense.note!
            : '';

    return WillPopScope(
      onWillPop: () async {
        AppRoutes.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: GoldAppBar(
          showSearch: false,
          
          title: 'View Details',
  titleFontSize: 16.sp,
  titleFontWeight: FontWeight.w500,
          
          showBackButton: true,
          onBackPressed: () => AppRoutes.pop(context, _hasChanges),
          centerTitle: true,
          showNotification: false,
          actions: [
            if (GoldSession.instance.canWrite('Expenses')) ...[
              IconButton(
                icon: Image.asset(
                  'assets/images/delete.png',
                  width: 18.sp,
                  height: 18.sp,
                  fit: BoxFit.contain,
                ),
                onPressed: _handleDelete,
              ),
              IconButton(
                icon: Image.asset(
                  'assets/images/edit.png',
                  width: 18.sp,
                  height: 18.sp,
                  fit: BoxFit.contain,
                ),
                onPressed: _handleEdit,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : SingleChildScrollView(
                padding: EdgeInsets.all(ScreenUtility.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailHeader(
                      // Show description if available, otherwise show category name or empty string
                      title: (_expense.description != null && _expense.description!.isNotEmpty)
                          ? _expense.description!
                          : (_expense.expenseCategory?.name ?? ''),
                      amount: _expense.amount.toStringAsFixed(2),
                      date: _formatDateString(_expense.expenseDate),
                      addedBy: _expense.user?.name ?? '',
                      fileUrl: _expense.file,
                      allFileUrls: _expense.files,
                      iconUrl: _expense.expenseCategory?.icon,
                      currencySymbol: _expense.currencySymbol,
                      branchName: _expense.branch?.name,
                      paidBy: _expense.paidByUser?.name,
                      quantities: _expense.quantities,
                      service: _expense.service,
                    ),
                    SizedBox(height: 1.5.h),
                    const Divider(color: Color(0xFFF1F2F5)),
                    SizedBox(height: 2.h),

                    if (displayNote.trim().isNotEmpty) ...[
                      DetailNote(note: displayNote),
                      SizedBox(height: 3.h),
                    ],

                    Text('History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    SizedBox(height: 2.h),
                    _filteredHistory.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            child: Text(
                              'No modification history for this expense.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredHistory.length,
                            itemBuilder: (context, idx) {
                              final item = _filteredHistory[idx];
                              final dateFormatted = item.updatedAt != null
                                  ? _formatDateString(item.updatedAt!)
                                  : 'Recent';
                              return HistoryItem(
                                status:
                                    'Updated this Transaction: $dateFormatted',
                                subtext: _formatChangeHistory(item),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
