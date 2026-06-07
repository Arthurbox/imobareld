import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cinetpay/cinetpay.dart';
import 'package:imobareld/core/constants/cinetpay_config.dart';
import 'package:imobareld/features/home/property_controller.dart';

class BoostPlansScreen extends StatelessWidget {
  final String propertyId;
  const BoostPlansScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Light grey background like the reference
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Plans de Boost',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Gradient Section
            _buildHeader(),

            const SizedBox(height: 24),

            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Nos Formules de Visibilité',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Propulsez vos annonces en haut de page pour\ntrouver des clients plus rapidement.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Starter Plan ----
            InkWell(
              onTap: () => _payWithCinetPay(context, 500, 7, 'Starter'),
              child: _buildPlanCard(
                context,
                title: 'Starter',
                subtitle: 'Visible en tête de liste\npendant 7 jours',
                price: '500 FCFA',
                duration: '7 jours',
                iconWidget: const FaIcon(FontAwesomeIcons.bolt, color: Color(0xFFFF8C00), size: 26),
                iconBgColor: const Color(0xFFFFF0D4),
                priceColor: const Color(0xFFFF8C00),
                cardBorderColor: const Color(0xFFFFD180),
              ),
            ),

            // ---- Standard Plan ----
            InkWell(
              onTap: () => _payWithCinetPay(context, 1000, 15, 'Standard'),
              child: _buildPlanCard(
                context,
                title: 'Standard',
                subtitle: 'Meilleure visibilité\npendant 15 jours',
                price: '1000 FCFA',
                duration: '15 jours',
                iconWidget: const FaIcon(FontAwesomeIcons.rocket, color: Color(0xFFFF5722), size: 24),
                iconBgColor: const Color(0xFFFFE0D6),
                priceColor: const Color(0xFFFF5722),
                cardBorderColor: const Color(0xFFFFAB91),
                isPopular: true,
              ),
            ),

            // ---- Premium Plan ----
            InkWell(
              onTap: () => _payWithCinetPay(context, 2000, 30, 'Premium'),
              child: _buildPlanCard(
                context,
                title: 'Premium',
                subtitle: 'Visibilité maximale\npendant 30 jours',
                price: '2000 FCFA',
                duration: '30 jours',
                iconWidget: const FaIcon(FontAwesomeIcons.award, color: Color(0xFF9C27B0), size: 24),
                iconBgColor: const Color(0xFFF0DAF5),
                priceColor: const Color(0xFF9C27B0),
                cardBorderColor: const Color(0xFFCE93D8),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _payWithCinetPay(BuildContext context, int amount, int durationDays, String planName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CinetPayCheckout(
          title: 'Boost $durationDays jours',
          titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleBackgroundColor: const Color(0xFF1A3A8F),
          configData: const <String, dynamic>{
            'apikey': CinetPayConfig.apiKey,
            'site_id': CinetPayConfig.siteId,
            'notify_url': CinetPayConfig.notifyUrl,
          },
          paymentData: <String, dynamic>{
            'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
            'amount': amount,
            'currency': 'XOF',
            'channels': 'ALL',
            'description': 'Boost immobilier $durationDays jours',
          },
          waitResponse: (response) async {
            if (response['status'] == 'ACCEPTED') {
              Navigator.pop(ctx); // Ferme CinetPay
              final success = await Provider.of<PropertyController>(context, listen: false).boostProperty(propertyId, durationDays, planName);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement réussi, propriété boostée !')));
                Navigator.pop(context); // Retourne au dashboard
              }
            } else {
              Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paiement échoué: ${response['status']}')));
            }
          },
          onError: (error) {
            Navigator.pop(ctx);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $error')));
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // Bleu profond → Orange chaud, accentué
          colors: [Color(0xFF0D47A1), Color(0xFFFF7A00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Rocket icon avec une légère ombre pour ressembler à la maquette
          Container(
            padding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Flamme/étoiles autour
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.star, color: Colors.white54, size: 14),
                ),
                const Positioned(
                  bottom: 2,
                  left: 4,
                  child: Icon(Icons.star, color: Colors.white38, size: 10),
                ),
                const FaIcon(
                  FontAwesomeIcons.rocket,
                  size: 72,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Boostez votre visibilité',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vendez ou louez 5x plus vite',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required String duration,
    required Widget iconWidget,
    required Color iconBgColor,
    required Color priceColor,
    required Color cardBorderColor,
    bool isPopular = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône ronde sans bordure
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 14),

          // Contenu (titre + sous-titre)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + badge "Populaire"
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Populaire',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Prix + durée (alignés à droite)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
