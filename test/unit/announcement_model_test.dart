import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/models/announcement_model.dart';

void main() {
  group('AnnouncementModel', () {
    // =============================================
    // fromMap
    // =============================================
    group('fromMap', () {
      test('parse correctement une annonce complète (snake_case)', () {
        final map = {
          'author_id': 'author-1',
          'author_name': 'Admin IMOBARELD',
          'content': 'Bienvenue sur la plateforme !',
          'created_at': '2025-06-01T12:00:00.000Z',
          'reply_to_id': 'ann-parent',
          'reply_to_content': 'Message original',
          'reply_to_author_name': 'Amadou',
        };

        final ann = AnnouncementModel.fromMap(map, 'ann-1');

        expect(ann.id, 'ann-1');
        expect(ann.authorId, 'author-1');
        expect(ann.authorName, 'Admin IMOBARELD');
        expect(ann.content, 'Bienvenue sur la plateforme !');
        expect(ann.replyToId, 'ann-parent');
        expect(ann.replyToContent, 'Message original');
        expect(ann.replyToAuthorName, 'Amadou');
      });

      test('parse correctement en camelCase', () {
        final map = {
          'authorId': 'a-2',
          'authorName': 'Test',
          'content': 'Hello',
          'createdAt': '2025-01-01T00:00:00.000Z',
          'replyToId': null,
        };

        final ann = AnnouncementModel.fromMap(map, 'ann-2');
        expect(ann.authorId, 'a-2');
        expect(ann.replyToId, isNull);
      });

      test('valeurs par défaut si données manquantes', () {
        final ann = AnnouncementModel.fromMap({}, 'ann-3');

        expect(ann.authorId, '');
        expect(ann.authorName, 'Anonyme');
        expect(ann.content, '');
        expect(ann.replyToId, isNull);
        expect(ann.replyToContent, isNull);
      });
    });

    // =============================================
    // toMap
    // =============================================
    group('toMap', () {
      test('produit le Map attendu sans created_at ni id', () {
        final ann = AnnouncementModel(
          id: 'ann-1',
          authorId: 'a-1',
          authorName: 'Admin',
          content: 'Test',
          createdAt: DateTime(2025, 1, 1),
          replyToId: 'parent-1',
          replyToContent: 'Parent content',
          replyToAuthorName: 'Parent',
        );

        final map = ann.toMap();
        expect(map['author_id'], 'a-1');
        expect(map['author_name'], 'Admin');
        expect(map['content'], 'Test');
        expect(map['reply_to_id'], 'parent-1');
        // Ne doit PAS contenir 'id' ni 'created_at'
        expect(map.containsKey('id'), false);
        expect(map.containsKey('created_at'), false);
      });
    });

    // =============================================
    // copyWith
    // =============================================
    group('copyWith', () {
      test('modifie uniquement les champs spécifiés', () {
        final original = AnnouncementModel(
          id: 'a-1',
          authorId: 'auth-1',
          authorName: 'Original',
          content: 'Ancien contenu',
          createdAt: DateTime(2025, 1, 1),
        );

        final modified = original.copyWith(content: 'Nouveau contenu');

        expect(modified.content, 'Nouveau contenu');
        expect(modified.authorName, 'Original');
        expect(modified.id, 'a-1');
      });
    });
  });
}
