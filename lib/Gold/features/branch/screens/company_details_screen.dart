import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final String companyId;
  final Company? initialCompany;

  const CompanyDetailsScreen({
    super.key,
    required this.companyId,
    this.initialCompany,
  });

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final BranchRepository _repository = BranchRepository();
  Company? _company;
  bool _isLoading = true;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _company = widget.initialCompany;
    _isLoading = _company == null;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_company == null) {
      setState(() => _isLoading = true);
    }
    try {
      final company = await _repository.getCompanyById(widget.companyId);
      if (mounted) {
        setState(() {
          if (company != null) {
            _company = company.copyWith(
              user: company.user ?? _company?.user,
              branches: company.branches.isNotEmpty ? company.branches : (_company?.branches ?? []),
            );
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        leading: GoldBackButton(
          onPressed: () => Navigator.pop(context, _hasUpdated),
        ),
        title: const Text(
          'Company Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_company != null)
            IconButton(
              icon: SvgPicture.asset('assets/images/Edit.svg', width: 20, height: 20),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.addCompany,
                  arguments: _company,
                );
                if (result == true) {
                  _hasUpdated = true;
                  _fetchDetails();
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _company == null
              ? const Center(child: Text('Failed to load company details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title
                      Text(
                        _company!.companyName ?? 'Company',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Company Details Card
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
                            if (_company!.legalEntityName != null && _company!.legalEntityName!.isNotEmpty)
                              _buildDetailRow('Legal Name', _company!.legalEntityName!),
                            if (_company!.companyType != null && _company!.companyType!.isNotEmpty)
                              _buildDetailRow('Type', _company!.companyType!),
                            _buildDetailRow('Sector', _company!.sector?.isNotEmpty == true ? _company!.sector! : 'N/A'),
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
                            _buildDetailRow('Location', _company!.city?.isNotEmpty == true ? _company!.city! : 'N/A'),
                            if (_company!.country != null && _company!.country!.isNotEmpty)
                              _buildDetailRow('Country', _company!.country!),
                            if (_company!.companyEmail != null && _company!.companyEmail!.isNotEmpty)
                              _buildDetailRow('Email', _company!.companyEmail!),
                            if (_company!.companyPhone != null && _company!.companyPhone!.isNotEmpty)
                              _buildDetailRow('Phone', _company!.companyPhone!),
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

                      // User Information Card (from GET /api/company/all)
                      if (_company!.user != null) ...[
                        const Text(
                          'Authorized User',
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
                              if (_company!.user!.name != null && _company!.user!.name!.isNotEmpty)
                                _buildDetailRow('User Name', _company!.user!.name!),
                              if (_company!.user!.email != null && _company!.user!.email!.isNotEmpty)
                                _buildDetailRow('User Email', _company!.user!.email!),
                              if (_company!.user!.id != null)
                                _buildDetailRow('User ID', _company!.user!.id.toString()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Branches Card (from branches array in GET calls)
                      const Text(
                        'Branches',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_company!.branches.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'No branches associated.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ..._company!.branches.map((branch) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name.isNotEmpty ? branch.name : 'Branch ${branch.id ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  if (branch.id != null)
                                    _buildDetailRow('Branch ID', branch.id!),
                                  _buildDetailRow('Name', branch.name.isNotEmpty ? branch.name : 'N/A'),
                                  if (branch.sector.isNotEmpty)
                                    _buildDetailRow('Sector', branch.sector),
                                  if (branch.location.isNotEmpty)
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
                    ],
                  ),
                ),
    );
  }
}
