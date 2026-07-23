import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_extensions.dart';
import '../../../core/utils/screen_utility.dart';
import '../../../widgets/gold_back_button.dart';
import '../models/customer_model.dart';
import '../repository/customer_repository.dart';
import '../../gold/models/gold_purchase_model.dart';
import '../../gold/widgets/party_details_card.dart';
import '../../gold/widgets/billed_item_card.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final CustomerRepository _repository = CustomerRepository();
  late Customer _customer;
  bool _isLoading = true;

  // Tabs
  String _activeTab = 'Gold'; // 'Gold' or 'Loans'
  String _activeSubTab = 'Purchase'; // 'Purchase' or 'Sell'
  String _loansActiveSubTab = 'Loan Details'; // 'Loan Details' or 'Due Payments'

  // Expandable list items state: store expanded status index
  final Map<int, bool> _purchaseExpanded = {};
  final Map<int, bool> _sellExpanded = {};
  final Map<int, bool> _loansExpanded = {};
  final Map<int, bool> _showAllPayments = {};
  bool _additionalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getSingleCustomer(
        name: widget.customer.name,
        phoneNumber: widget.customer.phoneNumber,
      );
      setState(() {
        _customer = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatIndianCurrency(double amount) {
    String fixedStr = amount.toStringAsFixed(2);
    List<String> parts = fixedStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    if (integerPart.length <= 3) {
      return '$integerPart.$decimalPart';
    }
    String lastThree = integerPart.substring(integerPart.length - 3);
    String other = integerPart.substring(0, integerPart.length - 3);
    String result = '';
    int count = 0;
    for (int i = other.length - 1; i >= 0; i--) {
      result = other[i] + result;
      count++;
      if (count == 2 && i != 0) {
        result = ',$result';
        count = 0;
      }
    }
    return '$result,$lastThree.$decimalPart';
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtility().init(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GoldBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Details',
          style: AppTextStyles.h1.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,

          ),
        ),
        centerTitle: true,
       
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // Main Details Box
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile Info
                          Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F9D58),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getInitials(_customer.name),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _customer.name,
                                    style: AppTextStyles.h2.copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    _customer.phoneNumber.startsWith('+91')
                                        ? _customer.phoneNumber
                                        : '+91 ${_customer.phoneNumber}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          
                          // Bento row (3 cards)
                          Row(
                            children: [
                              Expanded(
                                child: _buildBentoCard(
                                  icon: Icons.shopping_cart_outlined,
                                  iconColor: const Color(0xFFE28743),
                                  bgColor: const Color(0xFFFFF7ED),
                                  title: 'Total Purchase',
                                  value: '₹ ${_formatIndianCurrency(_customer.totalPurchase ?? 0.0)}',
                                  subtitle: '${_customer.purchaseTransactionsCount ?? 0} Transactions',
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: _buildBentoCard(
                                  icon: Icons.local_mall_outlined,
                                  iconColor: const Color(0xFF1E88E5),
                                  bgColor: const Color(0xFFEFF6FF),
                                  title: 'Total Sell',
                                  value: '₹ ${_formatIndianCurrency(_customer.totalSell ?? 0.0)}',
                                  subtitle: '${_customer.sellTransactionsCount ?? 0} Transactions',
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: _buildBentoCard(
                                  icon: Icons.description_outlined,
                                  iconColor: const Color(0xFFD32F2F),
                                  bgColor: const Color(0xFFFEF2F2),
                                  title: 'Total Due',
                                  value: '₹ ${_formatIndianCurrency(_customer.totalDue ?? 0.0)}',
                                  subtitle: '${_customer.duePaymentsCount ?? 0} Due Payments',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_activeTab == 'Loans')
                    _buildAdditionalInformationSection(),

                  // Tabs: Gold & Loans
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMainTabButton('Gold'),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: _buildMainTabButton('Loans'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Inner content switcher
                  if (_activeTab == 'Gold') ...[
                    // Subtabs: Purchase History & Sell History
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSubTabButton('Purchase', 'Purchase History'),
                            ),
                            Expanded(
                              child: _buildSubTabButton('Sell', 'Sell History'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Dynamic Subtab Lists
                    if (_activeSubTab == 'Purchase')
                      _buildPurchaseHistoryList()
                    else
                      _buildSellHistoryList()
                  ] else ...[
                    // Subtabs: Loan Details & Due Payments
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildLoansSubTabButton('Loan Details'),
                            ),
                            Expanded(
                              child: _buildLoansSubTabButton('Due Payments'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    if (_loansActiveSubTab == 'Loan Details') ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        child: Text(
                          'Loan Accounts',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      _buildLoansList(),
                    ] else
                      _buildDuePaymentsTab(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAdditionalInformationSection() {
    final person = _customer.persons.isNotEmpty ? _customer.persons.first : null;
    if (person == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _additionalInfoExpanded = !_additionalInfoExpanded;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    Icon(
                      _additionalInfoExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
            if (_additionalInfoExpanded) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Container(
                color: const Color(0xFFF8F9FA),
                padding: EdgeInsets.all(4.w),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Id Proof', person.idProof ?? '---'),
                    SizedBox(height: 1.5.h),
                    Text(
                      'Id Proof Upload',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildProofImage(person.idProofImage),
                    SizedBox(height: 1.5.h),
                    _buildInfoItem('Address', person.address ?? '---'),
                    SizedBox(height: 1.5.h),
                    _buildInfoItem('Witness Name', person.witnessName ?? '---'),
                    SizedBox(height: 1.5.h),
                    _buildInfoItem('Nominee Mobile Number', person.witnessMobileNumber ?? '---'),
                    SizedBox(height: 1.5.h),
                    _buildInfoItem('Witness Relation', person.witnessRelation ?? '---'),
                    SizedBox(height: 1.5.h),
                    _buildInfoItem('Witness Id Proof', person.witnessIdProof ?? '---'),
                    SizedBox(height: 1.5.h),
                    Text(
                      'Witness Id Proof Upload',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildProofImage(person.witnessIdProofImage),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildProofImage(String? imageUrl) {
    return GestureDetector(
      onTap: () {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _showAgreementImageDialog(context, imageUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image uploaded.')),
          );
        }
      },
      child: Container(
        height: 15.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: Center(
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_outlined, color: const Color(0xFF94A3B8), size: 30.sp),
                  ),
                )
              : Icon(Icons.image_outlined, color: const Color(0xFF94A3B8), size: 30.sp),
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard(GoldPurchase record, bool isPurchase) {
    // Determine the party details from the backend based on purchase vs sale
    final party = isPurchase ? record.party : record.saleParty;

    final name = party?.partyName ?? record.partyName;
    final phone = party?.partyPhoneNumber ?? record.partyPhoneNumber;
    final dlNo = party?.dlNumber ?? record.dlNumber;
    final licNo = party?.licenseNumber ?? record.licenseNumber;

    // Check if license number is null/empty and DL number exists
    final showDl = (licNo == null || licNo.isEmpty) && (dlNo != null && dlNo.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Purchase Date',
                isPurchase ? record.purchaseDate : (record.saleDate ?? record.purchaseDate),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Customer Name', name),
              const SizedBox(height: 12),
              _buildDetailRow('Ph No', phone),
              const SizedBox(height: 12),
              if (showDl)
                _buildDetailRow('DL No', dlNo)
              else if (licNo != null && licNo.isNotEmpty)
                _buildDetailRow('LIC No', licNo)
              else
                _buildDetailRow('LIC No', ''), // Fallback if both are empty
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value.isEmpty ? '---' : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Circle
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14.sp),
          ),
          SizedBox(height: 1.5.h),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          SizedBox(
            height: 18.sp,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(String tabName) {
    final isSelected = _activeTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
        });
      },
      child: Container(
        height: 5.5.h,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          tabName,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String subTabName, String label) {
    final isSelected = _activeSubTab == subTabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeSubTab = subTabName;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        margin: EdgeInsets.all(0.5.w),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLoansSubTabButton(String subTabName) {
    final isSelected = _loansActiveSubTab == subTabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _loansActiveSubTab = subTabName;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        margin: EdgeInsets.all(0.5.w),
        child: Text(
          subTabName,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLoansList() {
    if (_customer.loans.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Text(
            'No loan accounts found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
        ),
      );
    }

    final loansList = _customer.loans;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: loansList.length,
      itemBuilder: (context, idx) {
        final loan = loansList[idx];
        final isExpanded = _loansExpanded[idx] ?? false;
        final isActive = loan.status.toUpperCase() == 'ACTIVE';
        final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFF64748B);
        final statusBgColor = isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Column(
            children: [
              // Header Row (Clickable)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _loansExpanded[idx] = !isExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
                  child: Row(
                    children: [
                      // Icon Circle
                      Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.home_work_outlined,
                          color: const Color(0xFF64748B),
                          size: 15.sp,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan ${idx + 1}',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${_formatDisplayDate(loan.loanDate)} - Tenure ${loan.loanPeriod} ${loan.loanPeriodType.toLowerCase() == 'month' ? 'Months' : loan.loanPeriodType}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          loan.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Arrow
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Content
              if (isExpanded) ...[
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Details',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      
                      // Loan parameters grid (Date & Period)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLoanDetailsRow('Loan Period', '${loan.loanPeriod} ${loan.loanPeriodType.toLowerCase() == 'month' ? 'Months' : loan.loanPeriodType}'),
                            SizedBox(height: 1.5.h),
                            _buildLoanDetailsRow('Loan Date', _formatDisplayDate(loan.loanDate)),
                            SizedBox(height: 1.5.h),
                            _buildLoanDetailsRow('Principal Amount', '₹ ${_formatIndianCurrency(loan.principalAmount)}'),
                            SizedBox(height: 1.5.h),
                            _buildLoanDetailsRow('Interest Rate', '${loan.interestRate.toStringAsFixed(0)}%'),
                            SizedBox(height: 1.5.h),
                            _buildLoanDetailsRow('Interest Payment Period', '${loan.interestPaymentPeriodType.toUpperCase() == 'MONTHLY' ? 'Monthly' : loan.interestPaymentPeriodType} / ${loan.interestPaymentPeriod}'),
                            SizedBox(height: 1.5.h),
                            
                            // Agreement Image
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agreement Image',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                GestureDetector(
                                  onTap: () {
                                    if (loan.agreementImage != null && loan.agreementImage!.isNotEmpty) {
                                      _showAgreementImageDialog(context, loan.agreementImage!);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No agreement image uploaded.')),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 15.h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Center(
                                      child: loan.agreementImage != null && loan.agreementImage!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8.r),
                                              child: Image.network(
                                                loan.agreementImage!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Icon(Icons.image_outlined, color: const Color(0xFF94A3B8), size: 30.sp),
                                              ),
                                            )
                                          : Icon(Icons.image_outlined, color: const Color(0xFF94A3B8), size: 30.sp),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 3.h),
                      
                      // Payment History Section
                      Text(
                        'Payment History',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      
                      _buildPaymentHistoryList(loan.id),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanDetailsRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryList(int loanId) {
    final List<CustomerPaymentUpdate> payments = _customer.paymentUpdates.where((p) => p.loanId == loanId).toList();
    
    if (payments.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Center(
          child: Text(
            'No payment history found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
          ),
        ),
      );
    }

    final bool showAll = _showAllPayments[loanId] ?? false;
    final int displayCount = showAll ? payments.length : (payments.length > 5 ? 5 : payments.length);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDisplayDate(payment.paymentDate),
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Interest Amount',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (payment.principalAmount > 0) ...[
                          SizedBox(height: 1.h),
                          Text(
                            'Principal Amount Paid',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${_formatIndianCurrency(payment.principalAmount + payment.interestAmount)}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.south_west, size: 8.sp, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              '₹ ${_formatIndianCurrency(payment.interestAmount)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (payment.principalAmount > 0) ...[
                          SizedBox(height: 1.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.south_west, size: 8.sp, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                '₹ ${_formatIndianCurrency(payment.principalAmount)}',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          if (payments.length > 5) ...[
            SizedBox(height: 1.5.h),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllPayments[loanId] = !showAll;
                });
              },
              child: Text(
                showAll ? 'View less' : 'View more',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          SizedBox(height: 0.5.h),
        ],
      ),
    );
  }

  Widget _buildDuePaymentsTab() {
    if (_customer.dues.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Text(
            'No due payments found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _customer.dues.length,
      itemBuilder: (context, index) {
        final item = _customer.dues[index];

        String monthStr = '';
        String dayStr = '';
        try {
          final date = DateTime.parse(item.dueDate);
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          monthStr = months[date.month - 1];
          dayStr = date.day.toString().padLeft(2, '0');
        } catch (_) {
          monthStr = item.dueMonth;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthStr,
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    dayStr,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Container(
                height: 4.h,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        (() {
                          final loanIndex = _customer.loans.indexWhere((l) => l.id == item.loanId);
                          final loan = loanIndex != -1 ? _customer.loans[loanIndex] : null;
                          final remainingMonths = loan?.remainingMonths;
                          return Text.rich(
                            TextSpan(
                              text: loanIndex != -1 ? 'Loan ${loanIndex + 1}' : 'Loan ${item.loanId}',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                              children: [
                                if (remainingMonths != null)
                                  TextSpan(
                                    text: ' (Remaining: $remainingMonths Months)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        })(),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Total Amount: ₹ ${_formatIndianCurrency(item.totalAmount.toDouble())}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'INTEREST AMOUNT',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 7.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '₹ ${_formatIndianCurrency(item.interestAmount.toDouble())}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAgreementImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Agreement Image'),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Could not load image'),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryList() {
    if (_customer.purchaseHistory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Text(
            'No purchase records found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _customer.purchaseHistory.length,
      itemBuilder: (context, index) {
        final record = _customer.purchaseHistory[index];
        final isExpanded = _purchaseExpanded[index] ?? false;

        return _buildHistoryAccordion(
          index: index,
          record: record,
          isExpanded: isExpanded,
          isPurchase: true,
          onToggle: () {
            setState(() {
              _purchaseExpanded[index] = !isExpanded;
            });
          },
        );
      },
    );
  }

  Widget _buildSellHistoryList() {
    if (_customer.sellHistory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Text(
            'No sell records found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary row for Sell History
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHistoryHeaderStat(
                  title: 'Total Gold Sell',
                  value: '${_customer.totalGoldSellWeight?.toStringAsFixed(3) ?? '0.000'} gm',
                  subtitle: '${_customer.goldSellTransactionsCount ?? 0} Transactions',
                ),
                _buildHistoryHeaderStat(
                  title: 'Total Received',
                  value: '₹ ${_formatIndianCurrency(_customer.totalReceivedAmount ?? 0.0)}',
                  subtitle: '${_customer.goldSellTransactionsCount ?? 0} Transactions',
                ),
                _buildHistoryHeaderStat(
                  title: 'Last Sell On',
                  value: _formatDisplayDate(_customer.lastSellDate),
                  subtitle: '12:45 PM',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: _customer.sellHistory.length,
          itemBuilder: (context, index) {
            final record = _customer.sellHistory[index];
            final isExpanded = _sellExpanded[index] ?? false;

            return _buildHistoryAccordion(
              index: index,
              record: record,
              isExpanded: isExpanded,
              isPurchase: false,
              onToggle: () {
                setState(() {
                  _sellExpanded[index] = !isExpanded;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryHeaderStat({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: 7.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryAccordion({
    required int index,
    required GoldPurchase record,
    required bool isExpanded,
    required bool isPurchase, // true if in Purchase History tab, false if in Sell History tab
    required VoidCallback onToggle,
  }) {
    final recordStatus = record.status?.toUpperCase() ?? 'PURCHASE';
    final isRecordPurchase = recordStatus == 'PURCHASE';

    final themeColor = isRecordPurchase ? const Color(0xFF10B981) : const Color(0xFFF97316);
    final themeBgColor = isRecordPurchase ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);
    final badgeText = isRecordPurchase ? 'Purchase' : 'Sale';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        children: [
          // Accordion Header
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: themeBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecordPurchase ? Icons.shopping_cart_outlined : Icons.local_mall_outlined,
                      color: themeColor,
                      size: 15.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gold 22K - ${(record.totalGrossWeight ?? 8.500).toStringAsFixed(3)} gm',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatDisplayDate(isRecordPurchase ? record.purchaseDate : record.saleDate),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge / Amount
                  if (!isPurchase) ...[
                    // Sell History tab: show "Sale" label and bold amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sale',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          _formatIndianCurrency(record.saleAmount ?? 0.0),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Purchase History tab: show status badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: themeBgColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 2.w),
                  
                  // Arrow
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerDetailsCard(record, isPurchase),
                  SizedBox(height: 3.h),
                  
                  // Billed Items Table Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Billed Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  
                  // Items list
                  if (record.items != null && record.items!.isNotEmpty)
                    Column(
                      children: record.items!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return BilledItemCard(
                          index: index + 1,
                          weight: item.grossWeight.toStringAsFixed(2),
                          side1: item.side1.toStringAsFixed(2),
                          side2: item.side2.toStringAsFixed(2),
                          average: item.averagePercentage.toStringAsFixed(2),
                          pureWeight: item.pureWeight.toStringAsFixed(2),
                          showActions: false,
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: const Center(child: Text('No items found.')),
                    ),
                  
                  SizedBox(height: 2.h),
                  
                  // Weight Summaries
                  _SummaryRow(
                    label: 'Total Gross Weight',
                    value: '${(record.totalGrossWeight ?? 0.0).toStringAsFixed(2)} gm',
                  ),
                  _SummaryRow(
                    label: 'Total Pure Weight',
                    value: '${(record.totalPureWeight ?? 0.0).toStringAsFixed(2)} gm',
                  ),
                  SizedBox(height: 3.h),
                  
                  // Financial Breakdown
                  _buildFinancialsCard(record),
                  SizedBox(height: 2.h),
                  
                  // Final summary
                  _buildFinalSummary(record),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialsCard(GoldPurchase purchase) {
    final totalAmountVal = purchase.totalAmount ?? 0.0;
    final royaltyVal = double.tryParse(purchase.royaltyCifHiv ?? '') ?? 0.0;
    final traVal = double.tryParse(purchase.tra ?? '') ?? 0.0;
    final svlVal = double.tryParse(purchase.svl ?? '') ?? 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        children: [
          _FinancialRow(
            label: 'Total Amount',
            value: _formatIndianCurrency(totalAmountVal),
          ),
          SizedBox(height: 1.2.h),
          _FinancialRow(
            label: 'Royalty CIF / HIV',
            value: _formatIndianCurrency(royaltyVal),
          ),
          SizedBox(height: 1.2.h),
          _FinancialRow(
            label: 'TRA',
            value: _formatIndianCurrency(traVal),
          ),
          SizedBox(height: 1.2.h),
          _FinancialRow(
            label: 'SVL',
            value: _formatIndianCurrency(svlVal),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSummary(GoldPurchase purchase) {
    final amountVal = purchase.amount ?? 0.0;
    final taxVal = purchase.tax ?? 0.0;
    final grandTotalVal = purchase.grandTotal ?? 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          _FinancialRow(
            label: 'Amount',
            value: _formatIndianCurrency(amountVal),
          ),
          SizedBox(height: 1.2.h),
          _FinancialRow(
            label: 'Tax',
            value: _formatIndianCurrency(taxVal),
          ),
          SizedBox(height: 1.8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  _formatIndianCurrency(grandTotalVal),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Private layout helpers identical to gold details screen
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;

  const _FinancialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
