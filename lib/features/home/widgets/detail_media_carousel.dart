import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/full_screen_image_viewer.dart';

/// Carousel d'images et vidéos pour l'écran de détail d'une propriété.
class DetailMediaCarousel extends StatelessWidget {
  final List<String> images;
  final List<String> videoUrls;
  final PageController pageController;
  final int currentImageIndex;
  final bool isUploadingImages;
  final bool isUploadingVideo;
  final bool isInitializingVideo;
  final int activeVideoIndex;
  final ChewieController? chewieController;
  final String propertyId;
  final void Function(int index) onPageChanged;

  const DetailMediaCarousel({
    super.key,
    required this.images,
    required this.videoUrls,
    required this.pageController,
    required this.currentImageIndex,
    required this.isUploadingImages,
    required this.isUploadingVideo,
    required this.isInitializingVideo,
    required this.activeVideoIndex,
    required this.chewieController,
    required this.propertyId,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalMedia = images.length + videoUrls.length;

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          // ── PageView ──
          PageView.builder(
            controller: pageController,
            itemCount: totalMedia + (isUploadingImages || isUploadingVideo ? 1 : 0),
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final bool isVideoSlide = index >= images.length;

              // Slide de chargement (upload en cours)
              if ((isUploadingImages || isUploadingVideo) && index == totalMedia) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Ajout en cours...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }

              // Slide vidéo
              if (isVideoSlide) {
                final int videoIdx = index - images.length;
                return Container(
                  color: Colors.black,
                  child: (isInitializingVideo && activeVideoIndex == index)
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : (activeVideoIndex == index && chewieController != null)
                          ? Chewie(controller: chewieController!)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Cliquer pour charger la vidéo ${videoIdx + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                );
              }

              // Slide image
              final String imageUrl = images[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        images: images,
                        initialIndex: index,
                        heroTagPrefix: 'prop_$propertyId',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'prop_${propertyId}_$index',
                  child: CachedImage(imageUrl: imageUrl, width: double.infinity),
                ),
              );
            },
          ),

          // ── Flèches de navigation ──
          if (totalMedia > 1)
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  currentImageIndex > 0
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          ),
                          onPressed: () => pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : const SizedBox(width: 48),
                  currentImageIndex < (totalMedia - 1)
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                          ),
                          onPressed: () => pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : const SizedBox(width: 48),
                ],
              ),
            ),

          // ── Dots indicateur ──
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalMedia,
                (index) => GestureDetector(
                  onTap: () => pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Badge VIDÉO ──
          if (currentImageIndex >= images.length)
            Positioned(
              top: 50 + MediaQuery.of(context).padding.top,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'VIDÉO ${currentImageIndex - images.length + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
