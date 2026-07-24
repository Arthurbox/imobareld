import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeniusPayService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Demande la création d'un paiement GeniusPay via Firebase Functions
  /// et retourne l'URL de la page de checkout.
  Future<Map<String, String>?> createCheckoutSession({
    required int amount,
    String? propertyId,
    required int durationDays,
    required String planName,
    String type = 'boost',
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      final HttpsCallable callable = _functions.httpsCallable('createGeniusPayCheckout');
      
      final response = await callable.call(<String, dynamic>{
        'amount': amount,
        'propertyId': propertyId,
        'durationDays': durationDays,
        'planName': planName,
        'userId': user.id,
        'userEmail': user.email ?? "user@imobareld.app",
        'userName': user.userMetadata?['name'] ?? "Utilisateur Imobareld",
        'type': type,
      });

      final responseData = response.data as Map<dynamic, dynamic>?;

      if (responseData != null && responseData['checkoutUrl'] != null && responseData['transactionId'] != null) {
        return {
          'checkoutUrl': responseData['checkoutUrl'] as String,
          'transactionId': responseData['transactionId'] as String,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la création du checkout GeniusPay: $e');
      rethrow;
    }
  }

  /// Ouvre l'URL de paiement dans le navigateur externe
  Future<void> openCheckoutPage(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      throw Exception('Impossible d\'ouvrir le lien de paiement: $url');
    }
  }
}
