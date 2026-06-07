import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:imobareld/core/services/app_cache_manager.dart';

/// A premium circular avatar with built-in caching, shimmer loading, and initials fallback.
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderWidth = 1,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1);
    final effectiveTextColor = textColor ?? theme.primaryColor;

    Widget avatarContent;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: imageUrl!,
        // 🔑 Cache persistant 30 jours (avatars visibles hors ligne)
        cacheManager: AppCacheManager.instance,
        imageBuilder: (context, imageProvider) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => _buildShimmer(context),
        errorWidget: (context, url, error) => _buildFallback(effectiveBackgroundColor, effectiveTextColor),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    } else {
      avatarContent = _buildFallback(effectiveBackgroundColor, effectiveTextColor);
    }

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? theme.primaryColor,
            width: borderWidth,
          ),
        ),
        child: avatarContent,
      );
    }

    return avatarContent;
  }

  Widget _buildFallback(Color bgColor, Color txtColor) {
    String initials = '';
    if (name != null && name!.trim().isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: txtColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? (radius * 0.8),
              ),
            )
          : Icon(Icons.person, color: txtColor, size: radius),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
      ),
    );
  }
}
