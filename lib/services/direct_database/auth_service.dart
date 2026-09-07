import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectDatabaseAuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static String _emailForLogin(String login) {
    final value = login.trim();
    if (value.contains('@')) return value;
    if (AppConfig.usernameEmailDomain.isEmpty) {
      throw StateError(
        'يلزم ترحيل الحسابات إلى Supabase Auth أو ضبط '
        'SCA_USERNAME_EMAIL_DOMAIN قبل استخدام اسم المستخدم.',
      );
    }
    return '$value@${AppConfig.usernameEmailDomain}';
  }

  static String emailForLogin(String login) => _emailForLogin(login);

  static Future<String> login(String login, String password) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError(
        'Supabase غير مهيأ. شغّل التطبيق مع SCA_SUPABASE_URL و'
        'SCA_SUPABASE_ANON_KEY.',
      );
    }

    final response = await _client.auth.signInWithPassword(
      email: _emailForLogin(login),
      password: password,
    );
    final accessToken = response.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('لم يتم إنشاء جلسة Supabase للمستخدم.');
    }
    return accessToken;
  }

  static Future<void> restoreSession(String token) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ لاستعادة الجلسة.');
    }
    final session = _client.auth.currentSession;
    if (session == null || session.accessToken != token) {
      throw StateError('جلسة Supabase غير صالحة.');
    }
  }

  static Future<void> logout() => _client.auth.signOut();
}