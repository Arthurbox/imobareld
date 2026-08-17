import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/models/property_model.dart';

void main() {
  group('PropertyModel', () {
    // =============================================
    // fromMap — Format snake_case (Supabase)
    // =============================================
    group('fromMap (snake_case)', () {
      test('parse correctement toutes les données Supabase', () {
        final map = {
          'owner_id': 'user-123',
          'title': 'Belle villa Ouaga 2000',
          'description': 'Villa de luxe',
          'category': 'Maison',
          'price': 350000,
          'city': 'Ouagadougou',
          'quartier': 'Ouaga 2000',
          'images': ['img1.jpg', 'img2.jpg'],
          'pieces': 4,
          'created_at': '2025-01-15T10:00:00.000Z',
          'latitude': 12.3456,
          'longitude': -1.5167,
          'likes_count': 42,
          'is_liked': true,
          'video_urls': ['video1.mp4'],
          'is_owner_verified': true,
          'owner_name': 'Amadou',
          'owner_phone': '+22670000000',
          'price_duration': 'mois',
          'amenities': ['Wifi', 'Climatisation'],
          'is_certified': true,
          'average_rating': 4.5,
          'review_count': 10,
          'transaction_type': 'Location',
          'rent_advance_months': 3,
          'security_deposit_months': 2,
          'is_boosted': true,
          'boost_expiry_date': '2025-06-15T10:00:00.000Z',
          'boost_plan_type': 'premium',
          'comments_count': 5,
        };

        final property = PropertyModel.fromMap(map, 'prop-abc123');

        expect(property.id, 'prop-abc123');
        expect(property.ownerId, 'user-123');
        expect(property.title, 'Belle villa Ouaga 2000');
        expect(property.description, 'Villa de luxe');
        expect(property.category, 'Maison');
        expect(property.price, 350000.0);
        expect(property.city, 'Ouagadougou');
        expect(property.quartier, 'Ouaga 2000');
        expect(property.images, ['img1.jpg', 'img2.jpg']);
        expect(property.pieces, 4);
        expect(property.latitude, 12.3456);
        expect(property.longitude, -1.5167);
        expect(property.likesCount, 42);
        expect(property.isLiked, true);
        expect(property.videoUrls, ['video1.mp4']);
        expect(property.isOwnerVerified, true);
        expect(property.ownerName, 'Amadou');
        expect(property.ownerPhone, '+22670000000');
        expect(property.priceDuration, 'mois');
        expect(property.amenities, ['Wifi', 'Climatisation']);
        expect(property.isCertified, true);
        expect(property.averageRating, 4.5);
        expect(property.reviewCount, 10);
        expect(property.transactionType, 'Location');
        expect(property.rentAdvanceMonths, 3);
        expect(property.securityDepositMonths, 2);
        expect(property.isBoosted, true);
        expect(property.boostPlanType, 'premium');
        expect(property.commentsCount, 5);
      });

      test('parse le prix en string correctement', () {
        final map = {
          'owner_id': 'u1',
          'title': 'Test',
          'description': '',
          'category': 'Maison',
          'price': '250000',
          'quartier': 'Cissin',
          'images': <String>[],
          'pieces': '3',
          'created_at': '2025-01-01T00:00:00.000Z',
        };

        final property = PropertyModel.fromMap(map, 'id-1');
        expect(property.price, 250000.0);
        expect(property.pieces, 3);
      });
    });

    // =============================================
    // fromMap — Format camelCase (legacy/Firebase)
    // =============================================
    group('fromMap (camelCase)', () {
      test('parse correctement les données en camelCase', () {
        final map = {
          'ownerId': 'user-456',
          'title': 'Appartement',
          'description': 'Bel appart',
          'category': 'Appartement',
          'price': 150000,
          'quartier': 'Pissy',
          'images': <String>[],
          'pieces': 2,
          'createdAt': '2025-03-01T00:00:00.000Z',
          'likesCount': 5,
          'isLiked': false,
          'videoUrls': ['v1.mp4', 'v2.mp4'],
          'isOwnerVerified': false,
          'ownerName': 'Ibrahim',
          'priceDuration': 'Jour',
          'isCertified': false,
          'averageRating': 3.2,
          'reviewCount': 2,
          'transactionType': 'Vente',
          'rentAdvanceMonths': 0,
          'securityDepositMonths': 0,
          'isBoosted': false,
          'commentsCount': 1,
        };

        final property = PropertyModel.fromMap(map, 'id-2');
        expect(property.ownerId, 'user-456');
        expect(property.likesCount, 5);
        expect(property.videoUrls.length, 2);
        expect(property.priceDuration, 'jour');
        expect(property.transactionType, 'Vente');
      });
    });

    // =============================================
    // Valeurs par défaut
    // =============================================
    group('valeurs par défaut', () {
      test('utilise les bonnes valeurs par défaut si données manquantes', () {
        final map = {
          'title': 'Terrain nu',
          'description': '',
          'quartier': 'Somgandé',
          'images': <String>[],
          'pieces': 0,
        };

        final property = PropertyModel.fromMap(map, 'id-3');
        expect(property.ownerId, '');
        expect(property.category, 'Maison');
        expect(property.city, 'Ouagadougou');
        expect(property.price, 0.0);
        expect(property.likesCount, 0);
        expect(property.isLiked, false);
        expect(property.videoUrls, isEmpty);
        expect(property.isOwnerVerified, false);
        expect(property.priceDuration, 'mois');
        expect(property.amenities, isEmpty);
        expect(property.isCertified, false);
        expect(property.averageRating, 0.0);
        expect(property.reviewCount, 0);
        expect(property.transactionType, 'Location');
        expect(property.isBoosted, false);
        expect(property.commentsCount, 0);
      });
    });

    // =============================================
    // toMap
    // =============================================
    group('toMap', () {
      test('produit un Map avec les clés snake_case attendues par Supabase', () {
        final property = PropertyModel(
          id: 'test-id',
          ownerId: 'owner-1',
          title: 'Maison test',
          description: 'Description',
          category: 'Maison',
          price: 200000,
          city: 'Bobo-Dioulasso',
          quartier: 'Secteur 1',
          images: ['img.jpg'],
          pieces: 3,
          createdAt: DateTime(2025, 1, 1),
          amenities: ['Wifi'],
          transactionType: 'Location',
        );

        final map = property.toMap();
        expect(map['owner_id'], 'owner-1');
        expect(map['title'], 'Maison test');
        expect(map['price'], 200000);
        expect(map['city'], 'Bobo-Dioulasso');
        expect(map['images'], ['img.jpg']);
        expect(map['amenities'], ['Wifi']);
        expect(map['transaction_type'], 'Location');
        expect(map['is_boosted'], false);
        // toMap ne doit PAS contenir 'id' ni 'createdAt' (gérés par Supabase)
        expect(map.containsKey('id'), false);
        expect(map.containsKey('created_at'), false);
      });
    });

    // =============================================
    // toFilteredMap
    // =============================================
    group('toFilteredMap', () {
      test('filtre correctement les clés autorisées', () {
        final property = PropertyModel(
          ownerId: 'o1',
          title: 'Test',
          description: 'Desc',
          category: 'Terrain',
          price: 500000,
          quartier: 'Q1',
          images: [],
          pieces: 0,
          createdAt: DateTime.now(),
        );

        final filtered = property.toFilteredMap(['title', 'price', 'category']);
        expect(filtered.length, 3);
        expect(filtered['title'], 'Test');
        expect(filtered['price'], 500000);
        expect(filtered.containsKey('description'), false);
      });
    });

    // =============================================
    // copyWith
    // =============================================
    group('copyWith', () {
      test('crée une copie avec les champs modifiés', () {
        final original = PropertyModel(
          id: 'id-1',
          ownerId: 'o1',
          title: 'Ancien titre',
          description: 'Desc',
          category: 'Maison',
          price: 100000,
          quartier: 'Q1',
          images: [],
          pieces: 2,
          createdAt: DateTime(2025, 1, 1),
          isBoosted: false,
          likesCount: 0,
        );

        final modified = original.copyWith(
          title: 'Nouveau titre',
          price: 200000,
          isBoosted: true,
          likesCount: 10,
        );

        expect(modified.title, 'Nouveau titre');
        expect(modified.price, 200000);
        expect(modified.isBoosted, true);
        expect(modified.likesCount, 10);
        // Les champs non modifiés doivent rester identiques
        expect(modified.id, 'id-1');
        expect(modified.ownerId, 'o1');
        expect(modified.category, 'Maison');
        expect(modified.pieces, 2);
      });
    });

    // =============================================
    // referenceCode
    // =============================================
    group('referenceCode', () {
      test('génère un code de référence à partir de l\'ID', () {
        final property = PropertyModel(
          id: 'abcdef-1234-5678',
          ownerId: 'o1',
          title: 'T',
          description: 'D',
          category: 'Maison',
          price: 0,
          quartier: 'Q',
          images: [],
          pieces: 0,
          createdAt: DateTime.now(),
        );

        expect(property.referenceCode, 'REF-ABCDEF');
      });

      test('retourne REF-UNKNOWN si ID trop court', () {
        final property = PropertyModel(
          id: 'abc',
          ownerId: 'o1',
          title: 'T',
          description: 'D',
          category: 'Maison',
          price: 0,
          quartier: 'Q',
          images: [],
          pieces: 0,
          createdAt: DateTime.now(),
        );

        expect(property.referenceCode, 'REF-UNKNOWN');
      });

      test('retourne REF-UNKNOWN si ID est null', () {
        final property = PropertyModel(
          ownerId: 'o1',
          title: 'T',
          description: 'D',
          category: 'Maison',
          price: 0,
          quartier: 'Q',
          images: [],
          pieces: 0,
          createdAt: DateTime.now(),
        );

        expect(property.referenceCode, 'REF-UNKNOWN');
      });
    });
  });
}
