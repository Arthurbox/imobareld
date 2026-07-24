import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/vehicles/rental_controller.dart';
import 'package:imobareld/features/vehicles/widgets/reservation_card.dart';
import 'package:imobareld/models/reservation_model.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

class UserReservationsScreen extends StatefulWidget {
  const UserReservationsScreen({super.key});

  @override
  State<UserReservationsScreen> createState() => _UserReservationsScreenState();
}

class _UserReservationsScreenState extends State<UserReservationsScreen> {
  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final rentalCtrl = Provider.of<RentalController>(context, listen: false);
    final theme = Theme.of(context);

    if (auth.currentUser == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Réservations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryBlue,
        child: FutureBuilder<List<ReservationModel>>(
          future: rentalCtrl.getUserReservations(auth.currentUser!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5, itemHeight: 120);
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final reservations = snapshot.data ?? [];

            if (reservations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note_outlined, size: 64, color: theme.dividerColor),
                    const SizedBox(height: 16),
                    const Text('Aucune réservation effectuée.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Parcourir les véhicules'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                return ReservationCard(reservation: reservations[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
