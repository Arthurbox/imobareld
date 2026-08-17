import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/features/auth/auth_controller.dart';

void main() {
  group('AuthController Unit Tests', () {
    test('getErrorMessage returns friendly French messages for Firebase/Supabase codes', () {
      expect(AuthController.getErrorMessage('email-already-in-use'), contains('déjà lié'));
      expect(AuthController.getErrorMessage('invalid-email'), contains('incorrect'));
      expect(AuthController.getErrorMessage('weak-password'), contains('faible'));
      expect(AuthController.getErrorMessage('user-not-found'), contains('Email incorrect'));
      expect(AuthController.getErrorMessage('wrong-password'), contains('Mot de passe incorrect'));
      expect(AuthController.getErrorMessage('unknown'), contains('Une erreur est survenue'));
    });
  });
}
