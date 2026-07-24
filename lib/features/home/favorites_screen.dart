import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/property_card.dart';
import 'package:imobareld/core/widgets/responsive_layout.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

/// Écran des propriétés favorites.
/// Lit les IDs favoris depuis AuthController (mis à jour en temps réel)
/// et charge les données directement depuis Firestore.
/// Compatible Web et Mobile.
class FavoritesScreen extends StatelessWidget {
  final bool hideAppBar;
  const FavoritesScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyController = Provider.of<PropertyController>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: hideAppBar ? null : AppBar(
        title: Text('Mes Favoris', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ResponsiveLayout(
        child: FutureBuilder<List<PropertyModel>>(
          future: propertyController.getFavoriteProperties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 4, itemHeight: 260);
            }
    
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Erreur de chargement', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                    const SizedBox(height: 4),
                    Text('${snapshot.error}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }
    
            final properties = snapshot.data ?? [];
    
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: theme.dividerColor),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun favori pour le moment',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appuyez sur le ❤️ sur une annonce pour l\'ajouter ici',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }
    
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    cacheExtent: 1500,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 260,
                    ),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      return PropertyCard(property: properties[index]);
                    },
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  cacheExtent: 1500, // PRÉ-CHARGEMENT pour une fluidité maximale
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    return Container(
                      height: 260,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: PropertyCard(property: properties[index]),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
