import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class BranchDetailsScreen extends StatefulWidget {
  final String branchId;

  const BranchDetailsScreen({super.key, required this.branchId});

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  final BranchRepository _repository = BranchRepository();
  Branch? _branch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final branch = await _repository.getBranchById(widget.branchId);
      setState(() {
        _branch = branch;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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
          'Branch Details',
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
          : _branch == null
              ? const Center(child: Text('Failed to load branch details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_branch!.name} Branch Details',
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
                            _buildDetailRow('Name', _branch!.name),
                            _buildDetailRow('Sector', _branch!.sector),
                            _buildDetailRow('Location', _branch!.location),
                            _buildDetailRow('Radius', _branch!.radius.toString()),
                            _buildDetailRow('Latitude', _branch!.latitude.toString()),
                            _buildDetailRow('Longitude', _branch!.longitude.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

