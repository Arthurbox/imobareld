import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imobareld/models/ad_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/skeleton_banner.dart';

class BannerCarousel extends StatefulWidget {
  final List<AdModel> ads;
  final bool isLoading;
  final Function(AdModel) onAdTap;

  const BannerCarousel({
    super.key,
    required this.ads,
    required this.isLoading,
    required this.onAdTap,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  PageController? _pageController;
  Timer? _timer;
  int _currentPage = 0;
  static const int _virtualItemCount = 10000;

  /// Calcule la page initiale centrée pour un défilement infini équilibré
  int _calcInitialPage(int adsCount) {
    if (adsCount == 0) return 0;
    final mid = _virtualItemCount ~/ 2;
    return mid - (mid % adsCount);
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final initialPage = _calcInitialPage(widget.ads.length);
    _pageController?.dispose();
    _pageController = PageController(initialPage: initialPage);
    _currentPage = widget.ads.isEmpty ? 0 : initialPage % widget.ads.length;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    // Ne démarrer le timer que s'il y a au moins 2 publicités à faire défiler
    if (widget.ads.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final controller = _pageController;
      if (controller != null && controller.hasClients) {
        controller.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Les ads sont arrivées (passage de vide → non vide) :
    // on réinitialise complètement le controller et le timer
    if (oldWidget.ads.isEmpty && widget.ads.isNotEmpty) {
      _initController();
    } else if (widget.ads.length != oldWidget.ads.length) {
      // Nombre d'ads changé (ajout / suppression) : juste relancer le timer
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Sur grand écran (Desktop/Web > 800px), on augmente la hauteur à 300 (réduit suite au test)
    final double bannerHeight = screenWidth > 800 ? 300.0 : 220.0;

    if (widget.isLoading) {
      return const SkeletonBanner();
    }

    if (widget.ads.isEmpty) return const SizedBox.shrink();

    // Guard : le controller peut être null si initState n'a pas encore terminé
    final controller = _pageController;
    if (controller == null) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                controller: controller,
                physics: widget.ads.length == 1 ? const NeverScrollableScrollPhysics() : null,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index % widget.ads.length;
                  });
                },
                itemCount: widget.ads.length == 1 ? 1 : _virtualItemCount,
                itemBuilder: (context, index) {
                  final adIndex = index % widget.ads.length;
                  final ad = widget.ads[adIndex];
                  return GestureDetector(
                    onTap: () => widget.onAdTap(ad),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black12,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          if (ad.type == 'image' && ad.imageUrl.isNotEmpty)
                            Positioned.fill(
                              child: CachedImage(
                                imageUrl: ad.imageUrl,
                                borderRadius: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (ad.type == 'video')
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                                  SizedBox(height: 8),
                                  Text('Publicité Vidéo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Indicateur de page (points)
            if (widget.ads.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.ads.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withValues(
                        alpha: _currentPage == entry.key ? 0.9 : 0.2
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

