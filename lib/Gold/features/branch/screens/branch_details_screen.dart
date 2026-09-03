import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../users/repository/user_repository.dart';

class BranchDetailsScreen extends StatefulWidget {
  final String companyId;

  const BranchDetailsScreen({super.key, required this.companyId});

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  final BranchRepository _repository = BranchRepository();
  Company? _company;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final company = await _repository.getCompanyById(widget.companyId);
      setState(() {
        _company = company;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteBranchConfirmation(Branch branch) async {
    if (_company != null && _company!.branches.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A company must have at least one branch.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final users = await UserRepository().getAllUsers();
      final branchIdInt = int.tryParse(branch.id?.toString() ?? '');
      
      bool hasUsers = false;
      for (var u in users) {
        if (u.branchId == branchIdInt || u.branchIds.contains(branchIdInt)) {
          hasUsers = true;
          break;
        }
        if (u.userAccess.any((ca) => ca.branches.any((ba) => ba.branchId == branchIdInt))) {
          hasUsers = true;
          break;
        }
      }
      
      setState(() => _isLoading = false);

      if (hasUsers) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Already users exist you dont have permision to delete'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ok'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check users.')),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Branch'),
          content: Text('Are you sure you want to delete "${branch.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true && branch.id != null) {
      setState(() => _isLoading = true);
      final success = await _repository.deleteBranch(branch.id!.toString()); 
      if (success) {
        _fetchDetails();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete branch')),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    const double labelFontSize = 14;
    const double valueFontSize = labelFontSize - 2; // always 2 less than label

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + inline value row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: labelFontSize,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F2F5)),
                  ),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF727271),
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
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
        title: const Text(
          'Company Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _company == null
              ? const Center(child: Text('Failed to load company details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _company!.companyName ?? 'Company',
                        style: const TextStyle(
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
                            _buildDetailRow('Name', _company!.companyName ?? 'N/A'),
                            _buildDetailRow('Sector', _company!.sector ?? 'N/A'),
                            _buildDetailRow('Location', _company!.city ?? 'N/A'),
                            _buildDetailRow('Radius', _company!.radius?.toString() ?? 'N/A'),
                            _buildDetailRow('Latitude', _company!.latitude?.toString() ?? 'N/A'),
                            _buildDetailRow('Longitude', _company!.longitude?.toString() ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_company!.branches.isNotEmpty) ...[
                        const Text(
                          'Branches',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._company!.branches.map((branch) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    branch.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: SvgPicture.asset('assets/images/Delete.svg', width: 16, height: 16),
                                  onPressed: () => _showDeleteBranchConfirmation(branch),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Name', branch.name),
                                  _buildDetailRow('Sector', branch.sector),
                                  _buildDetailRow('Location', branch.location),
                                  _buildDetailRow('Radius', branch.radius.toString()),
                                  _buildDetailRow('Latitude', branch.latitude.toString()),
                                  _buildDetailRow('Longitude', branch.longitude.toString()),
                                ],
                              ),
                            ),
                          ],
                        )).toList(),
                      ]
                    ],
                  ),
                ),
    );
  }
}

