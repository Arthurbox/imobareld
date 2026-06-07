import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/home/widgets/notification_tile.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/models/property_model.dart';

class NewPropertiesScreen extends StatelessWidget {
  const NewPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyCtrl = Provider.of<PropertyController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: theme.colorScheme.primary),
            tooltip: 'Tout marquer comme lu',
            onPressed: () {
              auth.updateLastReadProperties();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les notifications ont été marquées comme lues.')),
              );
            },
          ),
        ],
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<PropertyModel>>(
        future: propertyCtrl.getProperties(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Erreur lors du chargement des notifications: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  const Text('Aucune nouvelle notification.'),
                ],
              ),
            );
          }

          final lastRead = auth.currentUser?.lastReadProperties;

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              final isUnread = lastRead == null || property.createdAt.isAfter(lastRead);

              return NotificationTile(
                property: property,
                isUnread: isUnread,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(property: property),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
