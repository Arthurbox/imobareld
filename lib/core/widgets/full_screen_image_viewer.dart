import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:imobareld/core/services/app_cache_manager.dart';

class FullScreenImageViewer extends StatelessWidget {
  final List<dynamic> images; // Can be Uint8List or String (URL or Base64)
  final int initialIndex;
  final String heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              Widget imageWidget;

              if (image is Uint8List) {
                imageWidget = Image.memory(image, fit: BoxFit.contain);
              } else if (image is String) {
                if (image.startsWith('http') || image.startsWith('/media')) {
                  final String imageUrl = image;
                  imageWidget = CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheManager: AppCacheManager.instance,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                    errorWidget: (context, url, err) => const Icon(Icons.broken_image, color: Colors.white),
                  );
                } else {
                  imageWidget = const Icon(Icons.broken_image, color: Colors.white);
                }
              } else {
                imageWidget = const Icon(Icons.broken_image, color: Colors.white);
              }

              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: '${heroTagPrefix}_$index',
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: imageWidget,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      int currentPage = initialIndex;
                      if (pageController.hasClients && pageController.position.hasContentDimensions) {
                        currentPage = pageController.page?.round() ?? initialIndex;
                      }
                      return Text(
                        '${currentPage + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

