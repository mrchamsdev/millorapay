import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          'MilloraPay Help Center',
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

            _buildSectionHeader('1. Getting Started'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How do I set up my company on MilloraPay?'),
                  _buildAnswer('When you first sign in as a company administrator, create your company profile, then add at least one branch. Every expense, transaction, and report in MilloraPay is organised under a branch, so this is the first thing to set up.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('What\'s the difference between a company and a branch?'),
                  _buildAnswer('Your company account is the top level of your organisation. Branches sit underneath it — each branch can have its own staff, its own transactions, and its own branch administrator, while the company administrator can see activity across every branch.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Who can create a company account?'),
                  _buildAnswer('Company accounts are set up by an authorised representative of the organisation. That person becomes the company administrator and can then invite branch administrators and staff.'),
                ],
              ),
            ),
            
            _buildSectionHeader('2. Branches & Staff'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How do I add a new branch?'),
                  _buildAnswer('From the company dashboard, go to Branches and select Add branch. Give the branch a name and location, then assign a branch administrator to manage it day to day.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('How do I add staff to a branch?'),
                  _buildAnswer('Open the branch, go to Staff, and add each team member. A branch administrator can create logins for their own branch\'s staff; a company administrator can do this for any branch.'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Assign each staff member only the access their role needs.'),
                  _buildBulletPoint('Remove or reassign access when someone leaves the branch.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Can one person manage more than one branch?'),
                  _buildAnswer('Yes. A company administrator can be given oversight of multiple branches, while a branch administrator\'s access is normally limited to the branch they\'re assigned to.'),
                ],
              ),
            ),
            
            _buildSectionHeader('3. Accounts & Login'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('I forgot my password. What do I do?'),
                  _buildAnswer('Use the Forgot password link on the sign-in screen. If you\'re not able to reset it yourself, ask your branch or company administrator to reset it for you, since accounts are managed by administrators rather than self-registration.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Why can\'t I see another branch\'s data?'),
                  _buildAnswer('Staff accounts are scoped to the branch they belong to. If you need visibility into another branch, your company administrator can adjust your permissions.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('I think someone accessed my account without permission. What should I do?'),
                  _buildAnswer('Change your password immediately and report it to your administrator or MilloraPay support right away so the account can be reviewed and secured.'),
                ],
              ),
            ),
            
            _buildSectionHeader('4. Expenses & Transactions'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How do I record an expense?'),
                  _buildAnswer('Go to Expenses within your branch and select Add expense. Enter the amount, choose a category, and add the purpose or reason for the transaction so it\'s clear why the spend happened.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('What if I entered an amount incorrectly?'),
                  _buildAnswer('Open the transaction from your expense list and edit the details, if your role has permission to do so. If you can\'t edit it yourself, ask your branch administrator to correct it — accuracy is the responsibility of whoever enters and reviews the record.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Can I attach supporting documents to a transaction?'),
                  _buildAnswer('Where supported, you can attach receipts or supporting information to a transaction. Make sure anything you attach is genuine and matches the expense it\'s attached to.'),
                ],
              ),
            ),
            
            _buildSectionHeader('5. Categories'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How do categories work?'),
                  _buildAnswer('Categories describe why a purchase or transaction happened — for example, travel, supplies, or utilities. Choosing the right category keeps your reports accurate and easy to review later.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Can I create custom categories for my organisation?'),
                  _buildAnswer('Company administrators can set up categories that match how your organisation wants to track spending, and apply them consistently across branches.'),
                ],
              ),
            ),
            
            _buildSectionHeader('6. Reports & Charts'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How do I generate a spending report?'),
                  _buildAnswer('Go to Reports, choose a branch (or your whole company), a date range, and the categories you want to include. MilloraPay builds the report and charts from the transactions already recorded in the system.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Can I see spending trends across all branches?'),
                  _buildAnswer('Company administrators can view combined reports and charts across every branch, alongside each branch\'s individual figures.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Are these reports the same as tax or accounting advice?'),
                  _buildAnswer('No. Reports and charts are built for internal expense monitoring. For tax, accounting, or legal decisions, check with a qualified professional.'),
                ],
              ),
            ),
            
            _buildSectionHeader('7. Data & Security'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('How detailed is the record MilloraPay keeps?'),
                  _buildAnswer('Every transaction is stored with its amount, category, purpose, and timestamp, so your organisation has a precise, penny-level record of spending it can review at any time.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('How is my organisation\'s data protected?'),
                  _buildAnswer('MilloraPay applies technical and organisational security measures to protect business and user data. You can help by keeping your login private and reporting anything unusual straight away.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('Who is responsible for the accuracy of the data entered?'),
                  _buildAnswer('Your organisation and its authorised users are responsible for what\'s entered into MilloraPay. Administrators should periodically review transactions and access for accuracy.'),
                ],
              ),
            ),
            
            _buildSectionHeader('8. Troubleshooting'),
            _buildCardBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestion('MilloraPay seems to be down or slow. What now?'),
                  _buildAnswer('Temporary interruptions can happen during maintenance or due to technical issues. Try refreshing after a few minutes; if the issue continues, contact support so we can look into it.'),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('A report or chart looks wrong. What should I check first?'),
                  _buildAnswer('Check that transactions are correctly categorised and dated, and that you\'ve selected the right branch and date range for the report. Most discrepancies come from how the underlying transactions were entered.'),
                ],
              ),
            ),
            
            _buildSectionHeader('Contact Support'),
            _buildCardBlock(
              child: _buildAnswer('For account-specific issues, contact your branch or company administrator first. For anything else, reach MilloraPay support through the app.'),
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

  Widget _buildQuestion(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAnswer(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: Color(0xFF727271),
        ),
      ),
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
