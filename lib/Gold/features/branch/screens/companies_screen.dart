import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/gold_session.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
import '../../auth/models/auth_models.dart';
import '../models/branch_model.dart';
import '../repository/branch_repository.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final BranchRepository _repository = BranchRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Company> _allCompanies = [];
  List<Company> _filteredCompanies = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all companies for the current user from the API
      List<Company> companies = await _repository.getAllCompanies();

      // 2. Fallback to individual getCompanyById for session companies if getAllCompanies returned nothing
      if (companies.isEmpty) {
        final userCompanyIds = GoldSession.instance.userAccess.map((ca) => ca.companyId).toList();
        if (userCompanyIds.isNotEmpty) {
          final results = await Future.wait(
            userCompanyIds.map((id) => _repository.getCompanyById(id.toString())),
          );
          companies = results.whereType<Company>().toList();
        }
      }

      // 3. Final fallback to userAccess basic names if still empty
      if (companies.isEmpty && GoldSession.instance.userAccess.isNotEmpty) {
        companies = GoldSession.instance.userAccess
            .map((ca) => Company(id: ca.companyId, companyName: ca.companyName))
            .toList();
      }

      // 4. Sync any new companies into GoldSession so drawer & session have them
      if (companies.isNotEmpty) {
        final existingIds = GoldSession.instance.userAccess.map((ca) => ca.companyId).toSet();
        final updatedAccess = List<CompanyAccess>.from(GoldSession.instance.userAccess);
        bool hasNew = false;
        for (final c in companies) {
          if (c.id != null && !existingIds.contains(c.id)) {
            hasNew = true;
            updatedAccess.add(CompanyAccess(
              companyId: c.id!,
              companyName: c.companyName ?? '',
              sector: c.sector,
              branches: c.branches.map((b) => BranchAccess(
                branchId: int.tryParse(b.id ?? '') ?? 0,
                branchName: b.name,
                access: [],
              )).toList(),
            ));
          }
        }
        if (hasNew) {
          GoldSession.instance.updateUserAccess(updatedAccess);
        }
      }

      if (mounted) {
        setState(() {
          _allCompanies = companies;
          _filteredCompanies = companies;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        GoldDialogs.showSnackBar(context, 'Failed to load companies', isError: true);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = _allCompanies;
      });
      return;
    }
    setState(() {
      _filteredCompanies = _allCompanies.where((c) {
        final name = (c.companyName ?? '').toLowerCase();
        final sector = (c.sector ?? '').toLowerCase();
        final city = (c.city ?? '').toLowerCase();
        return name.contains(query) || sector.contains(query) || city.contains(query);
      }).toList();
    });
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.addCompany);
          if (result == true) {
            _fetchCompanies();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text(
          '+ Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          'Companies',
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
                : _filteredCompanies.isEmpty
                    ? const Center(child: Text('No companies found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchCompanies,
                        color: AppColors.primaryBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredCompanies.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, index) {
                            final company = _filteredCompanies[index];
                            final hasSubtitle = (company.city != null && company.city!.isNotEmpty) ||
                                (company.sector != null && company.sector!.isNotEmpty);

                            return ListTile(
                              onTap: () async {
                                if (company.id != null) {
                                  final updated = await Navigator.pushNamed(
                                    context,
                                    AppRoutes.companyDetails,
                                    arguments: company,
                                  );
                                  if (updated == true) {
                                    _fetchCompanies();
                                  }
                                }
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: (company.logo != null && company.logo!.trim().isNotEmpty)
                                      ? Image.network(
                                          Uri.encodeFull(company.logo!.trim()),
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: SvgPicture.asset(
                                              'assets/images/Company.svg',
                                              width: 18,
                                              height: 18,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: SvgPicture.asset(
                                            'assets/images/Company.svg',
                                            width: 18,
                                            height: 18,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                company.companyName ?? 'Company',
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: hasSubtitle
                                  ? Text(
                                      [
                                        if (company.sector != null && company.sector!.isNotEmpty) company.sector!,
                                        if (company.city != null && company.city!.isNotEmpty) company.city!,
                                        if (company.branches.isNotEmpty)
                                          '${company.branches.length} ${company.branches.length == 1 ? "branch" : "branches"}',
                                      ].join(' • '),
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: SvgPicture.asset('assets/images/Edit.svg', width: 16, height: 16),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    AppRoutes.addCompany,
                                    arguments: company,
                                  );
                                  if (result == true) {
                                    _fetchCompanies();
                                  }
                                },
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
