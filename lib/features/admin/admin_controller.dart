import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/delivery_request_model.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:imobareld/core/constants/user_roles.dart';

class AdminController with ChangeNotifier {
  
  // 0. STREAMS EN TEMPS RÉEL (Supabase Realtime)
  
  final Set<String> _pendingDeletions = {};
  final StreamController<Map<String, int>> _statsController = StreamController<Map<String, int>>.broadcast();
  final List<sb.RealtimeChannel> _statsChannels = [];

  AdminController() {
    _initRealtimeStats();
  }

  @override
  void dispose() {
    for (var channel in _statsChannels) {
      channel.unsubscribe();
    }
    _statsController.close();
    super.dispose();
  }

  /// Flux des statistiques globales en temps réel
  Stream<Map<String, int>> get statsStream => _statsController.stream;

  void _initRealtimeStats() {
    // Premier chargement immédiat
    getStats().then((s) => _statsController.add(s));

    // Écouter les changements sur les tables clés
    final tables = ['profiles', 'properties', 'vehicles', 'delivery_requests'];
    
    for (var table in tables) {
      final channel = supabaseService.client.channel('public:$table-stats');
      channel.onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) async {
          debugPrint('📊 Changement détecté sur $table, actualisation des stats...');
          final stats = await getStats();
          if (!_statsController.isClosed) {
            _statsController.add(stats);
          }
        },
      ).subscribe();
      _statsChannels.add(channel);
    }
  }

  /// Vérifie si un ID est en cours de suppression (Optimistic UI)
  bool isPendingDeletion(String id) => _pendingDeletions.contains(id);

  /// Flux de TOUTES les demandes de vérification en attente
  Stream<List<UserModel>> get pendingVerificationsStream {
    return supabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .neq('verification_status', 'none') // Récupère pending, verified, et rejected
        .order('created_at', ascending: false)
        .map((list) => list.map((d) => UserModel.fromMap(d, d['id'].toString())).toList());
  }

  /// Flux de TOUS les utilisateurs inscrits sans exception (Temps Réel)
  Stream<List<UserModel>> allUsersStream({String query = ''}) {
    var streamQuery = supabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return streamQuery.map((list) {
      var users = list.map((d) => UserModel.fromMap(d, d['id'].toString())).toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        return users.where((u) {
          return u.name.toLowerCase().contains(q) || 
                 u.email.toLowerCase().contains(q) || 
                 (u.phone?.contains(q) ?? false);
        }).toList();
      }
      return users;
    });
  }

  /// Flux de TOUTES les demandes de livraison (pour gestion admin)
  Stream<List<DeliveryRequest>> get deliveryRequestsStream {
    return supabaseService.client
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.map((d) => DeliveryRequest.fromMap(d, d['id'].toString())).toList());
  }
  
  // 1. STATS (Supabase Count)
  Future<Map<String, int>> getStats() async {
    try {
      // On lance plusieurs comptages en parallèle pour gagner du temps
      // Utilisation de .count() qui renvoie une PostgrestResponse contenant le nombre de lignes
      final results = await Future.wait([
        supabaseService.client.from('profiles').select('id').count(sb.CountOption.exact),
        supabaseService.client.from('profiles').select('id').eq('role', UserRoles.owner).count(sb.CountOption.exact),
        supabaseService.client.from('profiles').select('id').eq('role', UserRoles.user).count(sb.CountOption.exact),
        supabaseService.client.from('profiles').select('id').eq('verification_status', 'verified').count(sb.CountOption.exact),
        supabaseService.client.from('profiles').select('id').eq('verification_status', 'pending').count(sb.CountOption.exact),
        supabaseService.client.from('properties').select('id').count(sb.CountOption.exact),
        supabaseService.client.from('vehicles').select('id').count(sb.CountOption.exact),
        supabaseService.client.from('delivery_requests').select('id').count(sb.CountOption.exact),
        supabaseService.client.from('properties').select('id').eq('is_boosted', true).count(sb.CountOption.exact),
      ]);
      
      // Dans Supabase 2.x, results[i] est une PostgrestResponse
      return {
        'totalUsers': results[0].count,
        'owners': results[1].count,
        'tenants': results[2].count,
        'verified': results[3].count,
        'pending': results[4].count,
        'totalProperties': results[5].count,
        'totalVehicles': results[6].count,
        'totalDeliveryRequests': results[7].count,
        'totalBoostedProperties': results[8].count,
      };
    } catch (e) {
      debugPrint('🚨 Erreur admin stats Supabase: $e');
    }
    return {};
  }


  /// Flux des propriétés boostées pour l'admin
  Stream<List<PropertyModel>> get boostedPropertiesStream {
    return supabaseService.client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('is_boosted', true)
        .order('created_at', ascending: false)
        .map((list) => list.map((d) => PropertyModel.fromMap(d, d['id'].toString())).toList());
  }

  // 3. PENDING VERIFICATIONS
  Future<List<UserModel>> getPendingVerifications() async {
    try {
      final response = await supabaseService.client
          .from('profiles')
          .select()
          .neq('verification_status', 'none')
          .order('created_at', ascending: false);
          
      return (response as List).map((d) => UserModel.fromMap(d, d['id'].toString())).toList();
    } catch (e) {
      debugPrint('🚨 Erreur getPendingVerifications Supabase: $e');
    }
    return [];
  }

  // 4. ACTIONS
  Future<void> approveVerification(String userId) async {
    try {
      await supabaseService.client.from('profiles').update({
        'verification_status': 'verified',
      }).eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur approbation Supabase: $e');
      rethrow;
    }
  }

  Future<void> rejectVerification(String userId, String reason) async {
    try {
      await supabaseService.client.from('profiles').update({
        'verification_status': 'rejected',
        'verification_message': reason,
      }).eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur rejet Supabase: $e');
      rethrow;
    }
  }

  Future<void> revokeVerification(String userId) async {
    try {
      await supabaseService.client.from('profiles').update({
        'verification_status': 'unverified',
      }).eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur révocation Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _pendingDeletions.add(userId);
      notifyListeners();

      // L'API client Flutter ne peut pas supprimer directement dans auth.users.
      // On fait donc appel à une fonction SQL (RPC) sécurisée qui supprime tout : auth + profil.
      await supabaseService.client.rpc('delete_target_user', params: {'target_id': userId});
    } catch (e) {
      debugPrint('🚨 Erreur suppression user Supabase: $e');
      rethrow;
    } finally {
      _pendingDeletions.remove(userId);
      notifyListeners();
    }
  }

  // 5. RÔLES
  Future<void> updateRole(String userId, String newRole) async {
    try {
      final Map<String, dynamic> updateData = {'new_role': newRole};
      
      // Si on nomme un administrateur, on le valide automatiquement (badge bleu certifié)
      if (newRole == 'admin') {
        updateData['status'] = 'verified';
      } else {
        updateData['status'] = 'none'; // ou 'unverified'
      }

      await supabaseService.client.rpc(
        'update_user_role', 
        params: {
          'target_id': userId,
          'new_role': newRole,
          'new_status': updateData['status']
        }
      );
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur mise à jour rôle Supabase: $e');
      rethrow;
    }
  }

  // 6. CERTIFICATION PROPRIÉTÉ
  Future<void> togglePropertyCertification(String propertyId, bool isCertified) async {
    try {
      await supabaseService.client.from('properties').update({
        'is_certified': isCertified,
      }).eq('id', propertyId);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur certification propriété Supabase: $e');
      rethrow;
    }
  }

  // 7. SUPPRESSION PROPRIÉTÉ (ADMIN)
  Future<void> deletePropertyAdmin(String propertyId) async {
    try {
      _pendingDeletions.add(propertyId);
      notifyListeners();

      // 1. Purger les relations existantes pour éviter les blocages de clés étrangères
      await supabaseService.client.from('property_likes').delete().eq('property_id', propertyId);
      await supabaseService.client.from('comments').delete().eq('property_id', propertyId);
      await supabaseService.client.from('reviews').delete().eq('property_id', propertyId);

      // 2. Supprimer la propriété et s'assurer que l'opération RLS a bien autorisé le 'DELETE'
      final response = await supabaseService.client.from('properties').delete().eq('id', propertyId).select();
      
      if (response.isEmpty) {
        throw Exception("Bloqué par la sécurité Supabase (RLS). Les administrateurs n'ont pas la permission de supprimer les propriétés. Veuillez mettre à jour la politique RLS.");
      }
    } catch (e) {
      debugPrint('🚨 Erreur suppression propriété admin Supabase: $e');
      rethrow;
    } finally {
      _pendingDeletions.remove(propertyId);
      notifyListeners();
    }
  }

  // 8. SUPPRESSION VÉHICULE (ADMIN)
  Future<void> deleteVehicleAdmin(String vehicleId) async {
    try {
      _pendingDeletions.add(vehicleId);
      notifyListeners();

      await supabaseService.client.from('vehicles').delete().eq('id', vehicleId);
    } catch (e) {
      debugPrint('🚨 Erreur suppression véhicule admin Supabase: $e');
      rethrow;
    } finally {
      _pendingDeletions.remove(vehicleId);
      notifyListeners();
    }
  }

  // 9. LIVRAISONS (ADMIN)
  Future<List<DeliveryRequest>> getDeliveryRequests() async {
    try {
      final response = await supabaseService.client
          .from('delivery_requests')
          .select()
          .order('created_at', ascending: false);
          
      return (response as List).map((d) => DeliveryRequest.fromMap(d, d['id'].toString())).toList();
    } catch (e) {
      debugPrint('🚨 Erreur fetching delivery requests Supabase: $e');
    }
    return [];
  }

  Future<void> updateDeliveryStatus(String requestId, String newStatus) async {
    try {
      await supabaseService.client.from('delivery_requests').update({
        'status': newStatus,
      }).eq('id', requestId);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur mise à jour statut livraison Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteDeliveryRequest(String requestId) async {
    try {
      _pendingDeletions.add(requestId);
      notifyListeners();

      await supabaseService.client.from('delivery_requests').delete().eq('id', requestId);
    } catch (e) {
      debugPrint('🚨 Erreur suppression livraison Supabase: $e');
      rethrow;
    } finally {
      _pendingDeletions.remove(requestId);
      notifyListeners();
    }
  }
}
