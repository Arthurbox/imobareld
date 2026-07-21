import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service de détection de la connectivité réseau
/// Permet de savoir si l'appareil est en ligne ou hors ligne
/// Compatible avec connectivity_plus ^5.x (retourne List<ConnectivityResult>)
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _hasBeenInitialized = false;

  /// Initialise le service et écoute les changements de connectivité
  Future<void> init() async {
    if (_hasBeenInitialized) return;
    _hasBeenInitialized = true;

    // Vérifier l'état initial de façon synchrone avant de continuer
    await _checkConnectivity();

    // Écouter les changements (compatibilité API)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus([result]);
      },
    );
  }

  /// Vérifie l'état de la connectivité (compatibilité API)
  Future<void> _checkConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      _updateConnectionStatus([result]);
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de la connectivité: $e');
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Met à jour le statut de connexion à partir d'une liste de résultats
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Considérer comme en ligne si au moins un type de connexion est disponible
    _isOnline = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );

    // Notifier uniquement si le statut a changé
    if (wasOnline != _isOnline) {
      debugPrint(
        _isOnline
            ? '✅ Connexion rétablie'
            : '⚠️ Connexion perdue - Mode hors ligne activé',
      );
      notifyListeners();
    }
  }

  /// Force une vérification manuelle de la connectivité et retourne le résultat
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
