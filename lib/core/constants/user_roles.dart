/// Constantes pour la gestion des rôles utilisateurs
class UserRoles {
  static const String user = 'locataire';
  static const String owner = 'propriétaire';
  static const String admin = 'admin';

  /// Email de l'Administrateur Suprême
  static const String supremeAdminEmail = 'afrmd05@gmail.com';

  /// ID Supabase du compte agence (compte admin principal)
  /// ⚠️ Remplace cette valeur par ton vrai UUID Supabase
  /// → Retrouve-le dans Supabase > Authentication > Users > afrmd05@gmail.com
  static const String agencyUserId = '7f6f315e-1766-49c0-8e80-d1fe9b909c49';

  /// Nom affiché pour l'agence dans le chat
  static const String agencyName = 'IMOBARELD Agence';
}
