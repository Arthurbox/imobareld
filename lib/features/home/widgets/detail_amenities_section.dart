import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/utils/amenity_utils.dart';
import 'package:imobareld/models/property_model.dart';

/// Section équipements et services de l'écran de détail.
/// Retourne un [SizedBox.shrink()] si la propriété n'a aucun équipement.
class DetailAmenitiesSection extends StatelessWidget {
  final PropertyModel property;

  const DetailAmenitiesSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    if (property.amenities.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text(
          'Équipements et services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: property.amenities.map((amenity) {
            final icon = AmenityUtils.getIcon(amenity);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    amenity,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
