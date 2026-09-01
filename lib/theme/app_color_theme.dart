import 'package:flutter/material.dart';

class AppColorTheme {
  final Color brandLight;
  final Color brandDark;
  final Color content;
  final Color base;
  final Color alert;
  final String name;

  const AppColorTheme({
    required this.brandLight,
    required this.brandDark,
    required this.content,
    required this.base,
    required this.alert,
    this.name = 'default',
  });

  factory AppColorTheme.fromJson(
    Map<String, dynamic> json, {
    String name = 'default',
  }) {
    final fallback = AppColorTheme.fallback();
    return AppColorTheme(
      name: name,
      brandLight: _parseColor(json['brandLight'], fallback.brandLight),
      brandDark: _parseColor(json['brandDark'], fallback.brandDark),
      content: _parseColor(json['content'], fallback.content),
      base: _parseColor(json['base'], fallback.base),
      alert: _parseColor(json['alert'], fallback.alert),
    );
  }

  static AppColorTheme fallback() {
    return const AppColorTheme(
      brandLight: Color(0xFF925709),
      brandDark: Color(0xFF6E3F1F),
      content: Color(0xFF533205),
      base: Color(0xFFdaae90),
      alert: Color(0xFFFF0000),
    );
  }

  static Color _parseColor(dynamic value, Color defaultValue) {
    if (value == null) return defaultValue;
    try {
      if (value is int) return Color(value);
      if (value is String) {
        var v = value
            .trim()
            .toLowerCase()
            .replaceAll('#', '')
            .replaceFirst('0x', '');
        if (v.length == 3) v = '${v[0]}${v[0]}${v[1]}${v[1]}${v[2]}${v[2]}';
        if (v.length == 6) v = 'ff$v';
        if (v.length != 8) throw FormatException('Invalid color: $value');
        return Color(int.parse(v, radix: 16));
      }
    } catch (e) {
      debugPrint('❌ COLOR PARSE FAILED: $value → $e');
    }
    return defaultValue;
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: brandLight,
        secondary: brandDark,
        surface: base,
        onSurface: content,
        error: alert,
      ),
      scaffoldBackgroundColor: base,
      appBarTheme: AppBarTheme(
        backgroundColor: brandLight,
        foregroundColor: base,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: base,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandLight,
        foregroundColor: base,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: content),
        bodyMedium: TextStyle(color: content),
        titleLarge: TextStyle(color: brandLight),
      ),
    );
  }
}
