import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class AdminRevenueView extends StatelessWidget {
  const AdminRevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Revenus & Transactions', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('transactions')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          
          // Calculer le revenu total (uniquement transactions 'completed')
          double totalRevenue = 0;
          for (var t in transactions) {
            if (t['status'] == 'completed') {
              totalRevenue += (t['amount'] as num?)?.toDouble() ?? 0.0;
            }
          }

          return Column(
            children: [
              // Jauge Temps Réel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Chiffre d\'Affaires Total',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalRevenue)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'En temps réel • ${transactions.where((t) => t['status'] == 'completed').length} paiements réussis',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Titre Liste
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text('Historique Global', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
                    const Spacer(),
                    Text('${transactions.length} transactions', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              // Liste Globale
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('Aucune transaction enregistrée', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = transactions[index];
                          return _buildGlobalTransactionCard(context, data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlobalTransactionCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final planName = data['plan_name'] as String? ?? 'Inconnu';
    final status = data['status'] as String? ?? 'unknown';
    
    // Format date
    String dateStr = '';
    if (data['created_at'] != null) {
      final date = DateTime.parse(data['created_at'].toString());
      dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    }

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Réussi';
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusLabel = 'Échec';
        statusIcon = Icons.error;
        break;
      case 'pending':
      case 'initiated':
      case 'created':
        statusColor = Colors.orange;
        statusLabel = 'En attente';
        statusIcon = Icons.access_time;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Annulé';
        statusIcon = Icons.cancel;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusLabel = 'Remboursé';
        statusIcon = Icons.money_off;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
        statusIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boost $planName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'User: ${data['user_id']?.toString().substring(0, 8)}...',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amount FCFA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: status == 'completed' ? Colors.green : theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
