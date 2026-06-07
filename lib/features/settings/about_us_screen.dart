import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/settings/legal_documents_screen.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'À propos de nous',
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
              const SizedBox(height: 20),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primaryBlue,
                        child: const Icon(Icons.home, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Nom de l'application
              const Text(
                'IMOBARELD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                   'Version 1.0.0',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.grey,
                     fontWeight: FontWeight.w500,
                   ),
                ),
              ),
              const SizedBox(height: 40),
              // Description
              Text(
                'Votre partenaire immobilier de confiance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'IMOBARELD simplifie votre recherche de logement. Que vous souhaitiez louer, acheter ou mettre en vente un bien, nous vous offrons une plateforme intuitive et sécurisée pour concrétiser vos projets immobiliers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 40),
              // Informations supplémentaires
              _buildInfoItem(context, Icons.verified_user_outlined, '100% Sécurisé'),
              const SizedBox(height: 16),
              _buildInfoItem(context, Icons.headset_mic_outlined, 'Support 24/7'),
              const SizedBox(height: 16),
              _buildInfoItem(context, Icons.update, 'Mises à jour régulières'),
              
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalDocumentsScreen(isTermsOfService: true))),
                    child: const Text('CGU', style: TextStyle(color: AppColors.primaryBlue, decoration: TextDecoration.underline)),
                  ),
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalDocumentsScreen(isTermsOfService: false))),
                    child: const Text('Confidentialité', style: TextStyle(color: AppColors.primaryBlue, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2026 IMOBARELD. Tous droits réservés.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
