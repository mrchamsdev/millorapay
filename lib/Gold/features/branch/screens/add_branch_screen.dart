import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/network/gold_network_service.dart';
import '../../../core/network/gold_api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _BranchFormBlock {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController sectorCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController radiusCtrl = TextEditingController();
  final TextEditingController latitudeCtrl = TextEditingController();
  final TextEditingController longitudeCtrl = TextEditingController();
  String? branchId;

  void dispose() {
    nameCtrl.dispose();
    sectorCtrl.dispose();
    locationCtrl.dispose();
    radiusCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();
  }
}

class AddBranchScreen extends StatefulWidget {
  final Company? companyToEdit;

  const AddBranchScreen({super.key, this.companyToEdit});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_BranchFormBlock> _blocks = [];
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _blocks.add(_BranchFormBlock());
    if (widget.companyToEdit != null) {
      final c = widget.companyToEdit!;
      _blocks[0].nameCtrl.text = c.companyName ?? '';
      _blocks[0].sectorCtrl.text = c.sector ?? '';
      _blocks[0].locationCtrl.text = c.city ?? '';
      _blocks[0].radiusCtrl.text = c.radius?.toString() ?? '';
      _blocks[0].latitudeCtrl.text = c.latitude?.toString() ?? '';
      _blocks[0].longitudeCtrl.text = c.longitude?.toString() ?? '';
      
      for (final branch in c.branches) {
        final block = _BranchFormBlock();
        block.branchId = branch.id;
        block.nameCtrl.text = branch.name;
        block.sectorCtrl.text = branch.sector;
        block.locationCtrl.text = branch.location;
        block.radiusCtrl.text = branch.radius.toString();
        block.latitudeCtrl.text = branch.latitude.toString();
        block.longitudeCtrl.text = branch.longitude.toString();
        _blocks.add(block);
      }
    }
  }

  @override
  void dispose() {
    for (var b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _addBranchBlock() {
    setState(() {
      _blocks.add(_BranchFormBlock());
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    bool allSuccess = true;
    int? currentCompanyId = widget.companyToEdit?.id;
    
    if (_blocks.isEmpty) {
      setState(() => _isSubmitting = false);
      return;
    }

    final companyBlock = _blocks[0];
    final companyPayload = <String, dynamic>{
      "companyName": companyBlock.nameCtrl.text.trim(),
      "legalEntityName": companyBlock.nameCtrl.text.trim(), 
      "companyType": "Individual",
      "sector": companyBlock.sectorCtrl.text.trim(),
      "radius": num.tryParse(companyBlock.radiusCtrl.text.trim()) ?? 0,
      "latitude": num.tryParse(companyBlock.latitudeCtrl.text.trim()) ?? 0,
      "longitude": num.tryParse(companyBlock.longitudeCtrl.text.trim()) ?? 0,
    };

    if (companyBlock.locationCtrl.text.trim().isNotEmpty) {
      companyPayload["city"] = companyBlock.locationCtrl.text.trim();
    }
    
    if (widget.companyToEdit != null && widget.companyToEdit!.id != null) {
      // UPDATE existing company
      final success = await BranchRepository().updateCompany(widget.companyToEdit!.id!.toString(), companyPayload);
      if (!success) allSuccess = false;
    } else {
      // CREATE new company
      final service = GoldPostAuthService(GoldApiConstants.addCompany, companyPayload);
      final result = await service.data();
      final statusCode = result[0] as int;
      final data = result[1];
      
      if (statusCode >= 200 && statusCode < 300) {
        try {
          dynamic decodedData = data is String ? jsonDecode(data) : data;
          if (decodedData is Map) {
             var id = decodedData['companyId'] ?? decodedData['id'] ?? decodedData['company_id'];
             if (id == null && decodedData['data'] is Map) {
               id = decodedData['data']['companyId'] ?? decodedData['data']['id'] ?? decodedData['data']['company_id'];
             }
             if (id is int) {
               currentCompanyId = id;
             } else if (id != null) {
               currentCompanyId = int.tryParse(id.toString());
             }
          }
        } catch (_) {}
      } else {
        allSuccess = false;
      }
    }
    
    if (allSuccess) {
      // Process branches (starting from index 1)
      for (int i = 1; i < _blocks.length; i++) {
        final block = _blocks[i];
        final branch = Branch(
          id: block.branchId, // Use the stored branch ID to determine if it's existing or new
          companyId: currentCompanyId,
          name: block.nameCtrl.text.trim(),
          sector: block.sectorCtrl.text.trim(),
          location: block.locationCtrl.text.trim(),
          radius: num.tryParse(block.radiusCtrl.text.trim()) ?? 0,
          latitude: num.tryParse(block.latitudeCtrl.text.trim()) ?? 0,
          longitude: num.tryParse(block.longitudeCtrl.text.trim()) ?? 0,
        );

        bool success;
        if (block.branchId != null) {
          success = await BranchRepository().updateBranch(block.branchId!, branch);
        } else {
          success = await BranchRepository().addBranch(branch);
        }
        
        if (!success) {
          allSuccess = false;
        }
      }
    }
    
    setState(() => _isSubmitting = false);
    
    if (allSuccess && mounted) {
      Navigator.pop(context, true); 
    } else if (mounted) {
      GoldDialogs.showSnackBar(
        context,
        widget.companyToEdit != null ? 'Failed to update successfully' : 'Failed to save completely',
        isError: true,
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, Widget? suffixIcon, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const GoldBackButton(),
        title: Text(
          widget.companyToEdit != null ? 'Edit Company' : 'Add Company',
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
              ...List.generate(_blocks.length, (index) {
              final block = _blocks[index];
              final title = index == 0 ? 'Company Details' : 'Branch Details';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (index > 0 && block.branchId == null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: SvgPicture.asset('assets/images/Delete.svg', width: 16, height: 16),
                          onPressed: () {
                            setState(() {
                              _blocks[index].dispose();
                              _blocks.removeAt(index);
                            });
                          },
                        ),
                    ],
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
                        _buildTextField('Name', block.nameCtrl),
                        _buildTextField('Sector', block.sectorCtrl),
                        _buildTextField('Location', block.locationCtrl),
                        _buildTextField('Radius', block.radiusCtrl, isNumber: true, isRequired: false),
                        _buildTextField('Latitude', block.latitudeCtrl, isNumber: true, isRequired: false),
                        _buildTextField('Longitude', block.longitudeCtrl, isNumber: true, isRequired: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                ],
              );
            }),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addBranchBlock,
                icon: const Icon(Icons.add, color: AppColors.primaryBlue, size: 20),
                label: const Text(
                  'Add Branch',
                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
