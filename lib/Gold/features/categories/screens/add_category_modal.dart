import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/gold_detail_input.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/category_model.dart';
import '../repository/category_repository.dart';
import '../../units/models/unit_model.dart';
import '../../units/repository/unit_repository.dart';
import '../../services/models/service_model.dart';
import '../../services/repository/service_repository.dart';

class AddCategoryModal extends StatefulWidget {
  final ExpenseCategory? category;
  const AddCategoryModal({super.key, this.category});

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _nameController = TextEditingController();
  
  bool _isQuantity = false;
  List<Unit> _selectedUnits = [];
  
  bool _isService = false;
  List<ServiceModel> _selectedServices = [];

  final _repository = CategoryRepository();
  final _unitRepo = UnitRepository();
  final _serviceRepo = ServiceRepository();

  List<Unit> _availableUnits = [];
  List<ServiceModel> _availableServices = [];

  bool _isLoading = false;
  String? _selectedFilePath;
  String? _existingFileUrl;
  final ImagePicker _picker = ImagePicker();
  
  bool _hasAttemptedSubmit = false;

  void _onFieldChanged() {
    if (_hasAttemptedSubmit) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _existingFileUrl = widget.category!.icon;
      if (widget.category!.quantity == true) {
        _isQuantity = true;
      }
      if (widget.category!.units != null) {
        _selectedUnits = List.from(widget.category!.units!);
      }
      if (widget.category!.service == true) {
        _isService = true;
      }
      if (widget.category!.services != null) {
        _selectedServices = List.from(widget.category!.services!);
      }
    }
    _nameController.addListener(_onFieldChanged);
  }

  Future<void> _fetchDropdownData() async {
    final units = await _unitRepo.getAllUnits();
    final services = await _serviceRepo.getAllServices();
    if (mounted) {
      setState(() {
        _availableUnits = units;
        _availableServices = services;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Enter Category name';
    final alphaRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!alphaRegex.hasMatch(value)) return 'Category name should only contain alphabets';
    return null;
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
    setState(() => _hasAttemptedSubmit = true);
    if (_validateName(_nameController.text) != null) return;

    setState(() => _isLoading = true);
    try {
      List<Unit>? unitsToSubmit = _isQuantity && _selectedUnits.isNotEmpty ? _selectedUnits : null;
      List<ServiceModel>? servicesToSubmit = _isService && _selectedServices.isNotEmpty ? _selectedServices : null;

      bool success;
      if (widget.category != null) {
        success = await _repository.updateCategory(
          widget.category!.id!,
          ExpenseCategory(
            name: _nameController.text.trim(),
            quantity: _isQuantity,
            units: unitsToSubmit,
            service: _isService,
            services: servicesToSubmit,
          ),
          filePath: _selectedFilePath,
        );
      } else {
        success = await _repository.createCategory(
          ExpenseCategory(
            name: _nameController.text.trim(),
            quantity: _isQuantity,
            units: unitsToSubmit,
            service: _isService,
            services: servicesToSubmit,
          ),
          filePath: _selectedFilePath,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        GoldDialogs.showSnackBar(
          context,
          widget.category != null ? 'Failed to update category' : 'Failed to create category',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        GoldDialogs.showSnackBar(
          context,
          widget.category != null ? 'Failed to update category' : 'Failed to create category',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFullScreenImage(BuildContext context, String title, String imageUrl) {
    if (imageUrl.isEmpty) return;
    final isNetwork = imageUrl.startsWith('http');
    final formattedUrl = isNetwork ? imageUrl.replaceAll(' ', '%20') : imageUrl;
    
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
            child: isNetwork 
                ? (formattedUrl.toLowerCase().endsWith('.svg')
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
                      ))
                : Image.file(
                    File(formattedUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _openMultiSelectPicker<T>({
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) getName,
    required bool Function(T, T) isSelected,
    required ValueChanged<List<T>> onSelectionChanged,
  }) {
    List<T> tempSelected = List.from(selectedItems);

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onSelectionChanged(tempSelected);
                            Navigator.pop(context);
                          },
                          child: const Text('Done', style: TextStyle(color: AppColors.primaryBlue)),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final checked = tempSelected.any((e) => isSelected(e, item));
                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(
                            getName(item),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: checked ? AppColors.primaryBlue : const Color(0xFF727271),
                            ),
                          ),
                          value: checked,
                          activeColor: const Color(0xFF003366),
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? val) {
                            setModalState(() {
                              if (val == true) {
                                tempSelected.add(item);
                              } else {
                                tempSelected.removeWhere((e) => isSelected(e, item));
                              }
                            });
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                    errorText: _hasAttemptedSubmit ? _validateName(_nameController.text) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Category Upload',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5), width: 1.0)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    _selectedFilePath != null
                                        ? _selectedFilePath!.split('/').last
                                        : (_existingFileUrl != null && _existingFileUrl!.isNotEmpty)
                                            ? _existingFileUrl!.split('/').last.replaceFirst(RegExp(r'^\d{13}-'), '')
                                            : 'No file choosen',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF727271),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_selectedFilePath != null || (_existingFileUrl != null && _existingFileUrl!.isNotEmpty)) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      final fileToView = _selectedFilePath ?? _existingFileUrl!;
                                      _showFullScreenImage(context, 'Category Upload', fileToView);
                                    },
                                    child: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                ],
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Quantity Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: _isQuantity,
                        activeColor: const Color(0xFF00B4D8),
                        side: const BorderSide(color: Color(0xFF00B4D8)),
                        onChanged: (val) {
                          setState(() {
                            _isQuantity = val ?? false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_isQuantity) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openMultiSelectPicker<Unit>(
                    title: 'Select Units',
                    items: _availableUnits,
                    selectedItems: _selectedUnits,
                    getName: (u) => u.name,
                    isSelected: (a, b) => a.id == b.id,
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedUnits = val;
                      });
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5), width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedUnits.isEmpty
                              ? const Text(
                                  'Select unit here',
                                  style: TextStyle(
                                    color: Color(0xFF727271),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    _selectedUnits.map((u) => u.name).join(', '),
                                    style: const TextStyle(
                                      color: Color(0xFF727271),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4D4D4), size: 20),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Service Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: _isService,
                        activeColor: const Color(0xFF00B4D8),
                        side: const BorderSide(color: Color(0xFF00B4D8)),
                        onChanged: (val) {
                          setState(() {
                            _isService = val ?? false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_isService) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openMultiSelectPicker<ServiceModel>(
                    title: 'Select Services',
                    items: _availableServices,
                    selectedItems: _selectedServices,
                    getName: (s) => s.name,
                    isSelected: (a, b) => a.id == b.id,
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedServices = val;
                      });
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5), width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedServices.isEmpty
                              ? const Text(
                                  'Select here',
                                  style: TextStyle(
                                    color: Color(0xFF727271),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    _selectedServices.map((s) => s.name).join(', '),
                                    style: const TextStyle(
                                      color: Color(0xFF727271),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4D4D4), size: 20),
                      ],
                    ),
                  ),
                ),
              ],

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
