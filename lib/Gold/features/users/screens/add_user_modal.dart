import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/gold_dialogs.dart';
import '../../../widgets/gold_detail_input.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../core/network/gold_session.dart';
import '../../branch/models/branch_model.dart';
import '../../branch/repository/branch_repository.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';
import '../../auth/models/auth_models.dart';

class AddUserModal extends StatefulWidget {
  final User? user;
  const AddUserModal({super.key, this.user});

  @override
  State<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  final _repository = UserRepository();
  final _branchRepository = BranchRepository();
  
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _branchController = TextEditingController();
  
  List<Branch> _selectedBranches = [];
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;

  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

  void _onFieldChanged() {
    if (_hasAttemptedSubmit) setState(() {});
  }

  late Country _selectedCountry;

  final List<String> _branchModuleNames = [
    'Expenses',
  ];
  
  final List<String> _globalModuleNames = [
    'Users',
  ];

  Map<int, List<UserAccessEntry>> _branchAccessMap = {};
  List<UserAccessEntry> _globalAccessList = [];

  @override
  void initState() {
    super.initState();
    
    try {
      _selectedCountry = CountryService().getAll().firstWhere((c) => c.countryCode == 'IN');
    } catch (_) {
      _selectedCountry = Country(
        phoneCode: '91',
        countryCode: 'IN',
        e164Sc: 0,
        geographic: true,
        level: 1,
        name: 'India',
        example: '9123456789',
        displayName: 'India (IN) [+91]',
        displayNameNoCountryCode: 'India (IN)',
        e164Key: '',
      );
    }

    _nameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _roleController.addListener(_onFieldChanged);
    _branchController.addListener(_onFieldChanged);
    _genderController.addListener(_onFieldChanged);

    _initializeAccessList();
    _fetchBranches().then((_) {
      if (widget.user != null) {
        if (widget.user!.branchIds.isNotEmpty || widget.user!.branches.isNotEmpty) {
           _selectedBranches = _branches.where((b) {
             final intId = int.tryParse(b.id ?? '');
             return widget.user!.branchIds.contains(intId) || widget.user!.branches.contains(b.name);
           }).toList();
           
           // If we still didn't find anything but branch text exists
           if (_selectedBranches.isEmpty && widget.user!.branch != null) {
              final fallback = _branches.where((b) => b.name == widget.user!.branch).toList();
              if (fallback.isNotEmpty) {
                _selectedBranches = fallback;
              }
           }
        } else if (widget.user!.branch != null) {
            final fallback = _branches.where((b) => b.name == widget.user!.branch).toList();
            if (fallback.isNotEmpty) {
              _selectedBranches = fallback;
            }
        }
        
        setState(() {
          _branchController.text = _selectedBranches.map((e) => e.name).join(', ');
          if (_branchController.text.isEmpty && widget.user!.branch != null) {
            _branchController.text = widget.user!.branch!;
          }
        });
      }
    });

    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _lastNameController.text = widget.user!.lastName ?? '';
      _genderController.text = widget.user!.gender ?? '';
      _emailController.text = widget.user!.email ?? '';
      
      final phone = widget.user!.phoneNumber ?? '';
      if (phone.startsWith('+')) {
        bool found = false;
        for (int i = 4; i >= 1; i--) {
          if (phone.length > i) {
            final code = phone.substring(1, i + 1);
            try {
              final country = CountryService().getAll().firstWhere((c) => c.phoneCode == code);
              _selectedCountry = country;
              _phoneController.text = phone.substring(i + 1);
              found = true;
              break;
            } catch (_) {}
          }
        }
        if (!found) {
          _phoneController.text = phone;
        }
      } else {
        _phoneController.text = phone;
      }
      
      _roleController.text = widget.user!.role ?? '';
      // Branch is set after fetching branches
    }
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

  Future<void> _showBranchPicker() async {
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
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      'Select Branches',
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
                          final isSelected = _selectedBranches.any((element) => element.id == b.id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: Colors.cyan,
                                side: const BorderSide(color: Colors.cyan),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (isSelected) {
                                      _selectedBranches.removeWhere((element) => element.id == b.id);
                                    } else {
                                      _selectedBranches.add(b);
                                    }
                                  });
                                  setState(() {
                                    _branchController.text = _selectedBranches.map((e) => e.name).join(', ');
                                  });
                                },
                              ),
                            ),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedBranches.removeWhere((element) => element.id == b.id);
                                } else {
                                  _selectedBranches.add(b);
                                }
                              });
                              setState(() {
                                _branchController.text = _selectedBranches.map((e) => e.name).join(', ');
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

  void _initializeAccessList() {
    _branchAccessMap.clear();
    
    _globalAccessList = _globalModuleNames.map((modName) {
      if (widget.user != null && widget.user!.globalAccess.isNotEmpty) {
        final existing = widget.user!.globalAccess.firstWhere(
          (m) => m.module == modName,
          orElse: () => UserAccessEntry(module: modName, read: false, write: false)
        );
        return UserAccessEntry(module: modName, read: existing.read, write: existing.write);
      }
      
      // Fallback for old data where 'Users' might have been inside a branch
      if (widget.user != null && widget.user!.userAccess.isNotEmpty) {
        bool anyRead = false;
        bool anyWrite = false;
        for (var b in widget.user!.userAccess) {
          try {
            final found = b.access.firstWhere((e) => e.module == modName);
            if (found.read) anyRead = true;
            if (found.write) anyWrite = true;
          } catch (_) {}
        }
        if (anyRead || anyWrite) {
          return UserAccessEntry(module: modName, read: anyRead, write: anyWrite);
        }
      }
      
      return UserAccessEntry(module: modName, read: false, write: false);
    }).toList();

    if (widget.user != null && widget.user!.userAccess.isNotEmpty) {
      for (var branchAccess in widget.user!.userAccess) {
        final accessList = _branchModuleNames.map((modName) {
          final existing = branchAccess.access.firstWhere(
            (m) => m.module == modName, 
            orElse: () => UserAccessEntry(module: modName, read: true, write: false)
          );
          return UserAccessEntry(module: modName, read: existing.read, write: existing.write);
        }).toList();
        _branchAccessMap[branchAccess.branchId] = accessList;
      }
    }
  }

  List<UserAccessEntry> _getAccessForBranch(int branchId) {
    if (!_branchAccessMap.containsKey(branchId)) {
      _branchAccessMap[branchId] = _branchModuleNames.map((modName) => UserAccessEntry(module: modName, read: true, write: false)).toList();
    }
    return _branchAccessMap[branchId]!;
  }

  String? get _displayGender {
    if (_genderController.text.isEmpty) return null;
    final text = _genderController.text.toLowerCase();
    if (text == 'male') return 'Male';
    if (text == 'female') return 'Female';
    return _genderController.text;
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Text(
                    'Select Gender',
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Male', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                trailing: _genderController.text.toLowerCase() == 'male'
                    ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  setState(() {
                    _genderController.text = 'male';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Female', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                trailing: _genderController.text.toLowerCase() == 'female'
                    ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  setState(() {
                    _genderController.text = 'female';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _roleController.removeListener(_onFieldChanged);
    _branchController.removeListener(_onFieldChanged);
    _genderController.removeListener(_onFieldChanged);
    
    _nameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  String? _validateAlphabets(String value, String fieldName, bool isSelect) {
    if (value.trim().isEmpty) return isSelect ? 'Select $fieldName' : 'Enter $fieldName';
    final alphaRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!alphaRegex.hasMatch(value)) return '${fieldName[0].toUpperCase()}${fieldName.substring(1)} should only contain alphabets';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Enter phone number';
    final phoneRegex = RegExp(r'^\d+$');
    if (!phoneRegex.hasMatch(value)) return 'Phone number should only contain numbers';
    
    final expectedLength = _selectedCountry.example.replaceAll(RegExp(r'\D'), '').length;
    if (expectedLength > 0 && value.trim().length != expectedLength) {
      return 'Must be $expectedLength digits for ${_selectedCountry.countryCode}';
    }
    return null;
  }
  
  String? _validateRequired(String? value, String fieldName, bool isSelect) {
    if (value == null || value.trim().isEmpty) return isSelect ? 'Select $fieldName' : 'Enter $fieldName';
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _hasAttemptedSubmit = true);

    bool hasAnyAccess = _globalAccessList.any((a) => a.read || a.write);
    if (!hasAnyAccess) {
      for (var b in _selectedBranches) {
        final bId = int.tryParse(b.id ?? '') ?? 0;
        if (_getAccessForBranch(bId).any((a) => a.read || a.write)) {
          hasAnyAccess = true;
          break;
        }
      }
    }

    if (_validateAlphabets(_nameController.text, 'name', false) != null ||
        _validateAlphabets(_lastNameController.text, 'last name', false) != null ||
        _validateRequired(_genderController.text, 'gender', true) != null ||
        _validateEmail(_emailController.text) != null ||
        _validatePhone(_phoneController.text) != null ||
        _validateAlphabets(_roleController.text, 'role', false) != null ||
        _validateRequired(_branchController.text, 'branch', true) != null ||
        !hasAnyAccess) {
      return;
    }

    setState(() => _isLoading = true);
    
    // Only include modules that have at least read or write access
    Set<String> activeModulesSet = {};
    List<BranchAccess> finalAccess = [];
    
    // Add global modules if active
    final activeGlobalAccess = _globalAccessList.where((a) => a.read || a.write).toList();
    for (var a in activeGlobalAccess) {
      activeModulesSet.add(a.module);
    }
    
    for (var b in _selectedBranches) {
      final bId = int.tryParse(b.id ?? '') ?? 0;
      final activeAccessForBranch = _getAccessForBranch(bId).where((a) => a.read || a.write).toList();
      if (activeAccessForBranch.isNotEmpty) {
        finalAccess.add(BranchAccess(branchId: bId, branchName: b.name, access: activeAccessForBranch));
        for (var a in activeAccessForBranch) {
          activeModulesSet.add(a.module);
        }
      }
    }

    final branchIds = _selectedBranches.map((b) => int.tryParse(b.id ?? '') ?? 0).toList();
    final branches = _selectedBranches.map((b) => b.name).toList();

    final user = User(
      id: widget.user?.id,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      gender: _genderController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
      role: _roleController.text.trim(),
      branch: branches.isNotEmpty ? branches.first : _branchController.text.trim(),
      branchId: branchIds.isNotEmpty ? branchIds.first : null,
      branches: branches,
      branchIds: branchIds,
      createdBy: widget.user == null ? (GoldSession.instance.userId ?? 1) : widget.user?.createdBy,
      modules: activeModulesSet.toList(),
      globalAccess: activeGlobalAccess,
      userAccess: finalAccess,
    );

    try {
      String? errorMessage;
      if (widget.user != null) {
        errorMessage = await _repository.updateUser(widget.user!.id!, user);
      } else {
        errorMessage = await _repository.createUser(user);
      }

      if (mounted) {
        if (errorMessage == null) {
          GoldDialogs.showSuccessDialog(
            context: context,
            title: 'Success',
            message: widget.user != null ? 'User updated successfully.' : 'User created successfully.',
            onOkPressed: () {
              Navigator.pop(context, true);
            },
          );
        } else {
          GoldDialogs.showErrorDialog(
            context: context,
            title: 'Action Failed',
            message: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GoldDialogs.showSnackBar(
          context,
          widget.user != null ? 'Failed to update user' : 'Failed to create user',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: GoldBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.user != null ? 'Edit User' : 'Add User',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Details', style: AppTextStyles.h2.copyWith(fontSize: 15)),
                  const SizedBox(height: 24),
                  
                  GoldDetailInputGroup(
                    padding: EdgeInsets.zero,
                    children: [
                      GoldDetailInputField(
                        label: 'Name',  
                        controller: _nameController,
                        hint: 'Enter name',
                        errorText: _hasAttemptedSubmit ? _validateAlphabets(_nameController.text, 'name', false) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        hint: 'Enter last name',
                        errorText: _hasAttemptedSubmit ? _validateAlphabets(_lastNameController.text, 'last name', false) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Gender',
                        value: _displayGender,
                        hint: 'Select gender',
                        onTap: _showGenderPicker,
                        errorText: _hasAttemptedSubmit ? _validateRequired(_genderController.text, 'gender', true) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'Enter email',
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.user != null,
                        errorText: _hasAttemptedSubmit ? _validateEmail(_emailController.text) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Country Code',
                        value: '+${_selectedCountry.phoneCode} ${_selectedCountry.flagEmoji}',
                        hint: 'Select country code',
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            countryListTheme: CountryListThemeData(
                              inputDecoration: InputDecoration(
                                icon: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: AppColors.textPrimary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                hintText: 'Search',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F2F5),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            onSelect: (Country country) {
                              setState(() {
                                _selectedCountry = country;
                                if (_hasAttemptedSubmit) _onFieldChanged();
                              });
                            },
                          );
                        },
                      ),
                      GoldDetailInputField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        hint: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            _selectedCountry.example.replaceAll(RegExp(r'\D'), '').length > 0
                                ? _selectedCountry.example.replaceAll(RegExp(r'\D'), '').length
                                : 15,
                          ),
                        ],
                        errorText: _hasAttemptedSubmit ? _validatePhone(_phoneController.text) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Role',
                        controller: _roleController,
                        hint: 'Enter role',
                        errorText: _hasAttemptedSubmit ? _validateAlphabets(_roleController.text, 'role', false) : null,
                      ),
                      GoldDetailInputField(
                        label: 'Branch',
                        value: _branchController.text.isNotEmpty ? _branchController.text : null,
                        hint: 'Select branch',
                        onTap: _showBranchPicker,
                        suffixIcon: Icons.keyboard_arrow_down_rounded,
                        showBottomBorder: false,
                        errorText: _hasAttemptedSubmit ? _validateRequired(_branchController.text, 'branch', true) : null,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                    Text('User Access', style: AppTextStyles.h2.copyWith(fontSize: 15)),
                    const SizedBox(height: 16),
                    
                    // Global Access (Users)
                    Row(
                      children: [
                        Expanded(flex: 3, child: Text('Modules', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(child: Center(child: Text('Write', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_globalAccessList.length, (index) {
                      final item = _globalAccessList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, 
                              child: Text(item.module, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12))
                            ),
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: Checkbox(
                                    value: item.write,
                                    activeColor: Colors.cyan,
                                    side: const BorderSide(color: Colors.cyan),
                                    onChanged: (val) {
                                      final newWrite = val ?? false;
                                      setState(() => _globalAccessList[index] = UserAccessEntry(
                                        module: item.module, read: true, write: newWrite
                                      ));
                                      if (_hasAttemptedSubmit) _onFieldChanged();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    
                    ..._selectedBranches.expand((branch) {
                      final bId = int.tryParse(branch.id ?? '') ?? 0;
                      final accessList = _getAccessForBranch(bId);
                      return [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(branch.name, style: AppTextStyles.h2.copyWith(fontSize: 13)),
                      ),
                      // Access Table Header
                      Row(
                        children: [
                          Expanded(flex: 3, child: Text('Modules', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(child: Center(child: Text('Write', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Access Rows
                      ...List.generate(accessList.length, (index) {
                        final item = accessList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3, 
                                child: Text(item.module, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12))
                              ),
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 20, height: 20,
                                    child: Checkbox(
                                      value: item.write,
                                      activeColor: Colors.cyan,
                                      side: const BorderSide(color: Colors.cyan),
                                      onChanged: (val) {
                                        final newWrite = val ?? false;
                                        setState(() => accessList[index] = UserAccessEntry(
                                          module: item.module, read: true, write: newWrite
                                        ));
                                        if (_hasAttemptedSubmit) _onFieldChanged();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ];
                  }),
                    if (_hasAttemptedSubmit)
                      Builder(
                        builder: (context) {
                          bool hasAny = _globalAccessList.any((a) => a.read || a.write);
                          if (!hasAny) {
                            for (var b in _selectedBranches) {
                              final bId = int.tryParse(b.id ?? '') ?? 0;
                              if (_getAccessForBranch(bId).any((a) => a.read || a.write)) {
                                hasAny = true;
                                break;
                              }
                            }
                          }
                          if (!hasAny) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'At least one module must be selected',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Submit Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }
}
