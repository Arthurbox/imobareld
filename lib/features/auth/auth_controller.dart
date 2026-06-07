import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:imobareld/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/auth/phone_entry_screen.dart';
import 'package:imobareld/features/auth/login_screen.dart';
import 'package:imobareld/features/auth/reset_password_screen.dart';
import '../../core/services/supabase_service.dart';
import 'package:imobareld/main.dart' show navigatorKey;
import 'package:imobareld/core/services/notification_service.dart';

/// Contrôleur d'authentification pour gérer toutes les opérations liées aux utilisateurs
class AuthController extends ChangeNotifier {
  AuthController() {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    supabaseService.client.auth.onAuthStateChange.listen((data) {
      final sb.AuthChangeEvent event = data.event;
      debugPrint('🔔 [Auth Event] : $event');
      // On print aussi l'URL au cas où supabase_flutter nous donnerait du contexte supplémentaire ? 
      // Non, data n'a que event et session.
      
      if (event == sb.AuthChangeEvent.passwordRecovery) {
        debugPrint('🔓 [passwordRecovery] Event reçu ! Redirection vers ResetPasswordScreen...');
        _isRecoveringPassword = true;
        notifyListeners();

        // Si l'application est déjà ouverte, on navigue de force avec un court délai 
        // pour s'assurer que le Navigator est bien prêt et pas en cours de build.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (navigatorKey.currentState != null) {
            debugPrint('🚀 navigatorKey valide, exécution de pushAndRemoveUntil!');
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              (route) => false,
            );
          } else {
            debugPrint('❌ navigatorKey est NULL ! Navigation échouée.');
          }
        });
      }
    });
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecoveringPassword = false;
  final Map<String, UserModel> _userCache = {};
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _listenToProfileChanges(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = supabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((data) {
      if (data.isNotEmpty) {
        _currentUser = UserModel.fromMap(data.first, userId);
        _userCache[userId] = _currentUser!;
        // Appeler notifyListeners() ici forcera tous les widgets écoutant AuthController 
        // (comme HomeScreen ou le Drawer) à se reconstruire, affichant ainsi le panneau Admin.
        notifyListeners();
      }
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecoveringPassword => _isRecoveringPassword;
  bool get isAuthenticated => _currentUser != null;

  /// Retourne l'écran approprié en fonction du rôle et de l'état du profil
  Widget getNextScreen() {
    if (_isRecoveringPassword) return ResetPasswordScreen();
    if (_currentUser == null) return const LoginScreen();

    // 2. Propriétaire ou Administrateur (Tous deux vont vers la Home/Map)
    if (_currentUser!.isOwner) {
      // Vérifier si le téléphone est renseigné (requis pour publier)
      if (!_currentUser!.canPost) {
        return const PhoneEntryScreen();
      }
      return const HomeScreen();
    }

    // 3. Locataire (Par défaut)
    return const HomeScreen();
  }

  // ─── Clé SharedPreferences pour le cache du profil ───
  static const String _cachedProfileKey = 'cached_user_profile';
  static const String _cachedUserIdKey = 'user_id';

  /// Sauvegarde le profil utilisateur dans SharedPreferences (mode hors ligne)
  Future<void> _saveProfileToCache(UserModel user, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserIdKey, userId);
      await prefs.setString(_cachedProfileKey, jsonEncode(user.toMap()));
      debugPrint('💾 Profil utilisateur mis en cache local');
    } catch (e) {
      debugPrint('⚠️ Impossible de mettre le profil en cache: $e');
    }
  }

  /// Charge le profil utilisateur depuis SharedPreferences (si hors ligne)
  Future<bool> _loadProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_cachedUserIdKey);
      final profileJson = prefs.getString(_cachedProfileKey);

      if (userId != null && profileJson != null) {
        final map = jsonDecode(profileJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(map, userId);
        _userCache[userId] = _currentUser!;
        notifyListeners();
        debugPrint('📦 Profil chargé depuis le cache local (mode hors ligne)');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement profil cache: $e');
    }
    return false;
  }

  /// Initialise l'utilisateur au démarrage avec Supabase
  /// Si hors ligne, charge depuis le cache local (comportement WhatsApp/TikTok)
  Future<bool> initUser() async {
    try {
      final session = supabaseService.client.auth.currentSession;

      // ── Gestion du userType après redirection OAuth (Web) ──
      if (session != null && kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final pendingType = prefs.getString('pending_user_type');
        if (pendingType != null) {
          debugPrint('🔄 Profil post-OAuth : détection du rôle en attente ($pendingType)');
          await _manualProfileSync(
            id: session.user.id, 
            name: session.user.userMetadata?['full_name'] as String? ?? 
                  session.user.userMetadata?['name'] as String? ?? '', 
            email: session.user.email ?? '', 
            userType: pendingType,
          );
          await prefs.remove('pending_user_type');
        }
      }

      // ── Pas de session Supabase locale → vérifier si on a un cache ──
      if (session == null) {
        debugPrint('⚡ Pas de session Supabase — tentative cache hors ligne');
        return await _loadProfileFromCache();
      }

      final userId = session.user.id;

      // ── Mode hors ligne : utiliser le cache immédiatement ──
      final isOnline = ConnectivityService().isOnline;
      if (!isOnline) {
        debugPrint('⚡ Hors ligne : chargement du profil depuis le cache');
        final fromCache = await _loadProfileFromCache();
        // Si pas de cache, construire un user minimal depuis la session
        if (!fromCache) {
          _currentUser = UserModel.fromSessionData(
            userId: userId,
            email: session.user.email ?? '',
            name: session.user.userMetadata?['full_name'] as String? ??
                session.user.userMetadata?['name'] as String?,
          );
          notifyListeners();
          return true;
        }
        return fromCache;
      }

      // ── Mode en ligne : récupérer depuis Supabase avec timeout 5s ──
      Map<String, dynamic>? response;
      try {
        response = await supabaseService.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⏱️ Timeout Supabase profiles — basculement cache');
                return null;
              },
            );
      } catch (timeoutErr) {
        debugPrint('⚠️ Erreur appel profiles: $timeoutErr — basculement cache');
        response = null;
      }

      if (response != null) {
        _currentUser = UserModel.fromMap(response, userId);
        _userCache[userId] = _currentUser!;

        // 💾 Mettre le profil en cache pour les prochains démarrages hors ligne
        await _saveProfileToCache(_currentUser!, userId);

        // Mettre à jour le token FCM si nécessaire
        await _updateFcmToken(userId);

        // S'abonne aux changements temps réel du profil (ex: passage au rôle Admin)
        _listenToProfileChanges(userId);

        notifyListeners();
        return true;
      }

      // Profil non trouvé sur Supabase (timeout ou pas de ligne) → essayer le cache
      final fromCache = await _loadProfileFromCache();
      if (!fromCache) {
        // Dernier recours : construire un user minimal depuis la session
        _currentUser = UserModel.fromSessionData(
          userId: userId,
          email: session.user.email ?? '',
          name: session.user.userMetadata?['full_name'] as String? ??
              session.user.userMetadata?['name'] as String?,
        );
        notifyListeners();
        return true;
      }
      return fromCache;
    } catch (e) {
      debugPrint('⚠️ initUser Supabase échoué, tentative cache hors ligne: $e');
      // Fallback sur le cache en cas d'erreur réseau
      return await _loadProfileFromCache();
    }
  }

  /// Récupère le token FCM de l'appareil et le met à jour sur Supabase
  Future<void> _updateFcmToken(String userId) async {
    try {
      if (kIsWeb) return; // Optionnel : Ignorer sur Web si tu ne fais des push que sur mobile
      final token = await NotificationService().getToken();
      if (token != null && token.isNotEmpty && token != _currentUser?.fcmToken) {
        debugPrint('🔔 FCM Token obtenu: $token, mise à jour DB...');
        await supabaseService.client.from('profiles').update({
          'fcm_token': token,
        }).eq('id', userId);
        
        _currentUser = _currentUser?.copyWith(fcmToken: token);
        if (_currentUser != null) {
          _userCache[userId] = _currentUser!;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur FCM Token Update: $e');
    }
  }

  /// Inscription via Supabase
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String userType,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await supabaseService.signUp(
        email: email, 
        password: password,
        emailRedirectTo: kIsWeb ? null : 'imobareldapp://',
        data: {
          'name': name,
          'user_name': name,
          'full_name': name,
          'userType': userType,
          'user_type': userType,
          'phone': phone ?? '',
        },
      );

      if (response.user != null) {
        // Si la session est nulle, c'est que la confirmation par email est activée sur Supabase
        if (response.session == null) {
          _isLoading = false;
          _errorMessage = 'Compte créé ! Veuillez confirmer votre adresse email pour continuer.';
          notifyListeners();
          return false; // Retourner false pour afficher le message sur l'écran d'inscription
        }

        // Forcer la synchronisation du profil manuellement pour s'assurer que user_type et phone sont là
        await _manualProfileSync(
          id: response.user!.id,
          name: name,
          email: email,
          userType: userType,
          phone: phone,
        );

        // Tentative de récupération du profil après synchronisation
        bool success = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          await Future.delayed(const Duration(seconds: 1));
          success = await initUser();
          if (success) break;
        }

        if (!success) {
          _errorMessage = 'Compte créé ! Votre profil sera disponible dès votre première connexion.';
        }

        _isLoading = false;
        notifyListeners();
        return true; // Toujours retourner true si le compte est créé
      } else {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue lors de l\'inscription Supabase.';
        notifyListeners();
        return false;
      }
    } on sb.AuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Une erreur inattendue est survenue: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  String _getReadableErrorMessage(sb.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('rate limit') || e.statusCode == '429' || message.contains('seconds')) {
      return "Pour des raisons de sécurité, veuillez attendre environ 1 minute avant de réessayer.";
    }
    if (message.contains('already registered') || message.contains('already exists')) {
      return "Cet email est déjà utilisé. Essayez de vous connecter plutôt.";
    }
    if (message.contains('invalid login credentials')) {
      return "Email ou mot de passe incorrect.";
    }
    if (message.contains('email not confirmed')) {
      return "Veuillez confirmer votre adresse email avant de vous connecter.";
    }
    return "Erreur d'authentification: ${e.message}";
  }

  /// Connexion via Supabase
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await supabaseService.signIn(email: email, password: password);
      final success = await initUser();
      
      if (!success) {
         _errorMessage = 'Erreur lors de la récupération du profil.';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } on sb.AuthException catch (e) {
      debugPrint('🚨 Supabase Auth Raw Error: ${e.message} (Code: ${e.statusCode})');
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🚨 Unhandled Auth Error: $e');
      _isLoading = false;
      _errorMessage = 'Email ou mot de passe incorrect.';
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour le mot de passe après récupération
  Future<bool> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await supabaseService.client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      _isRecoveringPassword = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur updatePassword: $e');
      _errorMessage = 'Impossible de mettre à jour le mot de passe.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Réinitialisation du mot de passe via Supabase
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'imobareldapp://',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on sb.AuthException catch (e) {
      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Impossible d'envoyer l'email de réinitialisation.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Authentification Google via Supabase
  Future<bool> signInWithGoogle({String userType = 'locataire'}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ─── MÉTHODE WEB : Redirection OAuth (La plus stable) ───
      if (kIsWeb) {
        debugPrint('🌐 Lancement du flux Google OAuth via redirection (Web)');
        
        // Sauvegarder le userType souhaité pour le récupérer après redirection
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_user_type', userType);
        
        await supabaseService.client.auth.signInWithOAuth(
          sb.OAuthProvider.google,
          redirectTo: kIsWeb
              ? (kDebugMode
                  ? 'http://localhost:5000'
                  : 'https://imobareld.web.app')
              : null,
          authScreenLaunchMode: sb.LaunchMode.platformDefault,
        );
        
        // Sur Web, l'appel ci-dessus redirige l'onglet, l'exécution s'arrête ici.
        return true;
      }

      // ─── MÉTHODE MOBILE : Plugin Google Sign-In ───
      // configuration native Google Sign-In
      final String webClientId = '704257001092-k5qgf3cv9k7qdhkoenmrv6goelkl5t0r.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: webClientId,
        serverClientId: webClientId,
        scopes: [
          'email',
          'profile',
          'openid',
        ],
      );
      
      // Force always showing the account chooser by signing out of the local cache first
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        _isLoading = false;
        _errorMessage = "Erreur : ID Token Google manquant.";
        notifyListeners();
        return false;
      }

      // Authentification auprès de Supabase
      final response = await supabaseService.client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Attendre que le trigger SQL crée le profil si besoin
        await Future.delayed(const Duration(milliseconds: 800));
        
        // 1. Tenter d'initialiser l'utilisateur pour voir s'il a déjà un profil
        bool success = await initUser();
        
        // 2. Extraire le nom depuis Google ou les métadonnées Supabase
        String? googleName = googleUser.displayName;
        if (googleName == null || googleName.isEmpty) {
          googleName = response.user?.userMetadata?['full_name'] as String?;
        }
        if (googleName == null || googleName.isEmpty) {
          googleName = response.user?.userMetadata?['name'] as String?;
        }
        
        final String expectedName = (googleName != null && googleName.isNotEmpty) 
            ? googleName 
            : (_currentUser?.name ?? '');

        // 3. Mettre à jour ou Créer le profil si nécessaire
        final currentName = _currentUser?.name ?? '';
        final currentType = _currentUser?.userType ?? 'locataire';
        
        final bool isNewOrMissingName = !success || _currentUser == null || currentName.isEmpty || currentName == 'Utilisateur';
        final bool isTypeWrong = currentType != userType;
        
        if ((isNewOrMissingName || isTypeWrong) && expectedName.isNotEmpty) {
           debugPrint('🔄 Synchronisation du profil Google: $expectedName | Type: $userType (ancien: $currentType)');
             await _manualProfileSync(
               id: response.user!.id, 
               name: expectedName, 
               email: response.user!.email ?? '',
               userType: userType,
               phone: _currentUser?.phone, // Conserver le téléphone existant si présent
             );
           // Rafraîchir l'utilisateur local après synchronisation
           success = await initUser();
        }

        _isLoading = false;
        notifyListeners();
        return success;
      }

      _isLoading = false;
      _errorMessage = "Erreur lors de la connexion Supabase.";
      notifyListeners();
      return false;
      
    } on sb.AuthException catch (e) {
      debugPrint('🚨 Erreur Google Auth Supabase: $e');
      _isLoading = false;
      _errorMessage = "Supabase Auth Error: ${e.message}";
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🚨 Erreur Google Auth: $e');
      _isLoading = false;
      _errorMessage = "Google Error: $e";
      notifyListeners();
      return false;
    }
  }

  /// Méthode interne pour synchroniser manuellement un profil (utile pour Google/Apple login)
  Future<void> _manualProfileSync({
    required String id, 
    required String name, 
    required String email,
    required String userType,
    String? phone,
  }) async {
    try {
      // 1. Mettre à jour les métadonnées auth.users (ça peut déclencher un trigger)
      try {
        await supabaseService.client.auth.updateUser(
          sb.UserAttributes(
            data: {
              'user_type': userType,
              'userType': userType,
              'name': name,
            }
          )
        );
      } catch (e) {
        debugPrint('⚠️ Erreur update métadonnées: $e');
      }

      // 2. Préparation des données pour la table profils
      final Map<String, dynamic> updateData = {
        'user_name': name,
        'email': email,
        'user_type': userType,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }

      // 3. Mise à jour directe (Update) de la table. 
      // Si la ligne n'existe pas, on tente un insert ensuite.
      final existingProfile = await supabaseService.client
          .from('profiles')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      if (existingProfile != null) {
        await supabaseService.client.from('profiles').update(updateData).eq('id', id);
      } else {
        updateData['id'] = id;
        await supabaseService.client.from('profiles').insert(updateData);
      }

    } catch (e) {
      debugPrint('🚨 Erreur manualProfileSync: $e');
    }
  }

  /// Récupérer Utilisateur par ID via Supabase
  Future<UserModel?> getUserById(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    if (_currentUser?.id == userId) return _currentUser;

    try {
      final response = await supabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromMap(response, userId);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint('🚨 Erreur getUserById Supabase: $e');
    }
    return null;
  }

  /// Obtenir l'ID de support (Admin)
  Future<String?> getSupportUserId() async {
    try {
      final response = await supabaseService.client
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();
      return response?['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _profileSubscription?.cancel();
    await supabaseService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
    notifyListeners();
  }

  /// Vider l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Favoris, MàJ profil etc...
  // Ces méthodes seront complétées dans la prochaine étape. Pour l'instant on garde une structure vide pour ne pas casser l'app.
  Future<void> toggleFavorite(String propertyId) async {
    // La logique des favoris est principalement dans PropertyController pour l'instant.
    // On pourrait ajouter ici un appel API si on veut synchroniser avec le serveur.
  }

  Future<bool> updateProfile({required String name, String? phone}) async {
    try {
      _isLoading = true; notifyListeners();
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        _errorMessage = "Utilisateur non connecté.";
        return false;
      }

      final Map<String, dynamic> updateData = {
        'phone': phone ?? '',
      };

      try {
        // Mettre à jour les métadonnées de l'auth Supabase pour la synchronisation
        await supabaseService.client.auth.updateUser(sb.UserAttributes(
          data: {
            'name': name,
            'full_name': name,
            'user_name': name,
            'phone': phone ?? '',
          },
        ));

        // Tentative 1 : avec full_name (standard Supabase)
        await supabaseService.client.from('profiles').update({
          ...updateData,
          'full_name': name,
        }).eq('id', userId);
      } catch (e) {
        debugPrint('⚠️ Échec update full_name, tentative avec user_name: $e');
        try {
          // Tentative 2 : avec user_name (legacy/migré)
          await supabaseService.client.from('profiles').update({
            ...updateData,
            'user_name': name,
          }).eq('id', userId);
        } catch (e2) {
          debugPrint('❌ Échec critique updateProfile: $e2');
          _errorMessage = "Erreur lors de la mise à jour du profil.";
          rethrow;
        }
      }
      
      await initUser();
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur updateProfile finale: $e');
      _isLoading = false; 
      _errorMessage = "Erreur de connexion au serveur.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePicture(XFile image) async {
    try {
      _isLoading = true; notifyListeners();
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      final bytes = await image.readAsBytes();
      final extension = p.extension(image.path).toLowerCase();
      final fileName = 'profile_$userId$extension';
      final path = 'profiles/$fileName';

      // Uploader sur Supabase Storage (Bucket 'media')
      final imageUrl = await supabaseService.uploadBytes('media', path, bytes);
      
      // Mettre à jour le profil avec l'URL
      await supabaseService.client.from('profiles').update({
        'profile_picture': imageUrl,
      }).eq('id', userId);

      await initUser();
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Err updateProfilePicture Supabase: $e');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  /// Soumission des documents de vérification via Supabase
  Future<bool> submitVerificationRequest(List<String> documents) async {
    try {
      _isLoading = true; notifyListeners();
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      await supabaseService.client.from('profiles').update({
        'verification_documents': documents,
        'verification_status': 'pending',
        'verification_message': null,
      }).eq('id', userId);

      await initUser();
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur submitVerificationRequest Supabase: $e');
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<void> updateLastReadAnnouncement() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      // Mise à jour optimiste locale
      _currentUser = _currentUser!.copyWith(lastReadAnnouncement: now);
      notifyListeners();

      // Mise à jour sur le serveur en arrière-plan
      await supabaseService.client
          .from('profiles')
          .update({'last_read_announcement': now.toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Erreur updateLastReadAnnouncement: $e');
    }
  }

  Future<void> updateLastReadProperties() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      // Mise à jour optimiste locale
      _currentUser = _currentUser!.copyWith(lastReadProperties: now);
      notifyListeners();

      // Mise à jour sur le serveur en arrière-plan
      await supabaseService.client
          .from('profiles')
          .update({'last_read_properties': now.toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Erreur updateLastReadProperties: $e');
    }
  }

  /// Retourne un message d'erreur convivial en français (compatibilité Firebase et Django)
  static String getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'L\'email est déjà lié à un autre compte.';
      case 'invalid-email': return 'L\'adresse email est incorrecte.';
      case 'weak-password': return 'Le mot de passe est trop faible.';
      case 'user-not-found': return 'Email incorrect ou utilisateur inexistant.';
      case 'wrong-password': return 'Mot de passe incorrect.';
      case 'network-request-failed': return 'Vérifiez votre connexion internet.';
      default: return 'Une erreur est survenue ($code).';
    }
  }
}
