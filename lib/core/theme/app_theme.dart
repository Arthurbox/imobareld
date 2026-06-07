import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class AppTheme {
  
  // Utilitaire pour créer le MaterialColor (si besoin)
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255).round(), g = (color.g * 255).round(), b = (color.b * 255).round();

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.from(
        alpha: 1.0,
        red: (r + ((ds < 0 ? r : (255 - r)) * ds).round()) / 255.0,
        green: (g + ((ds < 0 ? g : (255 - g)) * ds).round()) / 255.0,
        blue: (b + ((ds < 0 ? b : (255 - b)) * ds).round()) / 255.0,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // COULEURS PRINCIPALES
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.background,
      
      // COLOR SCHEME
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: createMaterialColor(AppColors.primaryBlue),
      ).copyWith(
        secondary: AppColors.primaryOrange,
        surface: AppColors.cardBackground,
        error: AppColors.error,
      ),

      // APP BAR THEME
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // TEXT THEME
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textLight),
      ),

      // ELEVATED BUTTON THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // INPUT DECORATION THEME
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ICON THEME
      iconTheme: const IconThemeData(
        color: AppColors.primaryBlue,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // COULEURS PRINCIPALES
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: Colors.black,
      
      // COLOR SCHEME
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: createMaterialColor(const Color(0xFF42A5F5)),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF42A5F5),
        secondary: AppColors.primaryOrange,
        surface: const Color(0xFF121212), // Un gris très très sombre pour les cartes
        error: AppColors.error,
        onSurface: Colors.white,
      ),

      // APP BAR THEME
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // TEXT THEME
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),

      // ELEVATED BUTTON THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // INPUT DECORATION THEME
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ICON THEME
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      
      // BOTTOM NAVIGATION BAR THEME
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.white70,
      ),

      // CARD THEME
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 2,
      ),

      // LIST TILE THEME
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),

      // DIVIDER THEME
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
        thickness: 1,
      ),
    );
  }
}
