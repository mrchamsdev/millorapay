import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final String companyId;

  const CompanyDetailsScreen({super.key, required this.companyId});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
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



  String _getFileName(String? url) {
    if (url == null || url.trim().isEmpty) return 'N/A';
    try {
      final uri = Uri.parse(url.trim());
      if (uri.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(uri.pathSegments.last);
      }
      return Uri.decodeComponent(url.split('/').last);
    } catch (_) {
      return url.split('/').last;
    }
  }

  void _showFullScreenImage(BuildContext context, String title, String imageUrl) {
    final formattedUrl = imageUrl.replaceAll(' ', '%20');

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
            child: formattedUrl.toLowerCase().endsWith('.svg')
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
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    const double labelFontSize = 14;
    const double valueFontSize = labelFontSize - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF727271),
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
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
                            _buildDetailRow(
                              'Logo',
                              _getFileName(_company!.logo),
                              trailing: (_company!.logo != null && _company!.logo!.trim().isNotEmpty)
                                  ? InkWell(
                                      onTap: () => _showFullScreenImage(context, 'Company Logo', _company!.logo!),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            _buildDetailRow('Location', _company!.city ?? 'N/A'),
                            if (_company!.radius != null)
                              _buildDetailRow('Radius', _company!.radius.toString()),
                            if (_company!.latitude != null)
                              _buildDetailRow('Latitude', _company!.latitude.toString()),
                            if (_company!.longitude != null)
                              _buildDetailRow('Longitude', _company!.longitude.toString()),
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
                            Text(
                              branch.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
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
                                  if (branch.radius != null)
                                    _buildDetailRow('Radius', branch.radius.toString()),
                                  if (branch.latitude != null)
                                    _buildDetailRow('Latitude', branch.latitude.toString()),
                                  if (branch.longitude != null)
                                    _buildDetailRow('Longitude', branch.longitude.toString()),
                                ],
                              ),
                            ),
                          ],
                        )),
                      ]
                    ],
                  ),
                ),
    );
  }
}
