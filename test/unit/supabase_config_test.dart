import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/core/constants/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    // Note : les valeurs de String.fromEnvironment sont injectées
    // au moment de la compilation. En mode test (flutter test),
    // elles utilisent les defaultValue (chaînes vides) sauf si
    // on passe --dart-define lors du test.

    test('url et anonKey sont des String (non null)', () {
      // Vérifie que les constantes existent et sont bien des String
      expect(SupabaseConfig.url, isA<String>());
      expect(SupabaseConfig.anonKey, isA<String>());
    });

    test('isConfigured retourne false si les variables sont vides', () {
      // En mode test sans --dart-define, les defaultValue sont ''
      // Donc isConfigured doit retourner false
      // Cela protège contre un déploiement accidentel sans .env
      if (SupabaseConfig.url.isEmpty && SupabaseConfig.anonKey.isEmpty) {
        expect(SupabaseConfig.isConfigured, false);
      }
    });

    test('isConfigured retourne true si les variables sont remplies', () {
      // Si les tests sont lancés avec --dart-define-from-file=.env
      // alors les variables sont remplies et isConfigured = true
      if (SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty) {
        expect(SupabaseConfig.isConfigured, true);
      }
    });

    test('url doit commencer par https:// si configurée', () {
      if (SupabaseConfig.url.isNotEmpty) {
        expect(SupabaseConfig.url, startsWith('https://'));
      }
    });
  });
}
