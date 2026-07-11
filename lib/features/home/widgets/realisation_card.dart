import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/realisation_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/video_player_dialog.dart';

class RealisationCard extends StatelessWidget {
  final RealisationModel realisation;

  const RealisationCard({super.key, required this.realisation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = realisation.videoUrls.isNotEmpty;
    final String? coverUrl = realisation.images.isNotEmpty 
        ? realisation.images.first 
        : null;

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          // Si c'est une vidéo, on ouvre le lecteur vidéo
          showDialog(
            context: context,
            builder: (_) => VideoPlayerDialog(
              videoUrl: realisation.videoUrls.first,
              title: realisation.title.isNotEmpty ? realisation.title : 'Notre Réalisation',
            ),
          );
        } else if (coverUrl != null) {
          // Sinon si c'est une image, on l'affiche en grand
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImage(imageUrl: coverUrl),
              ),
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 350 : MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Cover
              if (coverUrl != null)
                CachedImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                )
              else if (isVideo)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 50),
                  ),
                )
              else
                 const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                ),

              // Si Vidéo, ajouter un icone "Play" au centre
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),

              // Gradient sombre en bas pour le texte
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Texte Intitulé de la réalisation
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (realisation.title.isNotEmpty) ...[
                      Text(
                        realisation.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (realisation.description.isNotEmpty)
                      Text(
                        realisation.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
