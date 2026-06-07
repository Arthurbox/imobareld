import 'package:flutter/material.dart';
import 'package:imobareld/core/services/database_helper.dart';
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/property_model.dart';

/// Service de synchronisation entre Supabase et la base de données locale
/// Gère le cache hors ligne et la synchronisation des données
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialise le service de synchronisation
  Future<void> init() async {
    // Charger la dernière date de synchronisation
    final lastSync = await _db.getSyncMetadata('last_sync_time');
    if (lastSync != null && lastSync.isNotEmpty) {
      _lastSyncTime = DateTime.parse(lastSync);
    }

    // Écouter les changements de connectivité pour synchroniser automatiquement
    _connectivity.addListener(_onConnectivityChanged);
  }

  /// Appelé quand la connectivité change
  void _onConnectivityChanged() {
    if (_connectivity.isOnline && !_isSyncing) {
      debugPrint('📡 Connexion détectée - Synchronisation automatique...');
      syncProperties();
    }
  }

  /// Synchronise les propriétés depuis Supabase vers la base locale
  Future<void> syncProperties({int limit = 100}) async {
    if (_isSyncing) {
      debugPrint('⚠️ Synchronisation déjà en cours');
      return;
    }

    if (!_connectivity.isOnline) {
      debugPrint('⚠️ Pas de connexion - Synchronisation impossible');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('🔄 Début de la synchronisation (Supabase)...');

      final List<dynamic> data = await supabaseService.client
          .from('properties')
          .select()
          .limit(limit)
          .order('created_at', ascending: false);
      
      int syncedCount = 0;
      for (var item in data) {
        final property = PropertyModel.fromMap(item, item['id'].toString());
        await _db.upsertProperty(property);
        syncedCount++;
      }

      // Mettre à jour la date de dernière synchronisation
      _lastSyncTime = DateTime.now();
      await _db.setSyncMetadata('last_sync_time', _lastSyncTime!.toIso8601String());

      debugPrint('✅ Synchronisation terminée: $syncedCount propriétés');
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation Supabase: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Récupère les propriétés (en ligne ou hors ligne)
  Future<List<PropertyModel>> getProperties({String? category, String? quartier}) async {
    if (_connectivity.isOnline) {
      // En ligne : récupérer depuis Supabase et mettre en cache
      try {
        var query = supabaseService.client.from('properties').select();
        
        if (category != null && category != 'Toutes' && category != 'Tous') query = query.eq('category', category);
        if (quartier != null && quartier != 'Tous') query = query.eq('quartier', quartier);
        
        final List<dynamic> data = await query.order('created_at', ascending: false);
        final properties = data.map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();

        // Mettre en cache
        for (var property in properties) {
          await _db.upsertProperty(property);
        }

        return properties;
      } catch (e) {
        debugPrint('⚠️ Erreur Supabase, basculement sur le cache: $e');
        return _getPropertiesFromCache(category: category, quartier: quartier);
      }
    } else {
      // Hors ligne : récupérer depuis le cache
      return _getPropertiesFromCache(category: category, quartier: quartier);
    }
  }

  /// Récupère les propriétés depuis le cache local
  Future<List<PropertyModel>> _getPropertiesFromCache({String? category, String? quartier}) async {
    if (category != null && category != 'Toutes' && category != 'Tous') {
      return await _db.getPropertiesByCategory(category);
    } else if (quartier != null && quartier != 'Tous') {
      return await _db.getPropertiesByQuartier(quartier);
    } else {
      return await _db.getAllProperties();
    }
  }

  /// Récupère une propriété par ID (en ligne ou hors ligne)
  Future<PropertyModel?> getPropertyById(String id) async {
    if (_connectivity.isOnline) {
      try {
        final data = await supabaseService.client
            .from('properties')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (data != null) {
          final property = PropertyModel.fromMap(data, data['id'].toString());
          await _db.upsertProperty(property); // Mettre en cache
          return property;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur Supabase, basculement sur le cache: $e');
      }
    }
    
    // Fallback sur le cache
    return await _db.getPropertyById(id);
  }

  /// Vide le cache local
  Future<void> clearCache() async {
    await _db.clearAllProperties();
    _lastSyncTime = null;
    await _db.setSyncMetadata('last_sync_time', '');
    debugPrint('🗑️ Cache vidé');
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
