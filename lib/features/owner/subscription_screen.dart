import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedMonths = 1;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _plans = [
    {'months': 1, 'label': '1 Mois', 'price': 2500},
    {'months': 3, 'label': '3 Mois', 'price': 7000},
    {'months': 6, 'label': '6 Mois', 'price': 12500},
    {'months': 12, 'label': '1 An', 'price': 25000},
  ];

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    // Simulation d'un paiement de quelques secondes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.renewSubscription(_selectedMonths);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonnement activé avec succès !', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Retour au dashboard qui devrait maintenant être débloqué
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage ?? 'Erreur lors du renouvellement', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPrice = _plans.firstWhere((p) => p['months'] == _selectedMonths)['price'] as int;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Abonnement Propriétaire', style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.star, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Débloquez tout le potentiel de vos annonces',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Un abonnement actif vous permet de gérer vos biens, accepter des réservations et communiquer avec les locataires.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Choisissez votre forfait :',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                    ),
                    const SizedBox(height: 16),
                    ..._plans.map((plan) {
                      final months = plan['months'] as int;
                      final label = plan['label'] as String;
                      final planPrice = plan['price'] as int;
                      final isSelected = _selectedMonths == months;
                      
                      final monthlyEquivalent = (planPrice / months).round();

                      return GestureDetector(
                        onTap: () => setState(() => _selectedMonths = months),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? theme.primaryColor : theme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? theme.primaryColor : theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  if (months > 1)
                                    Text(
                                      'Soit $monthlyEquivalent FCFA / mois',
                                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                    ),
                                ],
                              ),
                              Text(
                                '$planPrice FCFA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total à payer :', style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color)),
                      Text('$totalPrice FCFA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Payer $totalPrice FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
