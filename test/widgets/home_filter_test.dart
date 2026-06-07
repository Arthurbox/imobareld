import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/home/home_screen.dart';
import 'package:imobareld/features/search/search_screen.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/features/home/ad_controller.dart';
import 'package:imobareld/core/services/connectivity_service.dart';
import 'package:imobareld/core/services/accessibility_settings.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:imobareld/models/ad_model.dart';
import 'package:imobareld/models/comment_model.dart';
import 'package:imobareld/models/property_model.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  UserModel? get currentUser => UserModel(
    id: 'user123',
    name: 'Test User',
    email: 'test@example.com',
    userType: 'locataire',
    createdAt: DateTime.now(),
  );
  @override
  bool get isAuthenticated => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPropertyController extends ChangeNotifier implements PropertyController {
  @override
  Future<List<PropertyModel>> getFilteredProperties({String? category, String? city, int? limit, double? maxPrice, int? minPieces, double? minPrice, String? quartier, List<String>? requiredAmenities, String? searchQuery}) => Future.value([]);
  @override
  Future<List<CommentModel>> getComments(String propertyId) => Future.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAdController extends ChangeNotifier implements AdController {
  @override
  Future<List<AdModel>> getActiveAds() => Future.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectivityService extends ChangeNotifier implements ConnectivityService {
  @override
  bool get isOnline => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAccessibilitySettings extends ChangeNotifier implements AccessibilitySettings {
  @override
  ThemeMode get themeMode => ThemeMode.light;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Clicking Filtre on Home navigates to SearchScreen', (WidgetTester tester) async {
    // Suppress errors related to AdHelper and NotificationService
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('AdHelper') || 
          details.exception.toString().contains('NotificationService')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: MockAuthController()),
          ChangeNotifierProvider<PropertyController>.value(value: MockPropertyController()),
          ChangeNotifierProvider<AdController>.value(value: MockAdController()),
          ChangeNotifierProvider<ConnectivityService>.value(value: MockConnectivityService()),
          ChangeNotifierProvider<AccessibilitySettings>.value(value: MockAccessibilitySettings()),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Find the "Filtre" button in the middle of the page
    final filterButton = find.widgetWithText(ElevatedButton, 'Filtre');
    expect(filterButton, findsOneWidget);

    // Tap the button
    await tester.tap(filterButton);
    
    // Pump to start the animation
    await tester.pump();
    // Pump again to finish the navigation
    await tester.pumpAndSettle();

    // Verify SearchScreen is present
    expect(find.byType(SearchScreen), findsOneWidget);
    
    // Verify filters are opened (look for the "Filtres avancés" text)
    expect(find.text('Filtres avancés'), findsOneWidget);
  });
}
