import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:imobareld/models/property_model.dart';

import 'package:imobareld/models/ad_model.dart';
import 'package:imobareld/models/realisation_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service de gestion de la base de données SQLite locale
/// Permet le stockage hors ligne des propriétés
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Récupère l'instance de la base de données
  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'imobareld.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables lors de la première création
  Future<void> _onCreate(Database db, int version) async {
    // Table des propriétés
    await db.execute('''
      CREATE TABLE properties (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        quartier TEXT NOT NULL,
        images TEXT NOT NULL,
        pieces INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        likesCount INTEGER DEFAULT 0,
        video_urls TEXT,
        isOwnerVerified INTEGER DEFAULT 0,
        priceDuration TEXT DEFAULT 'mois',
        amenities TEXT NOT NULL,
        isCertified INTEGER DEFAULT 0,
        averageRating REAL DEFAULT 0.0,
        reviewCount INTEGER DEFAULT 0,
        lastSyncedAt TEXT NOT NULL
      )
    ''');

    // Table des favoris (cache local)
    await db.execute('''
      CREATE TABLE favorites (
        userId TEXT NOT NULL,
        propertyId TEXT NOT NULL,
        addedAt TEXT NOT NULL,
        PRIMARY KEY (userId, propertyId)
      )
    ''');

    // Table de métadonnées de synchronisation
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Table des publicités (Ads)
    await db.execute('''
      CREATE TABLE ads (
        id TEXT PRIMARY KEY,
        imageUrl TEXT NOT NULL,
        targetUrl TEXT,
        priority INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        type TEXT DEFAULT 'image',
        createdAt TEXT NOT NULL
      )
    ''');

    // Table des véhicules (Version 4)
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        companyName TEXT NOT NULL,
        model TEXT NOT NULL,
        city TEXT NOT NULL,
        pricePerDay REAL NOT NULL,
        images TEXT NOT NULL,
        description TEXT NOT NULL,
        videoUrls TEXT,
        createdAt TEXT NOT NULL,
        lastSyncedAt TEXT NOT NULL
      )
    ''');

    // Table des réalisations (Version 5)
    await db.execute('''
      CREATE TABLE realisations (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        images TEXT NOT NULL,
        videoUrls TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Gère les migrations de schéma
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 -> v2
    }
    if (oldVersion < 3) {
      // Migration v2 -> v3 : Ajout de la table ads
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ads (
          id TEXT PRIMARY KEY,
          imageUrl TEXT NOT NULL,
          targetUrl TEXT,
          priority INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          type TEXT DEFAULT 'image',
          createdAt TEXT NOT NULL
        )
      ''');
      debugPrint('🚀 Base de données migrée vers la version 3 (Table ads ajoutée)');
    }
    if (oldVersion < 4) {
      // Migration v3 -> v4 : Ajout de la table vehicles
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicles (
          id TEXT PRIMARY KEY,
          ownerId TEXT NOT NULL,
          companyName TEXT NOT NULL,
          model TEXT NOT NULL,
          city TEXT NOT NULL,
          pricePerDay REAL NOT NULL,
          images TEXT NOT NULL,
          description TEXT NOT NULL,
          videoUrls TEXT,
          createdAt TEXT NOT NULL,
          lastSyncedAt TEXT NOT NULL
        )
      ''');
      debugPrint('🚀 Base de données migrée vers la version 4 (Table vehicles ajoutée)');
    }
    if (oldVersion < 5) {
      // Migration v4 -> v5 : Ajout de la table realisations
      await db.execute('''
        CREATE TABLE IF NOT EXISTS realisations (
          id TEXT PRIMARY KEY,
          ownerId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          images TEXT NOT NULL,
          videoUrls TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      debugPrint('🚀 Base de données migrée vers la version 5 (Table realisations ajoutée)');
    }
  }

  /// Insère ou met à jour une propriété
  Future<void> upsertProperty(PropertyModel property) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'properties',
      {
        'id': property.id,
        'ownerId': property.ownerId,
        'title': property.title,
        'description': property.description,
        'category': property.category,
        'price': property.price,
        'quartier': property.quartier,
        'images': jsonEncode(property.images),
        'pieces': property.pieces,
        'createdAt': property.createdAt.toIso8601String(),
        'latitude': property.latitude,
        'longitude': property.longitude,
        'likesCount': property.likesCount,
        'video_urls': jsonEncode(property.videoUrls),
        'isOwnerVerified': property.isOwnerVerified ? 1 : 0,
        'priceDuration': property.priceDuration,
        'amenities': jsonEncode(property.amenities),
        'isCertified': property.isCertified ? 1 : 0,
        'averageRating': property.averageRating,
        'reviewCount': property.reviewCount,
        'lastSyncedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insère ou met à jour une LISTE de propriétés en une seule transaction SQLite (optimisé)
  /// Utiliser cette méthode à la place d'une boucle for sur upsertProperty
  Future<void> batchUpsertProperties(List<PropertyModel> properties) async {
    if (kIsWeb || properties.isEmpty) return;
    final db = await database;
    if (db == null) return;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final property in properties) {
        if (property.id == null) continue;
        await txn.insert(
          'properties',
          {
            'id': property.id,
            'ownerId': property.ownerId,
            'title': property.title,
            'description': property.description,
            'category': property.category,
            'price': property.price,
            'quartier': property.quartier,
            'images': jsonEncode(property.images),
            'pieces': property.pieces,
            'createdAt': property.createdAt.toIso8601String(),
            'latitude': property.latitude,
            'longitude': property.longitude,
            'likesCount': property.likesCount,
            'video_urls': jsonEncode(property.videoUrls),
            'isOwnerVerified': property.isOwnerVerified ? 1 : 0,
            'priceDuration': property.priceDuration,
            'amenities': jsonEncode(property.amenities),
            'isCertified': property.isCertified ? 1 : 0,
            'averageRating': property.averageRating,
            'reviewCount': property.reviewCount,
            'lastSyncedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Récupère toutes les propriétés en cache
  Future<List<PropertyModel>> getAllProperties() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'properties',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _propertyFromMap(map)).toList();
  }

  /// Récupère les propriétés par catégorie
  Future<List<PropertyModel>> getPropertiesByCategory(String category) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'properties',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _propertyFromMap(map)).toList();
  }

  /// Récupère les propriétés par quartier
  Future<List<PropertyModel>> getPropertiesByQuartier(String quartier) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'properties',
      where: 'quartier = ?',
      whereArgs: [quartier],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _propertyFromMap(map)).toList();
  }

  /// Récupère une propriété par ID
  Future<PropertyModel?> getPropertyById(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    final List<Map<String, dynamic>> maps = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _propertyFromMap(maps.first);
  }

  /// Supprime une propriété
  Future<void> deleteProperty(String id) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Supprime toutes les propriétés (pour réinitialisation)
  Future<void> clearAllProperties() async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete('properties');
  }

  /// Ajoute un favori
  Future<void> addFavorite(String userId, String propertyId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert(
      'favorites',
      {
        'userId': userId,
        'propertyId': propertyId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ajoute plusieurs favoris d'un coup (Optimisé via Transaction)
  Future<void> batchAddFavorites(String userId, List<String> propertyIds) async {
    if (kIsWeb || propertyIds.isEmpty) return;
    final db = await database;
    if (db == null) return;
    
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      for (var id in propertyIds) {
        await txn.insert(
          'favorites',
          {
            'userId': userId,
            'propertyId': id,
            'addedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  Future<void> removeFavorite(String userId, String propertyId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      'favorites',
      where: 'userId = ? AND propertyId = ?',
      whereArgs: [userId, propertyId],
    );
  }

  /// Récupère les favoris d'un utilisateur
  Future<List<String>> getFavorites(String userId) async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return maps.map((map) => map['propertyId'] as String).toList();
  }

  /// Supprime tous les favoris d'un utilisateur (pour synchronisation)
  Future<void> clearFavorites(String userId) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// Sauvegarde une métadonnée de synchronisation
  Future<void> setSyncMetadata(String key, String value) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert(
      'sync_metadata',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère une métadonnée de synchronisation
  Future<String?> getSyncMetadata(String key) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  /// Convertit une map de la DB en PropertyModel
  PropertyModel _propertyFromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'],
      ownerId: map['ownerId'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      quartier: map['quartier'],
      images: List<String>.from(jsonDecode(map['images'])),
      pieces: map['pieces'],
      createdAt: DateTime.parse(map['createdAt']),
      latitude: map['latitude'],
      longitude: map['longitude'],
      likesCount: map['likesCount'] ?? 0,
      isLiked: false, // Sera mis à jour par le contrôleur si nécessaire
      videoUrls: map['video_urls'] != null ? List<String>.from(jsonDecode(map['video_urls'])) : (map['videoBase64'] != null ? [map['videoBase64']] : []),
      isOwnerVerified: map['isOwnerVerified'] == 1,
      priceDuration: map['priceDuration'] ?? 'mois',
      amenities: List<String>.from(jsonDecode(map['amenities'])),
      isCertified: map['isCertified'] == 1,
      averageRating: map['averageRating'] ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  // --- MÉTHODES POUR LES PUBLICITÉS (ADS) ---

  /// Insère ou met à jour une publicité
  Future<void> upsertAd(AdModel ad) async {
    if (kIsWeb || ad.id == null) return;
    final db = await database;
    if (db == null) return;

    await db.insert(
      'ads',
      {
        'id': ad.id,
        'imageUrl': ad.imageUrl,
        'targetUrl': ad.targetUrl,
        'priority': ad.priority,
        'isActive': ad.isActive ? 1 : 0,
        'type': ad.type,
        'createdAt': ad.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les publicités actives du cache
  Future<List<AdModel>> getActiveAds() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'ads',
      where: 'isActive = 1',
      orderBy: 'priority DESC, createdAt DESC',
    );

    return maps.map((map) => AdModel(
      id: map['id'],
      imageUrl: map['imageUrl'],
      targetUrl: map['targetUrl'],
      priority: map['priority'],
      isActive: map['isActive'] == 1,
      type: map['type'] ?? 'image',
      createdAt: DateTime.parse(map['createdAt']),
    )).toList();
  }

  /// Supprime toutes les publicités du cache
  Future<void> clearAds() async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete('ads');
  }


  // --- MÉTHODES POUR LES RÉALISATIONS ---

  Future<void> upsertRealisation(RealisationModel realisation) async {
    if (kIsWeb || realisation.id == null) return;
    final db = await database;
    if (db == null) return;

    await db.insert(
      'realisations',
      {
        'id': realisation.id,
        'ownerId': realisation.ownerId,
        'title': realisation.title,
        'description': realisation.description,
        'images': jsonEncode(realisation.images),
        'videoUrls': jsonEncode(realisation.videoUrls),
        'createdAt': realisation.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RealisationModel>> getAllRealisations() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'realisations',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => RealisationModel(
      id: map['id'],
      ownerId: map['ownerId'],
      title: map['title'],
      description: map['description'],
      images: List<String>.from(jsonDecode(map['images'])),
      videoUrls: List<String>.from(jsonDecode(map['videoUrls'])),
      createdAt: DateTime.parse(map['createdAt']),
    )).toList();
  }

  Future<void> deleteRealisation(String id) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete(
      'realisations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearRealisations() async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete('realisations');
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.close();
  }
}
