// On importe dart:async pour utiliser Timer (temps d’attente)
import 'dart:async';

// On importe le package Flutter Material
// Il contient les widgets de base (Scaffold, Text, Icon, etc.)
import 'package:flutter/material.dart';
import 'package:imobareld/features/auth/login_screen.dart';
import 'package:imobareld/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/owner/owner_dashboard.dart';
import 'package:imobareld/features/admin/admin_dashboard.dart';
import 'package:imobareld/features/auth/phone_entry_screen.dart';
import 'package:imobareld/core/constants/user_roles.dart';
import 'package:imobareld/core/services/connectivity_service.dart';

// SplashScreen est un StatefulWidget
// → parce qu’il y a un changement d’état (attendre puis naviguer)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Cette classe contient la logique du Splash Screen
class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    // On lance l'initialisation et on attend 2 secondes en même temps
    // results[0] contiendra le widget de destination retourné par _checkStatus
    final results = await Future.wait([
      _checkStatus(auth),
      Future.delayed(const Duration(milliseconds: 300)),
    ]);

    final Widget nextScreen = results[0] as Widget;

    if (!mounted) return;

    // Navigation vers l'écran approprié
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  Future<Widget> _checkStatus(AuthController auth) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!isCompleted) {
      return const OnboardingScreen();
    }

    // 🔑 Forcer une vérification fraîche de la connectivité AVANT initUser().
    // Sans ça, ConnectivityService._isOnline vaut 'true' par défaut au démarrage,
    // même quand l'appareil est hors ligne — ce qui provoque un appel Supabase inutile.
    await ConnectivityService().checkConnection();

    // Vérifier si Supabase a une session active (Supabase gère son propre stockage)
    try {
      final success = await auth.initUser();
      if (success) {
        debugPrint('🚀 Session restaurée avec succès (en ligne ou cache)');
        return auth.getNextScreen();
      }
    } catch (e) {
      debugPrint('⚠️ Échec de la restauration de session: $e');
    }

    // Si pas de session valide, retour vers l'écran de login
    return const LoginScreen();
  }

  // build construit l’interface utilisateur
  // cette méthode peut être rappelée plusieurs fois
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Scaffold est la structure de base d’une page Flutter
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 400, // Ajustez la taille si nécessaire
        ),
      ),
    );
  }
}
