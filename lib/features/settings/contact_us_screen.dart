import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});


  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Prise de contact IMOBARELD', 
    );
    await launchUrl(launchUri);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // WhatsApp URL scheme
    // Ajouter le code pays si nécessaire. Ici on assume que le numéro est complet ou local.
    // Pour l'international, il faudrait idéalement le format +226...
    // On essaie d'ouvrir whatsapp directement
    final String whatsappUrl = "whatsapp://send?phone=+226$phoneNumber&text=Bonjour IMOBARELD, je cherche des informations.";
    final String webUrl = "https://wa.me/+226$phoneNumber?text=Bonjour IMOBARELD, je cherche des informations.";

    try {
      if (!await launchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
       debugPrint('Could not launch WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Contactez-nous',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 50,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Notre équipe est là pour répondre à toutes vos questions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Téléphone
              _buildContactCard(
                context,
                icon: Icons.phone,
                title: 'Téléphone',
                content: '57 42 89 29',
                color: Colors.green,
                onTap: () => _makePhoneCall('57428929'),
              ),
              
              const SizedBox(height: 16),
              
              // WhatsApp
              _buildContactCard(
                context,
                icon: Icons.message, // Ou une icone WhatsApp si disponible via un package tierce, sinon message
                title: 'WhatsApp',
                content: '57 42 89 29',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp('57428929'),
              ),

              const SizedBox(height: 16),

              // Email
              _buildContactCard(
                context,
                icon: Icons.email_outlined,
                title: 'Email',
                content: 'afrmd05@gmail.com',
                color: Colors.redAccent,
                onTap: () => _sendEmail('afrmd05@gmail.com'),
              ),

              const SizedBox(height: 40),
             
              // Note horaires
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nous sommes disponibles du Lundi au Samedi de 8h à 18h.',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

