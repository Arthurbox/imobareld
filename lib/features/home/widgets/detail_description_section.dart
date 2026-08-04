import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/property_model.dart';

/// Section description de l'écran de détail : texte descriptif + conditions
/// de location (avance sur loyer et caution).
class DetailDescriptionSection extends StatelessWidget {
  final PropertyModel property;

  const DetailDescriptionSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          property.description,
          style: TextStyle(
            fontSize: 15,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
            height: 1.5,
          ),
        ),

        // ── Conditions de location ──
        if (property.transactionType == 'Location' &&
            (property.rentAdvanceMonths > 0 || property.securityDepositMonths > 0)) ...[
          const SizedBox(height: 24),
          Text(
            'Conditions de location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (property.rentAdvanceMonths > 0)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Avance sur loyer',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${property.rentAdvanceMonths} mois',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (property.rentAdvanceMonths > 0 && property.securityDepositMonths > 0)
                const SizedBox(width: 12),
              if (property.securityDepositMonths > 0)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryOrange.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Caution',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${property.securityDepositMonths} mois',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
