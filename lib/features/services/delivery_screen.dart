import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/services/delivery_controller.dart';
import 'package:imobareld/models/delivery_request_model.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/constants/bf_locations.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Services de Livraison', style: TextStyle(color: theme.primaryColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner or Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Besoin d\'aide pour votre déménagement ?',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nos partenaires sont là pour vous aider à transporter vos biens en toute sécurité.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 50),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choisissez un service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
          ),
          const SizedBox(height: 16),
          
          _buildServiceCard(
            context,
            title: 'Déménagement Complet',
            description: 'Camion + Main d\'oeuvre pour changer de maison sans effort.',
            icon: Icons.home_work_outlined,
            color: AppColors.primaryBlue,
          ),
          
          _buildServiceCard(
            context,
            title: 'Transport de Meubles',
            description: 'Idéal pour déplacer un canapé, un lit ou un frigo.',
            icon: Icons.chair_outlined,
            color: AppColors.primaryOrange,
          ),
          
          _buildServiceCard(
            context,
            title: 'Coursier Express',
            description: 'Livraison rapide de documents ou petits colis en ville.',
            icon: Icons.motorcycle_outlined,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppColors.softShadow,
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showOrderDialog(context, title);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleMedium?.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: theme.textTheme.bodySmall?.color ?? AppColors.textLight, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color ?? AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDialog(BuildContext context, String serviceName) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final pickupController = TextEditingController();
    final destinationController = TextEditingController();
    final phoneController = TextEditingController();
    final descController = TextEditingController();
    String selectedCity = 'Ouagadougou';
    
    // Pré-remplir le téléphone si l'utilisateur est connecté
    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.currentUser != null) {
      phoneController.text = auth.currentUser!.phone ?? '';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Commander : $serviceName', style: TextStyle(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    dropdownColor: theme.cardColor,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: BfLocations.cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) selectedCity = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu de départ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.my_location),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu d\'arrivée',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Détails, date...)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          Consumer<DeliveryController>(
            builder: (context, controller, child) {
              return ElevatedButton(
                onPressed: controller.isLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    final user = auth.currentUser;
                    if (user == null) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Veuillez vous connecter pour commander')),
                       );
                       return;
                    }
                    final request = DeliveryRequest(
                      userId: user.id,
                      serviceType: serviceName,
                      city: selectedCity,
                      pickupAddress: pickupController.text.trim(),
                      destinationAddress: destinationController.text.trim(),
                      contactPhone: phoneController.text.trim(),
                      description: descController.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    final success = await controller.submitRequest(request);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Fermer le dialog
                      if (success) {
                        _showSuccessDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                child: controller.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer la demande', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              'Demande Envoyée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notre équipe vous recontactera rapidement pour confirmer les détails.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
