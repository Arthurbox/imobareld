import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/vehicles/vehicle_controller.dart';
import 'package:imobareld/features/vehicles/widgets/vehicle_card.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/vehicles/add_vehicle_screen.dart';
import 'package:imobareld/features/vehicles/vehicle_detail_screen.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

class VehicleRentalScreen extends StatefulWidget {
  const VehicleRentalScreen({super.key});

  @override
  State<VehicleRentalScreen> createState() => _VehicleRentalScreenState();
}

class _VehicleRentalScreenState extends State<VehicleRentalScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les véhicules dès l'ouverture (marche en ligne et hors ligne)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleController>(context, listen: false).fetchVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Vérifier si l'utilisateur est propriétaire (ou admin) pour afficher le bouton +
    final isOwner = authController.currentUser?.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Location de véhicule",
          style: TextStyle(fontFamily: 'Cursive', fontSize: 22),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<VehicleController>(
        builder: (context, vehicleController, _) {
          if (vehicleController.isLoading && vehicleController.vehicles.isEmpty) {
            return const SkeletonList(itemCount: 4, itemHeight: 200);
          }
          
          final vehicles = vehicleController.vehicles;
          
          if (vehicles.isEmpty) {
            return const Center(child: Text("Aucun véhicule disponible pour le moment."));
          }

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              tooltip: 'Publier un véhicule',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            )
          : null,
      // Le FAB est visible uniquement par les propriétaires
    );
  }
}
