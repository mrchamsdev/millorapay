import 'package:bank_scan/Gold/core/utils/responsive_extensions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'image_gallery_viewer.dart';

class DetailHeader extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final String addedBy;
  final String? fileUrl;
  final List<String>? allFileUrls; // all images for gallery
  final String? iconUrl;
  final String currencySymbol;
  final String? branchName;
  final String? paidBy;
  final List<String>? quantities;

  const DetailHeader({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.addedBy,
    this.fileUrl,
    this.allFileUrls,
    this.iconUrl,
    this.currencySymbol = '₹',
    this.branchName,
    this.paidBy,
    this.quantities,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: iconUrl != null && iconUrl!.isNotEmpty
                ? iconUrl!.toLowerCase().endsWith('.svg')
                    ? SvgPicture.network(
                        iconUrl!.replaceAll(' ', '%20'),
                        width: 24,
                        height: 24,
                        placeholderBuilder: (context) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Image.network(
                        iconUrl!.replaceAll(' ', '%20'),
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryBlue, size: 24),
                      )
                : const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryBlue, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h2.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '$currencySymbol$amount',
                style: AppTextStyles.h1.copyWith(fontSize: 10.sp, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (branchName != null && branchName!.isNotEmpty)
                _buildInfoText('Branch: $branchName'),
              _buildInfoText('Bill Date: $date'),
              _buildInfoText('Added by: $addedBy'),
              if (paidBy != null && paidBy!.isNotEmpty)
                _buildInfoText('Paid by: $paidBy'),
              if (quantities != null && quantities!.isNotEmpty)
                _buildInfoText('Quantity: ${quantities!.join(', ')}'),
            ],
          ),
        ),
        _buildReceiptImage(context),
      ],
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: AppTextStyles.infoText,
      ),
    );
  }

  Widget _buildReceiptImage(BuildContext context) {
    // Combine allFileUrls and single fileUrl into a deduplicated list
    final List<String> images = [];
    if (allFileUrls != null && allFileUrls!.isNotEmpty) {
      images.addAll(allFileUrls!);
    } else if (fileUrl != null && fileUrl!.isNotEmpty) {
      images.add(fileUrl!);
    }

    final hasImage = images.isNotEmpty;

    return GestureDetector(
      onTap: hasImage
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageGalleryViewer(
                    imageUrls: images,
                    initialIndex: 0,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: hasImage
                  ? Image.network(
                      images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.iconLight, size: 40),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined,
                          color: AppColors.iconLight, size: 40),
                    ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${images.length - 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
