import 'package:flutter/material.dart';
import '../../../core/network/gold_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/country_utility.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import '../../../widgets/google_places_autocomplete.dart';
import 'map_selection_screen.dart';

class _BranchFormBlock {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController sectorCtrl = TextEditingController();
  final TextEditingController customSectorCtrl = TextEditingController();
  final TextEditingController countryCtrl = TextEditingController(text: 'India');
  String selectedCountryCode = 'IN';
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController radiusCtrl = TextEditingController();
  final TextEditingController latitudeCtrl = TextEditingController();
  final TextEditingController longitudeCtrl = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();
  String? branchId;

  void dispose() {
    nameCtrl.dispose();
    sectorCtrl.dispose();
    customSectorCtrl.dispose();
    countryCtrl.dispose();
    locationCtrl.dispose();
    radiusCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();
    locationFocusNode.dispose();
  }
}

class AddBranchScreen extends StatefulWidget {
  final Company? companyToEdit;
  final Branch? branchToEdit;

  const AddBranchScreen({super.key, this.companyToEdit, this.branchToEdit});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_BranchFormBlock> _blocks = [];
  final BranchRepository _repository = BranchRepository();


  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _blocks.add(_BranchFormBlock());
    if (widget.branchToEdit != null) {
      final b = widget.branchToEdit!;
      _blocks[0].branchId = b.id;
      _blocks[0].nameCtrl.text = b.name;
      _blocks[0].sectorCtrl.text = b.sector;
      if (b.country != null && b.country!.trim().isNotEmpty) {
        _blocks[0].countryCtrl.text = b.country!.trim();
        _blocks[0].selectedCountryCode = CountryUtility.getIsoCode(b.country!) ?? 'IN';
      } else {
        final detected = CountryUtility.detectCountryFromAddress(b.location);
        if (detected != null) {
          _blocks[0].selectedCountryCode = detected.isoCode;
          _blocks[0].countryCtrl.text = detected.name;
        } else {
          _blocks[0].selectedCountryCode = 'IN';
          _blocks[0].countryCtrl.text = 'India';
        }
      }
      _blocks[0].locationCtrl.text = b.location;
      _blocks[0].radiusCtrl.text = b.radius != null ? b.radius.toString() : '';
      _blocks[0].latitudeCtrl.text = b.latitude != null ? b.latitude.toString() : '';
      _blocks[0].longitudeCtrl.text = b.longitude != null ? b.longitude.toString() : '';
    } else if (widget.companyToEdit != null) {
      final c = widget.companyToEdit!;
      _blocks[0].nameCtrl.text = c.companyName ?? '';
      _blocks[0].sectorCtrl.text = c.sector ?? '';
      if (c.country != null && c.country!.trim().isNotEmpty) {
        _blocks[0].countryCtrl.text = c.country!.trim();
        _blocks[0].selectedCountryCode = CountryUtility.getIsoCode(c.country!) ?? 'IN';
      }
      _blocks[0].locationCtrl.text = c.city ?? '';
      _blocks[0].radiusCtrl.text = c.radius?.toString() ?? '';
      _blocks[0].latitudeCtrl.text = c.latitude?.toString() ?? '';
      _blocks[0].longitudeCtrl.text = c.longitude?.toString() ?? '';
      
      for (final branch in c.branches) {
        final block = _BranchFormBlock();
        block.branchId = branch.id;
        block.nameCtrl.text = branch.name;
        block.sectorCtrl.text = branch.sector;
        if (branch.country != null && branch.country!.trim().isNotEmpty) {
          block.countryCtrl.text = branch.country!.trim();
          block.selectedCountryCode = CountryUtility.getIsoCode(branch.country!) ?? 'IN';
        } else if (c.country != null && c.country!.trim().isNotEmpty) {
          block.countryCtrl.text = c.country!.trim();
          block.selectedCountryCode = CountryUtility.getIsoCode(c.country!) ?? 'IN';
        } else {
          final detected = CountryUtility.detectCountryFromAddress(branch.location);
          if (detected != null) {
            block.selectedCountryCode = detected.isoCode;
            block.countryCtrl.text = detected.name;
          } else {
            block.selectedCountryCode = 'IN';
            block.countryCtrl.text = 'India';
          }
        }
        block.locationCtrl.text = branch.location;
        block.radiusCtrl.text = branch.radius != null ? branch.radius.toString() : '';
        block.latitudeCtrl.text = branch.latitude != null ? branch.latitude.toString() : '';
        block.longitudeCtrl.text = branch.longitude != null ? branch.longitude.toString() : '';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    if (_blocks.isEmpty) {
      setState(() => _isSubmitting = false);
      return;
    }

    int? activeCompanyId = widget.companyToEdit?.id ?? widget.branchToEdit?.companyId;
    if (activeCompanyId == null && GoldSession.instance.userAccess.isNotEmpty) {
      activeCompanyId = GoldSession.instance.userAccess.first.companyId;
    }

    if (activeCompanyId == null) {
      try {
        final companies = await _repository.getAllCompanies();
        if (companies.isNotEmpty) {
          activeCompanyId = companies.first.id;
        }
      } catch (_) {}
    }

    if (activeCompanyId == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        GoldDialogs.showSnackBar(
          context,
          'Please create a company first, then you can create a branch.',
          isError: true,
        );
      }
      return;
    }

    bool allSuccess = true;

    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if ((block.latitudeCtrl.text.trim().isEmpty || block.longitudeCtrl.text.trim().isEmpty) &&
          block.locationCtrl.text.trim().isNotEmpty) {
        try {
          final locs = await locationFromAddress(block.locationCtrl.text.trim());
          if (locs.isNotEmpty) {
            block.latitudeCtrl.text = locs.first.latitude.toString();
            block.longitudeCtrl.text = locs.first.longitude.toString();
          }
        } catch (_) {}
      }

      String sectorVal = (block.sectorCtrl.text.trim() == 'Other' && block.customSectorCtrl.text.trim().isNotEmpty)
          ? block.customSectorCtrl.text.trim()
          : block.sectorCtrl.text.trim();
      if (sectorVal.isEmpty) {
        sectorVal = widget.companyToEdit?.sector ?? widget.branchToEdit?.sector ?? '';
      }

      final branch = Branch(
        id: block.branchId,
        companyId: activeCompanyId,
        name: block.nameCtrl.text.trim(),
        sector: sectorVal,
        country: block.countryCtrl.text.trim().isNotEmpty ? block.countryCtrl.text.trim() : null,
        location: block.locationCtrl.text.trim(),
        radius: num.tryParse(block.radiusCtrl.text.trim()),
        latitude: num.tryParse(block.latitudeCtrl.text.trim()),
        longitude: num.tryParse(block.longitudeCtrl.text.trim()),
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
    
    setState(() => _isSubmitting = false);
    
    if (allSuccess && mounted) {
      Navigator.pop(context, true); 
    } else if (mounted) {
      GoldDialogs.showSnackBar(
        context,
        widget.companyToEdit != null ? 'Failed to update branch' : 'Failed to save branch',
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

  Widget _buildCountryDropdownField(_BranchFormBlock block) {
    final countries = CountryUtility.getAllCountries();
    final currentCountryName = block.countryCtrl.text.trim();
    final currentIso = block.selectedCountryCode.isNotEmpty
        ? block.selectedCountryCode
        : (CountryUtility.getIsoCode(currentCountryName) ?? 'IN');

    final effectiveIso = countries.any((c) => c.isoCode.toUpperCase() == currentIso.toUpperCase())
        ? currentIso.toUpperCase()
        : 'IN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                'Country',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('${block.branchId}_country_${effectiveIso}'),
                value: effectiveIso,
                isExpanded: true,
                hint: const Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                items: countries
                    .map((item) => DropdownMenuItem(
                          value: item.isoCode.toUpperCase(),
                          child: Row(
                            children: [
                              if (item.flagEmoji != null && item.flagEmoji!.isNotEmpty) ...[
                                Text(item.flagEmoji!, style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  final selected = CountryUtility.findCountry(val);
                  setState(() {
                    block.selectedCountryCode = val;
                    block.countryCtrl.text = selected?.name ?? val;
                  });
                },
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Select Country';
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

  Widget _buildLocationField(_BranchFormBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: GooglePlacesAutocompleteWidget(
                key: ValueKey('places_${block.branchId}_${block.selectedCountryCode}'),
                controller: block.locationCtrl,
                focusNode: block.locationFocusNode,
                countryCode: block.selectedCountryCode,
                hintText: 'Enter Location',
                suffixIcon: IconButton(
                  tooltip: 'Pick on Map',
                  icon: const Icon(
                    Icons.location_on,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                  onPressed: () async {
                    final double? lat = double.tryParse(block.latitudeCtrl.text.trim());
                    final double? lng = double.tryParse(block.longitudeCtrl.text.trim());
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapSelectionScreen(
                          initialLatitude: lat,
                          initialLongitude: lng,
                          initialLocation: block.locationCtrl.text.trim(),
                          countryCode: block.selectedCountryCode,
                        ),
                      ),
                    );

                    if (result is Map) {
                      setState(() {
                        if (result['location'] != null && result['location'].toString().isNotEmpty) {
                          block.locationCtrl.text = result['location'].toString();
                        }
                        if (result['latitude'] != null) {
                          block.latitudeCtrl.text = result['latitude'].toString();
                        }
                        if (result['longitude'] != null) {
                          block.longitudeCtrl.text = result['longitude'].toString();
                        }
                      });
                    }
                  },
                ),
                onPlaceSelected: (data) {
                  setState(() {
                    if (data['location'] != null && data['location'].toString().isNotEmpty) {
                      block.locationCtrl.text = data['location'].toString();
                    }
                    if (data['latitude'] != null && data['latitude'].toString().isNotEmpty) {
                      block.latitudeCtrl.text = data['latitude'].toString();
                    }
                    if (data['longitude'] != null && data['longitude'].toString().isNotEmpty) {
                      block.longitudeCtrl.text = data['longitude'].toString();
                    }
                  });
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter Location';
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
          (widget.companyToEdit != null || widget.branchToEdit != null) ? 'Edit Branch' : 'Add Branch',
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
              const title = 'Branch Details';

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
                        _buildCountryDropdownField(block),
                        _buildLocationField(block),
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
