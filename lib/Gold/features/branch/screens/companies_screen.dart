import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/gold_session.dart';
import '../../../widgets/gold_back_button.dart';
import '../../../widgets/gold_dialogs.dart';
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
      final userCompanyIds = GoldSession.instance.userAccess.map((ca) => ca.companyId).toList();

      List<Company> companies = [];
      if (userCompanyIds.isNotEmpty) {
        final results = await Future.wait(
          userCompanyIds.map((id) => _repository.getCompanyById(id.toString())),
        );
        companies = results.whereType<Company>().toList();
      }

      // Fallback to getAllCompanies if individual calls returned nothing
      if (companies.isEmpty) {
        final all = await _repository.getAllCompanies();
        if (userCompanyIds.isNotEmpty) {
          companies = all.where((c) => userCompanyIds.contains(c.id)).toList();
        } else {
          companies = all;
        }
      }

      // Final fallback to userAccess basic names if still empty
      if (companies.isEmpty && GoldSession.instance.userAccess.isNotEmpty) {
        companies = GoldSession.instance.userAccess
            .map((ca) => Company(id: ca.companyId, companyName: ca.companyName))
            .toList();
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
                              onTap: () {
                                if (company.id != null) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.companyDetails,
                                    arguments: company.id.toString(),
                                  );
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
                                      company.city?.isNotEmpty == true
                                          ? company.city!
                                          : (company.sector ?? ''),
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    )
                                  : null,
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
