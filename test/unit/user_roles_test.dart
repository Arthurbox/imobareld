import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/core/constants/user_roles.dart';

void main() {
  group('UserRoles', () {
    // =============================================
    // Constantes de rôles
    // =============================================
    test('les constantes de rôle ont les bonnes valeurs', () {
      expect(UserRoles.user, 'locataire');
      expect(UserRoles.owner, 'propriétaire');
      expect(UserRoles.admin, 'admin');
    });

    test('agencyName est bien défini', () {
      expect(UserRoles.agencyName, 'IMOBARELD Agence');
      expect(UserRoles.agencyName, isNotEmpty);
    });

    // =============================================
    // Variables d'environnement
    // =============================================
    test('supremeAdminEmail est une String (non null)', () {
      expect(UserRoles.supremeAdminEmail, isA<String>());
    });

    test('agencyUserId est une String (non null)', () {
      expect(UserRoles.agencyUserId, isA<String>());
    });

    test('les rôles sont tous différents entre eux', () {
      final roles = [UserRoles.user, UserRoles.owner, UserRoles.admin];
      expect(roles.toSet().length, 3);
    });
  });
}
