/// Configuration CinetPay pour le paiement Orange Money / Moov Money (Burkina Faso)
///
/// ⚠️  IMPORTANT : Remplacez ces valeurs par vos vraies clés CinetPay.
/// Obtenez-les sur https://cinetpay.com → Mon Compte → API
class CinetPayConfig {
  /// Clé API fournie par CinetPay
  static const String apiKey = 'VOTRE_API_KEY_CINETPAY';

  /// Identifiant du site/service CinetPay
  static const int siteId = 0; // Remplacez par votre Site ID (entier)

  /// URL de notification webhook (peut être une URL Firebase Function)
  /// CinetPay appellera cette URL pour confirmer le paiement côté serveur
  static const String notifyUrl = 'https://votre-domaine.com/cinetpay/notify';

  /// Devise : XOF = Franc CFA (Burkina Faso, Côte d'Ivoire, Sénégal, etc.)
  static const String currency = 'XOF';

  /// Canaux de paiement : MOBILE_MONEY active Orange Money et Moov Money
  static const String channels = 'MOBILE_MONEY';
}
