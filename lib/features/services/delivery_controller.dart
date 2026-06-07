import 'package:flutter/material.dart';
import 'package:imobareld/models/delivery_request_model.dart';
import 'package:imobareld/core/services/supabase_service.dart';

class DeliveryController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Soumettre une demande de livraison via Supabase
  Future<bool> submitRequest(DeliveryRequest request) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabaseService.client.from('delivery_requests').insert(request.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur lors de l\'envoi de la demande Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupérer les demandes d'un utilisateur via Supabase
  Future<List<DeliveryRequest>> getUserRequests(String userId) async {
    try {
      final List<dynamic> data = await supabaseService.client
          .from('delivery_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return data.map((item) => DeliveryRequest.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('🚨 Erreur getUserRequests Supabase: $e');
      return [];
    }
  }
}
