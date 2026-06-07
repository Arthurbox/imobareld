import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imobareld/models/announcement_model.dart';
import 'package:imobareld/core/services/supabase_service.dart';

class AnnouncementController extends ChangeNotifier {
  
  // 0. STREAMS EN TEMPS RÉEL (Supabase Realtime)
  
  /// Flux des annonces de la communauté (Annonce & Recherche)
  Stream<List<AnnouncementModel>> get announcementsStream {
    return supabaseService.client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.map((item) => AnnouncementModel.fromMap(item, item['id'].toString())).toList());
  }
  
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  /// Récupérer le flux d'annonces via Supabase
  Future<void> fetchAnnouncements({bool silent = false}) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      final List<dynamic> data = await supabaseService.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      _announcements = data.map((item) => AnnouncementModel.fromMap(item, item['id'].toString())).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des annonces Supabase: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Publier une annonce
  Future<bool> postAnnouncement(AnnouncementModel announcement) async {
    try {
      _isLoading = true;
      notifyListeners();

      final Map<String, dynamic> data = announcement.toMap();
      data.remove('id');
      
      final response = await supabaseService.client.from('announcements').insert(data).select().single();
      final newAnn = AnnouncementModel.fromMap(response, response['id'].toString());
      _announcements.insert(0, newAnn);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la publication de l\'annonce Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Modifier une annonce
  Future<bool> editAnnouncement(String id, String newContent) async {
    try {
      await supabaseService.client.from('announcements').update({
        'content': newContent,
      }).eq('id', id);

      int index = _announcements.indexWhere((a) => a.id == id);
      if (index != -1) {
        _announcements[index] = _announcements[index].copyWith(content: newContent);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la modification Supabase: $e');
      return false;
    }
  }

  /// Supprimer une annonce
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await supabaseService.client.from('announcements').delete().eq('id', id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression Supabase: $e');
      return false;
    }
  }
}
