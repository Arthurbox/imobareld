/// Configuration Supabase chargée depuis les variables d'environnement.
/// 
/// Les valeurs sont injectées au moment de la compilation via :
///   flutter run --dart-define-from-file=.env
/// 
/// Voir .env.example pour le template des variables requises.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Vérifie que les variables d'environnement sont bien configurées.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
