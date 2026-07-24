import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/full_screen_image_viewer.dart';
import 'package:imobareld/core/widgets/skeleton_list.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/models/user_model.dart';

// 3. VUE VÉRIFICATIONS (Modifiée pour afficher photo)
class AdminVerificationsView extends StatefulWidget {
  const AdminVerificationsView({super.key});

  @override
  State<AdminVerificationsView> createState() => _AdminVerificationsViewState();
}

class _AdminVerificationsViewState extends State<AdminVerificationsView> {
  final Set<String> _processingIds = {}; // Track which requests are being processed

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context, listen: false);
    return StreamBuilder<List<UserModel>>(
      stream: adminCtrl.pendingVerificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonList(itemCount: 6, itemHeight: 80);
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Aucune demande ou profil vérifié', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        final pendingUsers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            final isProcessing = _processingIds.contains(user.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                backgroundColor: Theme.of(context).cardColor,
                collapsedBackgroundColor: Theme.of(context).cardColor,
                leading: Icon(
                  user.verificationStatus == 'verified' ? Icons.verified : 
                  user.verificationStatus == 'rejected' ? Icons.error : Icons.assignment_ind, 
                  color: user.verificationStatus == 'verified' ? Colors.blue : 
                         user.verificationStatus == 'rejected' ? Colors.red : Colors.orange, 
                  size: 32
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)
                      ),
                    ),
                    if (user.verificationStatus == 'verified') 
                      const Padding(
                        padding: EdgeInsets.only(left: 4), 
                        child: Icon(Icons.verified, color: Colors.blue, size: 18)
                      ),
                  ],
                ),
                subtitle: Text('ID: ${user.id.substring(0, 8)}... - Statut: ${user.verificationStatus.toUpperCase()}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                children: [
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Document d\'identité :', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        if (user.verificationDocuments.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showFullImage(context, user.verificationDocuments.first),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                            child: CachedImage(
                                imageUrl: user.verificationDocuments.first,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: const SizedBox(
                                  height: 200, 
                                  child: Center(child: Text('Erreur image', style: TextStyle(color: Colors.red)))
                                ),
                              ),
                            ),
                          )
                        else
                          const Text('Aucun document fourni.', style: TextStyle(color: Colors.red)),
                        
                        const SizedBox(height: 20),
                        isProcessing 
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (user.verificationStatus == 'pending') ...[
                              ElevatedButton.icon(
                                onPressed: () => _showRejectDialog(context, user.id, adminCtrl),
                                icon: const Icon(Icons.close),
                                label: const Text('Refuser'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _confirmAction(
                                  context, 
                                  'Approuver', 
                                  'Voulez-vous valider ce propriétaire ?\nIl sera marqué comme "Vérifié".',
                                  () => adminCtrl.approveVerification(user.id),
                                  user.id,
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approuver'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ] else if (user.verificationStatus == 'verified') ...[
                              ElevatedButton.icon(
                                onPressed: () => _confirmAction(
                                  context, 
                                  'Retirer la validation', 
                                  'Voulez-vous vraiment retirer la certification de ce profil ?',
                                  () => adminCtrl.revokeVerification(user.id),
                                  user.id,
                                ),
                                icon: const Icon(Icons.remove_circle_outline),
                                label: const Text('Retirer validation'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              ),
                            ]
                          ],
                        )
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

  void _showFullImage(BuildContext context, String base64Img) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: CachedImage(
            imageUrl: base64Img,
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String userId, AdminController adminCtrl) {
    String reason = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser le dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer le motif du refus. L\'utilisateur pourra le voir et soumettre une nouvelle demande.'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Document illisible, mauvais format...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => reason = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              if (reason.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Le motif est obligatoire.')));
                return;
              }
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() => _processingIds.add(userId));
              try {
                await adminCtrl.rejectVerification(userId, reason.trim());
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              } finally {
                if (mounted) setState(() => _processingIds.remove(userId));
              }
            },
            child: const Text('Confirmer le refus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, String action, String message, Future<void> Function() onConfim, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action le dossier ?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              if (!mounted) return;
              setState(() => _processingIds.add(userId));
              
              try {
                await onConfim();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              } finally {
                if(mounted) setState(() => _processingIds.remove(userId));
              }
            },
            child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
