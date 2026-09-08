import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFC),
        elevation: 0,
        leading: GoldBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardBlock(
              child: const Text(
                'Last Updated: September 2026\n\nWelcome to MilloraPay. These Terms & Conditions govern your access to and use of the MilloraPay application, website, platform, and related services.\n\nBy accessing or using MilloraPay, you acknowledge that you have read, understood, and agreed to these Terms & Conditions. If you are using MilloraPay on behalf of a company or organisation, you confirm that you are authorised to do so.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF727271),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            _buildSectionHeader('1. About MilloraPay'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay is a business expense and financial record management platform designed to help organisations manage companies, branches, staff, expenses, transactions, categories, reports, and spending information in an organised manner.\n\nThe features available through MilloraPay may change, expand, or be updated from time to time.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('2. Company and Branch Management'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MilloraPay allows an organisation to create and manage multiple branches under a company account. Each branch may maintain its own staff and management structure, separate from other branches, while remaining part of the overall company account.\n\nThe company administrator may:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Create and manage branches.'),
                  _buildBulletPoint('Add, remove, or manage branch users and staff.'),
                  _buildBulletPoint('Assign branch-level administrators to oversee staff and operations within a specific branch.'),
                  _buildBulletPoint('Assign appropriate access or management responsibilities.'),
                  _buildBulletPoint('Manage expenses and transaction records associated with the organisation.'),
                  _buildBulletPoint('Review branch-level and company-level financial information.'),
                  _buildBulletPoint('Generate reports and view spending insights.'),
                  const SizedBox(height: 12),
                  const Text(
                    'The organisation is responsible for ensuring that the information entered into the platform is accurate and authorised.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                ],
              ),
            ),
            
            _buildSectionHeader('3. User Accounts and Access'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User accounts and login credentials are created and managed by authorised administrators, including at the branch level. A branch administrator may create and manage login credentials for staff within their own branch, while company-level administrators retain oversight across all branches.\n\nEach user is responsible for:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Keeping their login credentials confidential.'),
                  _buildBulletPoint('Using only the access provided to them.'),
                  _buildBulletPoint('Not sharing their account with unauthorised individuals.'),
                  _buildBulletPoint('Ensuring that information entered through their account is accurate.'),
                  _buildBulletPoint('Immediately reporting suspected unauthorised access or security concerns.'),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrators are responsible for managing user access and ensuring that employees or staff members receive only the permissions appropriate to their role and branch.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                ],
              ),
            ),
            
            _buildSectionHeader('4. Expense and Transaction Records'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MilloraPay enables authorised users to record and manage business expenses and transactions.\n\nUsers are responsible for ensuring that:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Expense amounts are entered correctly.'),
                  _buildBulletPoint('Transaction details are accurate.'),
                  _buildBulletPoint('Appropriate categories are selected.'),
                  _buildBulletPoint('The purpose or reason for an expense is correctly recorded.'),
                  _buildBulletPoint('Supporting information, where required, is genuine and accurate.'),
                  const SizedBox(height: 12),
                  const Text(
                    'MilloraPay provides tools for organising and managing records but does not independently verify the authenticity, legality, or business purpose of every expense entered by users.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                ],
              ),
            ),
            
            _buildSectionHeader('5. Categories and Expense Classification'),
            _buildCardBlock(
              child: const Text(
                'Users may classify expenses and transactions according to categories, purposes, or other information supported by the platform, including the reason a purchase or transaction was made.\n\nThe organisation is responsible for maintaining appropriate categories and ensuring that transactions are classified correctly for its internal requirements.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('6. Reports, Charts and Insights'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay may provide reports, charts, summaries, spending analysis, and other representations of information entered into the platform.\n\nThese reports are generated from the data available in the system and are intended to assist organisations with internal expense monitoring and management.\n\nReports and analytics should not be considered professional accounting, taxation, legal, investment, or financial advice unless expressly stated otherwise.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('7. Accuracy of Information'),
            _buildCardBlock(
              child: const Text(
                'The accuracy and completeness of information entered into MilloraPay is the responsibility of the organisation and its authorised users.\n\nMilloraPay is not responsible for losses, decisions, accounting discrepancies, tax consequences, or other issues arising from incorrect, incomplete, outdated, fraudulent, or unauthorised information entered by users.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('8. Data and Records'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay stores information submitted through the platform to provide its services, maintain records, generate reports, and support organisational management. This includes capturing transaction-level detail — such as amounts, categories, purposes, and timestamps — to support accurate and complete financial record-keeping.\n\nThe organisation remains responsible for determining what information should be entered into the platform and ensuring that its collection and use are lawful and appropriately authorised.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('9. Data Security'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay is designed to protect business and user information through appropriate technical and organisational security measures.\n\nHowever, no digital platform can guarantee absolute protection against every possible security threat, unauthorised access, system failure, or data loss.\n\nUsers must also maintain appropriate account security and access controls.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('10. Acceptable Use'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Users must not:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Use MilloraPay for unlawful, fraudulent, or deceptive activities.'),
                  _buildBulletPoint('Enter knowingly false or misleading financial information.'),
                  _buildBulletPoint('Attempt to gain unauthorised access to another user\'s account or organisation.'),
                  _buildBulletPoint('Attempt to bypass access controls or security mechanisms.'),
                  _buildBulletPoint('Interfere with the operation or security of the platform.'),
                  _buildBulletPoint('Copy, reproduce, modify, reverse engineer, or attempt to extract the underlying software or source code.'),
                  _buildBulletPoint('Use the platform to distribute malicious software or harmful content.'),
                  _buildBulletPoint('Allow unauthorised persons to access organisational information.'),
                ],
              ),
            ),
            
            _buildSectionHeader('11. Administrator Responsibility'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The company or organisation using MilloraPay is responsible for:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Managing its administrator accounts, including branch-level administrators.'),
                  _buildBulletPoint('Managing branches and users.'),
                  _buildBulletPoint('Assigning appropriate permissions.'),
                  _buildBulletPoint('Maintaining the accuracy of its records.'),
                  _buildBulletPoint('Reviewing transactions and expenses entered by its users.'),
                  _buildBulletPoint('Maintaining appropriate internal financial controls.'),
                ],
              ),
            ),
            
            _buildSectionHeader('12. Service Availability'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay will make reasonable efforts to keep the platform available and operational.\n\nTemporary interruptions may occur due to maintenance, upgrades, technical issues, infrastructure failures, security incidents, third-party services, network failures, or circumstances beyond MilloraPay\'s reasonable control.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('13. Changes to the Platform'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay may introduce, modify, suspend, or discontinue features or services from time to time.\n\nFuture features may include additional financial, business management, reporting, integration, or administrative capabilities.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('14. Intellectual Property'),
            _buildCardBlock(
              child: const Text(
                'The MilloraPay application, software, design, branding, interface, logos, features, documentation, and related intellectual property belong to MilloraPay or its respective licensors.\n\nUsers are granted a limited right to use the platform for authorised business purposes and do not acquire ownership of the underlying software or intellectual property.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('15. Suspension or Termination'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MilloraPay may restrict, suspend, or terminate access where necessary, including in cases involving:',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Violation of these Terms.'),
                  _buildBulletPoint('Unauthorised access or activity.'),
                  _buildBulletPoint('Fraudulent or unlawful use.'),
                  _buildBulletPoint('Security risks.'),
                  _buildBulletPoint('Misuse of the platform.'),
                  _buildBulletPoint('Non-payment of applicable fees, where relevant.'),
                ],
              ),
            ),
            
            _buildSectionHeader('16. Limitation of Liability'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay provides the platform as a technology and management tool.\n\nTo the maximum extent permitted by applicable law, MilloraPay shall not be responsible for indirect, incidental, consequential, or business losses arising from reliance on information entered into, generated by, or managed through the platform.\n\nNothing in these Terms is intended to exclude liability that cannot legally be excluded under applicable law.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('17. Governing Law'),
            _buildCardBlock(
              child: const Text(
                'These Terms shall be governed by the applicable laws of India.\n\nAny disputes relating to the use of MilloraPay shall be subject to the jurisdiction specified by MilloraPay in its applicable business and legal documentation.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('18. Updates to These Terms'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay may update these Terms & Conditions from time to time to reflect changes to the platform, services, technology, or applicable legal requirements.\n\nUsers are encouraged to review the latest version periodically.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('19. Contact'),
            _buildCardBlock(
              child: const Text(
                'For questions, concerns, or support relating to these Terms or MilloraPay, users may contact the MilloraPay support team through the contact details provided within the application or on the official MilloraPay website.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCardBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F2F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF727271),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF727271),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
