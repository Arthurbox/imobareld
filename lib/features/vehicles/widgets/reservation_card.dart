import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/reservation_model.dart';
import 'package:imobareld/features/vehicles/reservation_detail_screen.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (reservation.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Acceptée';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Refusée';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationDetailScreen(reservation: reservation),
            ),
          );
        },
        title: Text(
          '${reservation.vehicleCompanyName} ${reservation.vehicleModel}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Par : ${reservation.userName}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${reservation.totalPrice.round()} F',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            Text('${reservation.numberOfDays} jours', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
