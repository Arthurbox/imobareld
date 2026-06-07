import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/models/property_model.dart';

class NotificationTile extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isUnread;

  const NotificationTile({
    super.key,
    required this.property,
    required this.onTap,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Formatage du prix simple
    String formattedPrice = property.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread 
              ? (theme.colorScheme.primary.withValues(alpha: 0.1))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: property.images.isNotEmpty
                    ? CachedImage(
                        imageUrl: property.images.first,
                        fit: BoxFit.cover,
                        borderRadius: 12,
                        errorWidget: const Icon(Icons.broken_image, size: 20),
                      )
                    : const Icon(Icons.image_outlined, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Nouveau Bien à ${property.city} (${property.quartier}) !',
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.category} • $formattedPrice FCFA',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(property.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

