import 'dart:typed_data';
import 'file_read_helper_io.dart' if (dart.library.html) 'file_read_helper_web.dart' as file_read_helper;

Future<Uint8List> readFileBytes(String path) async {
  return await file_read_helper.readFileBytes(path);
}
