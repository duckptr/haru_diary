import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show WidgetStateProperty, WidgetState;

class AppTheme {
  static const primaryBlue = Color(0xFF0064FF);

  // ========== LIGHT ==========
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: Color(0xFFF7F7F9),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1E1E1E),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      // M3 권장: 배경은 surface 계열 사용
      scaffoldBackgroundColor: scheme.surface,
      // 카드 배경색 통일
      cardColor: scheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.15),
        selectionHandleColor: scheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        hintStyle: const TextStyle(color: Colors.black54),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1E1E1E)),
        bodyMedium: TextStyle(color: Color(0xFF333333)),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E1E),
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent, // M3 틴트 제거
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8EEF9),
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.black87,
        contentTextStyle: TextStyle(color: Colors.white),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(primaryBlue),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(primaryBlue),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryBlue.withValues(alpha: 0.5)
              : Colors.black26,
        ),
      ),
    );
  }

  // ========== DARK ==========
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: Color(0xFF1E1E1E),
      error: Colors.red,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: scheme.surface,
      primaryColor: primaryBlue,

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white24,
        selectionHandleColor: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        labelStyle: TextStyle(color: Colors.white),
        shape: StadiumBorder(),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        contentTextStyle: TextStyle(color: Colors.white),
      ),

      dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A)),
      iconTheme: const IconThemeData(color: Colors.white),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(primaryBlue),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(primaryBlue),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryBlue.withValues(alpha: 0.5)
                  : Colors.white24,
        ),
      ),
    );
  }
}
