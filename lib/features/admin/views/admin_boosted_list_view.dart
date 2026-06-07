import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminBoostedListView extends StatelessWidget {
  const AdminBoostedListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Biens Boostés Actuellement'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: Provider.of<AdminController>(context, listen: false).boostedPropertiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(child: Text('Aucun bien n\'est actuellement boosté.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final prop = properties[index];
              return _buildBoostedCard(context, prop);
            },
          );
        },
      ),
    );
  }

  Widget _buildBoostedCard(BuildContext context, PropertyModel property) {
    final theme = Theme.of(context);
    final String planName = property.boostPlanType ?? 'Plan Inconnu';
    
    // Calculer le temps restant
    String timeLeft = '';
    if (property.boostExpiryDate != null) {
      final diff = property.boostExpiryDate!.difference(DateTime.now());
      if (diff.isNegative) {
         timeLeft = 'Expiré (rafraîchissement requis)';
      } else {
         timeLeft = '${diff.inDays}j ${diff.inHours % 24}h restantes';
      }
    } else {
      timeLeft = 'Illimité ou erreur de date';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: property.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: property.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Icon(Icons.image_not_supported),
                )
              : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.home)),
        ),
        title: Text(
          property.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Plan : $planName',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  timeLeft,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.primaryColor),
        onTap: () {
          // Facultatif : ouvrir les détails du bien si vous avez une vue pour l'admin
        },
      ),
    );
  }
}
