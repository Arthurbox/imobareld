import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imobareld/core/utils/amenity_utils.dart';

void main() {
  group('AmenityUtils', () {
    // =============================================
    // Correspondance aménité → icône
    // =============================================
    test('retourne l\'icône correcte pour chaque aménité connue', () {
      expect(AmenityUtils.getIcon('Wifi'), Icons.wifi);
      expect(AmenityUtils.getIcon('Climatisation'), Icons.ac_unit);
      expect(AmenityUtils.getIcon('Climatisé'), Icons.ac_unit);
      expect(AmenityUtils.getIcon('Piscine'), Icons.pool);
      expect(AmenityUtils.getIcon('Eau chaude'), Icons.hot_tub);
      expect(AmenityUtils.getIcon('Parking'), Icons.local_parking);
      expect(AmenityUtils.getIcon('Netflix'), Icons.tv);
      expect(AmenityUtils.getIcon('Canal+'), Icons.live_tv);
      expect(AmenityUtils.getIcon('Gaz'), Icons.propane);
      expect(AmenityUtils.getIcon('Frigo'), Icons.kitchen);
      expect(AmenityUtils.getIcon('Micro-ondes'), Icons.microwave);
      expect(AmenityUtils.getIcon('Sécurité 24/7'), Icons.security);
      expect(AmenityUtils.getIcon('Sonabel'), Icons.lightbulb_outline);
      expect(AmenityUtils.getIcon('ONEA'), Icons.water_drop_outlined);
    });

    test('retourne l\'icône fallback pour une aménité inconnue', () {
      expect(AmenityUtils.getIcon('Jardin'), Icons.check_circle_outline);
      expect(AmenityUtils.getIcon('Ascenseur'), Icons.check_circle_outline);
      expect(AmenityUtils.getIcon(''), Icons.check_circle_outline);
    });

    test('le map amenityIcons contient toutes les aménités', () {
      // Vérifie qu'on n'a pas oublié d'aménité
      expect(AmenityUtils.amenityIcons.length, 14);
    });

    test('chaque icône dans le map est une IconData valide', () {
      for (var entry in AmenityUtils.amenityIcons.entries) {
        expect(entry.value, isA<IconData>(),
            reason: '${entry.key} doit avoir une IconData valide');
      }
    });
  });
}
