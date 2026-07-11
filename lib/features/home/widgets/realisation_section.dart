import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/home/realisation_controller.dart';
import 'package:imobareld/models/realisation_model.dart';
import 'package:imobareld/features/home/widgets/realisation_card.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class RealisationSection extends StatelessWidget {
  const RealisationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Nos Réalisations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Carrousel des réalisations
        Consumer<RealisationController>(
          builder: (context, controller, child) {
            return StreamBuilder<List<RealisationModel>>(
              stream: controller.realisationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('Erreur RealisationSection: ${snapshot.error}');
                  return const SizedBox(); // On cache simplement si erreur
                }

                final realisations = snapshot.data ?? [];

                if (realisations.isEmpty) {
                  return const SizedBox(); // On cache la section si vide
                }

                return SizedBox(
                  height: 250, // Hauteur de la carte horizontale
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: realisations.length,
                    itemBuilder: (context, index) {
                      return RealisationCard(realisation: realisations[index]);
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
