// Import des packages nécessaires
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/constants/user_roles.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/settings/legal_documents_screen.dart';
import 'package:imobareld/features/auth/phone_entry_screen.dart';
import 'package:imobareld/features/owner/owner_dashboard.dart';
import 'package:imobareld/features/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';

/// Écran d'inscription de l'application IMOBARELD
/// Permet aux nouveaux utilisateurs de créer un compte
/// avec choix du type : Locataire ou Propriétaire
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// État privé de l'écran d'inscription
/// Gère les contrôleurs de texte, la sélection du type d'utilisateur
/// et la logique d'inscription
class _RegisterScreenState extends State<RegisterScreen> {
  // ========================================
  // VARIABLES D'ÉTAT
  // ========================================
  
  /// Clé globale pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  
  /// Contrôleur pour le champ nom
  final _nameController = TextEditingController();
  
  /// Contrôleur pour le champ email
  final _emailController = TextEditingController();
  
  /// Contrôleur pour le champ mot de passe
  final _passwordController = TextEditingController();
  
  /// Contrôleur pour le champ confirmation de mot de passe
  final _confirmPasswordController = TextEditingController();
  
  /// Contrôleur pour le champ téléphone
  final _phoneController = TextEditingController();
  
  /// Type d'utilisateur sélectionné : 'locataire' ou 'propriétaire'
  /// Par défaut : 'locataire'
  String _selectedUserType = UserRoles.user;
  
  /// Indique si le mot de passe est masqué
  bool _obscurePassword = true;
  
  /// Indique si la confirmation du mot de passe est masquée
  bool _obscureConfirmPassword = true;
  
  bool _acceptTermsAndPrivacy = false;

  bool _showTermsError = false;

  // ========================================
  // MÉTHODE : NETTOYAGE
  // ========================================
  
  /// Appelée quand l'écran est détruit
  /// Libère la mémoire utilisée par les contrôleurs
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ========================================
  // MÉTHODE : GÉRER L'INSCRIPTION
  // ========================================
  
  /// Gère le processus d'inscription quand l'utilisateur appuie sur le bouton
  Future<void> _handleRegister() async {
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
      
      // 3. Tenter de s'inscrire avec le type d'utilisateur sélectionné
      final success = await authController.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: _selectedUserType,
        phone: _selectedUserType == UserRoles.owner 
            ? '+226 ${_phoneController.text.trim()}'
            : null,
      );

      // 4. Si l'inscription réussit, naviguer vers le bon écran
      if (success) {
        if (!mounted) return;
        final currentUser = authController.currentUser;
        // Redirection centralisée basée sur le rôle
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => authController.getNextScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Impossible de finaliser l\'inscription. Veuillez réessayer.'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primaryOrange,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========================================
                  // LOGO IMOBARELD
                  // ========================================
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // Ombre portée orange pour le logo
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
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
                  const SizedBox(height: 24),

                  // ========================================
                  // TITRE "INSCRIPTION" AVEC DÉGRADÉ
                  // ========================================
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Inscription',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Sous-titre
                  Text(
                    'Créez votre compte IMOBARELD',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ========================================
                  // SÉLECTION DU TYPE D'UTILISATEUR
                  // ========================================
                  Text(
                    'Je suis :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // ========================================
                      // CARTE "LOCATAIRE"
                      // ========================================
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserRoles.user;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Fond bleu clair si sélectionné
                              color: _selectedUserType == UserRoles.user
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              // Bordure bleue si sélectionné
                              border: Border.all(
                                color: _selectedUserType == UserRoles.user
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Icône personne
                                Icon(
                                  Icons.person_outline,
                                  size: 40,
                                  color: _selectedUserType == UserRoles.user
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 8),
                                // Texte "Locataire"
                                Text(
                                  'Locataire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedUserType == UserRoles.user
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Description
                                Text(
                                  'Je cherche',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedUserType == UserRoles.user
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // ========================================
                      // CARTE "PROPRIÉTAIRE"
                      // ========================================
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserRoles.owner;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Fond orange clair si sélectionné
                              color: _selectedUserType == UserRoles.owner
                                  ? AppColors.primaryOrange.withValues(alpha: 0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              // Bordure orange si sélectionné
                              border: Border.all(
                                color: _selectedUserType == UserRoles.owner
                                    ? AppColors.primaryOrange
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Icône maison
                                Icon(
                                  Icons.home_outlined,
                                  size: 40,
                                  color: _selectedUserType == UserRoles.owner
                                      ? AppColors.primaryOrange
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 8),
                                // Texte "Propriétaire"
                                Text(
                                  'Propriétaire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedUserType == UserRoles.owner
                                        ? AppColors.primaryOrange
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Description
                                Text(
                                  'Je publie',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedUserType == UserRoles.owner
                                        ? AppColors.primaryOrange
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ========================================
                  // CHAMP NOM COMPLET
                  // ========================================
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ========================================
                  // CHAMP TÉLÉPHONE (Uniquement pour propriétaires)
                  // ========================================
                  if (_selectedUserType == UserRoles.owner) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          // Drapeau (Approximatif avec Emoji ou image)
                          const Text('🇧🇫', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 4),
                          Text(
                            '+226',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                hintText: '57428929',
                                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) {
                                if (_selectedUserType == UserRoles.owner && (value == null || value.trim().isEmpty)) {
                                  return 'Numéro requis';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ========================================
                  // CHAMP CONFIRMATION MOT DE PASSE
                  // ========================================
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      // Vérifier que les deux mots de passe correspondent
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                  // BOUTON "S'INSCRIRE"
                  // ========================================
                  Consumer<AuthController>(
                    builder: (context, authController, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: authController.isLoading
                            // Afficher un indicateur de chargement si inscription en cours
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryOrange,
                                ),
                              )
                            // Sinon, afficher le bouton
                            : ElevatedButton(
                                onPressed: _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Ink(
                                  // Appliquer le dégradé bleu → orange
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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

                                        final success = await authController.signInWithGoogle(userType: _selectedUserType);
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

                                        final success = await authController.signInWithFacebook(userType: _selectedUserType);
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
                  // LIEN VERS LA CONNEXION
                  // ========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Naviguer vers l'écran de connexion
                          // Utilisation de pushReplacement pour remplacer l'écran actuel
                          // et éviter l'accumulation dans la pile de navigation
                          Navigator.of(context).pop();
                        },
                        child: ShaderMask(
                          // Appliquer le dégradé au texte "Se connecter"
                          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'Se connecter',
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
  );
}
}
