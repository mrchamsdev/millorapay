import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/country_utility.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class AddCompanyScreen extends StatefulWidget {
  final Company? companyToEdit;

  const AddCompanyScreen({super.key, this.companyToEdit});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final BranchRepository _repository = BranchRepository();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _legalNameCtrl = TextEditingController();
  final TextEditingController _customSectorCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'India');
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _pinCodeCtrl = TextEditingController();
  final TextEditingController _gstNoCtrl = TextEditingController();
  final TextEditingController _panCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();

  String _companyType = 'Individual';
  final List<String> _companyTypes = [
    'Individual',
    'Private Limited',
    'Public Limited',
    'Partnership',
    'Proprietorship',
    'LLP',
    'Other',
  ];

  String? _selectedSector;
  List<String> _sectors = [];
  bool _isLoadingSectors = false;

  static const List<String> _defaultSectors = [
    'Information Technology (IT)',
    'Financial Services',
    'Banking',
    'Retail & E-commerce',
    'Manufacturing',
    'Healthcare & Pharmaceuticals',
    'Real Estate & Construction',
    'Education',
    'Hospitality & Tourism',
    'Automobile',
    'Telecommunications',
    'Agriculture',
    'Logistics & Supply Chain',
    'Other',
  ];

  String? _logoPath;
  String? _existingLogoUrl;
  bool _isSubmitting = false;

  bool get _isEditing => widget.companyToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.companyToEdit!;
      _nameCtrl.text = c.companyName ?? '';
      _legalNameCtrl.text = c.legalEntityName ?? '';
      if (c.companyType != null && c.companyType!.trim().isNotEmpty) {
        if (!_companyTypes.contains(c.companyType!.trim())) {
          _companyTypes.add(c.companyType!.trim());
        }
        _companyType = c.companyType!.trim();
      }
      if (c.sector != null && c.sector!.trim().isNotEmpty) {
        _selectedSector = c.sector!.trim();
      }
      _emailCtrl.text = c.companyEmail ?? '';
      _phoneCtrl.text = c.companyPhone ?? '';
      _cityCtrl.text = c.city ?? '';
      if (c.country != null && c.country!.trim().isNotEmpty) {
        _countryCtrl.text = c.country!.trim();
      }
      _existingLogoUrl = c.logo;
    }
    _fetchSectors();
  }

  Future<void> _fetchSectors() async {
    setState(() => _isLoadingSectors = true);
    try {
      final fetched = await _repository.getAllSectors();
      if (!mounted) return;
      setState(() {
        final set = <String>{};
        for (final s in fetched) {
          if (s.trim().isNotEmpty) set.add(s.trim());
        }
        if (set.isEmpty) {
          set.addAll(_defaultSectors);
        }
        if (_selectedSector != null && _selectedSector!.trim().isNotEmpty) {
          set.add(_selectedSector!.trim());
        }
        _sectors = set.toList();
        _isLoadingSectors = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_sectors.isEmpty) {
            _sectors = List.from(_defaultSectors);
            if (_selectedSector != null && _selectedSector!.trim().isNotEmpty) {
              if (!_sectors.contains(_selectedSector!.trim())) {
                _sectors.add(_selectedSector!.trim());
              }
            }
          }
          _isLoadingSectors = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalNameCtrl.dispose();
    _customSectorCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _pinCodeCtrl.dispose();
    _gstNoCtrl.dispose();
    _panCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _logoPath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        GoldDialogs.showSnackBar(context, 'Failed to pick image', isError: true);
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Company Logo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryBlue),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogo(ImageSource.camera);
                },
              ),
              if (_logoPath != null || (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _logoPath = null;
                      _existingLogoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final String? sectorToSubmit = (_selectedSector == 'Other' && _customSectorCtrl.text.trim().isNotEmpty)
        ? _customSectorCtrl.text.trim()
        : _selectedSector;

    final payload = <String, dynamic>{
      'companyName': _nameCtrl.text.trim(),
      if (_legalNameCtrl.text.trim().isNotEmpty)
        'legalEntityName': _legalNameCtrl.text.trim(),
      'companyType': _companyType,
      if (sectorToSubmit != null && sectorToSubmit.trim().isNotEmpty)
        'sector': sectorToSubmit.trim(),
      if (_emailCtrl.text.trim().isNotEmpty)
        'companyEmail': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty)
        'companyPhone': _phoneCtrl.text.trim(),
      if (_cityCtrl.text.trim().isNotEmpty)
        'city': _cityCtrl.text.trim(),
      if (_countryCtrl.text.trim().isNotEmpty)
        'country': _countryCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_stateCtrl.text.trim().isNotEmpty)
        'state': _stateCtrl.text.trim(),
      if (_pinCodeCtrl.text.trim().isNotEmpty)
        'pinCode': _pinCodeCtrl.text.trim(),
      if (_gstNoCtrl.text.trim().isNotEmpty)
        'gstNo': _gstNoCtrl.text.trim(),
      if (_panCtrl.text.trim().isNotEmpty)
        'pan': _panCtrl.text.trim(),
      if (_websiteCtrl.text.trim().isNotEmpty)
        'website': _websiteCtrl.text.trim(),
    };

    if (_isEditing) {
      final companyId = widget.companyToEdit!.id?.toString();
      if (companyId == null) {
        setState(() => _isSubmitting = false);
        GoldDialogs.showSnackBar(context, 'Invalid company ID', isError: true);
        return;
      }

      final (success, errorMsg, _) = await _repository.updateCompanyWithLogo(
        companyId,
        payload,
        logoPath: _logoPath,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        GoldDialogs.showSnackBar(context, 'Company updated successfully');
        Navigator.pop(context, true);
      } else {
        GoldDialogs.showSnackBar(
          context,
          errorMsg ?? 'Failed to update company',
          isError: true,
        );
      }
    } else {
      final (success, errorMsg) = await _repository.createCompany(payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        GoldDialogs.showSnackBar(context, 'Company created successfully');
        Navigator.pop(context, true);
      } else {
        GoldDialogs.showSnackBar(
          context,
          errorMsg ?? 'Failed to create company',
          isError: true,
        );
      }
    }
  }

  Widget _buildLogoSection() {
    Widget imageWidget;
    if (_logoPath != null) {
      imageWidget = Image.file(
        File(_logoPath!),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      );
    } else if (_existingLogoUrl != null && _existingLogoUrl!.trim().isNotEmpty) {
      imageWidget = Image.network(
        Uri.encodeFull(_existingLogoUrl!.trim()),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: SvgPicture.asset(
            'assets/images/Company.svg',
            width: 32,
            height: 32,
          ),
        ),
      );
    } else {
      imageWidget = Center(
        child: SvgPicture.asset(
          'assets/images/Company.svg',
          width: 32,
          height: 32,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF1F2F5),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _logoPath != null
                      ? 'New logo selected'
                      : (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty
                          ? 'Current Logo'
                          : 'No logo uploaded'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PNG, JPG up to 5MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showImagePickerSheet,
            icon: const Icon(Icons.upload_file, size: 16, color: AppColors.primaryBlue),
            label: Text(
              _logoPath != null || (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty)
                  ? 'Change'
                  : 'Upload',
              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool isRequired = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
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
              child: TextFormField(
                controller: controller,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: keyboardType ??
                    (isNumber
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB0B0B0),
                    fontWeight: FontWeight.normal,
                  ),
                  fillColor: Colors.transparent,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                  errorStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: suffixIcon,
                  suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                validator: (val) {
                  if (isRequired && (val == null || val.trim().isEmpty)) {
                    return 'Enter $label';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? hintText,
    bool isLoading = false,
  }) {
    final effectiveItems = List<String>.from(items);
    if (value != null && value.isNotEmpty && !effectiveItems.contains(value)) {
      effectiveItems.insert(0, value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
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
              child: DropdownButtonFormField<String>(
                initialValue: (value != null && effectiveItems.contains(value)) ? value : null,
                isExpanded: true,
                hint: Text(
                  isLoading ? 'Loading sectors...' : (hintText ?? 'Select $label'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                items: effectiveItems
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const GoldBackButton(),
        title: Text(
          _isEditing ? 'Edit Company' : 'Add Company',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo section
              const Text(
                'Company Logo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildLogoSection(),
              const SizedBox(height: 24),

              const Text(
                'Company Details',
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
                  children: [
                    _buildTextField('Name', _nameCtrl, isRequired: true, hintText: 'Company name'),
                    _buildTextField('Legal Name', _legalNameCtrl, hintText: 'Legal entity name'),
                    _buildDropdownField('Type', _companyType, _companyTypes, (val) {
                      if (val != null) setState(() => _companyType = val);
                    }),
                    _buildDropdownField(
                      'Sector',
                      _selectedSector,
                      _sectors,
                      (val) {
                        if (val != null) setState(() => _selectedSector = val);
                      },
                      hintText: 'Select sector',
                      isLoading: _isLoadingSectors,
                    ),
                    if (_selectedSector == 'Other') ...[
                      _buildTextField('Custom Sector', _customSectorCtrl, hintText: 'Enter sector name'),
                    ],
                    _buildTextField('Email', _emailCtrl, keyboardType: TextInputType.emailAddress, hintText: 'company@example.com'),
                    _buildTextField('Phone', _phoneCtrl, keyboardType: TextInputType.phone, hintText: '+91 9876543210'),
                    _buildDropdownField(
                      'Country',
                      _countryCtrl.text.isNotEmpty ? _countryCtrl.text : 'India',
                      CountryUtility.getAllCountries().map((c) => c.name).toList(),
                      (val) {
                        if (val != null) setState(() => _countryCtrl.text = val);
                      },
                      hintText: 'Select country',
                    ),
                    _buildTextField('City', _cityCtrl, hintText: 'City'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Additional Information',
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
                  children: [
                    _buildTextField('Address', _addressCtrl, hintText: 'Registered office address'),
                    _buildTextField('State', _stateCtrl, hintText: 'State / Province'),
                    _buildTextField('Pin Code', _pinCodeCtrl, isNumber: true, hintText: 'PIN / Zip Code'),
                    _buildTextField('GST No', _gstNoCtrl, hintText: 'GST Identification Number'),
                    _buildTextField('PAN', _panCtrl, hintText: 'PAN Number'),
                    _buildTextField('Website', _websiteCtrl, keyboardType: TextInputType.url, hintText: 'https://example.com'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _isEditing ? 'Update' : 'Save',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
