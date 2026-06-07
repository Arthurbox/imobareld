import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/comment_model.dart';
import 'package:imobareld/models/review_model.dart';
import 'package:imobareld/core/services/notification_service.dart';
import 'package:imobareld/core/services/database_helper.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/core/services/connectivity_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

import 'package:path/path.dart' as p;

class PropertyController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;

  // Compteur incrémenté à chaque publication/modification pour forcer le rechargement des flux
  int _streamVersion = 0;
  List<String>? _validPropertyColumns;
  int get streamVersion => _streamVersion;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();

  RealtimeChannel? _likesChannel;
  final Map<String, int> _realtimeLikesCount = {};

  PropertyController() {
    _initRealtimeLikes();
  }

  int getLikesCount(String propertyId, int fallbackCount) {
    return _realtimeLikesCount[propertyId] ?? fallbackCount;
  }

  void _initRealtimeLikes() {
    if (_likesChannel != null) return;
    
    _likesChannel = supabaseService.client.channel('public:property_likes');
    _likesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'property_likes',
          callback: (payload) async {
            final eventType = payload.eventType.name.toUpperCase();
            if (eventType == 'INSERT' || eventType == 'DELETE') {
              final propertyId = payload.oldRecord['property_id'] ?? payload.newRecord['property_id'];
              if (propertyId != null) {
                final pId = propertyId.toString();
                // Fetch the new absolute count to prevent race condition drifts
                try {
                  final dynamic countResponse = await supabaseService.client
                      .from('property_likes')
                      .select('property_id')
                      .eq('property_id', pId)
                      .count(CountOption.exact);
                  
                  _realtimeLikesCount[pId] = countResponse.count ?? 0;
                  notifyListeners();
                } catch (e) {
                  debugPrint('Erreur synchro realtime likes: $e');
                }
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _likesChannel?.unsubscribe();
    super.dispose();
  }

  /// Nouvelle méthode Supabase : Compresse et télécharge les fichiers vers Supabase Storage
  Future<List<String>> compressAndUploadImages(List<XFile> images) async {
    List<String> uploadedUrls = [];
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final extension = p.extension(image.path).toLowerCase();
        final fileName = 'prop_${DateTime.now().microsecondsSinceEpoch}$extension';
        final path = 'properties/$userId/$fileName';

        final url = await supabaseService.uploadBytes('media', path, bytes);
        uploadedUrls.add(url);
        debugPrint('✅ Image uploadée: $url');
      }
    } catch (e) {
      debugPrint('🚨 Erreur upload Supabase: $e');
    }
    return uploadedUrls;
  }

  /// Récupérer les noms des colonnes valides pour la table properties (cache)
  Future<List<String>> _getValidPropertyColumns() async {
    if (_validPropertyColumns != null) return _validPropertyColumns!;
    try {
      final res = await supabaseService.client.from('properties').select().limit(1).maybeSingle();
      if (res != null) {
        _validPropertyColumns = res.keys.toList();
        debugPrint('🔍 Schéma détecté: $_validPropertyColumns');
        return _validPropertyColumns!;
      }
    } catch (e) {
      debugPrint('⚠️ Impossible de détecter le schéma: $e');
    }
    // Fallback sur les colonnes standards essentielles
    return ['owner_id', 'title', 'description', 'category', 'price', 'city', 'quartier', 'images', 'pieces'];
  }

  /// Ajouter une propriété via Supabase
  Future<bool> addProperty(PropertyModel property) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      // Découverte du schéma réel de la table
      final validColumns = await _getValidPropertyColumns();
      
      // Filtrage intelligent
      final Map<String, dynamic> propertyData = property.toFilteredMap(validColumns);
      propertyData.remove('id'); // Supabase génère l'UUID
      propertyData['owner_id'] = userId; 

      final response = await supabaseService.client.from('properties').insert(propertyData).select().single();
      final newId = response['id'].toString();

      try {
        await NotificationService().showNewPropertyNotification(
          propertyId: newId,
          title: property.title,
          category: property.category,
          city: property.city,
          quartier: property.quartier,
          price: property.price,
          imageBase64: property.images.isNotEmpty ? property.images.first : null,
        );
      } catch (notifError) {
        debugPrint('⚠️ Erreur notification: $notifError');
      }
      
      _isLoading = false;
      _streamVersion++; // Forcer le rechargement des flux
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur ajout propriété Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour une propriété via Supabase
  Future<bool> updateProperty(PropertyModel property) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Découverte du schéma réel de la table
      final validColumns = await _getValidPropertyColumns();
      
      // Filtrage intelligent
      final Map<String, dynamic> updateData = property.toFilteredMap(validColumns);
      updateData.remove('id'); // Ne pas updater l'ID
      updateData.remove('created_at'); // Ne pas updater la date de création

      await supabaseService.client
          .from('properties')
          .update(updateData)
          .eq('id', property.id!);

      _isLoading = false;
      _streamVersion++; // Forcer le rechargement des flux
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur mise à jour Supabase: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupérer les propriétés via Supabase
  Future<List<PropertyModel>> getProperties({int? limit}) async {
    try {
      var query = supabaseService.client.from('properties').select().order('created_at', ascending: false);
      if (limit != null) query = query.limit(limit);
      
      final data = await query;
      return data.map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Erreur getProperties Supabase: $e');
    }
    return [];
  }

  /// Récupérer les propriétés par ville
  Future<List<PropertyModel>> getPropertiesByCity(String city) async {
    try {
      final data = await supabaseService.client
          .from('properties')
          .select()
          .eq('city', city)
          .order('created_at', ascending: false);
      return data.map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getPropertiesByCity Supabase: $e');
    }
    return [];
  }

  /// Récupérer les propriétés par catégorie
  Future<List<PropertyModel>> getPropertiesByCategory(String category, {int? limit}) async {
    return getFilteredProperties(category: category, limit: limit);
  }

  // PAGINATION
  List<PropertyModel> _pagedProperties = [];
  List<PropertyModel> get pagedProperties => _pagedProperties;
  int _currentPage = 0;
  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// Charger les propriétés avec pagination via Supabase (avec cache local)
  Future<void> fetchPagedProperties({bool refresh = false, String? category}) async {
    const int pageSize = 10;
    
    if (refresh) {
      _currentPage = 0; 
      _pagedProperties = [];
      _hasMore = true;
      notifyListeners();
    }
    if (!_hasMore || _isFetchingMore) return;

    // Mode Hors-ligne
    if (!_connectivity.isOnline) {
      debugPrint('⚠️ Offline: Loading properties from SQLite');
      _isFetchingMore = true;
      notifyListeners();
      
      final List<PropertyModel> cached;
      if (category != null && category != 'Tous') {
        cached = await _dbHelper.getPropertiesByCategory(category);
      } else {
        cached = await _dbHelper.getAllProperties();
      }
      
      _pagedProperties = cached;
      _hasMore = false; // Pas de pagination réelle en mode hors-ligne pour l'instant
      _isFetchingMore = false;
      notifyListeners();
      return;
    }

    _isFetchingMore = true;
    notifyListeners();

    try {
      final dynamic query = supabaseService.client.from('properties').select();
      dynamic filteredQuery = query;
      if (category != null && category != 'Tous') filteredQuery = query.eq('category', category);
      
      final from = _currentPage * pageSize;
      final to = from + pageSize - 1;
      
      final List<dynamic> data = await filteredQuery.range(from, to).order('created_at', ascending: false);
      
      if (data.length < pageSize) _hasMore = false;

      final newProps = data.map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();
      _pagedProperties.addAll(newProps);
      
      // Mettre à jour le cache local
      for (var prop in newProps) {
        await _dbHelper.upsertProperty(prop);
      }
      
      _currentPage++;
    } catch (e) {
      debugPrint('Err pagination Supabase: $e');
      // Tentative de fallback sur le cache au moins pour la première page
      if (_pagedProperties.isEmpty) {
        final cached = await _dbHelper.getAllProperties();
        _pagedProperties = cached;
      }
      _hasMore = false;
    }
    
    _isFetchingMore = false;
    notifyListeners();
  }

  /// Récupérer les propriétés filtrées via Supabase (avec cache local)
  Future<List<PropertyModel>> getFilteredProperties({
    String? category,
    String? city,
    String? quartier,
    double? minPrice,
    double? maxPrice,
    int? minPieces,
    List<String>? requiredAmenities,
    String? searchQuery,
    int? limit,
  }) async {
    // Mode Hors-ligne
    if (!_connectivity.isOnline) {
      debugPrint('⚠️ Offline: Loading filtered properties from SQLite');
      if (category != null && category != 'Tous' && category != 'Toutes') {
        return await _dbHelper.getPropertiesByCategory(category);
      }
      if (quartier != null && quartier != 'Tous') {
        return await _dbHelper.getPropertiesByQuartier(quartier);
      }
      return await _dbHelper.getAllProperties();
    }

    try {
      final dynamic filterQueryBase = supabaseService.client.from('properties').select();
      dynamic filterQuery = filterQueryBase;

      // FILTRAGE SERVEUR EXCLUSIF (Performance Maximale)
      if (category != null && category != 'Toutes' && category != 'Tous') {
        filterQuery = filterQuery.eq('category', category);
      }
      if (city != null && city != 'Toutes les villes' && city != 'Toutes') {
        filterQuery = filterQuery.eq('city', city);
      }
      if (quartier != null && quartier != 'Tous') {
        filterQuery = filterQuery.eq('quartier', quartier);
      }
      if (minPrice != null && minPrice > 0) {
        filterQuery = filterQuery.gte('price', minPrice);
      }
      if (maxPrice != null && maxPrice < 1000000000) {
        filterQuery = filterQuery.lte('price', maxPrice);
      }
      if (minPieces != null && minPieces > 0) {
        filterQuery = filterQuery.gte('pieces', minPieces);
      }
      
      if (requiredAmenities != null && requiredAmenities.isNotEmpty) {
        filterQuery = filterQuery.contains('amenities', requiredAmenities);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filterQuery = filterQuery.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,quartier.ilike.%$searchQuery%');
      }

      dynamic transformQuery = filterQuery.order('created_at', ascending: false);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      final data = await transformQuery;
      final results = (data as List).map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();
      
      // Mettre à jour le cache local
      for (var prop in results) {
        await _dbHelper.upsertProperty(prop);
      }
      
      return results;
    } catch (e) {
      debugPrint('🚨 Erreur Fatale getFilteredProperties: $e');
      return await _dbHelper.getAllProperties(); // Fallback ultime
    }
  }

  /// Flux temps réel pour la page de Recherche (avec fallback offline)
  Stream<List<PropertyModel>> getFilteredPropertiesStream({
    String? category,
    String? city,
    String? quartier,
    double? minPrice,
    double? maxPrice,
    int? minPieces,
    String? searchQuery,
  }) async* {
    // 1. Émettre le cache local immédiatement
    final List<PropertyModel> cached;
    if (category != null && category != 'Toutes' && category != 'Tous') {
      cached = await _dbHelper.getPropertiesByCategory(category);
    } else {
      cached = await _dbHelper.getAllProperties();
    }
    
    // Filtrage local simple du cache
    var currentList = cached;
    if (city != null && city != 'Toutes les villes' && city != 'Toutes') {
      currentList = currentList.where((p) => p.city == city).toList();
    }
    yield currentList;

    // 2. Si En-ligne, écouter Supabase
    if (_connectivity.isOnline) {
      try {
        final dynamic query = supabaseService.client.from('properties').stream(primaryKey: ['id']);
        dynamic filteredQuery = query;
        if (category != null && category != 'Toutes' && category != 'Tous') {
          filteredQuery = query.eq('category', category);
        }

        // .where() ignore les listes vides émises au moment de la déconnexion
        // .handleError() évite que l'erreur remonte au StreamBuilder et vide l'UI
        yield* (filteredQuery as Stream<List<Map<String, dynamic>>>)
            .where((data) => data.isNotEmpty)
            .handleError((e) {
              debugPrint('⚠️ Stream Filtered (handled): $e');
            })
            .map((List<Map<String, dynamic>> data) {
              List<PropertyModel> properties = data.map((item) => PropertyModel.fromMap(item, item['id']?.toString() ?? '')).toList();

              if (city != null && city != 'Toutes les villes' && city != 'Toutes') {
                properties = properties.where((p) => p.city == city).toList();
              }
              if (quartier != null && quartier != 'Tous') {
                properties = properties.where((p) => p.quartier == quartier).toList();
              }
              if (minPrice != null) {
                properties = properties.where((p) => p.price >= minPrice).toList();
              }
              if (maxPrice != null) {
                properties = properties.where((p) => p.price <= maxPrice).toList();
              }
              if (minPieces != null) {
                properties = properties.where((p) => p.pieces >= minPieces).toList();
              }
              if (searchQuery != null && searchQuery.isNotEmpty) {
                final queryLower = searchQuery.toLowerCase();
                properties = properties.where((p) =>
                  p.title.toLowerCase().contains(queryLower) ||
                  p.description.toLowerCase().contains(queryLower) ||
                  p.quartier.toLowerCase().contains(queryLower)
                ).toList();
              }

              return properties;
            });
      } catch (e) {
        debugPrint('⚠️ Stream Filtered setup error: $e');
      }
    }
  }

  /// Flux pour les sections de la page d'accueil (avec fallback offline)
  Stream<List<PropertyModel>> getPropertiesStream({
    required String category,
    String? city,
    int limit = 5,
  }) async* {
    // 1. Émettre le cache local immédiatement
    final cached = await _dbHelper.getPropertiesByCategory(category);
    var currentList = cached;
    if (city != null && city != 'Toutes les villes' && city != 'Toutes') {
      currentList = currentList.where((p) => p.city == city).toList();
    }
    yield currentList.take(limit).toList();

    // 2. Si En-ligne, écouter Supabase
    if (_connectivity.isOnline) {
      try {
        final dynamic query = supabaseService.client.from('properties').stream(primaryKey: ['id']).eq('category', category);
        
        // .where() ignore les émissions vides liées à la perte de connexion
        // .handleError() empêche l'erreur de vider le StreamBuilder
        if (city != null && city != 'Toutes les villes' && city != 'Toutes') {
          yield* (query as Stream<List<Map<String, dynamic>>>)
              .where((data) => data.isNotEmpty)
              .handleError((e) => debugPrint('⚠️ getPropertiesStream (handled): $e'))
              .map((data) {
                final filtered = data.where((item) => item['city'] == city).take(limit);
                return filtered.map((item) => PropertyModel.fromMap(item, item['id']?.toString() ?? '')).toList();
              });
        } else {
          yield* (query as Stream<List<Map<String, dynamic>>>)
              .where((data) => data.isNotEmpty)
              .handleError((e) => debugPrint('⚠️ getPropertiesStream (handled): $e'))
              .map((data) => data.take(limit).map((item) => PropertyModel.fromMap(item, item['id']?.toString() ?? '')).toList());
        }
      } catch (e) {
        debugPrint('⚠️ Stream Home setup error: $e');
      }
    }
  }

  /// Flux des propriétés filtrées par ville (Temps Réel avec fallback SQLite, pour Admin)
  Stream<List<PropertyModel>> propertiesByCityStream(String city) async* {
    var cached = await _dbHelper.getAllProperties();
    if (city != 'Toutes les villes' && city != 'Toutes') {
      cached = cached.where((p) => p.city == city).toList();
    }
    yield cached;

    if (_connectivity.isOnline) {
      try {
        final dynamic query = supabaseService.client.from('properties').stream(primaryKey: ['id']);
        dynamic filteredQuery = (city == 'Toutes les villes' || city == 'Toutes') ? query : query.eq('city', city);
        
        yield* (filteredQuery as Stream<List<Map<String, dynamic>>>)
            .where((data) => data.isNotEmpty)
            .handleError((e) => debugPrint('⚠️ propertiesByCityStream (handled): $e'))
            .map((data) {
              final results = data.map((item) => PropertyModel.fromMap(item, item['id']?.toString() ?? '')).toList();
              for (var p in results) {
                _dbHelper.upsertProperty(p);
              }
              return results;
            });
      } catch (e) {
        debugPrint('⚠️ Stream propertiesByCityStream setup error: $e');
      }
    }
  }

  /// Récupérer les propriétés d'un propriétaire
  Future<List<PropertyModel>> getPropertiesByOwner(String ownerId) async {
    try {
      final data = await supabaseService.client
          .from('properties')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      return data.map((item) => PropertyModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getPropertiesByOwner Supabase: $e');
    }
    return [];
  }

  /// Flux temps réel des propriétés d'un propriétaire (pour OwnerDashboard)
  Stream<List<PropertyModel>> getPropertiesByOwnerStream(String ownerId) {
    return supabaseService.client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((item) => PropertyModel.fromMap(item, item['id'].toString()))
            .toList());
  }

  /// Supprimer une propriété
  Future<bool> deleteProperty(String propertyId) async {
    try {
      await supabaseService.client.from('properties').delete().eq('id', propertyId);
      return true;
    } catch (e) {
      debugPrint('Err deleteProperty Supabase: $e');
      return false;
    }
  }

  // --- COMMENTAIRES ET AVIS ---

  /// Ajouter un commentaire via Supabase (avec retour booléen propre)
  Future<bool> addComment(CommentModel comment) async {
    try {
      await supabaseService.client.from('comments').insert(comment.toMap());
      return true;
    } catch (e) {
      debugPrint('Err addComment Supabase: $e');
      return false;
    }
  }

  /// Récupérer les commentaires d'un bien en Temps Réel (STREAM)
  Stream<List<CommentModel>> getCommentsStream(String propertyId) {
    return supabaseService.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => CommentModel.fromMap(item, item['id'].toString())).toList());
  }

  /// Récupérer les commentaires d'un bien
  Future<List<CommentModel>> getComments(String propertyId) async {
    try {
      final data = await supabaseService.client
          .from('comments')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return data.map((item) => CommentModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getComments Supabase: $e');
    }
    return [];
  }

  /// Ajouter un avis via Supabase
  Future<bool> addReview(ReviewModel review) async {
    try {
      await supabaseService.client.from('reviews').insert(review.toMap());
      return true;
    } catch (e) {
      debugPrint('Err addReview Supabase: $e');
      return false;
    }
  }

  /// Récupérer les avis d'un bien
  Future<List<ReviewModel>> getReviews(String propertyId) async {
    try {
      final data = await supabaseService.client
          .from('reviews')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return data.map((item) => ReviewModel.fromMap(item, item['id'].toString())).toList();
    } catch (e) {
      debugPrint('Err getReviews Supabase: $e');
    }
    return [];
  }

  /// Booster une propriété
  Future<bool> boostProperty(String propertyId, int durationDays, String planType) async {
    try {
      _isLoading = true; notifyListeners();
      final expiryDate = DateTime.now().add(Duration(days: durationDays));
      
      await supabaseService.client.from('properties').update({
        'is_boosted': true,
        'boost_expiry_date': expiryDate.toIso8601String(),
        'boost_plan_type': planType,
      }).eq('id', propertyId);

      // Récupérer le titre de la propriété pour la notification
      try {
        final propertyData = await supabaseService.client
            .from('properties')
            .select('title')
            .eq('id', propertyId)
            .single();
        
        final String title = propertyData['title'] ?? 'Votre annonce';
        
        // Planifier les rappels (48h, 24h, Fin)
        await NotificationService().scheduleBoostExpiryNotifications(
          propertyId: propertyId,
          propertyTitle: title,
          expiryDate: expiryDate,
        );
      } catch (e) {
        debugPrint('⚠️ Erreur planification notifications boost: $e');
        // On n'arrête pas le processus si seule la notification échoue
      }
      
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Err boostProperty Supabase: $e');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // --- FAVORIS (SQLite local + SharedPreferences) ---

  /// Charger les favoris depuis Supabase (Table property_likes)
  Future<void> loadFavorites() async {
    final userId = supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final List<dynamic> data = await supabaseService.client
          .from('property_likes')
          .select('property_id')
          .eq('user_id', userId);
      
      final List<String> serverIds = data.map((item) => item['property_id'].toString()).toList();
      
      _favoriteIds.clear();
      _favoriteIds.addAll(serverIds);

      // Sync local SQLite
      await _dbHelper.clearFavorites(userId);
      for (String id in serverIds) {
        await _dbHelper.addFavorite(userId, id);
      }
    } catch (e) {
      debugPrint('Err loadFavorites Supabase: $e');
      final ids = await _dbHelper.getFavorites(userId);
      _favoriteIds.clear(); _favoriteIds.addAll(ids);
    }
    notifyListeners();
  }

  /// Toggle Favorite via Supabase
  Future<Map<String, dynamic>?> toggleFavorite(PropertyModel property) async {
    final userId = supabaseService.client.auth.currentUser?.id;
    if (userId == null || property.id == null) return null;

    try {
      final isCurrentlyFavorite = _favoriteIds.contains(property.id);
      final pId = property.id!;
      
      // OPTIMISTIC UPDATE
      final currentCount = getLikesCount(pId, property.likesCount);
      _realtimeLikesCount[pId] = isCurrentlyFavorite ? (currentCount > 0 ? currentCount - 1 : 0) : currentCount + 1;
      
      if (isCurrentlyFavorite) {
        _favoriteIds.remove(pId);
        notifyListeners();
        
        await supabaseService.client
            .from('property_likes')
            .delete()
            .eq('user_id', userId)
            .eq('property_id', pId);
        
        await _dbHelper.removeFavorite(userId, pId);
      } else {
        _favoriteIds.add(pId);
        notifyListeners();
        
        await supabaseService.client.from('property_likes').insert({
          'user_id': userId,
          'property_id': pId,
        });
        
        await _dbHelper.addFavorite(userId, pId);
        await _dbHelper.upsertProperty(property);
      }

      // Fetch the true absolute count
      final dynamic countResponse = await supabaseService.client
          .from('property_likes')
          .select('id')
          .eq('property_id', pId)
          .count(CountOption.exact);
      
      final int newCount = countResponse.count ?? 0;
      _realtimeLikesCount[pId] = newCount;
      
      notifyListeners();
      return {'isLiked': !isCurrentlyFavorite, 'likesCount': newCount};
    } catch (e) {
      debugPrint('🚨 Erreur toggle favorite Supabase: $e');
    }
    return null;
  }

  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  Future<List<PropertyModel>> getFavoriteProperties() async {
    final userId = supabaseService.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final List<dynamic> data = await supabaseService.client
          .from('property_likes')
          .select('properties(*)') 
          .eq('user_id', userId);
      
      return data.map((item) {
        final propData = item['properties'];
        return PropertyModel.fromMap(propData, propData['id'].toString());
      }).toList();
    } catch (e) {
      debugPrint('Err getFavoriteProperties Supabase: $e');
    }

    // Fallback SQLite
    final ids = await _dbHelper.getFavorites(userId);
    List<PropertyModel> favorites = [];
    for (String id in ids) {
      final prop = await _dbHelper.getPropertyById(id);
      if (prop != null) favorites.add(prop);
    }
    return favorites;
  }

  /// Mettre à jour les images d'une propriété (via Multipart)
  Future<List<String>?> updatePropertyImages(String propertyId, List<XFile> images) async {
    try {
      final List<String> uploadedUrls = await compressAndUploadImages(images);
      if (uploadedUrls.isEmpty) return null;

      final response = await supabaseService.client.from('properties').select('images').eq('id', propertyId).single();
      final List<String> existingImages = List<String>.from(response['images'] ?? []);
      final List<String> finalImages = [...existingImages, ...uploadedUrls];

      await supabaseService.client.from('properties').update({
        'images': finalImages,
      }).eq('id', propertyId);
      
      _streamVersion++;
      notifyListeners();
      return finalImages;
    } catch (e) {
      debugPrint('Erreur updatePropertyImages: $e');
      return null;
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
      
      final fileName = 'vid_${DateTime.now().microsecondsSinceEpoch}$extension';
      final path = 'properties/$userId/videos/$fileName';
      
      final url = await supabaseService.uploadBytes('media', path, bytes);
      return url;
    } catch (e) {
      debugPrint('Err compressAndUploadVideo Supabase: $e');
    }
    return null;
  }

  /// Mettre à jour la vidéo d'une propriété via Supabase
  Future<List<String>?> updatePropertyVideo(String propertyId, XFile video) async {
    try {
      debugPrint('Début updatePropertyVideo pour $propertyId');
      final String? videoUrl = await compressAndUploadVideo(video);
      if (videoUrl == null) return null;

      final response = await supabaseService.client.from('properties').select('video_urls').eq('id', propertyId).single();
      final List<String> existingVideos = List<String>.from(response['video_urls'] ?? []);
      final List<String> finalVideos = [...existingVideos, videoUrl];

      await supabaseService.client.from('properties').update({
        'video_urls': finalVideos,
      }).eq('id', propertyId);

      _streamVersion++;
      notifyListeners();
      return finalVideos;
    } catch (e) {
      debugPrint('Err updatePropertyVideo Supabase: $e');
      return null;
    }
  }
}
