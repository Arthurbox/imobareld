import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/reservation_model.dart';
import 'package:imobareld/features/vehicles/rental_controller.dart';
import 'package:imobareld/core/widgets/full_screen_image_viewer.dart';

class ReservationDetailScreen extends StatefulWidget {
  final ReservationModel reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rentalController = Provider.of<RentalController>(context, listen: false);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Détails de Réservation'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 20,
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INFOS VÉHICULE & CLIENT
              _buildSectionTitle('Informations Générales'),
              _buildInfoTile('Véhicule', '${widget.reservation.vehicleCompanyName} ${widget.reservation.vehicleModel}'),
              _buildInfoTile('Client', widget.reservation.userName),
              _buildInfoTile('Email', widget.reservation.userEmail),
              if (widget.reservation.userPhone != null) _buildInfoTile('Téléphone', widget.reservation.userPhone!),
              
              const SizedBox(height: 20),
              
              // 2. DÉTAILS LOCATION
              _buildSectionTitle('Détails de la Location'),
              _buildInfoTile('Durée', '${widget.reservation.numberOfDays} jours'),
              _buildInfoTile('Avec Chauffeur', widget.reservation.withDriver ? 'Oui' : 'Non'),
              _buildInfoTile('Prix Total', '${widget.reservation.totalPrice.round()} FCFA', isBold: true),
              
              const SizedBox(height: 20),
              
              // 3. DOCUMENTS
              _buildSectionTitle('Documents Justificatifs'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildDocPreview(context, 'CNIB(R)', widget.reservation.cnibImage)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDocPreview(context, 'CNIB(V)', widget.reservation.cnibBackImage)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDocPreview(context, 'Permis', widget.reservation.licenseImage)),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // 4. ACTIONS (Si en attente)
              if (widget.reservation.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(context, rentalController, 'accepted'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('ACCEPTER', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(context, rentalController, 'rejected'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('REFUSER', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.reservation.status == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.reservation.status == 'accepted' ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      widget.reservation.status == 'accepted' ? 'RÉSERVATION ACCEPTÉE' : 'RÉSERVATION REFUSÉE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.reservation.status == 'accepted' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 400), // Pour s'assurer que le contenu est scrollable même s'il est court
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.primaryBlue : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String url) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            if (url.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
                  images: [url],
                  initialIndex: 0,
                  heroTagPrefix: 'reservation_${widget.reservation.id}_$label',
                ),
              ),
            );
          },
          child: Hero(
            tag: 'reservation_${widget.reservation.id}_$label' '_0',
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: url.isNotEmpty ? DecorationImage(
                  image: NetworkImage(
                    url
                  ),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: url.isEmpty ? const Icon(Icons.description, color: Colors.grey) : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, RentalController controller, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus == 'accepted' ? 'Accepter' : 'Refuser'} la demande ?'),
        content: Text('Voulez-vous vraiment ${newStatus == 'accepted' ? 'accepter' : 'refuser'} cette demande de location ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NON')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('OUI', style: TextStyle(color: newStatus == 'accepted' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.updateReservationStatus(widget.reservation.id!, newStatus);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

