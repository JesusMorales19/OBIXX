import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.deepOrange,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),
      ),
    );
  }
}
