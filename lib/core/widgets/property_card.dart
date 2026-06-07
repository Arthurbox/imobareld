import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/utils/app_page_route.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/core/widgets/cached_image.dart';

/// Carte de propriété universelle utilisée dans toute l'application.
/// Affiche une image, le quartier, la catégorie, le prix, et les compteurs d'interaction.
class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onCommentTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Formatage du prix avec espaces pour la lisibilité
    String formattedPrice = property.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: theme.brightness == Brightness.dark ? [] : AppColors.softShadow,
          border: theme.brightness == Brightness.dark ? Border.all(color: theme.dividerColor.withValues(alpha: 0.1)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION IMAGE (Agrandie avec overlays)
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        buildPropertyDetailRoute(PropertyDetailScreen(property: property)),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.white12 : AppColors.inputBackground,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: property.images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Hero(
                                tag: 'prop_${property.id}_main',
                                child: CachedImage(
                                  imageUrl: property.images[0],
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, size: 32, color: AppColors.textLight),
                            ),
                    ),
                  ),
                  // Badge Certification
                  if (property.isCertified)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'CERTIFIÉ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge Boosté
                  if (property.isBoosted && property.boostExpiryDate != null && property.boostExpiryDate!.isAfter(DateTime.now()))
                    Positioned(
                      top: property.isCertified ? 40 : 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFF5722)]),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.rocket_launch, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'BOOSTÉ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge Quartier
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        property.quartier.toUpperCase(),
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
            
            // SECTION INFORMATIONS
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Catégorie et Prix
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPill(
                          property.category == 'Terrains' 
                              ? '${property.pieces} m²' 
                              : '${property.pieces} pcs', 
                          theme.colorScheme.primary.withValues(alpha: 0.1), 
                          theme.colorScheme.primary
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _buildPricePill(formattedPrice, property.priceDuration, theme.colorScheme.secondary.withValues(alpha: 0.1), theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions (Like, Comment, Détail)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Favoris
                      Consumer<PropertyController>(
                        builder: (context, propCtrl, _) {
                          final isLiked = propCtrl.isFavorite(property.id!);
                          final currentLikes = propCtrl.getLikesCount(property.id!, property.likesCount);
                          
                          return _buildIconButton(
                            icon: isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : theme.primaryColor,
                            count: currentLikes,
                            onPressed: () => propCtrl.toggleFavorite(property),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      // Commentaires (OPTIMISÉ : Plus de FutureBuilder)
                      if (onCommentTap != null)
                        _buildIconButton(
                          icon: Icons.comment_outlined,
                          color: theme.primaryColor,
                          count: property.commentsCount,
                          onPressed: onCommentTap!,
                        ),
                      const SizedBox(width: 6),
                      // Bouton Détail
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            buildPropertyDetailRoute(PropertyDetailScreen(property: property)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Détail',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required int count, required VoidCallback onPressed}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Icon(icon, size: 20, color: color),
        ),
        if (count > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPill(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPricePill(String price, String duration, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: '$price FCFA '),
            if (property.transactionType != 'Vente')
              TextSpan(
                text: '/ ${duration.toLowerCase()}',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
    );
  }
}

