import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/vehicles/rental_controller.dart';
import 'package:imobareld/models/reservation_model.dart';

// ── Sous-vue Réservation (Véhicules) ──────────────────────────────────────────
class AdminReservationSubView extends StatelessWidget {
  final String city;
  const AdminReservationSubView({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final rentalCtrl = Provider.of<RentalController>(context, listen: false);

    return StreamBuilder<List<ReservationModel>>(
      stream: rentalCtrl.allReservationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final reservations = snapshot.data ?? [];
        
        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 64, color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                const Text('Aucune réservation en cours'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final res = reservations[index];
            return AdminReservationCard(reservation: res);
          },
        );
      },
    );
  }
}

class AdminReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const AdminReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rentalCtrl = Provider.of<RentalController>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Icon(Icons.event_available, color: theme.primaryColor),
        ),
        title: Text('${reservation.vehicleCompanyName} ${reservation.vehicleModel}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Par: ${reservation.userName}\n${reservation.totalPrice.toInt()} CFA • ${reservation.numberOfDays}j',
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
        trailing: _buildStatusChip(reservation.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildDetailRow(context, 'Utilisateur', reservation.userName),
                _buildDetailRow(context, 'Email', reservation.userEmail),
                if (reservation.userPhone != null) _buildDetailRow(context, 'Téléphone', reservation.userPhone!),
                _buildDetailRow(context, 'Chauffeur', reservation.withDriver ? 'Oui' : 'Non'),
                const SizedBox(height: 12),
                const Text('Documents joints :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDocPreview(context, 'CNIB Recto', reservation.cnibImage),
                      const SizedBox(width: 8),
                      _buildDocPreview(context, 'CNIB Verso', reservation.cnibBackImage),
                      const SizedBox(width: 8),
                      _buildDocPreview(context, 'Permis', reservation.licenseImage),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (reservation.status == 'pending') ...[
                      ElevatedButton(
                        onPressed: () async {
                          await rentalCtrl.updateReservationStatus(reservation.id!, 'accepted');
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation acceptée.')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Accepter', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                           await rentalCtrl.updateReservationStatus(reservation.id!, 'rejected');
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation refusée.')));
                           }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Refuser', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'accepted': color = Colors.green; label = 'Acceptée'; break;
      case 'rejected': color = Colors.red; label = 'Refusée'; break;
      default: color = Colors.orange; label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 85, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color))),
      ]),
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String url) {
    return GestureDetector(
      onTap: () {
        if (url.isNotEmpty) {
           showDialog(
            context: context,
            builder: (_) => Dialog(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (_, __, ___) => const Center(child: Text('Erreur image')),
                ),
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                    ),
                  )
                : const Icon(Icons.description, size: 20, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
