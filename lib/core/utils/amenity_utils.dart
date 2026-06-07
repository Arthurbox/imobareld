import 'package:flutter/material.dart';

class AmenityUtils {
  static final Map<String, IconData> amenityIcons = {
    'Wifi': Icons.wifi,
    'Climatisation': Icons.ac_unit,
    'Climatisé': Icons.ac_unit,
    'Piscine': Icons.pool,
    'Eau chaude': Icons.hot_tub,
    'Parking': Icons.local_parking,
    'Netflix': Icons.tv,
    'Canal+': Icons.live_tv,
    'Gaz': Icons.propane,
    'Frigo': Icons.kitchen,
    'Micro-ondes': Icons.microwave, 
    'Sécurité 24/7': Icons.security,
    'Sonabel': Icons.lightbulb_outline,
    'ONEA': Icons.water_drop_outlined,
  };

  static IconData getIcon(String amenity) {
    if (amenityIcons.containsKey(amenity)) {
      return amenityIcons[amenity]!;
    }
    // Fallback based on text if not exact match, or default
    return Icons.check_circle_outline;
  }
}
