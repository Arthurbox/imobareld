import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/models/vehicle_model.dart';
import 'package:imobareld/core/services/database_helper.dart';
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';

class VehicleController extends ChangeNotifier {
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  VehicleController() {
    // Écouter les changements de connectivité
    // Quand on passe hors ligne → recharger depuis le cache SQLite
    ConnectivityService().addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!ConnectivityService().isOnline) {
      _reloadFromCache();
    }
  }

  Future<void> _reloadFromCache() async {
    final cached = await _dbHelper.getAllVehicles();
    if (cached.isNotEmpty) {
      _vehicles = cached;
      notifyListeners();
      debugPrint('📦 Véhicules rechargés depuis le cache SQLite (hors ligne)');
    }
  }

  /// Nouvelle méthode Supabase : Compresse et télécharge les fichiers vers Supabase Storage
  Future<List<String>> compressAndUploadImages(List<XFile> images) async {
    List<String> uploadedUrls = [];
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      for (var image in images) {
        Uint8List bytes;
        if (kIsWeb) {
          bytes = await image.readAsBytes();
        } else {
          final compressed = await FlutterImageCompress.compressWithFile(
            image.path,
            quality: 85, // 85% pour garantir une excellente qualité visuelle
          );
          bytes = compressed ?? await image.readAsBytes();
        }
        final extension = p.extension(image.path).toLowerCase();
        final fileName = 'veh_${DateTime.now().microsecondsSinceEpoch}$extension';
        final path = 'vehicles/$userId/$fileName';

        final url = await supabaseService.uploadBytes('media', path, bytes);
        uploadedUrls.add(url);
        debugPrint('✅ Image véhicule uploadée: $url');
      }
    } catch (e) {
      debugPrint('🚨 Erreur upload véhicule Supabase: $e');
    }
    return uploadedUrls;
  }

  /// Récupérer tous les véhicules via Supabase (avec cache local)
  Future<void> fetchVehicles({String? category, String? city}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier la connexion
      if (!_connectivity.isOnline) {
        debugPrint('⚠️ Offline: Loading vehicles from SQLite');
        if (city != null) {
          _vehicles = await _dbHelper.getVehiclesByCity(city);
        } else {
          _vehicles = await _dbHelper.getAllVehicles();
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      var query = supabaseService.client.from('vehicles').select();
      
      if (category != null && category != 'Tous') query = query.eq('category', category);
      if (city != null && city != 'Toutes les villes') query = query.eq('city', city);
      
      final List<dynamic> data = await query.order('created_at', ascending: false);
      _vehicles = data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();

      // Mettre à jour le cache local
      for (var vehicle in _vehicles) {
        await _dbHelper.upsertVehicle(vehicle);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des véhicules Supabase: $e');
      
      // Fallback SQLite en cas d'erreur réseau
      if (city != null) {
        _vehicles = await _dbHelper.getVehiclesByCity(city);
      } else {
        _vehicles = await _dbHelper.getAllVehicles();
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajouter un nouveau véhicule via Supabase
  Future<bool> addVehicle(VehicleModel vehicle) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      final Map<String, dynamic> vehicleData = vehicle.toMap();
      vehicleData.remove('id');
      vehicleData['owner_id'] = userId;
      
      final response = await supabaseService.client.from('vehicles').insert(vehicleData).select().single();
      final newVehicle = VehicleModel.fromMap(response, response['id'].toString());
      _vehicles.insert(0, newVehicle);
      
      // Update local cache
      await _dbHelper.upsertVehicle(newVehicle);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du véhicule Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour un véhicule existant via Supabase
  Future<bool> updateVehicle(VehicleModel vehicle) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await supabaseService.client
          .from('vehicles')
          .update(vehicle.toMap())
          .eq('id', vehicle.id)
          .select()
          .single();
          
      final updatedVehicle = VehicleModel.fromMap(response, response['id'].toString());
      
      int index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
      }

      // Update local cache
      await _dbHelper.upsertVehicle(updatedVehicle);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du véhicule Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Compresser et télécharger une vidéo vers Supabase Storage
  Future<String?> compressAndUploadVideo(XFile video) async {
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return null;

      Uint8List bytes;
      String? extension = p.extension(video.path).toLowerCase();
      if (extension.isEmpty) extension = '.mp4';

      if (kIsWeb) {
        // Sur Web, on ne compresse pas (video_compress n'est pas compatible)
        bytes = await video.readAsBytes();
      } else {
        // Sur Mobile, on compresse
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          video.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        
        if (mediaInfo != null && mediaInfo.file != null) {
          bytes = await mediaInfo.file!.readAsBytes();
        } else {
          return null;
        }
      }
      
      final fileName = 'vid_veh_${DateTime.now().microsecondsSinceEpoch}$extension';
      final path = 'vehicles/$userId/videos/$fileName';
      
      final url = await supabaseService.uploadBytes('media', path, bytes);
      return url;
    } catch (e) {
      debugPrint('Err compressAndUploadVideo véhicule: $e');
    }
    return null;
  }

  /// Supprimer un véhicule via Supabase
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabaseService.client.from('vehicles').delete().eq('id', vehicleId);
      await _dbHelper.deleteVehicle(vehicleId);
      
      _vehicles.removeWhere((v) => v.id == vehicleId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du véhicule Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupérer les véhicules d'un propriétaire spécifique via Supabase
  Future<List<VehicleModel>> getVehiclesByOwner(String ownerId) async {
    try {
      final data = await supabaseService.client
          .from('vehicles')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      return data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Erreur getVehiclesByOwner Supabase: $e');
    }
    return [];
  }

  /// Récupérer les véhicules par ville (pour l'admin)
  Future<List<VehicleModel>> getVehiclesByCity(String city) async {
    try {
      final data = await supabaseService.client
          .from('vehicles')
          .select()
          .eq('city', city)
          .order('created_at', ascending: false);
      return data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getVehiclesByCity Supabase: $e');
    }
    return [];
  }

  /// Récupérer tous les véhicules (pour l'admin)
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final data = await supabaseService.client.from('vehicles').select().order('created_at', ascending: false);
      return data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getVehicles Supabase: $e');
    }
    return [];
  }

  /// Flux de tous les véhicules (Temps Réel avec fallback SQLite)
  Stream<List<VehicleModel>> getVehiclesStream({int? limit}) async* {
    // 1. Emettre le cache d'abord
    final cached = await _dbHelper.getAllVehicles();
    if (limit != null) {
      yield cached.take(limit).toList();
    } else {
      yield cached;
    }

    // 2. Si En-ligne, écouter Supabase
    if (_connectivity.isOnline) {
      try {
        var query = supabaseService.client.from('vehicles').stream(primaryKey: ['id']).order('created_at', ascending: false);
        if (limit != null) {
          query = query.limit(limit);
        }

        yield* query.map((data) {
          final results = data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();
          
          // Mise à jour asynchrone du cache uniquement si la liste n'est pas vide
          if (results.isNotEmpty) {
            for (var v in results) {
              _dbHelper.upsertVehicle(v);
            }
            _vehicles = results;
          }
          
          return results;
        // 🔑 Ignorer les listes vides émises par Supabase lors d'une coupure réseau
        }).where((list) => list.isNotEmpty);
      } catch (e) {
        debugPrint('⚠️ Stream getVehiclesStream error (mode hors ligne): $e');
        // En cas d'erreur réseau → émettre le cache
        final cached = await _dbHelper.getAllVehicles();
        if (cached.isNotEmpty) yield cached;
      }
    }
  }

  /// Flux des véhicules filtrés par ville (Temps Réel avec fallback SQLite)
  Stream<List<VehicleModel>> vehiclesByCityStream(String city) async* {
    // 1. Emettre le cache
    final cached = await _dbHelper.getVehiclesByCity(city);
    yield cached;

    // 2. Si En-ligne, écouter Supabase
    if (_connectivity.isOnline) {
      try {
        yield* supabaseService.client
            .from('vehicles')
            .stream(primaryKey: ['id'])
            .eq('city', city)
            .order('created_at', ascending: false)
            .map((data) {
              final results = data.map((item) => VehicleModel.fromMap(item, item['id'].toString())).toList();
              
              // Mise à jour asynchrone du cache uniquement si non vide
              if (results.isNotEmpty) {
                for (var v in results) {
                  _dbHelper.upsertVehicle(v);
                }
              }
              
              return results;
            // 🔑 Ignorer les listes vides émises lors d'une coupure réseau
            }).where((list) => list.isNotEmpty);
      } catch (e) {
        debugPrint('⚠️ Stream vehiclesByCityStream error (mode hors ligne): $e');
        final cached = await _dbHelper.getVehiclesByCity(city);
        if (cached.isNotEmpty) yield cached;
      }
    }
  }
}
