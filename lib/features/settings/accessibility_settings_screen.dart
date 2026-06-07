import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/services/accessibility_settings.dart';
import 'package:imobareld/core/constants/app_colors.dart';

/// Écran de paramètres d'accessibilité
/// Permet à l'utilisateur d'ajuster la taille de police et le mode haut contraste
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibilité'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AccessibilitySettings>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête
              const Text(
                'Paramètres d\'accessibilité',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personnalisez l\'affichage pour une meilleure lisibilité',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),

              // Section Taille de police
              _buildSectionTitle('Taille de police'),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Petit'),
                          Text(
                            'Aperçu du texte',
                            style: TextStyle(
                              fontSize: settings.getAdjustedFontSize(16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text('Grand'),
                        ],
                      ),
                      Slider(
                        value: settings.fontScale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 9,
                        label: _getFontScaleLabel(settings.fontScale),
                        activeColor: AppColors.primaryBlue,
                        onChanged: (value) {
                          settings.setFontScale(value);
                        },
                      ),
                      Center(
                        child: Text(
                          _getFontScaleLabel(settings.fontScale),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Section Mode haut contraste
              _buildSectionTitle('Contraste'),
              const SizedBox(height: 16),
              
              Card(
                child: SwitchListTile(
                  title: const Text('Mode haut contraste'),
                  subtitle: const Text(
                    'Augmente le contraste des couleurs pour une meilleure lisibilité',
                  ),
                  value: settings.highContrastMode,
                  activeThumbColor: AppColors.primaryBlue,
                  onChanged: (value) {
                    settings.setHighContrastMode(value);
                  },
                  secondary: Icon(
                    settings.highContrastMode 
                      ? Icons.contrast 
                      : Icons.contrast_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Aperçu
              _buildSectionTitle('Aperçu'),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Titre de l\'annonce',
                      style: TextStyle(
                        fontSize: settings.getAdjustedFontSize(20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(settings.highContrastMode),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ceci est un exemple de texte secondaire pour vous montrer comment les paramètres d\'accessibilité affectent l\'affichage.',
                      style: TextStyle(
                        fontSize: settings.getAdjustedFontSize(14),
                        color: AppColors.getTextColor(
                          settings.highContrastMode,
                          isLight: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimaryColor(
                          settings.highContrastMode,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Bouton d\'exemple',
                        style: TextStyle(
                          fontSize: settings.getAdjustedFontSize(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton de réinitialisation
              OutlinedButton.icon(
                onPressed: () async {
                  await settings.reset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paramètres réinitialisés'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser les paramètres'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Informations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ces paramètres s\'appliquent à toute l\'application et sont sauvegardés automatiquement.',
                        style: TextStyle(
                          fontSize: settings.getAdjustedFontSize(12),
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  String _getFontScaleLabel(double scale) {
    if (scale <= 0.9) return 'Petit';
    if (scale <= 1.05) return 'Normal';
    if (scale <= 1.2) return 'Grand';
    return 'Très grand';
  }
}
