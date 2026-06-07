import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des paramètres d'accessibilité
/// Permet d'ajuster la taille de police et le mode haut contraste
class AccessibilitySettings extends ChangeNotifier {
  static final AccessibilitySettings _instance = AccessibilitySettings._internal();
  factory AccessibilitySettings() => _instance;
  AccessibilitySettings._internal();

  // Taille de police
  double _fontScale = 1.0;
  double get fontScale => _fontScale;

  // Mode haut contraste
  bool _highContrastMode = false;
  bool get highContrastMode => _highContrastMode;

  // Mode de thème
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Clés de stockage
  static const String _fontScaleKey = 'accessibility_font_scale';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _themeModeKey = 'accessibility_theme_mode';

  /// Initialise les paramètres depuis le stockage local
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    _highContrastMode = prefs.getBool(_highContrastKey) ?? false;
    
    // Charger le mode de thème
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    
    notifyListeners();
  }

  /// Définit le mode de thème
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    debugPrint('✅ Mode de thème mis à jour: $mode');
  }

  /// Définit l'échelle de police
  /// Valeurs recommandées : 0.85 (petit), 1.0 (normal), 1.15 (grand), 1.3 (très grand)
  Future<void> setFontScale(double scale) async {
    if (scale < 0.75 || scale > 1.5) {
      debugPrint('⚠️ Échelle de police hors limites: $scale');
      return;
    }

    _fontScale = scale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
    debugPrint('✅ Échelle de police mise à jour: $scale');
  }

  /// Active/désactive le mode haut contraste
  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
    debugPrint('✅ Mode haut contraste: ${enabled ? "activé" : "désactivé"}');
  }

  /// Réinitialise les paramètres par défaut
  Future<void> reset() async {
    _fontScale = 1.0;
    _highContrastMode = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fontScaleKey);
    await prefs.remove(_highContrastKey);
    debugPrint('✅ Paramètres d\'accessibilité réinitialisés');
  }

  /// Obtient la taille de police ajustée
  double getAdjustedFontSize(double baseSize) {
    return baseSize * _fontScale;
  }

  /// Obtient le TextStyle ajusté
  TextStyle getAdjustedTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null 
        ? baseStyle.fontSize! * _fontScale 
        : null,
    );
  }
}
