import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/ad_model.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:imobareld/core/services/database_helper.dart';
import 'package:imobareld/core/services/connectivity_service.dart';

class AdController extends ChangeNotifier {
  // - [x] Update `DatabaseHelper` for local advertising caching (Schema v3)
  // - [x] Implement ad caching logic in `AdController`
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AdModel> _activeAds = [];
  List<AdModel> get activeAds => _activeAds;

  AdController() {
    // Écouter les changements de connectivité
    // Quand on passe hors ligne → recharger les pubs depuis le cache SQLite
    ConnectivityService().addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!ConnectivityService().isOnline) {
      _reloadAdsFromCache();
    }
  }

  Future<void> _reloadAdsFromCache() async {
    final cached = await _db.getActiveAds();
    if (cached.isNotEmpty) {
      _activeAds = cached;
      notifyListeners();
      debugPrint('📦 Publicités rechargées depuis le cache SQLite (hors ligne)');
    }
  }

  /// Récupérer les publicités actives (Cache local d'abord, puis Supabase)
  Future<List<AdModel>> getActiveAds() async {
    // 1. Charger depuis le cache local immédiatement
    final cachedAds = await _db.getActiveAds();
    if (cachedAds.isNotEmpty) {
      _activeAds = cachedAds;
      notifyListeners();
    }

    // 2. Si en ligne, mettre à jour depuis Supabase
    if (_connectivity.isOnline) {
      try {
        final List<dynamic> data = await supabaseService.client
            .from('ads')
            .select()
            .eq('is_active', true)
            .order('priority', ascending: false);
        
        final remoteAds = data.map((item) => AdModel.fromMap(item, item['id'].toString())).toList();
        
        // Mettre à jour le cache
        await _db.clearAds();
        for (var ad in remoteAds) {
          await _db.upsertAd(ad);
        }
        
        _activeAds = remoteAds;
        notifyListeners();
        return remoteAds;
      } catch (e) {
        debugPrint('Erreur récupération pubs Supabase: $e');
      }
    }
    
    return _activeAds;
  }

  /// Uploader une image de publicité vers Supabase Storage
  /// Accepte un [XFile] (compatible Web + Mobile)
  Future<String?> uploadAdImage(XFile imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Lecture des bytes via XFile — compatible Web et Mobile
      final Uint8List bytes = await imageFile.readAsBytes();
      String extension = p.extension(imageFile.path).toLowerCase();

      if (extension.isEmpty) extension = '.jpg';
      final fileName = 'ad_${DateTime.now().microsecondsSinceEpoch}$extension';
      final path = 'ads/$fileName';

      // Upload vers le bucket 'media'
      final url = await supabaseService.uploadBytes('media', path, bytes);
      
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint('Erreur upload ad image Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Ajouter une publicité via Supabase
  Future<bool> addAd(AdModel ad) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabaseService.client.from('ads').insert(ad.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur ajout publicité Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Modifier une publicité via Supabase
  Future<bool> updateAd(AdModel ad) async {
    if (ad.id == null) return false;
    try {
      await supabaseService.client.from('ads').update(ad.toMap()).eq('id', ad.id!);
      return true;
    } catch (e) {
      debugPrint('Erreur mise à jour Ad Supabase: $e');
      return false;
    }
  }

  /// Supprimer une publicité via Supabase
  Future<bool> deleteAd(String id) async {
    try {
      await supabaseService.client.from('ads').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Erreur suppression Ad Supabase: $e');
      return false;
    }
  }

  /// Flux de TOUTES les publicités (pour gestion admin)
  Stream<List<AdModel>> get allAdsStream {
    return supabaseService.client
        .from('ads')
        .stream(primaryKey: ['id'])
        .order('priority', ascending: false)
        .map((list) => list.map((item) => AdModel.fromMap(item, item['id'].toString())).toList());
  }

  /// Flux des publicités ACTIVES (pour les utilisateurs)
  /// Cette version retourne un mélange du cache et des données temps réel
  Stream<List<AdModel>> get activeAdsStream async* {
    // Émettre le cache immédiatement
    final cached = await _db.getActiveAds();
    if (cached.isNotEmpty) yield cached;

    // S'abonner aux changements Supabase si en ligne
    if (_connectivity.isOnline) {
      try {
        yield* supabaseService.client
            .from('ads')
            .stream(primaryKey: ['id'])
            .eq('is_active', true)
            .order('priority', ascending: false)
            .asyncMap((list) async {
              final remoteAds = list.map((item) => AdModel.fromMap(item, item['id'].toString())).toList();
              
              // Mise à jour silencieuse du cache uniquement si non vide
              if (remoteAds.isNotEmpty) {
                await _db.clearAds();
                for (var ad in remoteAds) {
                  await _db.upsertAd(ad);
                }
                _activeAds = remoteAds;
              }
              
              return remoteAds;
            // 🔑 Ignorer les listes vides émises par Supabase lors d'une coupure réseau
            }).where((list) => list.isNotEmpty);
      } catch (e) {
        debugPrint('⚠️ Stream activeAdsStream error (mode hors ligne): $e');
        // En cas d'erreur réseau → émettre le cache
        final fallback = await _db.getActiveAds();
        if (fallback.isNotEmpty) yield fallback;
      }
    }
  }
}
