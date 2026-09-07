import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectUserService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<Map<String, dynamic>> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('لا توجد جلسة مستخدم.');
    return {
      'id': user.id,
      'username': user.userMetadata?['username'] ?? user.email,
      'full_name': user.userMetadata?['full_name'],
      'role': user.userMetadata?['role'] ?? 'Viewer',
      'is_active': true,
      'email': user.email,
    };
  }

  static Future<void> updateUsername(String username) async {
    final value = username.trim();
    if (value.isEmpty) throw ArgumentError('اسم المستخدم مطلوب');
    await _client.auth.updateUser(
      UserAttributes(data: {'username': value}),
    );
  }

  static Future<void> changePassword(String newPassword) async {
    if (newPassword.isEmpty) throw ArgumentError('كلمة المرور مطلوبة');
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}