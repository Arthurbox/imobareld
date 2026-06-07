import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Callback optionnel pour afficher un SnackBar sur Web
  /// À assigner depuis main.dart : NotificationService().webMessageCallback = (msg) => ...
  void Function(String title, String body)? webMessageCallback;

  Future<void> init() async {
    // Demander la permission (avec timeout pour l'offline)
    try {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⏳ Timeout ou erreur requestPermission (offline probable): $e');
    }
    
    // Initialiser les fuseaux horaires pour les notifications programmées
    tz_data.initializeTimeZones();

    // Configurer les notifications locales
    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(initSettings);

      // Créer les canaux de notification Android
      await _createNotificationChannels();
    }

    // S'abonner aux topics des nouvelles publications
    await subscribeToNewProperties();
    await subscribeToNewVehicles();

    // Écouter les messages en premier plan (FCM)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _showAnnouncementNotification(String author, String content) async {
    if (kIsWeb) {
      // Sur Web : utiliser le callback SnackBar si disponible
      webMessageCallback?.call('Nouvelle annonce de $author', content);
      debugPrint('🔔 [Web] Annonce: $author - $content');
      return;
    }
    await _localNotifications.show(
      author.hashCode,
      'Nouvelle annonce de $author',
      content,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'announcements',
          'Annonces rapides',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Si c'est un message de type DATA (nouvelle annonce par exemple)
    if (data.isNotEmpty && data['type'] != null) {
      final type = data['type'];
      if (type == 'new_property') {
        await showNewPropertyNotification(
          propertyId: data['id'] ?? '',
          title: data['title'] ?? '',
          category: data['category'] ?? '',
          city: data['city'] ?? '',
          quartier: data['quartier'] ?? '',
          price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
        );
        return;
      } else if (type == 'new_vehicle') {
        await showNewVehicleNotification(
          vehicleId: data['id'] ?? '',
          model: data['model'] ?? '',
          company: data['company'] ?? '',
          city: data['city'] ?? '',
          price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
        );
        return;
      }
    }

    if (notification == null) return;

    if (kIsWeb) {
      // Sur Web : afficher un SnackBar via le callback
      webMessageCallback?.call(
        notification.title ?? 'IMOBARELD',
        notification.body ?? '',
      );
      debugPrint('🔔 [Web] Notification FCM : ${notification.title} - ${notification.body}');
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_alerts',
          'Alertes générales',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Planifie des rappels avant l'expiration d'un boost (48h, 24h et à la fin)
  Future<void> scheduleBoostExpiryNotifications({
    required String propertyId,
    required String propertyTitle,
    required DateTime expiryDate,
  }) async {
    // Les notifications programmées ne sont pas supportées sur Web
    if (kIsWeb) {
      debugPrint('🔔 [Web] scheduleBoostExpiryNotifications ignoré (non supporté sur Web)');
      return;
    }

    final now = DateTime.now();
    
    // Définir les délais de rappel (en heures avant l'expiration)
    final reminders = [
      {'id_suffix': 101, 'hours': 48, 'msg': 'Votre boost pour "$propertyTitle" expire dans 48 heures !'},
      {'id_suffix': 102, 'hours': 24, 'msg': 'Votre boost pour "$propertyTitle" expire demain ! Renouvelez-le vite.'},
      {'id_suffix': 103, 'hours': 0, 'msg': 'Le boost de votre annonce "$propertyTitle" est terminé.'},
    ];

    for (var reminder in reminders) {
      final int hoursBefore = reminder['hours'] as int;
      final scheduleDate = expiryDate.subtract(Duration(hours: hoursBefore));

      // Ne planifier que si la date est dans le futur
      if (scheduleDate.isAfter(now)) {
        final notificationId = propertyId.hashCode + (reminder['id_suffix'] as int);
        
        await _localNotifications.zonedSchedule(
          notificationId,
          '🚀 Boost Immobareld',
          reminder['msg'] as String,
          tz.TZDateTime.from(scheduleDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'boost_alerts',
              'Souscriptions & Boosts',
              channelDescription: 'Alertes sur la fin de vos abonnements de visibilité',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: propertyId,
        );
      }
    }
    debugPrint('🔔 Rappels de boost planifiés pour : $propertyTitle');
  }

  /// Affiche une notification pour une nouvelle propriété
  Future<void> showNewPropertyNotification({
    required String propertyId,
    required String title,
    required String category,
    required String city,
    required String quartier,
    required double price,
    String? imageBase64,
  }) async {
    // Formater le prix
    String formattedPrice = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '\${m[1]} '
    );

    final notificationTitle = '🏠 Nouvelle annonce : $category';
    final notificationBody = '$title\n📍 $city, $quartier • 💰 $formattedPrice FCFA';

    // Sur Web : SnackBar via callback
    if (kIsWeb) {
      webMessageCallback?.call(notificationTitle, '$title - $city, $quartier');
      debugPrint('🔔 [Web] Nouvelle propriété: $title');
      return;
    }

    final notificationId = propertyId.hashCode;

    await _localNotifications.show(
      notificationId,
      notificationTitle,
      notificationBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'new_properties',
          'Nouvelles Propriétés',
          channelDescription: 'Notifications pour les nouvelles annonces immobilières',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(
            notificationBody,
            contentTitle: notificationTitle,
            summaryText: 'IMOBARELD',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: '$quartier • $formattedPrice FCFA',
        ),
      ),
      payload: propertyId,
    );
  }

  /// Notifie le propriétaire d'une nouvelle demande de réservation
  Future<void> showReservationNotification({
    required String vehicleModel,
    required String tenantName,
  }) async {
    if (kIsWeb) {
      webMessageCallback?.call(
        '🚗 Nouvelle demande de location',
        '$tenantName souhaite louer : $vehicleModel',
      );
      return;
    }
    await _localNotifications.show(
      vehicleModel.hashCode ^ tenantName.hashCode,
      '🚗 Nouvelle demande de location',
      '$tenantName souhaite louer : $vehicleModel',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reservation_requests',
          'Demandes de réservation',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Affiche une notification pour un nouveau véhicule
  Future<void> showNewVehicleNotification({
    required String vehicleId,
    required String model,
    required String company,
    required String city,
    required double price,
  }) async {
    String formattedPrice = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '\${m[1]} '
    );

    final notificationTitle = '🚗 Nouveau véhicule : $company $model';
    final notificationBody = '📍 $city • 💰 $formattedPrice FCFA / jour';

    if (kIsWeb) {
      webMessageCallback?.call(notificationTitle, notificationBody);
      debugPrint('🔔 [Web] Nouveau véhicule: $company $model');
      return;
    }

    final notificationId = vehicleId.hashCode;

    await _localNotifications.show(
      notificationId,
      notificationTitle,
      notificationBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'new_vehicles',
          'Nouveaux Véhicules',
          channelDescription: 'Notifications pour les nouveaux véhicules en location',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: '$city • $formattedPrice FCFA',
        ),
      ),
      payload: vehicleId,
    );
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return await _fcm.getToken(
        vapidKey: 'BIXE4PQGWmQozB4916dmllOzI_e2_6MXATm_4plOOvAaJwKHz1ipmzddxpeoiM8WhJ520IvUJyqOD0ItNqAuPf8',
      );
    }
    return await _fcm.getToken();
  }

  /// S'abonner au topic des nouvelles propriétés pour les notifications push
  Future<void> subscribeToNewProperties() async {
    try {
      await _fcm.subscribeToTopic('new_properties')
          .timeout(const Duration(seconds: 5));
      debugPrint('🔔 Abonné au topic : new_properties');
    } catch (e) {
      debugPrint('❌ Erreur d\'abonnement topic (timeout possible) : $e');
    }
  }

  /// S'abonner au topic des nouveaux véhicules pour les notifications push
  Future<void> subscribeToNewVehicles() async {
    try {
      await _fcm.subscribeToTopic('new_vehicles')
          .timeout(const Duration(seconds: 5));
      debugPrint('🔔 Abonné au topic : new_vehicles');
    } catch (e) {
      debugPrint('❌ Erreur d\'abonnement topic véhicules (timeout possible) : $e');
    }
  }

  /// Créer les canaux de notification pour Android
  Future<void> _createNotificationChannels() async {
    if (kIsWeb) return;

    const channels = [
      AndroidNotificationChannel(
        'general_alerts',
        'Alertes générales',
        description: 'Notifications système et alertes',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'new_properties',
        'Nouvelles Propriétés',
        description: 'Notifications pour les nouvelles annonces immobilières',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'new_vehicles',
        'Nouveaux Véhicules',
        description: 'Notifications pour les nouveaux véhicules',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'announcements',
        'Annonces rapides',
        description: 'Notifications pour les flash annonces',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'boost_alerts',
        'Souscriptions & Boosts',
        description: 'Alertes sur la fin de vos abonnements de visibilité',
        importance: Importance.high,
      ),
    ];

    for (var channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Écoute les messages de chat (WebSocket ou FCM spécifique)
  void listenToMessages(String userId) {
    debugPrint('🔔 Écoute des messages pour l\'utilisateur : $userId');
  }
}
