import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'temporary_archive_store.dart';

class DirectArchiveService {
  static const _archivePrefix = 'direct_archive_';
  static const _temporaryPrefix = 'direct_archive_temporary_';

  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  // ============================================================
  // Archive List
  // ============================================================

  static Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.functions.invoke(
      'list-archives-from-github',
    );

    final data = response.data;

    if (data is! Map) {
      throw StateError(
        'جلب قائمة الأرشيفات من GitHub أعاد استجابة غير صالحة.',
      );
    }

    final result = Map<String, dynamic>.from(data);

    if (result['success'] != true) {
      throw StateError(
        result['error']?.toString() ??
            'فشل جلب قائمة الأرشيفات من GitHub.',
      );
    }

    final archives = result['archives'];

    if (archives is! List) {
      throw StateError(
        'قائمة الأرشيفات من GitHub غير صالحة.',
      );
    }

    return archives
        .whereType<Map>()
        .map(
          (archive) =>
              Map<String, dynamic>.from(archive),
        )
        .toList();
  }

  // ============================================================
  // Preview
  // ============================================================

  static Future<Map<String, dynamic>> preview(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filename =
        'sca_archive_${DateTime.now().millisecondsSinceEpoch}.sql';

    final content = await _generateArchive(
      filename: filename,
      startDate: startDate,
      endDate: endDate,
    );

    final metadata =
        _parseArchiveMetadata(content);

    return {
      'start_date': _date(startDate),
      'end_date': _date(endDate),
      'refuel_count':
          metadata['refuel_record_count'] ?? 0,
      'invoice_count':
          metadata['invoice_record_count'] ?? 0,
      'record_count':
          metadata['record_count'] ?? 0,
    };
  }

  // ============================================================
  // Create Archive
  // ============================================================

  static Future<Map<String, dynamic>> create(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final filename =
        'sca_archive_${DateTime.now().millisecondsSinceEpoch}.sql';

    final content = await _generateArchive(
      filename: filename,
      startDate: startDate,
      endDate: endDate,
    );

    // ----------------------------------------------------------
    // 1. رفع الأرشيف إلى GitHub
    // ----------------------------------------------------------

    final githubResult =
        await _saveToGitHub(
      filename: filename,
      content: content,
    );

    // ----------------------------------------------------------
    // 2. تسجيل الأرشيف في Supabase
    //
    // لا يتم تسجيله إلا بعد نجاح GitHub.
    // ----------------------------------------------------------

    final metadata =
        _parseArchiveMetadata(content);

    await _registerArchive(
      filename: filename,
      startDate: startDate,
      endDate: endDate,
      refuelCount:
          _toInt(metadata['refuel_record_count']),
      invoiceCount:
          _toInt(metadata['invoice_record_count']),
      recordCount:
          _toInt(metadata['record_count']),
    );

    // ----------------------------------------------------------
    // 3. الاحتفاظ بنسخة محلية
    // ----------------------------------------------------------

    await prefs.setString(
      _archivePrefix + filename,
      content,
    );

    return {
      ...metadata,
      'filename': filename,
      'size': utf8.encode(content).length,
      'github_url': githubResult['url'],
      'github_path': githubResult['path'],
    };
  }

  // ============================================================
  // Register Archive
  // ============================================================

  static Future<void> _registerArchive({
    required String filename,
    required DateTime startDate,
    required DateTime endDate,
    int? refuelCount,
    int? invoiceCount,
    int? recordCount,
  }) async {
    final result = await _client.rpc(
      'register_archive',
      params: {
        'p_filename': filename,
        'p_start_date': _date(startDate),
        'p_end_date': _date(endDate),
        'p_refuel_count': refuelCount ?? 0,
        'p_invoice_count': invoiceCount ?? 0,
        'p_record_count': recordCount ?? 0,
      },
    );

    if (result == null) {
      throw StateError(
        'تسجيل الأرشيف في قاعدة البيانات فشل.',
      );
    }

    final row = result is List
        ? (result.isEmpty ? null : result.first)
        : result;

    if (row is! Map) {
      throw StateError(
        'تسجيل الأرشيف أعاد نتيجة غير صالحة.',
      );
    }

    final data =
        Map<String, dynamic>.from(row);

    if (data['success'] != true) {
      throw StateError(
        data['error']?.toString() ??
            'فشل تسجيل الأرشيف في قاعدة البيانات.',
      );
    }
  }

  // ============================================================
  // Save To GitHub
  // ============================================================

  static Future<Map<String, dynamic>> _saveToGitHub({
    required String filename,
    required String content,
  }) async {
    final response =
        await _client.functions.invoke(
      'save-archive-to-github',
      body: {
        'filename': filename,
        'content': content,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw StateError(
        'رفع الأرشيف إلى GitHub أعاد استجابة غير صالحة.',
      );
    }

    final result =
        Map<String, dynamic>.from(data);

    if (result['success'] != true) {
      throw StateError(
        result['error']?.toString() ??
            'فشل رفع الأرشيف إلى GitHub.',
      );
    }

    return result;
  }

  // ============================================================
  // Generate Archive
  // ============================================================

  static Future<String> _generateArchive({
    required String filename,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _client.rpc(
      'generate_archive_sql',
      params: {
        'p_archive_name': filename,
        'p_start_date': _date(startDate),
        'p_end_date': _date(endDate),
      },
    );

    if (result == null) {
      throw StateError(
        'RPC إنشاء الأرشيف لم تُرجع بيانات.',
      );
    }

    return result.toString();
  }

  static Future<Map<String, dynamic>> status() async =>
      {
        'archives': await list(),
      };

  // ============================================================
  // Temporary Archive
  // ============================================================

  static Future<Map<String, dynamic>> loadTemporarily(
    String filename,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final alreadyLoaded =
        prefs.getBool(
              _temporaryPrefix + filename,
            ) ??
            false;

    if (alreadyLoaded) {
      throw StateError(
        'هذا الأرشيف محمّل بالفعل في الجلسة الحالية.',
      );
    }

    final response =
        await _client.functions.invoke(
      'get-archive-from-github',
      body: {
        'filename': filename,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw StateError(
        'تحميل الأرشيف من GitHub أعاد استجابة غير صالحة.',
      );
    }

    final result =
        Map<String, dynamic>.from(data);

    if (result['success'] != true) {
      throw StateError(
        result['error']?.toString() ??
            'فشل تحميل الأرشيف من GitHub.',
      );
    }

    final content = result['content'];

    if (content is! String ||
        content.isEmpty) {
      throw StateError(
        'محتوى الأرشيف من GitHub غير صالح.',
      );
    }

    TemporaryArchiveStore.load(
      filename: filename,
      content: content,
    );

    await prefs.setString(
      _archivePrefix + filename,
      content,
    );

    await prefs.setBool(
      _temporaryPrefix + filename,
      true,
    );

    return {
      'filename': filename,
      ..._parseArchiveMetadata(content),
    };
  }

  static Future<void> clearTemporary() async {
    final prefs =
        await SharedPreferences.getInstance();

    final temporaryKeys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(
                _temporaryPrefix,
              ),
        )
        .toList();

    for (final key in temporaryKeys) {
      await prefs.remove(key);
    }

    TemporaryArchiveStore.clear();
  }

  static Future<Map<String, dynamic>>
      temporaryStatus() async {
    final prefs =
        await SharedPreferences.getInstance();

    final temporaryArchives = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(
                _temporaryPrefix,
              ),
        )
        .map(
          (key) =>
              key.substring(
                _temporaryPrefix.length,
              ),
        )
        .toList()
      ..sort();

    return {
      'count':
          temporaryArchives.length,
      'filenames':
          temporaryArchives,
      'loaded':
          temporaryArchives.isNotEmpty,
    };
  }

  static Future<void> removeTemporary(
    String filename,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final key =
        _temporaryPrefix + filename;

    final exists =
        prefs.getBool(key) ?? false;

    if (!exists) {
      throw StateError(
        'هذا الأرشيف غير محمّل مؤقتًا في الجلسة الحالية.',
      );
    }

    TemporaryArchiveStore.remove(
      filename,
    );

    await prefs.remove(key);
  }

  // ============================================================
  // Archive Local Cache
  // ============================================================

  static Future<String> download(
    String filename,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final content =
        prefs.getString(
      _archivePrefix + filename,
    );

    if (content == null) {
      throw StateError(
        'الأرشيف غير موجود محليًا',
      );
    }

    return content;
  }

  static Future<void> delete(
    String filename,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    TemporaryArchiveStore.remove(
      filename,
    );

    await prefs.remove(
      _temporaryPrefix + filename,
    );

    await prefs.remove(
      _archivePrefix + filename,
    );
  }

  // ============================================================
  // Cleanup
  // ============================================================

  static Future<Map<String, dynamic>> cleanup({
    required DateTime startDate,
    required DateTime endDate,
    bool confirm = true,
  }) async {
    if (!confirm) {
      return {
        'cleaned': false,
      };
    }

    final result = await _client.rpc(
      'cleanup_archived_period',
      params: {
        'p_start_date': _date(startDate),
        'p_end_date': _date(endDate),
      },
    );

    final row = result is List
        ? (result.isEmpty ? null : result.first)
        : result;

    if (row is! Map) {
      throw StateError(
        'RPC تنظيف الأرشيف أعادت نتيجة غير صالحة.',
      );
    }

    final data =
        Map<String, dynamic>.from(row);

    if (data['success'] != true) {
      throw StateError(
        data['error']?.toString() ??
            'فشل تنظيف بيانات الأرشيف.',
      );
    }

    return {
      ...data,
      'cleaned': true,
    };
  }

  // ============================================================
  // Metadata
  // ============================================================

  static Map<String, dynamic>
      _parseArchiveMetadata(
    String content,
  ) {
    for (final line
        in const LineSplitter()
            .convert(content)) {
      const prefix =
          '-- SCA_ARCHIVE_METADATA';

      if (line.startsWith(prefix)) {
        final jsonText =
            line.substring(
          prefix.length,
        ).trim();

        try {
          final decoded =
              jsonDecode(jsonText);

          if (decoded is Map) {
            return Map<String, dynamic>.from(
              decoded,
            );
          }
        } catch (_) {
          return {};
        }
      }
    }

    return {};
  }

  static Map<String, dynamic> _metadata(
    String content,
  ) {
    final metadata =
        _parseArchiveMetadata(content);

    return {
      ...metadata,
      'size':
          utf8.encode(content).length,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
