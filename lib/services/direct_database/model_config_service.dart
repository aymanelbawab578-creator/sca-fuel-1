import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectModelConfigService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final rows = await _client.from('modelconfig').select().order('id');
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}