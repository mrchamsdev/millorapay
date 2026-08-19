import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class AddBranchScreen extends StatefulWidget {
  final Branch? branchToEdit;

  const AddBranchScreen({super.key, this.branchToEdit});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.branchToEdit != null) {
      final b = widget.branchToEdit!;
      _nameCtrl.text = b.name;
      _sectorCtrl.text = b.sector;
      _locationCtrl.text = b.location;
      _radiusCtrl.text = b.radius.toString();
      _latitudeCtrl.text = b.latitude.toString();
      _longitudeCtrl.text = b.longitude.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectorCtrl.dispose();
    _locationCtrl.dispose();
    _radiusCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    final branch = Branch(
      id: widget.branchToEdit?.id,
      name: _nameCtrl.text.trim(),
      sector: _sectorCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      radius: num.tryParse(_radiusCtrl.text.trim()) ?? 0,
      latitude: num.tryParse(_latitudeCtrl.text.trim()) ?? 0,
      longitude: num.tryParse(_longitudeCtrl.text.trim()) ?? 0,
    );

    bool success;
    if (widget.branchToEdit != null && widget.branchToEdit!.id != null) {
      success = await BranchRepository().updateBranch(widget.branchToEdit!.id!, branch);
    } else {
      success = await BranchRepository().addBranch(branch);
    }
    
    setState(() => _isSubmitting = false);
    
    if (success && mounted) {
      Navigator.pop(context, true); // Pop back with success indicator
    } else if (mounted) {
      GoldDialogs.showSnackBar(
        context,
        widget.branchToEdit != null ? 'Failed to update branch' : 'Failed to create branch',
        isError: true,
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, Widget? suffixIcon}) {
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
                  if (val == null || val.trim().isEmpty) {
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
          widget.branchToEdit != null ? 'Edit Branch' : 'Add Branch',
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
              const Text(
                'Branch Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
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
                    _buildTextField('Name', _nameCtrl),
                    _buildTextField('Sector', _sectorCtrl),
                    _buildTextField('Location', _locationCtrl /*, suffixIcon: const Icon(Icons.location_on, color: Colors.deepOrange, size: 20)*/),
                    _buildTextField('Radius', _radiusCtrl, isNumber: true),
                    _buildTextField('Latitude', _latitudeCtrl, isNumber: true),
                    _buildTextField('Longitude', _longitudeCtrl, isNumber: true),
                  ],
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
