import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF00E5FF), // couleur principale (cyan)
      useMaterial3: true,
      fontFamily: 'Roboto', // Utilise la Roboto locale
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF00E5FF), // couleur principale
      useMaterial3: true,
      fontFamily: 'Roboto', // Utilise la Roboto locale
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
