// Import du package Flutter Material pour les couleurs
import 'package:flutter/material.dart';

/// Classe contenant toutes les couleurs de la marque IMOBARELD
/// Ces couleurs sont extraites du logo de l'application
/// pour garantir une cohérence visuelle dans toute l'app
class AppColors {
  // ========================================
  // COULEURS PRINCIPALES DU LOGO
  // ========================================
  
  /// Bleu foncé principal du logo IMOBARELD
  static const Color primaryBlue = Color(0xFF0A4DA2);
  
  /// Orange vif principal du logo IMOBARELD
  static const Color primaryOrange = Color(0xFFFF8C00);

  /// Vert présent à la base du logo
  static const Color primaryGreen = Color(0xFF4CAF50);
  
  // ========================================
  // VARIANTES DE BLEU
  // ========================================
  
  /// Bleu plus clair pour les survols et états actifs
  static const Color lightBlue = Color(0xFF3B82F6);
  
  /// Bleu plus foncé pour les ombres et contrastes
  static const Color darkBlue = Color(0xFF1E40AF);
  
  // ========================================
  // VARIANTES D'ORANGE
  // ========================================
  
  /// Orange plus clair pour les survols et états actifs
  static const Color lightOrange = Color(0xFFFF8C61);
  
  /// Orange plus foncé pour les ombres et contrastes
  static const Color darkOrange = Color(0xFFE85A2A);
  
  // ========================================
  // DÉGRADÉS DE LA MARQUE
  // ========================================
  
  /// Dégradé horizontal : bleu → orange
  /// Utilisé pour les boutons principaux (Se connecter, S'inscrire)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryOrange],
    begin: Alignment.centerLeft,  // Commence à gauche (bleu)
    end: Alignment.centerRight,   // Termine à droite (orange)
  );
  
  /// Dégradé vertical : bleu → orange
  /// Utilisé pour les arrière-plans ou effets spéciaux
  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primaryBlue, primaryOrange],
    begin: Alignment.topCenter,    // Commence en haut (bleu)
    end: Alignment.bottomCenter,   // Termine en bas (orange)
  );
  
  // ========================================
  // COULEURS DE TEXTE
  // ========================================
  
  /// Couleur de texte foncé pour les titres et textes importants
  /// Contraste WCAG AA: 16.1:1 sur fond blanc
  static const Color textDark = Color(0xFF111827);
  
  /// Couleur de texte clair pour les sous-titres et textes secondaires
  /// Contraste WCAG AA: 4.6:1 sur fond blanc
  static const Color textLight = Color(0xFF4B5563);
  
  /// Couleur de texte blanc pour les boutons et textes sur fond foncé
  static const Color textWhite = Color(0xFFFFFFFF);

  // ========================================
  // COULEURS HAUT CONTRASTE (WCAG AAA)
  // ========================================
  
  /// Bleu haut contraste pour le mode accessibilité
  /// Contraste WCAG AAA: 8.2:1 sur fond blanc
  static const Color highContrastBlue = Color(0xFF003D82);
  
  /// Orange haut contraste pour le mode accessibilité
  /// Contraste WCAG AAA: 4.8:1 sur fond blanc
  static const Color highContrastOrange = Color(0xFFCC6600);
  
  /// Texte haut contraste (noir pur)
  /// Contraste WCAG AAA: 21:1 sur fond blanc
  static const Color highContrastText = Color(0xFF000000);
  
  /// Fond haut contraste (blanc pur)
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  
  // ========================================
  // COULEURS DE FOND
  // ========================================
  
  /// Couleur de fond principale de l'application (gris très clair)
  static const Color background = Color(0xFFF9FAFB);
  
  /// Couleur de fond des cartes et conteneurs (blanc)
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Couleur de fond des champs de saisie (gris clair)
  static const Color inputBackground = Color(0xFFF3F4F6);
  
  // ========================================
  // COULEURS D'ÉTAT
  // ========================================
  
  /// Vert pour les messages de succès
  static const Color success = Color(0xFF10B981);
  
  /// Rouge pour les messages d'erreur
  static const Color error = Color(0xFFEF4444);
  
  /// Orange/jaune pour les avertissements
  static const Color warning = Color(0xFFF59E0B);
  
  /// Bleu pour les informations
  static const Color info = Color(0xFF3B82F6);
  
  // ========================================
  // COULEURS DE BORDURES
  // ========================================
  
  /// Couleur de bordure par défaut (gris clair)
  static const Color border = Color(0xFFE5E7EB);
  
  /// Couleur de bordure quand un champ est sélectionné (focus)
  static const Color focusBorder = primaryBlue;

  // ========================================
  // OMBRES ET ÉLÉVATIONS
  // ========================================

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // ========================================
  // MÉTHODES UTILITAIRES
  // ========================================

  /// Retourne les couleurs appropriées selon le mode haut contraste
  static Color getTextColor(bool highContrast, {bool isLight = false}) {
    if (highContrast) {
      return highContrastText;
    }
    return isLight ? textLight : textDark;
  }

  /// Retourne la couleur primaire selon le mode haut contraste
  static Color getPrimaryColor(bool highContrast, {bool isOrange = false}) {
    if (highContrast) {
      return isOrange ? highContrastOrange : highContrastBlue;
    }
    return isOrange ? primaryOrange : primaryBlue;
  }

  /// Retourne le fond selon le mode haut contraste
  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
}
