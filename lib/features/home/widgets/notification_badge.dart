import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../property_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/property_model.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, PropertyController>(
      builder: (context, auth, propertyCtrl, _) {
        return FutureBuilder<List<PropertyModel>>(
          future: propertyCtrl.getProperties(limit: 20),
          builder: (context, snapshot) {
            final properties = snapshot.data ?? [];
            final lastRead = auth.currentUser?.lastReadProperties;

            int unreadCount = 0;
            if (properties.isNotEmpty) {
              if (lastRead == null) {
                // Par défaut, on considère les 3 biens les plus récents comme "nouveaux"
                unreadCount = properties.take(3).length;
              } else {
                unreadCount = properties.where((p) => p.createdAt.isAfter(lastRead)).length;
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
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
      },
    );
  }
}
