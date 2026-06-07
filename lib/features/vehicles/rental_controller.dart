import 'package:flutter/material.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/reservation_model.dart';
import 'package:imobareld/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';

class RentalController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Nouvelle méthode Supabase : Compresse et télécharge les documents vers Supabase Storage
  Future<List<String>> compressAndUploadImages(List<XFile> images) async {
    List<String> uploadedUrls = [];
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final extension = p.extension(image.path).toLowerCase();
        final fileName = 'rec_${DateTime.now().microsecondsSinceEpoch}$extension';
        final path = 'reservations/$userId/$fileName';

        final url = await supabaseService.uploadBytes('media', path, bytes);
        uploadedUrls.add(url);
      }
    } catch (e) {
      debugPrint('🚨 Erreur upload documents Supabase: $e');
    }
    return uploadedUrls;
  }

  /// Soumet une demande de réservation via Supabase
  Future<bool> submitReservation(ReservationModel reservation) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      final Map<String, dynamic> reservationData = reservation.toMap();
      reservationData.remove('id');
      reservationData['user_id'] = userId;

      await supabaseService.client.from('reservations').insert(reservationData);

      // Notifier le propriétaire via une notification locale
      await _notificationService.showReservationNotification(
        vehicleModel: '${reservation.vehicleCompanyName} ${reservation.vehicleModel}',
        tenantName: reservation.userName,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de la réservation Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupérer TOUTES les réservations via Supabase (Admin)
  Future<List<ReservationModel>> getAllReservations() async {
    try {
      final List<dynamic> data = await supabaseService.client
          .from('reservations')
          .select()
          .order('created_at', ascending: false);
      
      return data.map((item) => ReservationModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('❌ Erreur getAllReservations Supabase: $e');
    }
    return [];
  }

  /// Récupérer les réservations d'un propriétaire via Supabase
  Future<List<ReservationModel>> getOwnerReservations(String ownerId) async {
    try {
      final List<dynamic> data = await supabaseService.client
          .from('reservations')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      
      return data.map((item) => ReservationModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('❌ Erreur getOwnerReservations Supabase: $e');
    }
    return [];
  }

  /// Récupérer les réservations d'un utilisateur via Supabase
  Future<List<ReservationModel>> getUserReservations(String userId) async {
    try {
      final List<dynamic> data = await supabaseService.client
          .from('reservations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return data.map((item) => ReservationModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('❌ Erreur getUserReservations Supabase: $e');
    }
    return [];
  }

  /// Met à jour le statut d'une réservation via Supabase
  Future<bool> updateReservationStatus(String reservationId, String newStatus) async {
    try {
      await supabaseService.client.from('reservations').update({
        'status': newStatus,
      }).eq('id', reservationId);
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour statut réservation Supabase: $e');
      return false;
    }
  }

  /// Flux de TOUTES les réservations via Supabase (Admin)
  Stream<List<ReservationModel>> get allReservationsStream {
    return supabaseService.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.map((item) => ReservationModel.fromMap(item, item['id'].toString())).toList());
  }
}
