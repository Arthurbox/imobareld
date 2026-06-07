import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/features/auth/auth_controller.dart';

void main() {
  group('AuthController Unit Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    test('Initial state is correct', () {
      expect(authController.currentUser, isNull);
      expect(authController.isLoading, isFalse);
      expect(authController.errorMessage, isNull);
    });

    test('clearError resets errorMessage to null', () {
      authController.clearError();
      expect(authController.errorMessage, isNull);
    });

    test('getErrorMessage returns friendly French messages for Firebase codes', () {
      expect(AuthController.getErrorMessage('email-already-in-use'), contains('déjà lié'));
      expect(AuthController.getErrorMessage('invalid-email'), contains('incorrect'));
      expect(AuthController.getErrorMessage('weak-password'), contains('faible'));
      expect(AuthController.getErrorMessage('user-not-found'), contains('Email incorrect'));
      expect(AuthController.getErrorMessage('wrong-password'), contains('Mot de passe incorrect'));
      expect(AuthController.getErrorMessage('unknown'), contains('Erreur inconnue'));
    });
  });
}
