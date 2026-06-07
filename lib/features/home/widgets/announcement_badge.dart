import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../announcement_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/announcement_model.dart';

class AnnouncementBadge extends StatelessWidget {
  final Widget child;

  const AnnouncementBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // On écoute l'AuthController pour savoir quand le dernier message a été lu
    final auth = Provider.of<AuthController>(context);
    final controller = Provider.of<AnnouncementController>(context, listen: false);
    
    final lastRead = auth.currentUser?.lastReadAnnouncement;

    return StreamBuilder<List<AnnouncementModel>>(
      stream: controller.announcementsStream,
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        
        int unreadCount = 0;
        if (announcements.isNotEmpty) {
          if (lastRead == null) {
            // Si l'utilisateur n'a jamais lu les annonces, on notifie s'il y en a au moins une
            unreadCount = announcements.length > 5 ? 5 : announcements.length;
          } else {
            // Compter combien d'annonces sont plus récentes que la dernière lecture
            unreadCount = announcements.where((a) => a.createdAt.isAfter(lastRead)).length;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
