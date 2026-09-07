import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final saved = await _storage.read(key: 'dark_mode');
    _isDarkMode = saved == 'true';
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _storage.write(key: 'dark_mode', value: isDark.toString());
    notifyListeners();
  }

  ThemeData getLightTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAFAFB),
      canvasColor: const Color(0xFFFAFAFB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F2),
        foregroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        elevation: 0,
      ),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        elevation: 0,
      ),
    );
  }
}
