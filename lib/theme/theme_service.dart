import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'theme_mode'; // 'light' | 'dark'

  static Future<ThemeMode> load() async {
    final pref = await SharedPreferences.getInstance();
    final s = pref.getString(_key);
    if (s == 'dark') return ThemeMode.dark;
    return ThemeMode.light; // 기본: 라이트
  }

  static Future<void> save(ThemeMode mode) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
