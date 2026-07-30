import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/features/home/add_property_screen.dart';
import 'package:imobareld/features/chat/chat_list_screen.dart';
import 'package:imobareld/features/owner/verification_request_screen.dart';
import 'package:imobareld/features/owner/boost_plans_screen.dart';
import 'package:imobareld/features/owner/subscription_screen.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';


class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;
  final List<String> _titles = ['Tableau de Bord', 'Réservations', 'Mes Messages'];

  Future<void> _handleRefresh() async {
    // Les StreamBuilder se mettront à jour automatiquement, 
    // mais on peut forcer un petit délai pour l'animation
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthController>(context);
    final propertyController = Provider.of<PropertyController>(context, listen: false);

    if (auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Veuillez vous connecter.')));
    }

    if (!auth.currentUser!.hasActiveSubscription) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Abonnement requis', style: TextStyle(color: theme.primaryColor)),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Votre période d\'essai ou abonnement a expiré.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pour continuer à gérer vos annonces et recevoir des réservations, veuillez souscrire à un abonnement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Voir les offres d\'abonnement', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titles[_currentIndex], style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        actions: _currentIndex == 0 ? [
          IconButton(
            icon: Icon(Icons.add, color: theme.primaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
          ),
        ] : [],
      ),
      body: _buildBody(auth.currentUser!.id, propertyController),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        backgroundColor: theme.bottomAppBarTheme.color ?? theme.cardColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de Bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String userId, PropertyController propertyController) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardView(userId, propertyController);
      case 1:
        return const ChatListContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardView(String userId, PropertyController propertyController) {
    final theme = Theme.of(context);
    return StreamBuilder<List<PropertyModel>>(
        stream: propertyController.getPropertiesByOwnerStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4, itemHeight: 120);
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur de chargement : ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final properties = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            displacement: 20,
            color: theme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Carte de Vérification
                SliverToBoxAdapter(child: _buildVerificationCard(context, userId)),

                // Résumé des statistiques
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _buildStatCard(
                          'Annonces',
                          properties.length.toString(),
                          Icons.home,
                          theme.primaryColor,
                        ),

                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Mes Propriétés',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                    ),
                  ),
                ),

                if (properties.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Aucune propriété publiée.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPropertyManagementCard(context, properties[index], propertyController),
                        );
                      },
                      childCount: properties.length,
                    ),
                  ),


                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: theme.brightness == Brightness.dark ? [] : AppColors.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
            Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color ?? AppColors.textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }



  Widget _buildPropertyManagementCard(BuildContext context, PropertyModel property, PropertyController controller) {
    final theme = Theme.of(context);
    final isBoostActive = property.isBoosted && property.boostExpiryDate != null && property.boostExpiryDate!.isAfter(DateTime.now());

    return _buildManagementTile(
      context,
      title: property.title,
      subtitle: '${property.price.round()} FCFA - ${property.quartier}',
      imageWidget: property.images.isNotEmpty ? _buildPreviewImage(property.images[0]) : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property))),
      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(propertyToEdit: property))),
      onDelete: () => _confirmDeleteProperty(context, property, controller),
      onBoost: isBoostActive ? null : () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BoostPlansScreen(propertyId: property.id!)));
      },
      badge: isBoostActive ? Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
        child: const Text('BOOSTÉ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }



  Widget _buildManagementTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget? imageWidget,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    VoidCallback? onBoost,
    Widget? badge,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.brightness == Brightness.dark ? [] : AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onTap,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.white12 : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageWidget ?? const Icon(Icons.image),
            ),
            title: Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.titleMedium?.color))),
                if (badge != null) badge,
              ],
            ),
            subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBoost != null)
                  IconButton(
                    icon: const Icon(Icons.rocket_launch, color: Colors.orange, size: 20),
                    onPressed: onBoost,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }


  void _confirmDeleteProperty(BuildContext context, PropertyModel property, PropertyController controller) {
    _showDeleteDialog(
      context,
      onDelete: () async => await controller.deleteProperty(property.id!),
    );
  }


  void _showDeleteDialog(BuildContext context, {required Future<void> Function() onDelete}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onDelete();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget? _buildPreviewImage(String url) {
    if (url.trim().isEmpty) return null;
    return CachedImage(
      imageUrl: url,
      width: 50,
      height: 50,
      borderRadius: 8,
    );
  }

  Widget _buildVerificationCard(BuildContext context, String userId) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final status = auth.currentUser?.verificationStatus ?? 'none';
        
        Color cardColor;
        String title;
        String subtitle;
        IconData icon;
        VoidCallback? onTap;

        switch (status) {
          case 'verified':
            cardColor = Colors.green;
            title = 'Profil certifié';
            subtitle = 'Votre profil propriétaire est validé.';
            icon = Icons.verified;
            onTap = null;
            break;
          case 'pending':
            cardColor = Colors.orange;
            title = 'Vérification en cours';
            subtitle = 'Vos documents sont en cours d\'analyse.';
            icon = Icons.hourglass_empty;
            onTap = null;
            break;
          case 'rejected':
            cardColor = Colors.red;
            title = 'Vérification Refusée';
            final reason = auth.currentUser?.verificationMessage ?? 'Non spécifié';
            subtitle = 'Motif : $reason\nAppuyez pour soumettre à nouveau.';
            icon = Icons.error_outline;
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerificationRequestScreen()),
            );
            break;
          case 'none':
          default:
            cardColor = AppColors.primaryBlue;
            title = 'Vérifier mon Profil';
            subtitle = 'Obtenez le badge "Vérifié" pour rassurer les locataires.';
            icon = Icons.shield_outlined;
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerificationRequestScreen()),
            );
            break;
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cardColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cardColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 16, color: cardColor),
              ],
            ),
          ),
        );
      },
    );
  }

}
