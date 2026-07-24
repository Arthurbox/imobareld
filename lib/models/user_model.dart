/// depuis Firebase Firestore
library;
import 'package:imobareld/core/constants/user_roles.dart';


class UserModel {
  // ========================================
  // PROPRIÉTÉS DE L'UTILISATEUR
  // ========================================
  
  /// Identifiant unique de l'utilisateur (généré par Firebase Auth)
  final String id;
  
  /// Nom complet de l'utilisateur
  final String name;
  
  /// Adresse email de l'utilisateur (utilisée pour la connexion)
  final String email;
  
  /// Type d'utilisateur : 'locataire' ou 'propriétaire'
  /// - 'locataire' : utilisateur qui cherche des biens
  /// - 'propriétaire' : utilisateur qui publie des annonces
  final String userType;
  
  /// Rôle de l'utilisateur ('user', 'admin')
  final String role;
  /// Date de création du compte utilisateur
  final DateTime createdAt;

  /// Identifiants des propriétés favorites
  final List<String> favoritesIds;

  /// Photo de profil (URL /media ou Google)
  final String? profilePicture;

  /// Numéro de téléphone
  final String? phone;

  /// Statut de vérification : 'none', 'pending', 'verified', 'rejected'
  final String verificationStatus;

  /// Documents de vérification (URLs de fichiers)
  final List<String> verificationDocuments;

  /// Message de refus éventuel
  final String? verificationMessage;
  
  /// Date de dernière lecture des annonces (pour le badge de notification)
  final DateTime? lastReadAnnouncement;
  
  /// Date de dernière lecture des nouveaux biens
  final DateTime? lastReadProperties;

  /// Token Firebase Cloud Messaging pour les push notifications
  final String? fcmToken;

  /// Statut de l'abonnement : 'trial', 'active', 'expired', 'none'
  final String subscriptionStatus;

  /// Date de fin de la période d'essai (6 mois)
  final DateTime? trialEndsAt;

  /// Date de fin de l'abonnement payant
  final DateTime? subscriptionEndsAt;

  /// Helper pour savoir si l'utilisateur est vérifié
  bool get isVerified => verificationStatus == 'verified';

  /// Un utilisateur est admin s'il a le rôle 'admin' OU si c'est l'Administrateur Suprême par Email
  bool get isAdmin => role == 'admin' || isSupremeAdmin;

  /// Un utilisateur a les droits de propriétaire s'il a le type 'propriétaire' OU s'il est admin
  bool get isOwner => userType == UserRoles.owner || isAdmin;

  /// Vérifie si l'utilisateur a un abonnement actif ou une période d'essai valide
  bool get hasActiveSubscription {
    if (isAdmin) return true; // Les admins n'ont pas besoin d'abonnement
    if (!isOwner) return true; // Les locataires n'ont pas besoin d'abonnement
    
    final now = DateTime.now();
    final isTrialValid = trialEndsAt != null && trialEndsAt!.isAfter(now);
    final isSubValid = subscriptionEndsAt != null && subscriptionEndsAt!.isAfter(now);
    
    return isTrialValid || isSubValid;
  }

  /// Vérifie si l'utilisateur peut publier (doit être propriétaire/admin ET avoir un téléphone)
  bool get canPost => isOwner && phone != null && phone!.isNotEmpty && phone != 'Non renseigné';

  /// Vérifie si l'utilisateur est l'Administrateur Suprême (Email maître)
  bool get isSupremeAdmin => email.toLowerCase() == UserRoles.supremeAdminEmail.toLowerCase();

  // ========================================
  // CONSTRUCTEUR
  // ========================================
  
  /// Crée une nouvelle instance de UserModel
  /// Tous les champs sont obligatoires (required)
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.createdAt,
    this.favoritesIds = const [],
    this.profilePicture,
    this.phone,
    this.verificationStatus = 'none',
    this.verificationDocuments = const [],
    this.verificationMessage,
    this.role = 'user',
    this.lastReadAnnouncement,
    this.lastReadProperties,
    this.fcmToken,
    this.subscriptionStatus = 'trial',
    this.trialEndsAt,
    this.subscriptionEndsAt,
  });

  // ========================================
  // MÉTHODE : CRÉER DEPUIS FIRESTORE
  // ========================================
  
  /// Factory constructor : crée un UserModel à partir d'un Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? map['full_name'] ?? map['user_name'] ?? 
            ((map['first_name'] != null || map['last_name'] != null) 
              ? '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim() 
              : (map['username'] ?? '')),
      email: map['email'] ?? map['username'] ?? '',
      userType: map['userType'] ?? map['user_type'] ?? 'locataire',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      favoritesIds: List<String>.from(map['favoritesIds'] ?? map['favorites_ids'] ?? []),
      profilePicture: map['profilePicture'] ?? map['profile_picture'],
      phone: map['phone'],
      verificationStatus: map['verificationStatus'] ?? map['verification_status'] ?? 'none',
      verificationDocuments: List<String>.from(map['verificationDocuments'] ?? map['verification_documents'] ?? []),
      verificationMessage: map['verificationMessage'] ?? map['verification_message'],
      role: map['role'] ?? 'user',
      lastReadAnnouncement: (map['lastReadAnnouncement'] ?? map['last_read_announcement']) != null 
          ? DateTime.parse((map['lastReadAnnouncement'] ?? map['last_read_announcement']).toString()) 
          : null,
      lastReadProperties: (map['lastReadProperties'] ?? map['last_read_properties']) != null 
          ? DateTime.parse((map['lastReadProperties'] ?? map['last_read_properties']).toString()) 
          : null,
      fcmToken: map['fcm_token'] ?? map['fcmToken'],
      subscriptionStatus: map['subscription_status'] ?? map['subscriptionStatus'] ?? 'none',
      trialEndsAt: (map['trial_ends_at'] ?? map['trialEndsAt']) != null 
          ? DateTime.parse((map['trial_ends_at'] ?? map['trialEndsAt']).toString()) 
          : null,
      subscriptionEndsAt: (map['subscription_ends_at'] ?? map['subscriptionEndsAt']) != null 
          ? DateTime.parse((map['subscription_ends_at'] ?? map['subscriptionEndsAt']).toString()) 
          : null,
    );
  }

  /// Factory constructor : crée un UserModel minimal depuis les données de session Supabase.
  /// Utilisé comme dernier recours quand on est hors ligne et qu'il n'y a pas encore de cache profil.
  factory UserModel.fromSessionData({
    required String userId,
    required String email,
    String? name,
  }) {
    return UserModel(
      id: userId,
      name: name ?? email.split('@').first,
      email: email,
      userType: 'locataire',
      createdAt: DateTime.now(),
      role: 'user',
      fcmToken: null,
      subscriptionStatus: 'none',
    );
  }

  // ========================================
  // MÉTHODE : CONVERTIR POUR FIRESTORE
  // ========================================
  
  Map<String, dynamic> toMap() {
    return {
      'user_name': name,
      'email': email,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'profile_picture': profilePicture,
      'phone': phone,
      'verification_status': verificationStatus,
      'verification_documents': verificationDocuments,
      'verification_message': verificationMessage,
      'role': role,
      'last_read_announcement': lastReadAnnouncement?.toIso8601String(),
      'last_read_properties': lastReadProperties?.toIso8601String(),
      'fcm_token': fcmToken,
      'subscription_status': subscriptionStatus,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'subscription_ends_at': subscriptionEndsAt?.toIso8601String(),
    };
  }

  // ========================================
  // MÉTHODE : CRÉER UNE COPIE MODIFIÉE
  // ========================================
  
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? userType,
    DateTime? createdAt,
    List<String>? favoritesIds,
    String? profilePicture,
    String? phone,
    String? verificationStatus,
    List<String>? verificationDocuments,
    String? verificationMessage,
    String? role,
    DateTime? lastReadAnnouncement,
    DateTime? lastReadProperties,
    String? fcmToken,
    String? subscriptionStatus,
    DateTime? trialEndsAt,
    DateTime? subscriptionEndsAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      favoritesIds: favoritesIds ?? this.favoritesIds,
      profilePicture: profilePicture ?? this.profilePicture,
      phone: phone ?? this.phone,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
      verificationMessage: verificationMessage ?? this.verificationMessage,
      role: role ?? this.role,
      lastReadAnnouncement: lastReadAnnouncement ?? this.lastReadAnnouncement,
      lastReadProperties: lastReadProperties ?? this.lastReadProperties,
      fcmToken: fcmToken ?? this.fcmToken,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
    );
  }
}
