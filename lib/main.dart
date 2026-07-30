import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:imobareld/core/constants/supabase_config.dart';

import 'package:imobareld/features/splash/splash_screen.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/services/notification_service.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/chat/chat_controller.dart';
import 'package:imobareld/features/auth/login_screen.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/owner/owner_dashboard.dart';
import 'package:imobareld/features/home/announcement_controller.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/features/home/ad_controller.dart';

import 'package:imobareld/features/home/realisation_controller.dart';

import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/core/services/sync_service.dart';
import 'package:imobareld/core/services/accessibility_settings.dart';
import 'package:imobareld/core/theme/app_theme.dart';
import 'package:imobareld/core/utils/app_logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:imobareld/core/services/deep_link_service.dart';

import 'package:flutter_web_plugins/url_strategy.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  usePathUrlStrategy();
  
  appLogger.i('--- CRITICAL APP IDENTITY CHECK ---');
  appLogger.i('PACKAGE_ID: bf.imobareld.app');

  // Initialisation des bindings Flutter
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // Supprimé : le forçage de useAndroidViewSurface (Hybrid Composition) car 
  // cela cause des écrans gris sur les versions récentes de Flutter en Release.

  // Préserver l'écran de chargement natif (logo sur fond noir) pendant l'initialisation
  // Cela évite la page blanche pendant que Firebase et Supabase chargent.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialisation PARALLÈLE des services critiques pour gagner du temps au démarrage
  try {
    // Timeout de 8 secondes pour Supabase/Firebase pour ne pas bloquer indéfiniment offline
    await Future.wait([
      Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      ),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]).timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('⏳ Timeout initialisation Supabase/Firebase (4s)');
        return [];
      },
    );

    if (!kIsWeb) {
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RealtimeSubscribeException')) {
          debugPrint('Ignored RealtimeSubscribeException in FlutterError');
          return;
        }
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      
      PlatformDispatcher.instance.onError = (error, stack) {
        if (error.toString().contains('RealtimeSubscribeException')) {
          debugPrint('Ignored RealtimeSubscribeException in PlatformDispatcher');
          return true;
        }
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Services secondaires initialisés juste après les critiques
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // On lance ces initialisations avec un timeout de 5s pour garantir runApp()
    await Future.wait([
      NotificationService().init().catchError(
        (e) => debugPrint('Err Notification: $e'),
      ),
      ConnectivityService().init().catchError(
        (e) => debugPrint('Err Connectivity: $e'),
      ),
      SyncService().init().catchError((e) => debugPrint('Err Sync: $e')),
      AccessibilitySettings().init().catchError(
        (e) => debugPrint('Err Settings: $e'),
      ),
    ]).timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('⏳ Timeout services secondaires (2s)');
        return [];
      },
    );

    // Sur Web : brancher le callback de notification sur un SnackBar global
    if (kIsWeb) {
      NotificationService().webMessageCallback = (title, body) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        if (body.isNotEmpty)
                          Text(
                            body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      };
    }
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation initiale: $e');
  }

  runApp(const ImobareldApp());

  // Une fois runApp() appelé, on peut retirer l'écran natif
  // Le Splash Screen Flutter prendra le relais
  FlutterNativeSplash.remove();

  // Initialiser la gestion des liens profonds (Deep Links)
  DeepLinkService().init(navigatorKey);
}

class ImobareldApp extends StatelessWidget {
  const ImobareldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PropertyController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => AnnouncementController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => AdController()),

        ChangeNotifierProvider(create: (_) => RealisationController()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => AccessibilitySettings()),
      ],
      child: Consumer<AccessibilitySettings>(
        builder: (context, accessibility, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'IMOBARELD',
            debugShowCheckedModeBanner: false,
            themeMode: accessibility.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/owner_dashboard': (context) => const OwnerDashboard(),
            },
          );
        },
      ),
    );
  }
}
