/// Constantes pour la gestion des rôles utilisateurs.
///
/// Les identifiants sensibles (email admin, UUID agence) sont chargés
/// depuis les variables d'environnement via --dart-define-from-file=.env
class UserRoles {
  static const String user = 'locataire';
  static const String owner = 'propriétaire';
  static const String admin = 'admin';

  /// Email de l'Administrateur Suprême (chargé depuis les variables d'environnement)
  static const String supremeAdminEmail = String.fromEnvironment(
    'SUPREME_ADMIN_EMAIL',
    defaultValue: '',
  );

  /// ID Supabase du compte agence (chargé depuis les variables d'environnement)
  static const String agencyUserId = String.fromEnvironment(
    'AGENCY_USER_ID',
    defaultValue: '',
  );

  /// Nom affiché pour l'agence dans le chat
  static const String agencyName = 'IMOBARELD Agence';
}

