import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About Us',
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
            _buildSectionHeader('Smarter Expense Management. Better Financial Visibility.'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay is a business expense and financial management platform designed to help organisations manage their expenses, transactions, branches, and staff in one organised system.\n\nWith MilloraPay, businesses can create multiple branches, manage branch-level staff and access, record detailed expenses and transactions, categorise spending, and maintain a clear record of their financial activities.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('Simple, Clear & Organised'),
            _buildCardBlock(
              child: const Text(
                'MilloraPay helps businesses understand where and why their money is being spent. Detailed records, spending categories, reports, and visual charts provide better visibility into expenses across different branches and areas of the business.\n\nWhether managing one branch or multiple locations, MilloraPay helps keep financial records structured, accessible, and easy to review.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            _buildSectionHeader('Our Purpose'),
            _buildCardBlock(
              child: const Text(
                'Our goal is to make expense management simpler, more transparent, and more organised helping businesses keep track of every expense and make better-informed decisions.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF727271)),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 24),
              child: Center(
                child: Text(
                  'MilloraPay — Every Expense. Clearly Recorded.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
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
}
