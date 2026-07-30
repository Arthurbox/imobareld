import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/features/admin/views/admin_boosted_list_view.dart';
import 'package:imobareld/features/admin/views/admin_chat_manager_view.dart';

// 1. VUE STATISTIQUES (En temps réel simulé par rafraîchissement périodique)
class AdminStatsView extends StatelessWidget {
  const AdminStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context, listen: false);
    final theme = Theme.of(context);
    
    return StreamBuilder<Map<String, int>>(
      stream: adminCtrl.statsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
        if (snapshot.connectionState == ConnectionState.waiting && stats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(context, 'Utilisateurs Total', stats['totalUsers']?.toString() ?? '0', Icons.people, Colors.blue),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Propriétaires', stats['owners']?.toString() ?? '0', Icons.home_work, Colors.orange)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(context, 'Locataires', stats['tenants']?.toString() ?? '0', Icons.person, Colors.green)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Vérifiés', stats['verified']?.toString() ?? '0', Icons.verified, Colors.blueAccent)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(context, 'En attente', stats['pending']?.toString() ?? '0', Icons.hourglass_top, Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatCard(context, 'Annonces Immotes', stats['totalProperties']?.toString() ?? '0', Icons.apartment, Colors.purple),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminBoostedListView()),
                  ),
                  child: _buildStatCard(
                    context,
                    'Biens Boostés (Voir liste)',
                    stats['totalBoostedProperties']?.toString() ?? '0',
                    Icons.rocket_launch,
                    Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 10),
                // --- NOUVEL ONGLET CHAT ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminChatManagerView()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.forum, color: Colors.redAccent, size: 30),
                        const SizedBox(height: 10),
                        Text('Gestion des Chats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
                        Text('Gérer et supprimer les discussions', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppColors.softShadow,
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
          Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color ?? AppColors.textLight, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
