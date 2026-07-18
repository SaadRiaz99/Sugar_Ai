import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier() : super(AppTheme.lightTheme);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.brightness == Brightness.dark) {
      state = AppTheme.lightTheme;
      await prefs.setBool('isDarkMode', false);
    } else {
      state = AppTheme.darkTheme;
      await prefs.setBool('isDarkMode', true);
    }
  }

  bool get isDarkMode => state.brightness == Brightness.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});
