import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/services/connectivity_service.dart';

/// Bannière persistante affichée en haut de l'écran quand l'application est hors ligne.
/// Wrappez votre Scaffold body avec ce widget.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            AnimatedSlide(
              offset: connectivity.isOnline ? const Offset(0, -1) : Offset.zero,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: connectivity.isOnline ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: connectivity.isOnline
                    ? const SizedBox.shrink()
                    : _OfflineBannerContent(),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFBF360C)],
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Mode hors ligne — Données du cache affichées',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'état vide spécifique au mode hors-ligne.
/// Affiché quand aucune donnée n'est disponible en cache.
class OfflineEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineEmptyState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pas de connexion internet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les données.\nVérifiez votre connexion et réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
