import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/gold_back_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/category_model.dart';
import '../repository/category_repository.dart';
import '../../units/models/unit_model.dart';
import '../../services/models/service_model.dart';

class ViewCategoryScreen extends StatefulWidget {
  final int categoryId;

  const ViewCategoryScreen({super.key, required this.categoryId});

  @override
  State<ViewCategoryScreen> createState() => _ViewCategoryScreenState();
}

class _ViewCategoryScreenState extends State<ViewCategoryScreen> {
  final CategoryRepository _repository = CategoryRepository();
  ExpenseCategory? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final category = await _repository.getCategoryById(widget.categoryId);
      setState(() {
        _category = category;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing, bool allowWrap = false}) {
    final valueStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF727271),
    );

    if (allowWrap) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final rightWidth = constraints.maxWidth - 140;
          if (rightWidth <= 0) return const SizedBox(); 
          
          final textPainter = TextPainter(
            text: TextSpan(text: value, style: valueStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: rightWidth);

          if (textPainter.didExceedMaxLines) {
            final pos = textPainter.getPositionForOffset(Offset(rightWidth - 10, 0));
            int splitIdx = pos.offset;
            int spaceIdx = value.lastIndexOf(' ', splitIdx);
            if (spaceIdx > 0) {
              splitIdx = spaceIdx;
            }
            
            final line1 = value.substring(0, splitIdx);
            final line2 = value.substring(splitIdx).trimLeft();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5)))),
                        child: Text(line1, style: valueStyle),
                      ),
                    ),
                  ],
                ),
                if (line2.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5)))),
                    child: Text(line2, style: valueStyle),
                  ),
                const SizedBox(height: 16),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F2F5)))),
                        child: Text(value, style: valueStyle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Container(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
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

  Widget _buildQuantitySection(dynamic quantity) {
    if (quantity != true && quantity != 1 && quantity != 'true') {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 140,
              child: Text(
                'Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Transform.scale(
                      scale: 0.7,
                      child: Checkbox(
                        value: true,
                        fillColor: WidgetStateProperty.all(Colors.white),
                        checkColor: const Color(0xFF727271),
                        side: const BorderSide(color: Color(0xFF727271), width: 1.5),
                        onChanged: (val) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitsSection(List<Unit>? units) {
    if (units == null || units.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Units',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...units.map((unit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF727271),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    unit.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF727271),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildServiceSection(dynamic service, List<ServiceModel>? services) {
    if (service != true && service != 1 && service != 'true') {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 140,
              child: Text(
                'Services',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Transform.scale(
                      scale: 0.7,
                      child: Checkbox(
                        value: true,
                        fillColor: WidgetStateProperty.all(Colors.white),
                        checkColor: const Color(0xFF727271),
                        side: const BorderSide(color: Color(0xFF727271), width: 1.5),
                        onChanged: (val) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (services != null && services.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...services.map((svc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF727271),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      svc.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF727271),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const GoldBackButton(),
        title: const Text(
          'View Category',
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
          : _category == null
              ? const Center(child: Text('Failed to load category details.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Details',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Category Name', _category!.name, allowWrap: true),
                            _buildDetailRow(
                              'Category Upload', 
                              (_category!.icon != null && _category!.icon!.isNotEmpty) 
                                  ? _category!.icon!.split('/').last.replaceFirst(RegExp(r'^\d{13}-'), '')
                                  : 'No file uploaded',
                              trailing: (_category!.icon != null && _category!.icon!.isNotEmpty)
                                  ? InkWell(
                                      onTap: () {
                                        _showFullScreenImage(context, 'Category Upload', _category!.icon!);
                                      },
                                      child: const Icon(
                                        Icons.remove_red_eye_outlined, 
                                        color: AppColors.primaryBlue, 
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            _buildQuantitySection(_category!.quantity),
                            _buildUnitsSection(_category!.units),
                            _buildServiceSection(_category!.service, _category!.services),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
