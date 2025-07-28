import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // ✅ 전체 배경 검정색
        primaryColor: const Color(0xFF0064FF), // ✅ 버튼 및 주요 색상

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // 앱바 배경 검정색
          foregroundColor: Colors.white, // 앱바 텍스트 흰색
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0064FF), // ✅ 버튼 파란색
            foregroundColor: Colors.white, // 버튼 텍스트 흰색
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 버튼 둥글게
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900], // 입력창 배경 어둡게
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF0064FF)),
            borderRadius: BorderRadius.circular(12),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
}
