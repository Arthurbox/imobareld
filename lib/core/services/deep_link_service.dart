import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/deep_link_loader.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _appLinks = AppLinks();

    // 1. Gérer le lien qui a ouvert l'application (Cold Start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri, navigatorKey);
      }
    });

    // 2. Écouter les liens entrants pendant que l'app est ouverte
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri, navigatorKey);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    debugPrint('Handling Deep Link: $uri');
    
    // Gérer le retour de paiement
    if (uri.scheme == 'imobareldapp' && uri.host == 'payment') {
      final status = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      final context = navigatorKey.currentContext;
      if (context != null) {
        if (status == 'return') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('De retour sur l\'application ! Votre paiement est en cours de traitement.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (status == 'cancel') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement annulé.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      return;
    }

    // On supporte https://imobareld.app/property/[id] 
    // ou imobareld://property/[id]
    
    final pathSegments = uri.pathSegments;
    String? type;
    String? id;

    if (pathSegments.length >= 2) {
      type = pathSegments[0]; // property ou vehicle
      id = pathSegments[1];   // l'UUID
    } else if (uri.scheme == 'imobareld') {
      // Cas du schéma personnalisé imobareld://property/[id]
      type = uri.host;
      if (pathSegments.isNotEmpty) {
        id = pathSegments[0];
      }
    }

    if (type != null && id != null) {
      if (type == 'property' || type == 'vehicle') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => DeepLinkLoader(type: type!, id: id!),
          ),
        );
      }
    }
  }
}
