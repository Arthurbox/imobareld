import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';

// ── Sous-vue Immobilier (grille avec images) ──────────────────────────────────
class AdminImmoSubView extends StatelessWidget {
  final String city;
  final bool filterVideosOnly;
  const AdminImmoSubView({super.key, required this.city, this.filterVideosOnly = false});

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context);
    final theme = Theme.of(context);

    final propertyController = Provider.of<PropertyController>(context, listen: false);

    return StreamBuilder<List<PropertyModel>>(
      stream: propertyController.propertiesByCityStream(city),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var properties = snapshot.data ?? [];

        // Filtrage Optimistic UI
        properties = properties.where((p) => !adminCtrl.isPendingDeletion(p.id!)).toList();

        // Filtrage optionnel pour ne garder que les biens avec vidéo
        if (filterVideosOnly) {
          properties = properties.where((p) => p.videoUrls.isNotEmpty).toList();
        }

        if (properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterVideosOnly ? Icons.video_library_outlined : Icons.home_outlined, 
                  size: 64, 
                  color: theme.dividerColor
                ),
                const SizedBox(height: 12),
                Text(
                  filterVideosOnly ? 'Aucune vidéo à $city' : 'Aucun bien à $city', 
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color)
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return AdminImmoCard(property: property, adminCtrl: adminCtrl);
          },
        );
      },
    );
  }
}

class AdminImmoCard extends StatelessWidget {
  final PropertyModel property;
  final AdminController adminCtrl;
  const AdminImmoCard({super.key, required this.property, required this.adminCtrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property))
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : AppColors.softShadow,
          border: isDark ? Border.all(color: Colors.white10) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: property.images.isNotEmpty
                      ? CachedImage(
                          imageUrl: property.images.first,
                          height: 110,
                          width: double.infinity,
                        )
                      : Container(
                          height: 110,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(child: Icon(Icons.apartment, size: 36)),
                        ),
                ),
                if (property.videoUrls.isNotEmpty)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            // Titre & infos
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      property.title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.titleSmall?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (property.isCertified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified, size: 12, color: Colors.purple),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${property.price.toInt()} CFA',
                style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
              child: Text(
                property.quartier,
                style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton Certification
                  GestureDetector(
                    onTap: () async {
                      try {
                        final newVal = !property.isCertified;
                        await adminCtrl.togglePropertyCertification(property.id!, newVal);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(newVal ? 'Annonce certifiée !' : 'Certification retirée.'))
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: property.isCertified ? Colors.purple.withValues(alpha: 0.1) : theme.cardColor,
                        border: Border.all(color: property.isCertified ? Colors.purple : theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            property.isCertified ? Icons.verified : Icons.verified_outlined,
                            size: 14,
                            color: property.isCertified ? Colors.purple : theme.textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            property.isCertified ? 'Certifié' : 'Certifier',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: property.isCertified ? Colors.purple : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Supprimer
                  GestureDetector(
                    onTap: () => _confirmPropertyDelete(context, property, adminCtrl),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPropertyDelete(BuildContext context, PropertyModel property, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: Text('Voulez-vous vraiment supprimer "${property.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer le dialogue immédiatement
              try {
                await controller.deletePropertyAdmin(property.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce supprimée avec succès.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ));
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),

        ],
      ),
    );
  }
}
