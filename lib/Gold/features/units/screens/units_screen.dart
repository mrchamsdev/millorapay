import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../../../core/network/gold_session.dart';
import '../models/unit_model.dart';
import '../repository/unit_repository.dart';
import 'add_unit_modal.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UnitRepository _repository = UnitRepository();

  List<Unit> _units = [];
  List<Unit> _filteredUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoading = true);
    try {
      final units = await _repository.getAllUnits();
      if (mounted) {
        setState(() {
          _units = units;
        });
        _onSearchChanged();
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        GoldDialogs.showSnackBar(context, 'Failed to load units', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUnits = _units;
      } else {
        _filteredUnits = _units.where((u) => u.name.toLowerCase().contains(query)).toList();
      }
    });
  }

  Future<void> _showDeleteConfirmation(Unit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Unit'),
          content: Text('Are you sure you want to delete "${unit.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF002E6E))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true && unit.id != null) {
      setState(() => _isLoading = true);
      final error = await _repository.deleteUnit(unit.id!);
      if (mounted) {
        if (error == null) {
          _fetchUnits();
        } else {
          setState(() => _isLoading = false);
          GoldDialogs.showSnackBar(context, 'Failed to delete unit', isError: true);
        }
      }
    }
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const AddUnitsModal(),
          );
          if (result == true) _fetchUnits();
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
          'Units',
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Recent', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _filteredUnits.isEmpty
                    ? const Center(child: Text('No units found.', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _fetchUnits,
                        color: AppColors.primaryBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredUnits.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, index) {
                            final unit = _filteredUnits[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                unit.name,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: SvgPicture.asset('assets/images/Edit.svg', width: 16, height: 16),
                                            onPressed: () async {
                                              final result = await showDialog(
                                                context: context,
                                                builder: (context) => AddUnitsModal(unit: unit),
                                              );
                                              if (result == true) _fetchUnits();
                                            },
                                          ),
                                          IconButton(
                                            icon: SvgPicture.asset('assets/images/Delete.svg', width: 16, height: 16),
                                            onPressed: () {
                                              _showDeleteConfirmation(unit);
                                            },
                                          ),
                                        ],
                                      ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
