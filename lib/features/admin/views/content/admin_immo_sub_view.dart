import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';

// ── Sous-vue Immobilier (grille avec images) ──────────────────────────────────
class AdminImmoSubView extends StatefulWidget {
  final String city;
  final bool filterVideosOnly;
  const AdminImmoSubView({super.key, required this.city, this.filterVideosOnly = false});

  @override
  State<AdminImmoSubView> createState() => _AdminImmoSubViewState();
}

class _AdminImmoSubViewState extends State<AdminImmoSubView> {
  final Set<String> _selectedPropertyIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<PropertyModel>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    final propertyController = Provider.of<PropertyController>(context, listen: false);
    _propertiesFuture = propertyController.getPropertiesByCityAdmin(widget.city);
  }

  @override
  void didUpdateWidget(covariant AdminImmoSubView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city || oldWidget.filterVideosOnly != widget.filterVideosOnly) {
      final propertyController = Provider.of<PropertyController>(context, listen: false);
      _propertiesFuture = propertyController.getPropertiesByCityAdmin(widget.city);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPropertyIds.contains(id)) {
        _selectedPropertyIds.remove(id);
      } else {
        _selectedPropertyIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPropertyIds.clear();
    });
  }

  void _confirmDeleteSelected(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la sélection ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedPropertyIds.length} annonce(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suppression de ${_selectedPropertyIds.length} annonce(s) en cours...')),
                );
                
                for (var id in _selectedPropertyIds) {
                  await controller.deletePropertyAdmin(id);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Annonces supprimées avec succès !'), backgroundColor: Colors.green),
                  );
                  _clearSelection();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur:\n${e.toString()}'), 
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context);
    final theme = Theme.of(context);

    final propertyController = Provider.of<PropertyController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _selectedPropertyIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _confirmDeleteSelected(context, adminCtrl),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('Supprimer (${_selectedPropertyIds.length})', style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: FutureBuilder<List<PropertyModel>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList(itemCount: 4, itemHeight: 120);

          var properties = snapshot.data ?? [];

          // Filtrage Optimistic UI
          properties = properties.where((p) => !adminCtrl.isPendingDeletion(p.id!)).toList();

          // Filtrage optionnel pour ne garder que les biens avec vidéo
          if (widget.filterVideosOnly) {
            properties = properties.where((p) => p.videoUrls.isNotEmpty).toList();
          }

          // Filtrage par recherche
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            properties = properties.where((p) => 
                p.referenceCode.toLowerCase().contains(q) || 
                p.title.toLowerCase().contains(q)
            ).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par référence (REF-...) ou titre',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: properties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.filterVideosOnly ? Icons.video_library_outlined : Icons.home_outlined, 
                              size: 64, 
                              color: theme.dividerColor
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucun résultat pour "$_searchQuery"'
                                  : (widget.filterVideosOnly ? 'Aucune vidéo à ${widget.city}' : 'Aucun bien à ${widget.city}'),
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color)
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12).copyWith(bottom: 80), // Padding pour le bouton flottant
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          final isSelected = _selectedPropertyIds.contains(property.id);

                          return AdminImmoCard(
                            property: property, 
                            adminCtrl: adminCtrl,
                            isSelected: isSelected,
                            onSelect: () => _toggleSelection(property.id!),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminImmoCard extends StatelessWidget {
  final PropertyModel property;
  final AdminController adminCtrl;
  final bool isSelected;
  final VoidCallback onSelect;

  const AdminImmoCard({
    super.key, 
    required this.property, 
    required this.adminCtrl,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          onSelect();
        } else {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property))
          );
        }
      },
      onLongPress: onSelect,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : AppColors.softShadow,
              border: Border.all(
                color: isSelected ? Colors.red : (isDark ? Colors.white10 : Colors.transparent),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: property.images.isNotEmpty
                            ? CachedImage(
                                imageUrl: property.images.first,
                                width: double.infinity,
                              )
                            : Container(
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
                            color: property.isCertified ? Colors.purple.withOpacity(0.1) : theme.cardColor,
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
                            color: Colors.red.withOpacity(0.1),
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
          Positioned(
            top: 4,
            right: 4,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onSelect(),
              activeColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
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
