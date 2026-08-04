import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:provider/provider.dart';

/// En-tête informatif de l'écran de détail : catégorie, prix, titre, badge
/// certifié, note, nombre de likes et localisation.
class DetailInfoHeader extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onShowReviewSheet;

  const DetailInfoHeader({
    super.key,
    required this.property,
    required this.onShowReviewSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Catégorie + Prix ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        property.category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    Flexible(
                      child: Text(
                        property.transactionType,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: property.transactionType == 'Vente'
                              ? AppColors.primaryOrange
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                  children: [
                    TextSpan(text: '${property.price.toInt()} FCFA '),
                    if (property.transactionType != 'Vente')
                      TextSpan(
                        text: '/ ${property.priceDuration.toLowerCase()}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // ── Titre + Badge certifié ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              property.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            if (property.isCertified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: Colors.purple, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'CERTIFIÉ',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Note + Likes ──
        Row(
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              property.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              '(${property.reviewCount} avis)',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onShowReviewSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Noter'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            ),
            const Spacer(),
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 4),
            Consumer<PropertyController>(
              builder: (context, propCtrl, _) {
                final count = propCtrl.getLikesCount(property.id!, property.likesCount);
                return Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Localisation + Pièces ──
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 18),
            const SizedBox(width: 4),
            Text(
              property.quartier,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 20),
            if (property.category != 'Boutiques' && property.category != 'Magasins') ...[
              const Icon(Icons.king_bed, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 4),
              Text(
                property.category == 'Terrains'
                    ? '${property.pieces} m²'
                    : '${property.pieces} pièces',
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
