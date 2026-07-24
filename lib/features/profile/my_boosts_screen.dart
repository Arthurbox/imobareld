import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:intl/intl.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

class MyBoostsScreen extends StatefulWidget {
  const MyBoostsScreen({super.key});

  @override
  State<MyBoostsScreen> createState() => _MyBoostsScreenState();
}

class _MyBoostsScreenState extends State<MyBoostsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rafraîchir l'interface chaque minute pour mettre à jour les comptes à rebours
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getRemainingTime(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) return 'Expiré';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} jour(s) et ${difference.inHours % 24} heure(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure(s) et ${difference.inMinutes % 60} min';
    } else {
      return '${difference.inMinutes} minute(s)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Boostes')),
        body: const Center(child: Text('Erreur: Non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Boostes', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Boosts Actifs'),
            Tab(text: 'Expirés'),
          ],
        ),
      ),
      body: FutureBuilder<List<PropertyModel>>(
        future: Provider.of<PropertyController>(context, listen: false).getPropertiesByOwner(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4, itemHeight: 120);
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement des annonces'));
          }

          final allProperties = snapshot.data ?? [];
          
          // Filtrer les propriétés qui ont été boostées (boostExpiryDate n'est pas null)
          final boostedProperties = allProperties.where((p) => p.boostExpiryDate != null).toList();

          final now = DateTime.now();
          final activeBoosts = boostedProperties.where((p) => p.boostExpiryDate!.isAfter(now)).toList();
          final expiredBoosts = boostedProperties.where((p) => p.boostExpiryDate!.isBefore(now)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBoostList(activeBoosts, isActive: true),
              _buildBoostList(expiredBoosts, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoostList(List<PropertyModel> properties, {required bool isActive}) {
    if (properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.rocket_launch_outlined : Icons.history, 
              size: 64, 
              color: Colors.grey.withOpacity(0.5)
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Aucun boost actif pour le moment' : 'Aucun boost expiré',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: property.images.isNotEmpty ? property.images.first : '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plan : ${property.boostPlanType ?? "Standard"}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isActive ? Icons.timer : Icons.timer_off,
                            size: 16,
                            color: isActive ? AppColors.primaryOrange : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isActive 
                                  ? 'Expire dans : ${_getRemainingTime(property.boostExpiryDate!)}'
                                  : 'Expiré le : ${DateFormat('dd/MM/yyyy HH:mm').format(property.boostExpiryDate!)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? AppColors.primaryOrange : Colors.red,
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
      },
    );
  }
}
