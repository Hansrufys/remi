import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'themeMode';
  
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      if (value == 'light') state = ThemeMode.light;
      if (value == 'dark') state = ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
    }
  }

  void updateAppColorsSync(BuildContext context) {
    // The framework handles the theme internally via `themeMode` on MaterialApp.
    // However, if we need to force brightness updates on specific views early,
    // we can do logic here. For now, it's not needed since AppColorsExtension responds 
    // to Theme.of(context) inherently via AppTheme.
  }
}
