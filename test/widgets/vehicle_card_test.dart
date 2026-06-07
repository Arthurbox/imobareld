import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/features/vehicles/widgets/vehicle_card.dart';
import 'package:imobareld/models/vehicle_model.dart';

void main() {
  final testVehicle = VehicleModel(
    id: '1',
    model: 'Toyota Corolla',
    pricePerDay: 25000,
    images: [], // Vide pour éviter le décodage base64 complexe dans le test simple
    videoUrls: [],
    companyName: 'Express Rental',
    ownerId: 'owner123',
    description: 'Une voiture confortable',
    city: 'Ouagadougou',
    createdAt: DateTime.now(),
  );

  testWidgets('VehicleCard displays correct information', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleCard(
            vehicle: testVehicle,
            onTap: () {},
          ),
        ),
      ),
    );

    // Vérifier que le nom de l'entreprise est affiché
    expect(find.text('Express Rental'), findsOneWidget);

    // Vérifier que le modèle est affiché
    expect(find.text('Toyota Corolla'), findsOneWidget);

    // Vérifier que le prix est affiché (Formaté sans "Prix :")
    expect(find.text('25000 F/jour'), findsOneWidget);

    // Vérifier la présence du bouton Détail
    expect(find.text('Détail'), findsOneWidget);
  });

  testWidgets('VehicleCard triggers onTap when image or button is pressed', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleCard(
            vehicle: testVehicle,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Tap sur le bouton Détail
    await tester.tap(find.text('Détail'));
    expect(tapped, isTrue);

    // Reset et tap sur l'image (GestureDetector)
    tapped = false;
    // On cherche le GestureDetector qui entoure l'image (Container avec Icon par défaut si imageUrl vide)
    await tester.tap(find.byIcon(Icons.directions_car));
    expect(tapped, isTrue);
  });
}
