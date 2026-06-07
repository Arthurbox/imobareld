import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Gestionnaire de cache personnalisé pour les images réseau.
/// Conserve les images pendant 30 jours avec une limite de 500 images,
/// permettant un accès hors ligne aux images précédemment consultées.
class AppCacheManager {
  static const String _cacheKey = 'imobareld_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      // Conserver les images pendant 30 jours (hors ligne inclus)
      stalePeriod: const Duration(days: 30),
      // Stocker jusqu'à 500 images en cache disque
      maxNrOfCacheObjects: 500,
    ),
  );
}
