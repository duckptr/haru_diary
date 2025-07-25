import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        primarySwatch: Colors.green, // primarySwatch는 제한된 색상만 가능
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B872C), // ✅ 앱바 색상
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B872C), // ✅ 버튼 배경
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
}
