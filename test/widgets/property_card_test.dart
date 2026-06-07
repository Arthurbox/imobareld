import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/widgets/property_card.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/comment_model.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

// Mock simple pour les contrôleurs
class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  UserModel? get currentUser => null;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  bool get isAuthenticated => false;
  
  @override
  void clearError() {}
  
  @override
  Future<bool> initUser() async => false;
  
  @override
  Future<bool> login({required String email, required String password}) async => true;
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<bool> register({required String name, required String email, required String password, required String userType, String? phone}) async => true;
  
  @override
  Future<bool> signInWithGoogle({String userType = 'locataire'}) async => true;
  
  @override
  Future<void> toggleFavorite(String propertyId) async {}

  @override
  Future<UserModel?> getUserById(String userId) async => null;

  @override
  Future<String?> getSupportUserId() async => null;

  @override
  Future<bool> submitVerificationRequest(List<String> documents) async => true;

  @override
  Future<bool> updateProfile({required String name, String? phone}) async => true;

  @override
  Future<bool> updateProfilePicture(XFile image) async => true;

  @override
  Future<void> updateLastReadProperties() async {}

  @override
  Future<void> updateLastReadAnnouncement() async {}

  @override
  Widget getNextScreen() => const SizedBox();

  @override
  Future<bool> resetPassword(String email) async => true;

  @override
  Future<bool> updatePassword(String newPassword) async => true;

  @override
  bool get isRecoveringPassword => false;
}

class MockPropertyController extends ChangeNotifier implements PropertyController {
  @override
  bool get isLoading => false;
  
  @override
  List<PropertyModel> get pagedProperties => [];
  
  @override
  bool get isFetchingMore => false;
  
  @override
  bool get hasMore => false;

  @override
  Future<List<CommentModel>> getComments(String propertyId) => Future.value([]);
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testProperty = PropertyModel(
    id: 'prop123',
    ownerId: 'owner1',
    title: 'Bel Appartement',
    description: 'Une superbe vue',
    price: 150000,
    priceDuration: 'Mois',
    category: 'Appartement',
    quartier: 'Ouaga 2000',
    pieces: 3,
    images: [],
    isCertified: true,
    createdAt: DateTime.now(),
  );

  group('PropertyCard Widget Tests', () {
    testWidgets('PropertyCard displays title, price and certification', (WidgetTester tester) async {
      final mockAuth = MockAuthController();
      final mockProp = MockPropertyController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: mockAuth),
            ChangeNotifierProvider<PropertyController>.value(value: mockProp),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 300,
                width: 400,
                child: PropertyCard(
                  property: testProperty,
                  onCommentTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Laisser le temps au StreamBuilder

      debugPrint('Checking for 3 pcs...');
      expect(find.text('3 pcs'), findsOneWidget);
      
      debugPrint('Checking for price...');
      expect(find.textContaining('150 000'), findsOneWidget);
      
      debugPrint('Checking for certification...');
      expect(find.text('CERTIFIÉ'), findsOneWidget);
    });
  });
}
