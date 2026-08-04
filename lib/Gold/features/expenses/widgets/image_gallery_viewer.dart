import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Full-screen image gallery viewer with a large preview on top
/// and a horizontal thumbnail strip at the bottom.
/// Tapping a thumbnail swaps it with the main image.
class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late int _mainIndex;

  @override
  void initState() {
    super.initState();
    _mainIndex = widget.initialIndex;
  }

  void _swapWithMain(int tappedIndex) {
    if (tappedIndex == _mainIndex) return;
    setState(() {
      _mainIndex = tappedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Receipt Preview',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Main large preview ──────────────────────────────────────
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.zero,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  images[_mainIndex],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Thumbnail strip (only shown if more than 1 image) ────────
          if (images.length > 1)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _mainIndex;
                  return GestureDetector(
                    onTap: () => _swapWithMain(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white30,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
