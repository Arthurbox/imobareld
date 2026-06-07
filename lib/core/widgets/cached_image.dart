import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/services/app_cache_manager.dart';

/// A premium network image loader with persistent disk caching (30 days).
/// Images previously loaded while online remain visible offline.
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;
  final bool showShimmer;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? maxWidthThreshold;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
    this.showShimmer = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthThreshold,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        // 🔑 Cache persistant 30 jours (images visibles hors ligne)
        cacheManager: AppCacheManager.instance,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        maxWidthDiskCache: maxWidthThreshold?.toInt(),
        fadeInDuration: const Duration(milliseconds: 500),
        fadeOutDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => showShimmer ? _buildShimmer(context) : const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(context),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: isDark ? Colors.white24 : Colors.grey[400],
          size: width != null && width! < 50 ? 20 : 32,
        ),
      ),
    );
  }
}
