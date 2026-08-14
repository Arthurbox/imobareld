import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/realisation_model.dart';
import 'package:path/path.dart' as p;
import 'package:imobareld/core/services/database_helper.dart';
import 'package:imobareld/core/services/connectivity_service.dart';

class RealisationController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RealisationModel> _realisations = [];
  List<RealisationModel> get realisations => _realisations;

  RealisationController() {
    ConnectivityService().addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!ConnectivityService().isOnline) {
      _reloadFromCache();
    }
  }

  Future<void> _reloadFromCache() async {
    final cached = await _db.getAllRealisations();
    if (cached.isNotEmpty) {
      _realisations = cached;
      notifyListeners();
      debugPrint('📦 Réalisations rechargées depuis le cache SQLite (hors ligne)');
    }
  }

  Future<List<RealisationModel>> getRealisations() async {
    final cached = await _db.getAllRealisations();
    if (cached.isNotEmpty) {
      _realisations = cached;
      notifyListeners();
    }

    if (_connectivity.isOnline) {
      try {
        final List<dynamic> data = await supabaseService.client
            .from('realisations')
            .select()
            .order('created_at', ascending: false);
        
        final remote = data.map((item) => RealisationModel.fromMap(item)).toList();
        
        await _db.clearRealisations();
        for (var r in remote) {
          await _db.upsertRealisation(r);
        }
        
        _realisations = remote;
        notifyListeners();
        return remote;
      } catch (e) {
        debugPrint('Erreur récupération réalisations Supabase: $e');
      }
    }
    
    return _realisations;
  }

  Future<String?> uploadMedia(XFile file) async {
    try {
      _isLoading = true;
      notifyListeners();

      final bytes = await file.readAsBytes();
      String extension = p.extension(file.path).toLowerCase();

      if (extension.isEmpty) extension = '.jpg';
      final fileName = 'realisation_${DateTime.now().microsecondsSinceEpoch}$extension';
      final path = 'realisations/$fileName';

      final url = await supabaseService.uploadBytes('media', path, bytes);
      
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint('Erreur upload realisation media: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> generateThumbnail(XFile video) async {
    try {
      if (kIsWeb) return null;
      
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 50,
        position: -1,
      );
      
      final bytes = await thumbnailFile.readAsBytes();
      final fileName = 'thumb_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final path = 'realisations/thumbnails/$fileName';
      
      return await supabaseService.uploadBytes('media', path, bytes);
    } catch (e) {
      debugPrint('Erreur génération miniature: $e');
      return null;
    }
  }

  Future<String?> compressAndUploadVideo(XFile video) async {
    try {
      if (kIsWeb) return await uploadMedia(video);
      
      _isLoading = true;
      notifyListeners();

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        video.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
      );
      
      final bytes = mediaInfo != null && mediaInfo.file != null 
          ? await mediaInfo.file!.readAsBytes() 
          : await video.readAsBytes();
      String extension = p.extension(video.path).toLowerCase();
      if (extension.isEmpty) extension = '.mp4';
      
      final fileName = 'realisation_vid_${DateTime.now().microsecondsSinceEpoch}$extension';
      final path = 'realisations/$fileName';

      final url = await supabaseService.uploadBytes(
        'media', 
        path, 
        bytes,
        contentType: 'video/mp4', // Spécifier explicitement le Content-Type
      );
      
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint('Erreur compression/upload vidéo: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addRealisation(RealisationModel realisation) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabaseService.client.from('realisations').insert(realisation.toMap());

      // Fetch latest
      await getRealisations();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur ajout réalisation: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRealisation(String id) async {
    try {
      await supabaseService.client.from('realisations').delete().eq('id', id);
      await _db.deleteRealisation(id);
      
      _realisations.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur suppression réalisation: $e');
      return false;
    }
  }

  Stream<List<RealisationModel>> get realisationsStream async* {
    final cached = await _db.getAllRealisations();
    if (cached.isNotEmpty) yield cached;

    if (_connectivity.isOnline) {
      try {
        yield* supabaseService.client
            .from('realisations')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .asyncMap((list) async {
              final remote = list.map((item) => RealisationModel.fromMap(item)).toList();
              
              // Toujours mettre à jour le cache et la liste locale, même si vide
              await _db.clearRealisations();
              for (var r in remote) {
                await _db.upsertRealisation(r);
              }
              _realisations = remote;
              
              return remote;
            })
            .handleError((e) {
              debugPrint('⚠️ Stream realisation error (handled): $e');
            });
      } catch (e) {
        debugPrint('⚠️ Stream realisation error: $e');
      }
    }
  }
}
