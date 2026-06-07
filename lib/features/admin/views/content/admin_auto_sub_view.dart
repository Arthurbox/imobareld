import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/features/vehicles/vehicle_controller.dart';
import 'package:imobareld/models/vehicle_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';

// ── Sous-vue Auto ─────────────────────────────────────────────────────────────
class AdminAutoSubView extends StatelessWidget {
  final String city;
  const AdminAutoSubView({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context, listen: true);

    final vehicleController = Provider.of<VehicleController>(context, listen: false);

    return StreamBuilder<List<VehicleModel>>(
      stream: vehicleController.vehiclesByCityStream(city),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var vehicles = snapshot.data ?? [];
        
        // Filtrage Optimistic UI
        vehicles = vehicles.where((v) => !adminCtrl.isPendingDeletion(v.id)).toList();

        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                Text('Aucun véhicule à $city', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];

            String? imageUrl;
            if (vehicle.imageUrl.isNotEmpty) {
              imageUrl = vehicle.imageUrl;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedImage(imageUrl: imageUrl, width: 60, height: 60)
                      : Container(
                          width: 60, height: 60,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                          child: const Icon(Icons.directions_car),
                        ),
                ),
                title: Text('${vehicle.companyName} ${vehicle.model}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${vehicle.pricePerDay.toInt()} CFA / jour',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmVehicleDelete(context, vehicle, adminCtrl),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmVehicleDelete(BuildContext context, VehicleModel vehicle, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('Supprimer "${vehicle.companyName} ${vehicle.model}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                await controller.deleteVehicleAdmin(vehicle.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Véhicule supprimé.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
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
