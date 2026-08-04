import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/gold_detail_input.dart';
import '../models/category_model.dart';
import '../repository/category_repository.dart';

class AddCategoryModal extends StatefulWidget {
  final ExpenseCategory? category;
  const AddCategoryModal({super.key, this.category});

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _nameController = TextEditingController();
  final List<TextEditingController> _quantityControllers = [
    TextEditingController(),
  ];
  final _repository = CategoryRepository();
  bool _isLoading = false;
  String? _selectedFilePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      if (widget.category!.quantity != null && widget.category!.quantity!.isNotEmpty) {
        _quantityControllers.clear();
        for (final q in widget.category!.quantity!) {
          _quantityControllers.add(TextEditingController(text: q.toString()));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addQuantityField() {
    setState(() {
      _quantityControllers.add(TextEditingController());
    });
  }

  void _removeQuantityField(int index) {
    if (_quantityControllers.length > 1) {
      setState(() {
        _quantityControllers[index].dispose();
        _quantityControllers.removeAt(index);
      });
    } else {
      _quantityControllers[0].clear();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _selectedFilePath = image.path;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty) return;

    final quantities = _quantityControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);
    try {
      bool success;
      if (widget.category != null) {
        success = await _repository.updateCategory(
          widget.category!.id!,
          ExpenseCategory(
            name: _nameController.text.trim(),
            quantity: quantities,
          ),
          filePath: _selectedFilePath,
        );
      } else {
        success = await _repository.createCategory(
          ExpenseCategory(
            name: _nameController.text.trim(),
            quantity: quantities,
          ),
          filePath: _selectedFilePath,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Error handled in repo
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.category == null ? 'Add Categories' : 'Edit Category',
                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GoldDetailInputGroup(
                padding: EdgeInsets.zero,
                children: [
                  GoldDetailInputField(
                    label: 'Category Name',
                    controller: _nameController,
                    hint: 'Enter here',
                  ),
                  GoldDetailInputField(
                    label: 'Category Upload',
                    value: _selectedFilePath?.split('/').last,
                    hint: 'No file choosen',
                    onTap: _pickImage,
                    showBottomBorder: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Quantity Header Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addQuantityField,
                    child: const Text(
                      '+ Add Quantity',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Dynamic Quantity Fields ──
              ..._quantityControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF727271),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter here',
                            hintStyle: TextStyle(
                              color: Color(0xFF727271),
                              fontSize: 10,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _removeQuantityField(index),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFF727271),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
