import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Fullscreen, zoomable, swipeable image lightbox used across the public site.
class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  /// Opens the viewer as a modal route above the current page.
  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    final cleaned = images.where((e) => e.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return Future<void>.value();

    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => FullscreenImageViewer(
          images: cleaned,
          initialIndex: initialIndex.clamp(0, cleaned.length - 1),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.96),
      body: SafeArea(
        child: Stack(
          children: [
            // Swipeable + pinch-zoomable image pages
            PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    widget.images[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentCyan),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondaryDark, size: 64),
                    ),
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
              ),
            ),

            // Previous / Next controls (desktop friendly)
            if (total > 1 && _index > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    tooltip: 'Previous',
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),
            if (total > 1 && _index < total - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    tooltip: 'Next',
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),

            // Counter
            if (total > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
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
