import 'dart:typed_data';

import 'file_picker_wrapper_io.dart' if (dart.library.html) 'file_picker_wrapper_web.dart' as file_picker_impl;

class PickedFileResult {
  final String? path;
  final Uint8List? bytes;

  PickedFileResult({this.path, this.bytes});
}

Future<PickedFileResult?> pickExcelFile() async {
  return await file_picker_impl.pickExcelFile();
}
