import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../../../core/network/gold_session.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final BranchRepository _repository = BranchRepository();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Branch> _allBranches = [];
  List<Branch> _filteredBranches = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAllBranches();
      setState(() {
        _allBranches = data;
        _filteredBranches = data;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        GoldDialogs.showSnackBar(context, 'Failed to load branches', isError: true);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredBranches = _allBranches;
      });
      return;
    }
    setState(() {
      _filteredBranches = _allBranches.where((b) {
        return b.name.toLowerCase().contains(query) ||
               b.location.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _showDeleteConfirmation(Branch branch) async {
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
      final success = await _repository.deleteBranch(branch.id!);
      if (success) {
        _fetchBranches();
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

  Widget _buildAddButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.addBranch);
          if (result == true) {
            _fetchBranches();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
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
          'Branches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          _buildAddButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _filteredBranches.isEmpty
                    ? const Center(child: Text('No branches found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _filteredBranches.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final branch = _filteredBranches[index];
                          return ListTile(
                            onTap: () {
                              if (branch.id != null) {
                                Navigator.pushNamed(context, AppRoutes.branchDetails, arguments: branch.id!);
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              branch.name,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              branch.location,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: SvgPicture.asset('assets/images/Edit.svg', width: 16, height: 16),
                                          onPressed: () async {
                                            final result = await Navigator.pushNamed(context, AppRoutes.addBranch, arguments: branch);
                                            if (result == true) {
                                              _fetchBranches();
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: SvgPicture.asset('assets/images/Delete.svg', width: 16, height: 16),
                                          onPressed: () {
                                            _showDeleteConfirmation(branch);
                                          },
                                        ),
                                      ],
                                    ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

