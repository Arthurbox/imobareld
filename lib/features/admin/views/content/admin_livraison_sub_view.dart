import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/models/delivery_request_model.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';

// ── Sous-vue Livraison ────────────────────────────────────────────────────────
class AdminLivraisonSubView extends StatelessWidget {
  final String city;
  const AdminLivraisonSubView({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context, listen: true);

    return StreamBuilder<List<DeliveryRequest>>(
      stream: adminCtrl.deliveryRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList(itemCount: 4, itemHeight: 80);

        var allRequests = snapshot.data ?? [];
        
        // Filtrage Optimistic UI
        allRequests = allRequests.where((req) => !adminCtrl.isPendingDeletion(req.id!)).toList();
        
        // Filtre par le nouveau champ city
        final filtered = allRequests.where((req) => req.city == city).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                Text('Aucune livraison à $city', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final req = filtered[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                backgroundColor: Theme.of(context).cardColor,
                collapsedBackgroundColor: Theme.of(context).cardColor,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
                ),
                title: Text(req.serviceType,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
                subtitle: Text('De: ${req.pickupAddress}\nÀ: ${req.destinationAddress}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                trailing: _buildStatusChip(req.status),
                children: [
                   Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        _buildDetailRow(context, 'Description', req.description),
                        _buildDetailRow(context, 'Contact', req.contactPhone),
                        _buildDetailRow(context, 'Date', req.createdAt.toString().split('.')[0]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (req.status == 'pending')
                              ElevatedButton(
                                onPressed: () => adminCtrl.updateDeliveryStatus(req.id!, 'accepted'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                child: const Text('Accepter', style: TextStyle(color: Colors.white)),
                              ),
                            if (req.status == 'accepted')
                              ElevatedButton(
                                onPressed: () => adminCtrl.updateDeliveryStatus(req.id!, 'completed'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Terminer', style: TextStyle(color: Colors.white)),
                              ),
                            OutlinedButton(
                              onPressed: () => _confirmDelete(context, req, adminCtrl),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'accepted': color = Colors.blue; label = 'Accepté'; break;
      case 'completed': color = Colors.green; label = 'Terminé'; break;
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
        SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color))),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, DeliveryRequest req, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette demande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () { controller.deleteDeliveryRequest(req.id!); Navigator.pop(context); },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
