import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/category_model.dart';
import '../repository/category_repository.dart';

class EditCategoryScreen extends StatefulWidget {
  final int categoryId;

  const EditCategoryScreen({super.key, required this.categoryId});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final CategoryRepository _repository = CategoryRepository();
  final ImagePicker _picker = ImagePicker();
  
  ExpenseCategory? _category;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _quantityControllers = [];
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _quantityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final category = await _repository.getCategoryById(widget.categoryId);
      if (category != null) {
        _category = category;
        _nameController.text = category.name;
        
        if (category.quantity != null && category.quantity!.isNotEmpty) {
          for (final q in category.quantity!) {
            _quantityControllers.add(TextEditingController(text: q.toString()));
          }
        } else {
          _quantityControllers.add(TextEditingController());
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;

    final quantities = _quantityControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);
    try {
      final success = await _repository.updateCategory(
        widget.categoryId,
        ExpenseCategory(
          name: _nameController.text.trim(),
          type: _category?.type ?? 'Personal',
          quantity: quantities,
          icon: _category?.icon, // Not strictly needed for payload, but good for model integrity
        ),
        filePath: _selectedFilePath,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Error handled in repo
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildEditRow(String label, Widget inputField, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: inputField),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String title, String imageUrl) {
    if (imageUrl.isEmpty) return;
    final formattedUrl = imageUrl.replaceAll(' ', '%20');
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: formattedUrl.toLowerCase().endsWith('.svg')
                ? SvgPicture.network(
                    formattedUrl,
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                  )
                : Image.network(
                    formattedUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF727271),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const GoldBackButton(),
        title: const Text(
          'Edit Category',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _category != null)
            _isSaving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primaryBlue),
                    onPressed: _saveChanges,
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _category == null
              ? const Center(child: Text('Failed to load category details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEditRow(
                              'Category Name',
                              TextField(
                                controller: _nameController,
                                style: valueStyle,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            _buildEditRow(
                              'Category Upload',
                              Text(
                                _selectedFilePath != null
                                    ? _selectedFilePath!.split('/').last
                                    : (_category!.icon != null && _category!.icon!.isNotEmpty)
                                        ? _category!.icon!.split('/').last.replaceFirst(RegExp(r'^\d{13}-'), '')
                                        : 'No file uploaded',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: valueStyle,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_category!.icon != null && _category!.icon!.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        _showFullScreenImage(context, 'Category Upload', _category!.icon!);
                                      },
                                      child: const Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: AppColors.primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                  if (_category!.icon != null && _category!.icon!.isNotEmpty)
                                    const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _pickImage,
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _quantityControllers.add(TextEditingController());
                                    });
                                  },
                                  child: const Text(
                                    '+ Add Quantity',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._quantityControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        style: valueStyle,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter here',
                                          hintStyle: TextStyle(
                                            color: Color(0xFFB0B1B4),
                                            fontSize: 12,
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
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (_quantityControllers.length > 1) {
                                          setState(() {
                                            controller.dispose();
                                            _quantityControllers.removeAt(index);
                                          });
                                        } else {
                                          controller.clear();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
