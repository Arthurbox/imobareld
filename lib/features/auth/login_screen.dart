// Import des packages nécessaires
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/constants/user_roles.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/auth/forgot_password_screen.dart';
import 'package:imobareld/features/auth/phone_entry_screen.dart';
import 'package:imobareld/features/auth/register_screen.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/owner/owner_dashboard.dart';
import 'package:imobareld/features/admin/admin_dashboard.dart';
import 'package:imobareld/features/settings/legal_documents_screen.dart';
import 'package:provider/provider.dart';

/// Écran de connexion de l'application IMOBARELD
/// Permet aux utilisateurs existants de se connecter avec leur email et mot de passe
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// État privé de l'écran de connexion
/// Gère les contrôleurs de texte et la logique de connexion
class _LoginScreenState extends State<LoginScreen> {
  // ========================================
  // VARIABLES D'ÉTAT
  // ========================================
  
  /// Clé globale pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  
  /// Contrôleur pour le champ email
  final _emailController = TextEditingController();
  
  /// Contrôleur pour le champ mot de passe
  final _passwordController = TextEditingController();
  
  /// Indique si le mot de passe est masqué (true) ou visible (false)
  bool _obscurePassword = true;
  bool _acceptTermsAndPrivacy = false;

  bool _showTermsError = false;

  // ========================================
  // MÉTHODE : NETTOYAGE
  // ========================================
  
  /// Appelée quand l'écran est détruit
  /// Libère la mémoire utilisée par les contrôleurs
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================
  // MÉTHODE : GÉRER LA CONNEXION
  // ========================================
  
  /// Gère le processus de connexion quand l'utilisateur appuie sur le bouton
  Future<void> _handleLogin() async {
    setState(() {
      _showTermsError = !_acceptTermsAndPrivacy;
    });

    // 0. Vérifier l'acceptation des CGU et de la Politique de Confidentialité
    if (!_acceptTermsAndPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les CGU et la Politique de Confidentialité'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 1. Vérifier que le formulaire est valide
    if (_formKey.currentState!.validate()) {
      // 2. Récupérer le contrôleur d'authentification
      final authController = context.read<AuthController>();
      
      // 3. Tenter de se connecter
      final success = await authController.login(
        email: _emailController.text.trim(), // Enlever les espaces
        password: _passwordController.text,
      );

      // 4. Si la connexion réussit, naviguer vers le bon écran selon le rôle
      if (success) {
        if (!mounted) return;
        final currentUser = authController.currentUser;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => authController.getNextScreen()),
        );
      } 
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Erreur de connexion'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ========================================
  // MÉTHODE : RAFRAÎCHISSEMENT
  // ========================================
  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  // ========================================
  // MÉTHODE : CONSTRUIRE L'INTERFACE
  // ========================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========================================
                  // LOGO IMOBARELD
                  // ========================================
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // Ombre portée bleue pour le logo
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ========================================
                  // TITRE "CONNEXION" AVEC DÉGRADÉ
                  // ========================================
                  ShaderMask(
                    // Applique le dégradé bleu → orange au texte
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Nécessaire pour ShaderMask
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Sous-titre
                  Text(
                    'Bienvenue sur IMOBARELD',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ========================================
                  // CHAMP EMAIL
                  // ========================================
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      // Bordure par défaut (sans bordure visible)
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      // Bordure quand le champ est sélectionné (focus)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    // Validation du champ email
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Adresse email invalide';
                      }
                      return null;
                    },

                  ),
                  const SizedBox(height: 16),

                  // ========================================
                  // CHAMP MOT DE PASSE
                  // ========================================
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Masquer le mot de passe
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      // Bouton pour afficher/masquer le mot de passe
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    // Validation du mot de passe
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ========================================
                  // LIEN MOT DE PASSE OUBLIÉ
                  // ========================================
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // ========================================
                  // CASE À COCHER CGU & CONFIDENTIALITÉ
                  // ========================================
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _showTermsError ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _showTermsError ? Border.all(color: Colors.red) : null,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptTermsAndPrivacy,
                          activeColor: AppColors.primaryOrange,
                          onChanged: (value) {
                            setState(() {
                              _acceptTermsAndPrivacy = value ?? false;
                              if (_acceptTermsAndPrivacy) _showTermsError = false;
                            });
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Icon(
                                  Icons.verified_user_outlined,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'J\'accepte les ',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'CGU',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LegalDocumentsScreen(isTermsOfService: true),
                                            ),
                                          );
                                        },
                                      ),
                                      const TextSpan(text: ' et la '),
                                      TextSpan(
                                        text: 'Politique de Confidentialité',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LegalDocumentsScreen(isTermsOfService: false),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ========================================
                  // BOUTON "SE CONNECTER"
                  // ========================================
                  Consumer<AuthController>(
                    builder: (context, authController, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: authController.isLoading
                            // Afficher un indicateur de chargement si connexion en cours
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            // Sinon, afficher le bouton
                            : ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Ink(
                                  // Appliquer la même couleur que les prix
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ========================================
                  // SÉPARATEUR "OU"
                  // ========================================
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ========================================
                  // BOUTONS "CONTINUER AVEC..."
                  // ========================================
                  Consumer<AuthController>(
                    builder: (context, authController, _) {
                      return Row(
                        children: [
                          // Bouton Google
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: authController.isLoading
                                    ? null
                                    : () async {
                                        final navigator = Navigator.of(context);
                                        final messenger = ScaffoldMessenger.of(context);
                                        
                                        setState(() {
                                          _showTermsError = !_acceptTermsAndPrivacy;
                                        });
                                        if (!_acceptTermsAndPrivacy) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Veuillez accepter les CGU et la Politique de Confidentialité'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                          return;
                                        }

                                        final success = await authController.signInWithGoogle();
                                        if (!mounted) return;
                                        
                                        if (success) {
                                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => authController.getNextScreen()));
                                        } else if (authController.errorMessage != null) {
                                          messenger.showSnackBar(SnackBar(content: Text(authController.errorMessage!), backgroundColor: AppColors.error));
                                        }
                                      },
                                icon: Image.asset('assets/images/Google__G__logo.svg.webp', height: 24, width: 24),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  side: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  backgroundColor: Theme.of(context).cardColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Bouton Facebook
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: authController.isLoading
                                    ? null
                                    : () async {
                                        final navigator = Navigator.of(context);
                                        final messenger = ScaffoldMessenger.of(context);
                                        
                                        setState(() {
                                          _showTermsError = !_acceptTermsAndPrivacy;
                                        });
                                        if (!_acceptTermsAndPrivacy) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Veuillez accepter les CGU et la Politique de Confidentialité'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                          return;
                                        }

                                        final success = await authController.signInWithFacebook();
                                        if (!mounted) return;
                                        
                                        if (success) {
                                          navigator.pushReplacement(MaterialPageRoute(builder: (_) => authController.getNextScreen()));
                                        } else if (authController.errorMessage != null) {
                                          messenger.showSnackBar(SnackBar(content: Text(authController.errorMessage!), backgroundColor: AppColors.error));
                                        }
                                      },
                                icon: const Icon(Icons.facebook, color: Colors.white, size: 28),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Facebook',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  backgroundColor: const Color(0xFF1877F2), // Facebook Blue
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ========================================
                  // LIEN VERS L'INSCRIPTION
                  // ========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Naviguer vers l'écran d'inscription
                          // Utilisation de pushReplacement pour remplacer l'écran actuel
                          // et éviter l'accumulation dans la pile de navigation
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: ShaderMask(
                          // Appliquer le dégradé au texte "S'inscrire"
                          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
