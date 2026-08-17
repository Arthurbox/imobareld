import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/models/realisation_model.dart';

void main() {
  group('RealisationModel', () {
    // =============================================
    // fromMap
    // =============================================
    group('fromMap', () {
      test('parse correctement les données complètes', () {
        final map = {
          'id': 'real-1',
          'owner_id': 'owner-1',
          'title': 'Construction villa moderne',
          'description': 'Projet terminé en 6 mois',
          'images': ['img1.jpg', 'img2.jpg', 'img3.jpg'],
          'video_urls': ['vid1.mp4'],
          'created_at': '2025-03-15T10:00:00.000Z',
        };

        final real = RealisationModel.fromMap(map);

        expect(real.id, 'real-1');
        expect(real.ownerId, 'owner-1');
        expect(real.title, 'Construction villa moderne');
        expect(real.description, 'Projet terminé en 6 mois');
        expect(real.images.length, 3);
        expect(real.videoUrls, ['vid1.mp4']);
      });

      test('parse les images depuis une String JSON', () {
        final map = {
          'id': 'real-2',
          'owner_id': 'o-2',
          'title': 'Test',
          'description': '',
          'images': jsonEncode(['a.jpg', 'b.jpg']),
          'video_urls': jsonEncode(['v.mp4']),
          'created_at': '2025-01-01T00:00:00.000Z',
        };

        final real = RealisationModel.fromMap(map);
        expect(real.images, ['a.jpg', 'b.jpg']);
        expect(real.videoUrls, ['v.mp4']);
      });

      test('gère les images null ou absentes', () {
        final map = {
          'id': 'real-3',
          'owner_id': 'o-3',
          'title': 'Vide',
          'description': '',
          'created_at': '2025-01-01T00:00:00.000Z',
        };

        final real = RealisationModel.fromMap(map);
        expect(real.images, isEmpty);
        expect(real.videoUrls, isEmpty);
      });

      test('gère une string non-JSON pour les images', () {
        final map = {
          'id': 'real-4',
          'owner_id': 'o-4',
          'title': 'Test',
          'description': '',
          'images': 'pas-du-json',
          'created_at': '2025-01-01T00:00:00.000Z',
        };

        final real = RealisationModel.fromMap(map);
        expect(real.images, isEmpty);
      });

      test('parse les clés camelCase (legacy)', () {
        final map = {
          'id': 'real-5',
          'ownerId': 'o-5',
          'title': 'Legacy',
          'description': '',
          'videoUrls': ['v1.mp4'],
          'createdAt': '2025-06-01T00:00:00.000Z',
        };

        final real = RealisationModel.fromMap(map);
        expect(real.ownerId, 'o-5');
        expect(real.videoUrls, ['v1.mp4']);
      });
    });

    // =============================================
    // toMap
    // =============================================
    group('toMap', () {
      test('produit les clés snake_case attendues', () {
        final real = RealisationModel(
          ownerId: 'o-1',
          title: 'Projet A',
          description: 'Description',
          images: ['img.jpg'],
          videoUrls: ['vid.mp4'],
          createdAt: DateTime(2025, 6, 1),
        );

        final map = real.toMap();
        expect(map['owner_id'], 'o-1');
        expect(map['title'], 'Projet A');
        expect(map['images'], ['img.jpg']);
        expect(map['video_urls'], ['vid.mp4']);
        expect(map['created_at'], '2025-06-01T00:00:00.000');
        // Ne doit PAS contenir 'id'
        expect(map.containsKey('id'), false);
      });
    });

    // =============================================
    // copyWith
    // =============================================
    group('copyWith', () {
      test('modifie le titre sans toucher au reste', () {
        final original = RealisationModel(
          id: 'r-1',
          ownerId: 'o-1',
          title: 'Ancien',
          description: 'Desc',
          images: ['a.jpg'],
          createdAt: DateTime(2025, 1, 1),
        );

        final modified = original.copyWith(title: 'Nouveau');

        expect(modified.title, 'Nouveau');
        expect(modified.id, 'r-1');
        expect(modified.images, ['a.jpg']);
      });
    });
  });
}
