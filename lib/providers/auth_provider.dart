import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/direct_database/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'access_token');
    if (_token != null) {
      try {
        await DirectDatabaseAuthService.restoreSession(_token!);
      } catch (e) {
        _token = null;
        try {
          await _storage.delete(key: 'access_token');
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _token = await DirectDatabaseAuthService.login(username, password);
    await _storage.write(key: 'access_token', value: _token);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await DirectDatabaseAuthService.logout();
    } catch (_) {}
    _token = null;
    // Clear all secure storage keys to ensure no residual credentials remain.
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Fallback to deleting the specific key if deleteAll is unsupported.
      try {
        await _storage.delete(key: 'access_token');
      } catch (_) {}
    }

    // Ensure any SharedPreferences values are also cleared.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    notifyListeners();
  }
}
