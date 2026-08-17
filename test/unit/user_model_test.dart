import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/models/user_model.dart';

void main() {
  group('UserModel', () {
    // =============================================
    // fromMap — parsing complet
    // =============================================
    group('fromMap', () {
      test('parse correctement les données Supabase (snake_case)', () {
        final map = {
          'name': 'Amadou Traoré',
          'email': 'amadou@gmail.com',
          'user_type': 'propriétaire',
          'created_at': '2025-01-15T10:00:00.000Z',
          'favorites_ids': ['prop-1', 'prop-2'],
          'profile_picture': 'https://example.com/avatar.jpg',
          'phone': '+22670000000',
          'verification_status': 'verified',
          'verification_documents': ['doc1.pdf', 'doc2.pdf'],
          'verification_message': null,
          'role': 'user',
          'last_read_announcement': '2025-06-01T00:00:00.000Z',
          'last_read_properties': '2025-06-01T00:00:00.000Z',
          'fcm_token': 'token-xyz',
          'subscription_status': 'active',
          'trial_ends_at': '2025-07-15T00:00:00.000Z',
          'subscription_ends_at': '2026-01-15T00:00:00.000Z',
        };

        final user = UserModel.fromMap(map, 'user-123');

        expect(user.id, 'user-123');
        expect(user.name, 'Amadou Traoré');
        expect(user.email, 'amadou@gmail.com');
        expect(user.userType, 'propriétaire');
        expect(user.favoritesIds, ['prop-1', 'prop-2']);
        expect(user.profilePicture, 'https://example.com/avatar.jpg');
        expect(user.phone, '+22670000000');
        expect(user.verificationStatus, 'verified');
        expect(user.verificationDocuments.length, 2);
        expect(user.role, 'user');
        expect(user.fcmToken, 'token-xyz');
        expect(user.subscriptionStatus, 'active');
        expect(user.trialEndsAt, isNotNull);
        expect(user.subscriptionEndsAt, isNotNull);
      });

      test('parse les noms alternatifs (full_name, user_name, first+last)', () {
        // Cas 1 : full_name
        final map1 = {
          'full_name': 'Fatou Diallo',
          'email': 'fatou@test.com',
          'created_at': '2025-01-01T00:00:00.000Z',
        };
        expect(UserModel.fromMap(map1, 'u1').name, 'Fatou Diallo');

        // Cas 2 : user_name
        final map2 = {
          'user_name': 'Ibrahim',
          'email': 'ibrahim@test.com',
          'created_at': '2025-01-01T00:00:00.000Z',
        };
        expect(UserModel.fromMap(map2, 'u2').name, 'Ibrahim');

        // Cas 3 : first_name + last_name
        final map3 = {
          'first_name': 'Ousmane',
          'last_name': 'Ouédraogo',
          'email': 'ousmane@test.com',
          'created_at': '2025-01-01T00:00:00.000Z',
        };
        expect(UserModel.fromMap(map3, 'u3').name, 'Ousmane Ouédraogo');
      });

      test('valeurs par défaut si données manquantes', () {
        final user = UserModel.fromMap({}, 'u-empty');

        expect(user.name, '');
        expect(user.email, '');
        expect(user.userType, 'locataire');
        expect(user.verificationStatus, 'none');
        expect(user.role, 'user');
        expect(user.favoritesIds, isEmpty);
        expect(user.verificationDocuments, isEmpty);
        expect(user.subscriptionStatus, 'none');
      });
    });

    // =============================================
    // fromSessionData
    // =============================================
    group('fromSessionData', () {
      test('crée un utilisateur minimal depuis la session', () {
        final user = UserModel.fromSessionData(
          userId: 'session-1',
          email: 'test@gmail.com',
        );

        expect(user.id, 'session-1');
        expect(user.email, 'test@gmail.com');
        expect(user.name, 'test');
        expect(user.userType, 'locataire');
        expect(user.role, 'user');
      });

      test('utilise le nom fourni au lieu du split email', () {
        final user = UserModel.fromSessionData(
          userId: 's2',
          email: 'user@mail.com',
          name: 'Nom Complet',
        );

        expect(user.name, 'Nom Complet');
      });
    });

    // =============================================
    // Logique des droits — isAdmin
    // =============================================
    group('isAdmin', () {
      test('retourne true si role == admin', () {
        final user = _makeUser(role: 'admin', email: 'random@test.com');
        expect(user.isAdmin, true);
      });

      test('retourne false si role == user et email non-admin', () {
        final user = _makeUser(role: 'user', email: 'random@test.com');
        expect(user.isAdmin, false);
      });
    });

    // =============================================
    // Logique des droits — isOwner
    // =============================================
    group('isOwner', () {
      test('retourne true si userType == propriétaire', () {
        final user = _makeUser(userType: 'propriétaire');
        expect(user.isOwner, true);
      });

      test('retourne true si admin (même si locataire)', () {
        final user = _makeUser(userType: 'locataire', role: 'admin');
        expect(user.isOwner, true);
      });

      test('retourne false si locataire simple', () {
        final user = _makeUser(userType: 'locataire', role: 'user');
        expect(user.isOwner, false);
      });
    });

    // =============================================
    // Logique des droits — canPost
    // =============================================
    group('canPost', () {
      test('retourne true si propriétaire avec téléphone', () {
        final user = _makeUser(
          userType: 'propriétaire',
          phone: '+22670000000',
        );
        expect(user.canPost, true);
      });

      test('retourne false si propriétaire SANS téléphone', () {
        final user = _makeUser(userType: 'propriétaire', phone: null);
        expect(user.canPost, false);
      });

      test('retourne false si téléphone est "Non renseigné"', () {
        final user = _makeUser(
          userType: 'propriétaire',
          phone: 'Non renseigné',
        );
        expect(user.canPost, false);
      });

      test('retourne false si locataire même avec téléphone', () {
        final user = _makeUser(
          userType: 'locataire',
          phone: '+22670000000',
        );
        expect(user.canPost, false);
      });
    });

    // =============================================
    // Logique des droits — isVerified
    // =============================================
    group('isVerified', () {
      test('retourne true si verification_status == verified', () {
        final user = _makeUser(verificationStatus: 'verified');
        expect(user.isVerified, true);
      });

      test('retourne false si pending', () {
        final user = _makeUser(verificationStatus: 'pending');
        expect(user.isVerified, false);
      });

      test('retourne false si none', () {
        final user = _makeUser(verificationStatus: 'none');
        expect(user.isVerified, false);
      });
    });

    // =============================================
    // Logique abonnement — hasActiveSubscription
    // =============================================
    group('hasActiveSubscription', () {
      test('retourne true pour les admins (pas besoin d\'abonnement)', () {
        final user = _makeUser(role: 'admin');
        expect(user.hasActiveSubscription, true);
      });

      test('retourne true pour les locataires (pas besoin d\'abonnement)', () {
        final user = _makeUser(userType: 'locataire');
        expect(user.hasActiveSubscription, true);
      });

      test('retourne true si trial encore valide', () {
        final user = _makeUser(
          userType: 'propriétaire',
          trialEndsAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(user.hasActiveSubscription, true);
      });

      test('retourne true si abonnement encore valide', () {
        final user = _makeUser(
          userType: 'propriétaire',
          subscriptionEndsAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(user.hasActiveSubscription, true);
      });

      test('retourne false si propriétaire avec trial ET abonnement expirés', () {
        final user = _makeUser(
          userType: 'propriétaire',
          trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
          subscriptionEndsAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(user.hasActiveSubscription, false);
      });

      test('retourne false si propriétaire sans aucune date', () {
        final user = _makeUser(userType: 'propriétaire');
        expect(user.hasActiveSubscription, false);
      });
    });

    // =============================================
    // toMap
    // =============================================
    group('toMap', () {
      test('produit les clés snake_case attendues par Supabase', () {
        final user = _makeUser(
          name: 'Test User',
          email: 'test@test.com',
          phone: '+22670000000',
        );

        final map = user.toMap();
        expect(map['user_name'], 'Test User');
        expect(map['email'], 'test@test.com');
        expect(map['phone'], '+22670000000');
        expect(map['user_type'], 'locataire');
        expect(map['role'], 'user');
        expect(map['verification_status'], 'none');
        // Ne doit PAS contenir 'id' (géré par Supabase Auth)
        expect(map.containsKey('id'), false);
      });
    });

    // =============================================
    // copyWith
    // =============================================
    group('copyWith', () {
      test('crée une copie modifiée sans altérer l\'original', () {
        final original = _makeUser(name: 'Original', phone: null);
        final modified = original.copyWith(
          name: 'Modifié',
          phone: '+22670000000',
          verificationStatus: 'verified',
        );

        expect(modified.name, 'Modifié');
        expect(modified.phone, '+22670000000');
        expect(modified.verificationStatus, 'verified');
        // L'original ne doit pas changer
        expect(original.name, 'Original');
        expect(original.phone, null);
        expect(original.verificationStatus, 'none');
      });
    });
  });
}

/// Helper pour créer un UserModel rapidement avec des valeurs par défaut
UserModel _makeUser({
  String id = 'test-id',
  String name = 'Test User',
  String email = 'test@test.com',
  String userType = 'locataire',
  String role = 'user',
  String? phone,
  String verificationStatus = 'none',
  DateTime? trialEndsAt,
  DateTime? subscriptionEndsAt,
}) {
  return UserModel(
    id: id,
    name: name,
    email: email,
    userType: userType,
    createdAt: DateTime(2025, 1, 1),
    role: role,
    phone: phone,
    verificationStatus: verificationStatus,
    trialEndsAt: trialEndsAt,
    subscriptionEndsAt: subscriptionEndsAt,
  );
}
