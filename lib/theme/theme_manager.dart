import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waiter_app/theme/app_color_theme.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._();
  static ThemeManager get instance => _instance;
  ThemeManager._();

  static const _savedThemeKey = 'selected_theme_name';

  AppColorTheme _currentTheme = AppColorTheme.fallback();
  AppColorTheme get currentTheme => _currentTheme;

  Map<String, AppColorTheme> _availableThemes = {};
  List<String> get themeNames => _availableThemes.keys.toList();

  Future<void> loadThemes() async {
    try {
      final raw = await rootBundle.loadString('assets/theme/config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final mainTheme = AppColorTheme.fromJson(
        json['colors'] ?? {},
        name: 'default',
      );

      final themes = json['themes'] as Map<String, dynamic>? ?? {};
      _availableThemes = {
        'default': mainTheme,
        for (final entry in themes.entries)
          entry.key: AppColorTheme.fromJson(
            entry.value as Map<String, dynamic>,
            name: entry.key,
          ),
      };

      // Restore a previously chosen palette, if any — falls back to the
      // config's default if nothing was saved yet, or the saved name no
      // longer exists (e.g. config changed since last launch).
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_savedThemeKey);
      _currentTheme = (savedName != null ? _availableThemes[savedName] : null) ?? mainTheme;

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load themes: $e');
      _currentTheme = AppColorTheme.fallback();
      _availableThemes = {'default': _currentTheme};
      notifyListeners();
    }
  }

  Future<void> setTheme(String name) async {
    final theme = _availableThemes[name];
    if (theme == null) return;
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedThemeKey, name);
  }

  AppColorTheme getTheme(String name) {
    return _availableThemes[name] ?? _currentTheme;
  }
}