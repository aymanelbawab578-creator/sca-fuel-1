import 'dart:typed_data';
import 'file_save_helper_io.dart'
    if (dart.library.html) 'file_save_helper_web.dart' as file_save_helper;

Future<void> saveBytesAsFile(String filename, Uint8List bytes) async {
  await file_save_helper.saveBytesAsFile(filename, bytes);
}
